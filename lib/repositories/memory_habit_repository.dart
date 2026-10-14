import 'dart:async';

import '../models/frequency.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../utils/tanggal.dart';
import 'habit_repository.dart';

/// Penyimpanan di memori. Dipakai sebagai MODE DEMO saat Firebase belum
/// dikonfigurasi, dan berguna juga untuk pengujian. Data hilang saat aplikasi ditutup.
class MemoryHabitRepository implements HabitRepository {
  MemoryHabitRepository();

  factory MemoryHabitRepository.demo() {
    final r = MemoryHabitRepository();
    r._seed();
    return r;
  }

  final Map<String, Habit> _habits = {};
  final Map<String, Map<String, HabitLog>> _logs = {};
  final StreamController<List<Habit>> _habitCtrl = StreamController.broadcast();
  final Map<String, StreamController<Map<String, HabitLog>>> _logCtrls = {};
  int _seq = 0;

  List<Habit> _sorted() {
    final l = _habits.values.toList();
    l.sort((a, b) => a.urutan.compareTo(b.urutan));
    return l;
  }

  StreamController<Map<String, HabitLog>> _ctrl(String id) =>
      _logCtrls.putIfAbsent(id, () => StreamController.broadcast());

  void _emitHabits() => _habitCtrl.add(_sorted());
  void _emitLogs(String id) =>
      _ctrl(id).add(Map<String, HabitLog>.of(_logs[id] ?? <String, HabitLog>{}));

  @override
  Stream<List<Habit>> watchHabits() async* {
    yield _sorted();
    yield* _habitCtrl.stream;
  }

  @override
  Stream<Map<String, HabitLog>> watchLogs(String habitId) async* {
    yield Map<String, HabitLog>.of(_logs[habitId] ?? <String, HabitLog>{});
    yield* _ctrl(habitId).stream;
  }

  @override
  Future<String> addHabit(Habit habit) async {
    final id = 'm${++_seq}';
    _habits[id] = habit.copyWith(id: id);
    _emitHabits();
    return id;
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    _habits[habit.id] = habit;
    _emitHabits();
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    _habits.remove(habitId);
    _logs.remove(habitId);
    _emitHabits();
  }

  @override
  Future<void> saveLog(String habitId, HabitLog log) async {
    (_logs[habitId] ??= {})[log.tanggal] = log;
    _emitLogs(habitId);
  }

  @override
  Future<void> deleteLog(String habitId, String tanggal) async {
    _logs[habitId]?.remove(tanggal);
    _emitLogs(habitId);
  }

  // ---- data contoh ----
  void _put(Habit h) => _habits[h.id] = h;

  void _log(String id, DateTime d, {num? jumlah}) {
    (_logs[id] ??= {})[dateKey(d)] =
        HabitLog(tanggal: dateKey(d), selesai: true, jumlah: jumlah);
  }

  void _seed() {
    final today = dayOnly(DateTime.now());
    final mulai = dateKey(addDays(today, -40));
    _put(Habit(
      id: 'd1', nama: 'Minum air', ikon: 'water', warna: 0xFF1E88E5,
      frekuensi: const Frequency.daily(), targetAngka: 8, satuan: 'gelas',
      tanggalMulai: mulai, urutan: 1,
    ));
    _put(Habit(
      id: 'd2', nama: 'Olahraga', ikon: 'run', warna: 0xFFF57C00,
      frekuensi: const Frequency.onDays({1, 3, 5}),
      tanggalMulai: mulai, urutan: 2,
    ));
    _put(Habit(
      id: 'd3', nama: 'Membaca', ikon: 'book', warna: 0xFF7B3F8C,
      frekuensi: const Frequency.perWeek(3),
      tanggalMulai: mulai, urutan: 3,
    ));
    for (var i = 1; i <= 40; i++) {
      final d = addDays(today, -i);
      if (i % 11 != 5) _log('d1', d, jumlah: 8);
      if ([1, 3, 5].contains(d.weekday) && i % 9 != 4) _log('d2', d);
      if (i % 3 != 1) _log('d3', d);
    }
  }
}
