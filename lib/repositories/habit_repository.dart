import '../models/habit.dart';
import '../models/habit_log.dart';

/// Satu-satunya pintu ke penyimpanan data. UI tidak tahu apakah datanya
/// berasal dari Firestore atau dari memori (mode demo).
abstract class HabitRepository {
  Stream<List<Habit>> watchHabits();

  /// Peta tanggal ("YYYY-MM-DD") -> log.
  Stream<Map<String, HabitLog>> watchLogs(String habitId);

  /// Mengembalikan id baru.
  Future<String> addHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(String habitId);

  Future<void> saveLog(String habitId, HabitLog log);
  Future<void> deleteLog(String habitId, String tanggal);
}
