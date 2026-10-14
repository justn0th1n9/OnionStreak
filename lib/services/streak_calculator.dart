import 'dart:math' as math;

import '../models/frequency.dart';
import '../models/habit.dart';
import '../utils/tanggal.dart';

class StreakResult {
  /// Streak saat ini (hari, atau minggu untuk kebiasaan "X kali per minggu").
  final int current;

  /// Streak terpanjang di seluruh riwayat.
  final int longest;

  /// Panjang setiap rangkaian yang pernah terputus/berjalan (untuk lencana).
  final List<int> runs;

  final bool perMinggu;

  const StreakResult(this.current, this.longest, this.runs, this.perMinggu);

  String get unit => perMinggu ? 'minggu' : 'hari';
}

/// Streak TIDAK disimpan sebagai angka. Selalu dihitung dari riwayat centang,
/// sehingga koreksi centang hari lalu otomatis membuat streak benar.
class StreakCalculator {
  static StreakResult hitung(Habit h, Set<String> selesai, DateTime hariIni) {
    final today = dayOnly(hariIni);
    if (h.frekuensi.type == FrequencyType.perMinggu) {
      return _mingguan(h, selesai, today);
    }
    return _harian(h, selesai, today);
  }

  static StreakResult _harian(Habit h, Set<String> selesai, DateTime today) {
    final start = parseKey(h.tanggalMulai);
    final runs = <int>[];
    var run = 0;
    for (var d = start; !d.isAfter(today); d = addDays(d, 1)) {
      if (!h.isScheduledOn(d)) continue; // hari tak terjadwal / dijeda dilewati
      if (selesai.contains(dateKey(d))) {
        run++;
      } else if (sameDay(d, today)) {
        // Hari ini belum dicentang: belum memutus streak.
      } else {
        if (run > 0) runs.add(run);
        run = 0;
      }
    }
    if (run > 0) runs.add(run);
    return StreakResult(run, runs.isEmpty ? 0 : runs.reduce(math.max), runs, false);
  }

  static StreakResult _mingguan(Habit h, Set<String> selesai, DateTime today) {
    final target = h.frekuensi.timesPerWeek.clamp(1, 7);
    final awal = weekStart(parseKey(h.tanggalMulai));
    final mingguIni = weekStart(today);
    final runs = <int>[];
    var run = 0;
    for (var w = awal; !w.isAfter(mingguIni); w = addDays(w, 7)) {
      var hitung = 0;
      var semuaDijeda = true;
      for (var i = 0; i < 7; i++) {
        final d = addDays(w, i);
        if (!h.isPausedOn(d)) semuaDijeda = false;
        if (!d.isAfter(today) &&
            !h.isPausedOn(d) &&
            selesai.contains(dateKey(d))) {
          hitung++;
        }
      }
      if (semuaDijeda) continue;
      if (hitung >= target) {
        run++;
      } else if (sameDay(w, mingguIni)) {
        // Minggu berjalan belum mencapai target: belum memutus.
      } else {
        if (run > 0) runs.add(run);
        run = 0;
      }
    }
    if (run > 0) runs.add(run);
    return StreakResult(run, runs.isEmpty ? 0 : runs.reduce(math.max), runs, true);
  }
}
