import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/frequency.dart';
import '../models/habit.dart';
import '../utils/tanggal.dart';

/// Pengingat harian (notifikasi lokal). Seluruh kode paket notifikasi ada di
/// file ini saja. Semua pemanggilan dibungkus try/catch agar kegagalan
/// notifikasi tidak pernah membuat aplikasi crash.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _siap = false;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      final nama = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(nama));
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
          const InitializationSettings(android: android, iOS: ios));
      _siap = true;
    } catch (e) {
      debugPrint('Notifikasi tidak aktif: $e');
    }
  }

  Future<bool> mintaIzin() async {
    if (!_siap) return false;
    try {
      final a = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      final i = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return a ?? i ?? false;
    } catch (e) {
      debugPrint('Gagal meminta izin notifikasi: $e');
      return false;
    }
  }

    // Hash sederhana dan stabil (String.hashCode tidak dijamin sama antar-proses).
  int _hash(String habitId) {
    var h = 5381;
    for (final c in habitId.codeUnits) {
      h = ((h * 33) ^ c) & 0xFFFFF;
    }
    return h;
  }

  // Tiap kebiasaan memakai blok 100 ID: dasar + slot * 8 + hari
  // (slot 0..kMaksPengingat-1 = urutan jam, hari 0 = tiap hari, 1..7 = Senin..Minggu).
  int _idDasar(String habitId) => _hash(habitId) * 100;

  // Skema ID versi sebelumnya (satu jam per kebiasaan). Dibatalkan juga agar
  // pengingat lama tidak muncul dobel setelah pembaruan.
  int _idLama(String habitId) => _hash(habitId) * 10;

  // Semua operasi dijalankan berurutan supaya batal + jadwal ulang tidak saling tindih.
  Future<void> _rantai = Future<void>.value();
  Future<void> _antri(Future<void> Function() kerja) {
    final hasil = _rantai.then((_) => kerja());
    _rantai = hasil.catchError((Object _) {});
    return hasil;
  }

  // Tanda tangan jadwal terakhir per kebiasaan: jadwal ulang dilewati bila tidak berubah.
  final Map<String, String> _tanda = {};

  Future<void> batal(String habitId) => _antri(() => _batalSekarang(habitId));

  Future<void> _batalSekarang(String habitId) async {
    _tanda.remove(habitId);
    if (!_siap) return;
    try {
      final dasar = _idDasar(habitId);
      final lama = _idLama(habitId);
      final tugas = <Future<void>>[
        for (var slot = 0; slot < kMaksPengingat; slot++)
          for (var hari = 0; hari <= 7; hari++) _plugin.cancel(dasar + slot * 8 + hari),
        for (var i = 0; i <= 7; i++) _plugin.cancel(lama + i),
      ];
      await Future.wait(tugas);
    } catch (e) {
      debugPrint('Gagal membatalkan pengingat: $e');
    }
  }

  /// [tundaUntuk] mengembalikan tanggal paling awal pengingat boleh muncul
  /// (null = boleh mulai hari ini). Dipakai untuk pengingat pintar.
  Future<void> sinkron(
      List<Habit> habits, DateTime? Function(Habit h) tundaUntuk) async {
    for (final h in habits) {
      await jadwalkan(h, tundaHingga: tundaUntuk(h));
    }
  }

  /// Menjadwalkan semua jam pengingat sebuah kebiasaan.
  ///
  /// Pengingat pintar: bila [tundaHingga] diisi (misalnya kebiasaan hari ini sudah
  /// dicentang), kemunculan pertama digeser ke tanggal itu lalu berulang seperti biasa.
  /// Selain itu hari jeda dan hari sebelum tanggal mulai juga dilewati.
  Future<void> jadwalkan(Habit h, {DateTime? tundaHingga}) => _antri(() async {
        if (!_siap) return;
        final tanda =
            '${h.toMap()}|${tundaHingga == null ? '' : dateKey(tundaHingga)}';
        if (_tanda[h.id] == tanda) return;
        try {
          await _batalSekarang(h.id);
          if (h.pengingat.isEmpty || h.diarsipkan) {
            _tanda[h.id] = tanda;
            return;
          }

          const detail = NotificationDetails(
            android: AndroidNotificationDetails(
              'onionstreak_pengingat',
              'Pengingat kebiasaan',
              channelDescription: 'Pengingat harian untuk kebiasaanmu',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          );
          final judul = h.nama;
          final isi = 'Saatnya ${h.nama}. Jaga streak-mu!';
          final dasar = _idDasar(h.id);

          for (var slot = 0;
              slot < h.pengingat.length && slot < kMaksPengingat;
              slot++) {
            final p = h.pengingat[slot].split(':');
            final jam = int.parse(p[0]);
            final menit = int.parse(p[1]);
            final idSlot = dasar + slot * 8;

            if (h.frekuensi.type == FrequencyType.hariTertentu) {
              for (final hari in h.frekuensi.days) {
                await _plugin.zonedSchedule(
                  idSlot + hari,
                  judul,
                  isi,
                  _berikutnya(h, jam, menit, hari, tundaHingga),
                  detail,
                  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                  uiLocalNotificationDateInterpretation:
                      UILocalNotificationDateInterpretation.absoluteTime,
                  matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
                );
              }
            } else {
              await _plugin.zonedSchedule(
                idSlot,
                judul,
                isi,
                _berikutnya(h, jam, menit, null, tundaHingga),
                detail,
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                uiLocalNotificationDateInterpretation:
                    UILocalNotificationDateInterpretation.absoluteTime,
                matchDateTimeComponents: DateTimeComponents.time,
              );
            }
          }
          _tanda[h.id] = tanda;
        } catch (e) {
          debugPrint('Gagal menjadwalkan pengingat: $e');
        }
      });

  /// Kemunculan pertama: jam [jam]:[menit] terdekat yang belum lewat, cocok dengan
  /// [hariMinggu] (bila ada), tidak sebelum [tundaHingga], tidak di masa jeda, dan
  /// tidak sebelum tanggal mulai kebiasaan.
  tz.TZDateTime _berikutnya(
      Habit h, int jam, int menit, int? hariMinggu, DateTime? tundaHingga) {
    final now = tz.TZDateTime.now(tz.local);
    final batas = tundaHingga == null ? null : dateKey(tundaHingga);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, jam, menit);
    for (var i = 0; i < 400; i++) {
      final k = dateKey(t);
      final lewat = t.isBefore(now);
      final salahHari = hariMinggu != null && t.weekday != hariMinggu;
      final ditunda = (batas != null && k.compareTo(batas) < 0) ||
          h.isPausedOn(t) ||
          k.compareTo(h.tanggalMulai) < 0;
      if (!lewat && !salahHari && !ditunda) break;
      t = tz.TZDateTime(tz.local, t.year, t.month, t.day + 1, jam, menit);
    }
    return t;
  }
}
