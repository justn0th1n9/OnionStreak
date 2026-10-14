import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/frequency.dart';
import '../models/habit.dart';

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
  int _idDasar(String habitId) {
    var h = 5381;
    for (final c in habitId.codeUnits) {
      h = ((h * 33) ^ c) & 0xFFFFF;
    }
    return h * 10;
  }

  Future<void> batal(String habitId) async {
    if (!_siap) return;
    try {
      final dasar = _idDasar(habitId);
      for (var i = 0; i <= 7; i++) {
        await _plugin.cancel(dasar + i);
      }
    } catch (e) {
      debugPrint('Gagal membatalkan pengingat: $e');
    }
  }

  Future<void> sinkron(List<Habit> habits) async {
    for (final h in habits) {
      await jadwalkan(h);
    }
  }

  Future<void> jadwalkan(Habit h) async {
    if (!_siap) return;
    try {
      await batal(h.id);
      if (h.pengingat == null || h.diarsipkan) return;
      final p = h.pengingat!.split(':');
      final jam = int.parse(p[0]);
      final menit = int.parse(p[1]);

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

      if (h.frekuensi.type == FrequencyType.hariTertentu) {
        for (final hari in h.frekuensi.days) {
          await _plugin.zonedSchedule(
            dasar + hari,
            judul,
            isi,
            _berikutnya(jam, menit, hari),
            detail,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      } else {
        await _plugin.zonedSchedule(
          dasar,
          judul,
          isi,
          _berikutnya(jam, menit, null),
          detail,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } catch (e) {
      debugPrint('Gagal menjadwalkan pengingat: $e');
    }
  }

  tz.TZDateTime _berikutnya(int jam, int menit, int? hariMinggu) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, jam, menit);
    while (t.isBefore(now) || (hariMinggu != null && t.weekday != hariMinggu)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }
}
