import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/frequency.dart';
import '../models/habit.dart';
import '../state/app_mode.dart';
import '../state/habit_store.dart';
import '../utils/nav.dart';
import '../utils/tanggal.dart';
import '../widgets/day_sheet.dart';
import '../widgets/habit_style.dart';
import '../widgets/habit_tile.dart';
import '../widgets/onion_mascot.dart';
import 'habit_detail_screen.dart';
import 'habit_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HabitStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('OnionStreak'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => buka(context, const HabitFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Kebiasaan'),
      ),
      body: store.loading
          ? const Center(child: CircularProgressIndicator())
          : store.error != null && store.active.isEmpty
              ? _Galat(pesan: store.error!)
              : store.active.isEmpty
                  ? const _Kosong()
                  : _Daftar(store: store),
    );
  }
}

class _Galat extends StatelessWidget {
  const _Galat({required this.pesan});
  final String pesan;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Data belum bisa dimuat. Periksa aturan Firestore dan koneksimu.\n\n$pesan',
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _Kosong extends StatelessWidget {
  const _Kosong();

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const OnionMascot(streak: 0, size: 150),
              const SizedBox(height: 12),
              Text('Mulai kebiasaan pertamamu',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Pilih contoh di bawah atau buat sendiri. Centang tiap hari dan lihat bawangmu tumbuh.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final t in kTemplates)
                    ActionChip(
                      avatar: Icon(ikonDari(t.ikon), size: 18, color: Color(t.warna)),
                      label: Text(t.nama),
                      onPressed: () =>
                          buka(context, HabitFormScreen(template: t)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => buka(context, const HabitFormScreen()),
                icon: const Icon(Icons.add),
                label: const Text('Buat sendiri'),
              ),
            ],
          ),
        ),
      );
}

class _Daftar extends StatelessWidget {
  const _Daftar({required this.store});
  final HabitStore store;

  String _subjudul(Habit h, DateTime hari, bool terjadwal) {
    if (!terjadwal) return 'Tidak dijadwalkan hari ini';
    if (h.punyaTarget) {
      final j = store.logOn(h, hari)?.jumlah ?? 0;
      return '${fmtNum(j)}/${h.targetAngka} ${h.satuan ?? ''}'.trim();
    }
    if (h.frekuensi.type == FrequencyType.perMinggu) {
      return '${store.selesaiMingguIni(h)}/${h.frekuensi.timesPerWeek} minggu ini';
    }
    return h.frekuensi.label;
  }

  @override
  Widget build(BuildContext context) {
    final hari = dayOnly(DateTime.now());
    final aktif = store.active;
    final hariIni = aktif.where((h) => h.isScheduledOn(hari)).toList();
    final dijeda = aktif.where((h) => h.isPausedOn(hari)).toList();
    final lainnya =
        aktif.where((h) => !hariIni.contains(h) && !dijeda.contains(h)).toList();

    final selesai = hariIni.where((h) => store.isDone(h, hari)).length;
    var streakTertinggi = 0;
    for (final h in aktif) {
      final s = store.streak(h);
      streakTertinggi = math.max(streakTertinggi, s.perMinggu ? s.current * 7 : s.current);
    }
    final terancam = hariIni
        .where((h) => !store.isDone(h, hari) && store.streak(h).current > 0)
        .toList();

    Widget tile(Habit h, {bool terjadwal = true, bool paused = false}) =>
        HabitTile(
          habit: h,
          done: store.isDone(h, hari),
          subtitle: paused ? 'Dijeda sampai ${h.jedaSampai}' : _subjudul(h, hari, terjadwal),
          streak: store.streak(h).current,
          paused: paused,
          onTap: () => buka(context, HabitDetailScreen(habitId: h.id)),
          onToggle: paused ? null : () => centangHari(context, h, hari),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (context.read<AppMode>().demo)
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Mode demo: data hanya di memori dan hilang saat aplikasi ditutup. Hubungkan Firebase untuk menyimpannya.',
              ),
            ),
          ),
        _Ringkasan(selesai: selesai, total: hariIni.length, streak: streakTertinggi),
        if (terancam.isNotEmpty)
          Card(
            color: const Color(0x33F57C00),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Color(0xFFF57C00)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Streak ${terancam.map((h) => h.nama).join(', ')} akan putus kalau belum dicentang hari ini.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        const _Judul('Hari ini'),
        if (hariIni.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Tidak ada kebiasaan yang dijadwalkan hari ini.'),
          ),
        for (final h in hariIni) tile(h),
        if (lainnya.isNotEmpty) ...[
          const _Judul('Tidak dijadwalkan hari ini'),
          for (final h in lainnya) tile(h, terjadwal: false),
        ],
        if (dijeda.isNotEmpty) ...[
          const _Judul('Dijeda'),
          for (final h in dijeda) tile(h, paused: true),
        ],
      ],
    );
  }
}

class _Judul extends StatelessWidget {
  const _Judul(this.teks);
  final String teks;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
        child: Text(teks,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}

class _Ringkasan extends StatelessWidget {
  const _Ringkasan({required this.selesai, required this.total, required this.streak});
  final int selesai;
  final int total;
  final int streak;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              OnionMascot(streak: streak, size: 88),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tanggalPanjang(DateTime.now()),
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      total == 0 ? 'Tidak ada jadwal hari ini' : '$selesai dari $total selesai',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : selesai / total,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      streak > 0
                          ? 'Streak terbaik saat ini: $streak hari'
                          : 'Mulai streak pertamamu hari ini',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
