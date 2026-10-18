import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/frequency.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../utils/tanggal.dart';
import 'streak_calculator.dart';

class Hitungan {
  final double harapan;
  final double selesai;
  const Hitungan(this.harapan, this.selesai);
  static const kosong = Hitungan(0, 0);

  Hitungan operator +(Hitungan o) =>
      Hitungan(harapan + o.harapan, selesai + o.selesai);

  /// Null bila tidak ada yang diharapkan pada rentang tersebut.
  double? get rasio =>
      harapan <= 0 ? null : (selesai / harapan).clamp(0.0, 1.0).toDouble();
}

class BadgeInfo {
  final String nama;
  final String deskripsi;
  final IconData ikon;
  final bool diraih;
  const BadgeInfo(this.nama, this.deskripsi, this.ikon, this.diraih);
}

class StatsService {
  static Hitungan hitung(
      Habit h, Set<String> selesai, DateTime from, DateTime to, DateTime today) {
    final start = parseKey(h.tanggalMulai);
    final a = dayOnly(from).isBefore(start) ? start : dayOnly(from);
    final t = dayOnly(today);
    final b = dayOnly(to).isAfter(t) ? t : dayOnly(to);
    if (a.isAfter(b)) return Hitungan.kosong;

    if (h.frekuensi.type == FrequencyType.perMinggu) {
      var hari = 0, got = 0;
      for (var d = a; !d.isAfter(b); d = addDays(d, 1)) {
        if (h.isPausedOn(d)) continue;
        hari++;
        if (selesai.contains(dateKey(d))) got++;
      }
      final harapan = h.frekuensi.timesPerWeek * hari / 7;
      return Hitungan(harapan, math.min(got.toDouble(), harapan));
    }

    var harapan = 0, ok = 0;
    for (var d = a; !d.isAfter(b); d = addDays(d, 1)) {
      if (!h.isScheduledOn(d)) continue;
      harapan++;
      if (selesai.contains(dateKey(d))) ok++;
    }
    return Hitungan(harapan.toDouble(), ok.toDouble());
  }

  static Hitungan hitungSemua(List<Habit> habits, Map<String, Set<String>> done,
      DateTime from, DateTime to, DateTime today) {
    var total = Hitungan.kosong;
    for (final h in habits) {
      total += hitung(h, done[h.id] ?? <String>{}, from, to, today);
    }
    return total;
  }

  /// Contoh: "Kamu paling konsisten di hari Senin (87%)".
  static String? wawasan(
      List<Habit> habits, Map<String, Set<String>> done, DateTime today) {
    final harapan = List<int>.filled(7, 0);
    final ok = List<int>.filled(7, 0);
    final from = addDays(dayOnly(today), -89);
    for (final h in habits) {
      if (h.frekuensi.type == FrequencyType.perMinggu) continue;
      final s = done[h.id] ?? <String>{};
      for (var d = from; !d.isAfter(today); d = addDays(d, 1)) {
        if (!h.isScheduledOn(d)) continue;
        harapan[d.weekday - 1]++;
        if (s.contains(dateKey(d))) ok[d.weekday - 1]++;
      }
    }
    int? terbaik;
    double rBaik = -1;
    int? terburuk;
    double rBuruk = 2;
    for (var i = 0; i < 7; i++) {
      if (harapan[i] < 3) continue;
      final r = ok[i] / harapan[i];
      if (r > rBaik) {
        rBaik = r;
        terbaik = i;
      }
      if (r < rBuruk) {
        rBuruk = r;
        terburuk = i;
      }
    }
    if (terbaik == null) return null;
    final baik =
        'Kamu paling konsisten di hari ${namaHariPanjang[terbaik]} (${(rBaik * 100).round()}%).';
    if (terburuk != null && terburuk != terbaik && rBuruk < rBaik - 0.1) {
      return '$baik Hari ${namaHariPanjang[terburuk]} paling sering terlewat (${(rBuruk * 100).round()}%).';
    }
    return baik;
  }

