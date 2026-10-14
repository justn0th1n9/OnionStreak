import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import 'habit_repository.dart';

/// Struktur:
///   users/{uid}/habits/{habitId}
///   users/{uid}/habits/{habitId}/logs/{YYYY-MM-DD}
///
/// Catatan penting: Future dari operasi tulis Firestore baru selesai setelah
/// server membalas. Saat offline, Future itu menggantung. Karena itu penulisan
/// tidak di-await; tampilan tetap langsung berubah lewat cache lokal
/// (latency compensation) dan data tersinkron sendiri saat online.
class FirestoreHabitRepository implements HabitRepository {
  FirestoreHabitRepository({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _habits => _db
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('habits');

  void _api(Future<void> f) {
    unawaited(f.catchError((Object e) {
      debugPrint('Firestore: $e');
    }));
  }

  @override
  Stream<List<Habit>> watchHabits() => _habits
      .orderBy('urutan')
      .snapshots()
      .map((s) => s.docs.map((d) => Habit.fromMap(d.id, d.data())).toList());

  @override
  Stream<Map<String, HabitLog>> watchLogs(String habitId) =>
      _habits.doc(habitId).collection('logs').snapshots().map((s) => {
            for (final d in s.docs) d.id: HabitLog.fromMap(d.id, d.data()),
          });

  @override
  Future<String> addHabit(Habit habit) async {
    final ref = _habits.doc();
    _api(ref.set(habit.toMap()));
    return ref.id;
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    _api(_habits.doc(habit.id).set(habit.toMap()));
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    final ref = _habits.doc(habitId);
    final logs = await ref.collection('logs').get();
    final batch = _db.batch();
    for (final d in logs.docs) {
      batch.delete(d.reference);
    }
    batch.delete(ref);
    _api(batch.commit());
  }

  @override
  Future<void> saveLog(String habitId, HabitLog log) async {
    _api(_habits.doc(habitId).collection('logs').doc(log.tanggal).set(log.toMap()));
  }

  @override
  Future<void> deleteLog(String habitId, String tanggal) async {
    _api(_habits.doc(habitId).collection('logs').doc(tanggal).delete());
  }
}
