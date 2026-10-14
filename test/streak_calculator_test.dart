import 'package:flutter_test/flutter_test.dart';
import 'package:onionstreak/models/frequency.dart';
import 'package:onionstreak/models/habit.dart';
import 'package:onionstreak/services/streak_calculator.dart';
import 'package:onionstreak/utils/tanggal.dart';

Habit habit(String mulai, [Frequency f = const Frequency.daily()]) => Habit(
      id: 'h',
      nama: 'Tes',
      ikon: 'check',
      warna: 0xFF7B3F8C,
      frekuensi: f,
      tanggalMulai: mulai,
    );

Set<String> keys(List<DateTime> l) => l.map(dateKey).toSet();

void main() {
  group('Harian', () {
    test('contoh di laporan: 1-3 selesai, 4 terlewat, 5-6 selesai, hari ini (7) belum', () {
      final h = habit('2026-10-01');
      final done = keys([
        DateTime(2026, 10, 1), DateTime(2026, 10, 2), DateTime(2026, 10, 3),
        DateTime(2026, 10, 5), DateTime(2026, 10, 6),
      ]);
      final r = StreakCalculator.hitung(h, done, DateTime(2026, 10, 7));
      expect(r.current, 2);
      expect(r.longest, 3);
    });

    test('riwayat kosong', () {
      final r = StreakCalculator.hitung(habit('2026-10-01'), {}, DateTime(2026, 10, 7));
      expect(r.current, 0);
      expect(r.longest, 0);
    });

    test('hanya hari ini yang dicentang', () {
      final r = StreakCalculator.hitung(
          habit('2026-10-07'), keys([DateTime(2026, 10, 7)]), DateTime(2026, 10, 7));
      expect(r.current, 1);
      expect(r.longest, 1);
    });

    test('kemarin terlewat memutus streak', () {
      final done = keys([DateTime(2026, 10, 4), DateTime(2026, 10, 5)]);
      final r = StreakCalculator.hitung(habit('2026-10-01'), done, DateTime(2026, 10, 7));
      expect(r.current, 0);
      expect(r.longest, 2);
    });

    test('pergantian bulan dan tahun', () {
      final done = keys([
        DateTime(2025, 12, 29), DateTime(2025, 12, 30), DateTime(2025, 12, 31),
        DateTime(2026, 1, 1), DateTime(2026, 1, 2),
      ]);
      final r = StreakCalculator.hitung(habit('2025-12-29'), done, DateTime(2026, 1, 2));
      expect(r.current, 5);
      expect(r.longest, 5);
    });

    test('koreksi centang: membatalkan hari tengah memecah streak', () {
      final semua = [for (var d = 1; d <= 6; d++) DateTime(2026, 10, d)];
      final h = habit('2026-10-01');
      expect(StreakCalculator.hitung(h, keys(semua), DateTime(2026, 10, 6)).current, 6);
      final koreksi = keys(semua)..remove('2026-10-03');
      final r = StreakCalculator.hitung(h, koreksi, DateTime(2026, 10, 6));
      expect(r.current, 3);
      expect(r.longest, 3);
    });

    test('hari sebelum tanggal mulai tidak dihitung terlewat', () {
      final r = StreakCalculator.hitung(
          habit('2026-10-07'), keys([DateTime(2026, 10, 7)]), DateTime(2026, 10, 7));
      expect(r.current, 1);
    });

    test('hari jeda tidak memutus streak', () {
      final h = habit('2026-10-01').copyWith(jedaDari: '2026-10-04', jedaSampai: '2026-10-05');
      final done = keys([
        DateTime(2026, 10, 1), DateTime(2026, 10, 2), DateTime(2026, 10, 3),
        DateTime(2026, 10, 6),
      ]);
      final r = StreakCalculator.hitung(h, done, DateTime(2026, 10, 6));
      expect(r.current, 4);
    });
  });

  group('Hari tertentu (Sen, Rab, Jum)', () {
    // 5 Okt 2026 = Senin
    final f = Frequency.onDays({1, 3, 5});

    test('hari tak terjadwal tidak memutus streak', () {
      final done = keys([DateTime(2026, 10, 5), DateTime(2026, 10, 7)]);
      final r = StreakCalculator.hitung(habit('2026-10-05', f), done, DateTime(2026, 10, 8));
      expect(r.current, 2);
    });

    test('hari terjadwal yang terlewat memutus streak', () {
      final done = keys([DateTime(2026, 10, 5), DateTime(2026, 10, 7)]);
      final r = StreakCalculator.hitung(habit('2026-10-05', f), done, DateTime(2026, 10, 10));
      expect(r.current, 0);
      expect(r.longest, 2);
    });

    test('hari terjadwal tiga kali berturut-turut', () {
      final done = keys([DateTime(2026, 10, 5), DateTime(2026, 10, 7), DateTime(2026, 10, 9)]);
      final r = StreakCalculator.hitung(habit('2026-10-05', f), done, DateTime(2026, 10, 10));
      expect(r.current, 3);
    });
  });

  group('Per minggu (target 2)', () {
    const f = Frequency.perWeek(2);

    test('minggu berjalan belum cukup tidak memutus streak', () {
      final done = keys([
        DateTime(2026, 10, 6), DateTime(2026, 10, 8), // minggu 5-11 Okt: 2x
        DateTime(2026, 10, 13), // minggu 12-18 Okt: baru 1x
      ]);
      final r = StreakCalculator.hitung(habit('2026-10-05', f), done, DateTime(2026, 10, 14));
      expect(r.current, 1);
      expect(r.longest, 1);
      expect(r.unit, 'minggu');
    });

    test('target minggu berjalan tercapai menambah streak', () {
      final done = keys([
        DateTime(2026, 10, 6), DateTime(2026, 10, 8),
        DateTime(2026, 10, 13), DateTime(2026, 10, 14),
      ]);
      final r = StreakCalculator.hitung(habit('2026-10-05', f), done, DateTime(2026, 10, 14));
      expect(r.current, 2);
    });

    test('minggu lalu gagal memutus streak', () {
      final done = keys([DateTime(2026, 10, 6)]); // minggu pertama hanya 1x
      final r = StreakCalculator.hitung(habit('2026-10-05', f), done, DateTime(2026, 10, 14));
      expect(r.current, 0);
    });
  });
}