  static List<BadgeInfo> lencana(
      List<Habit> habits, Map<String, Set<String>> done, DateTime today,
      {Map<String, Map<String, HabitLog>> logs = const {}}) {
    var total = 0, terpanjang = 0;
    var bangkit = false;
    final perHari = <String, int>{}; // tanggal -> jumlah centang semua kebiasaan
    for (final h in habits) {
      final d = done[h.id] ?? <String>{};
      total += d.length;
      for (final k in d) {
        perHari[k] = (perHari[k] ?? 0) + 1;
      }
      final s = StreakCalculator.hitung(h, d, today);
      final hari = s.perMinggu ? s.longest * 7 : s.longest;
      if (hari > terpanjang) terpanjang = hari;
      if (s.runs.where((r) => r >= 3).length >= 2) bangkit = true;
    }

    // Lima sekaligus: 5 centang atau lebih dalam satu hari.
    final limaSekaligus = perHari.values.any((v) => v >= 5);

    // Hari sempurna: minimal 2 kebiasaan terjadwal di hari itu dan semuanya selesai.
    // Kebiasaan "N kali per minggu" tidak punya hari tetap, jadi dilewati.
    var hariSempurna = false;
    final terjadwal = habits
        .where((h) => !h.diarsipkan && h.frekuensi.type != FrequencyType.perMinggu)
        .toList();
    if (terjadwal.length >= 2) {
      for (final key in perHari.keys) {
        final d = parseKey(key);
        var jadwal = 0;
        var semua = true;
        for (final h in terjadwal) {
          if (!h.isScheduledOn(d)) continue;
          jadwal++;
          if (!(done[h.id] ?? <String>{}).contains(key)) {
            semua = false;
            break;
          }
        }
        if (semua && jadwal >= 2) {
          hariSempurna = true;
          break;
        }
      }
    }

    // Sebulan sempurna: satu kebiasaan menyelesaikan semua jadwalnya dalam satu
    // bulan kalender penuh (kebiasaan sudah ada sejak tanggal 1 bulan itu).
    var sebulan = false;
    final hariIni = dayOnly(today);
    for (final h in habits) {
      if (sebulan) break;
      if (h.frekuensi.type == FrequencyType.perMinggu) continue;
      final s = done[h.id] ?? <String>{};
      final mulai = parseKey(h.tanggalMulai);
      var bulan = mulai.day == 1
          ? DateTime(mulai.year, mulai.month, 1)
          : DateTime(mulai.year, mulai.month + 1, 1);
      while (true) {
        final akhir = DateTime(bulan.year, bulan.month + 1, 0);
        if (akhir.isAfter(hariIni)) break;
        var jadwal = 0, ok = 0;
        for (var d = bulan; !d.isAfter(akhir); d = addDays(d, 1)) {
          if (!h.isScheduledOn(d)) continue;
          jadwal++;
          if (s.contains(dateKey(d))) ok++;
        }
        if (jadwal >= 4 && ok == jadwal) {
          sebulan = true;
          break;
        }
        bulan = DateTime(bulan.year, bulan.month + 1, 1);
      }
    }

    // Pagi hari (centang antara 04.00 dan 08.00) dan jumlah catatan.
    var pagi = false;
    var catatan = 0;
    for (final m in logs.values) {
      for (final l in m.values) {
        final w = l.waktu;
        if (l.selesai && w != null && w.compareTo('04:00') >= 0 && w.compareTo('08:00') < 0) {
          pagi = true;
        }
        if (l.catatan != null && l.catatan!.trim().isNotEmpty) catatan++;
      }
    }

    return [
      BadgeInfo('Langkah pertama', 'Centang kebiasaan pertamamu', Icons.flag, total >= 1),
      BadgeInfo('Seminggu penuh', 'Streak 7 hari', Icons.local_fire_department, terpanjang >= 7),
      BadgeInfo('Bangkit lagi', 'Mulai lagi setelah streak putus', Icons.replay, bangkit),
      BadgeInfo('Konsisten 30 hari', 'Streak 30 hari', Icons.emoji_events, terpanjang >= 30),
      BadgeInfo('Seratus hari', 'Streak 100 hari', Icons.military_tech, terpanjang >= 100),
      BadgeInfo('Pagi hari', 'Centang kebiasaan antara jam 04.00 dan 08.00', Icons.wb_sunny, pagi),
      BadgeInfo('Hari sempurna', 'Semua kebiasaan terjadwal selesai dalam satu hari (min. 2)',
          Icons.stars, hariSempurna),
      BadgeInfo('Lima sekaligus', 'Selesaikan 5 kebiasaan dalam satu hari', Icons.checklist, limaSekaligus),
      BadgeInfo('Sebulan sempurna', 'Semua jadwal satu kebiasaan selesai dalam satu bulan kalender',
          Icons.calendar_month, sebulan),
      BadgeInfo('Si pencatat', 'Tulis 10 catatan harian', Icons.edit_note, catatan >= 10),
      BadgeInfo('Seratus centang', 'Total 100 centang', Icons.done_all, total >= 100),
    ];
  }
}
