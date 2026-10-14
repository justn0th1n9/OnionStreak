import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/frequency.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../repositories/habit_repository.dart';
import '../services/notification_service.dart';
import '../services/streak_calculator.dart';
import '../utils/tanggal.dart';

const Set<int> kMilestones = {7, 14, 30, 50, 100, 200, 365};

class HabitStore extends ChangeNotifier {
  HabitStore(this.repo, this.notifications) {
    _listen();
  }

  final HabitRepository repo;
  final NotificationService notifications;

  List<Habit> _habits = [];
  final Map<String, Map<String, HabitLog>> _logs = {};
  final Map<String, StreamSubscription<Map<String, HabitLog>>> _logSubs = {};
  StreamSubscription<List<Habit>>? _habitSub;

  bool loading = true;
  String? error;

  // ---------- baca ----------
  List<Habit> get active => _habits.where((h) => !h.diarsipkan).toList();
  List<Habit> get archived => _habits.where((h) => h.diarsipkan).toList();
  List<Habit> get all => List.unmodifiable(_habits);

  Habit? byId(String id) {
    for (final h in _habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  Map<String, HabitLog> logsOf(String id) => _logs[id] ?? const {};
  HabitLog? logOn(Habit h, DateTime d) => logsOf(h.id)[dateKey(d)];
  bool isDone(Habit h, DateTime d) => logOn(h, d)?.selesai ?? false;

  Set<String> doneKeys(String id) => {
        for (final e in logsOf(id).entries)
          if (e.value.selesai) e.key,
      };

  Map<String, Set<String>> doneMap(Iterable<Habit> habits) =>
      {for (final h in habits) h.id: doneKeys(h.id)};

  StreakResult streak(Habit h) =>
      StreakCalculator.hitung(h, doneKeys(h.id), DateTime.now());

  int selesaiMingguIni(Habit h) {
    final ws = weekStart(DateTime.now());
    var c = 0;
    for (var i = 0; i < 7; i++) {
      if (isDone(h, addDays(ws, i))) c++;
    }
    return c;
  }

  // ---------- langganan data ----------
  void _listen() {
    loading = true;
    _habitSub = repo.watchHabits().listen(_onHabits, onError: (Object e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    });
  }

  void _onHabits(List<Habit> list) {
    final ids = list.map((h) => h.id).toSet();
    final dihapus = _habits.map((h) => h.id).toSet().difference(ids);
    for (final id in dihapus) {
      _logSubs.remove(id)?.cancel();
      _logs.remove(id);
      unawaited(notifications.batal(id));
    }
    _habits = list;
    for (final id in ids) {
      if (_logSubs.containsKey(id)) continue;
      _logSubs[id] = repo.watchLogs(id).listen((m) {
        _logs[id] = m;
        notifyListeners();
      }, onError: (Object e) {
        error = e.toString();
        notifyListeners();
      });
    }
    loading = false;
    error = null;
    notifyListeners();
    // Selaraskan pengingat dengan daftar kebiasaan (juga memulihkan pengingat di perangkat baru).
    unawaited(notifications.sinkron(list));
  }

  /// Dipanggil setelah pengguna masuk/keluar akun (uid berubah).
  Future<void> reload() async {
    await _habitSub?.cancel();
    for (final s in _logSubs.values) {
      await s.cancel();
    }
    _logSubs.clear();
    _logs.clear();
    for (final h in _habits) {
      unawaited(notifications.batal(h.id));
    }
    _habits = [];
    loading = true;
    notifyListeners();
    _listen();
  }

  // ---------- tulis ----------
  Future<void> addHabit(Habit h) =>
      repo.addHabit(h.copyWith(urutan: DateTime.now().millisecondsSinceEpoch));

  Future<void> updateHabit(Habit h) => repo.updateHabit(h);

  Future<void> deleteHabit(Habit h) async {
    await notifications.batal(h.id);
    await repo.deleteHabit(h.id);
  }

  Future<void> setArsip(Habit h, bool arsip) =>
      repo.updateHabit(h.copyWith(diarsipkan: arsip));

  Future<void> jeda(Habit h, DateTime sampai) => repo.updateHabit(h.copyWith(
      jedaDari: dateKey(DateTime.now()), jedaSampai: dateKey(sampai)));

  Future<void> lanjutkan(Habit h) =>
      repo.updateHabit(h.copyWith(jedaDari: null, jedaSampai: null));

  /// Centang/batalkan satu hari. Mengembalikan angka milestone bila tercapai.
  Future<int?> toggleDay(Habit h, DateTime d) {
    final lama = logOn(h, d);
    final selesai = !(lama?.selesai ?? false);
    return saveDay(
      h,
      d,
      done: selesai,
      amount: selesai ? (h.punyaTarget ? h.targetAngka : lama?.jumlah) : null,
      note: lama?.catatan,
    );
  }

  Future<int?> saveDay(Habit h, DateTime d,
      {required bool done, num? amount, String? note}) async {
    final key = dateKey(d);
    final sebelum = streak(h).current;

    // Mengisi hari sebelum tanggal mulai: majukan tanggal mulai agar hari itu dihitung.
    var habit = h;
    if (key.compareTo(h.tanggalMulai) < 0) {
      habit = h.copyWith(tanggalMulai: key);
      await repo.updateHabit(habit);
    }

    final kosong = !done &&
        (amount == null || amount == 0) &&
        (note == null || note.trim().isEmpty);
    if (kosong) {
      await repo.deleteLog(h.id, key);
    } else {
      await repo.saveLog(
          h.id,
          HabitLog(
              tanggal: key, selesai: done, jumlah: amount, catatan: note?.trim()));
    }

    final set = doneKeys(h.id);
    if (done) {
      set.add(key);
    } else {
      set.remove(key);
    }
    final sesudah = StreakCalculator.hitung(habit, set, DateTime.now()).current;
    if (done && sesudah > sebelum && kMilestones.contains(sesudah)) {
      return sesudah;
    }
    return null;
  }

  @override
  void dispose() {
    _habitSub?.cancel();
    for (final s in _logSubs.values) {
      s.cancel();
    }
    super.dispose();
  }
}

String unitStreak(Habit h) =>
    h.frekuensi.type == FrequencyType.perMinggu ? 'minggu' : 'hari';
