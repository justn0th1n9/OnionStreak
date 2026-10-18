import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/stats_service.dart';
import '../state/habit_store.dart';
import '../utils/nav.dart';
import '../utils/tanggal.dart';
import '../widgets/habit_style.dart';
import '../widgets/mini_bar_chart.dart';
import 'habit_detail_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _mode = 0; // 0 = 7 hari, 1 = 30 hari

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HabitStore>();
    final today = dayOnly(DateTime.now());
    final aktif = store.active;
    final done = store.doneMap(store.all);
    final cs = Theme.of(context).colorScheme;

    final hari = _mode == 0 ? 7 : 30;
    final dari = addDays(today, -(hari - 1));
    final total = StatsService.hitungSemua(aktif, done, dari, today, today);

    var jumlahSelesai = 0;
    final kDari = dateKey(dari), kKe = dateKey(today);
    for (final h in aktif) {
      for (final k in done[h.id] ?? <String>{}) {
        if (k.compareTo(kDari) >= 0 && k.compareTo(kKe) <= 0) jumlahSelesai++;
      }
    }

    double persen(DateTime a, DateTime b) =>
        (StatsService.hitungSemua(aktif, done, a, b, today).rasio ?? 0) * 100;

    final nilai = <double>[];
    final label = <String>[];
    if (_mode == 0) {
      for (var i = 6; i >= 0; i--) {
        final d = addDays(today, -i);
        nilai.add(persen(d, d));
        label.add(namaHariPendek[d.weekday - 1]);
      }
    } else {
      for (var i = 4; i >= 0; i--) {
        final ws = addDays(weekStart(today), -7 * i);
        nilai.add(persen(ws, addDays(ws, 6)));
        label.add(DateFormat('d/M').format(ws));
      }
    }

    final urut = [...aktif]
      ..sort((a, b) => store.streak(b).current.compareTo(store.streak(a).current));
    final wawasan = StatsService.wawasan(aktif, done, today);
    final lencana = StatsService.lencana(store.all, done, today, logs: {
      for (final h in store.all) h.id: store.logsOf(h.id),
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: aktif.isEmpty
          ? const Center(child: Text('Belum ada data. Tambahkan kebiasaan dulu.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('7 hari')),
                    ButtonSegment(value: 1, label: Text('30 hari')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _Kotak(
                            total.rasio == null ? '-' : '${(total.rasio! * 100).round()}%',
                            'tingkat selesai')),
                    const SizedBox(width: 8),
                    Expanded(child: _Kotak('$jumlahSelesai', 'centang')),
                    const SizedBox(width: 8),
                    Expanded(child: _Kotak('${aktif.length}', 'kebiasaan')),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            _mode == 0
                                ? 'Penyelesaian per hari'
                                : 'Penyelesaian per minggu',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 12),
                        MiniBarChart(
                          values: nilai,
                          labels: label,
                          maxY: 100,
                          interval: 25,
                          suffix: '%',
                        ),
                      ],
                    ),
                  ),
                ),
                if (wawasan != null)
                  Card(
                    color: cs.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline),
                          const SizedBox(width: 12),
                          Expanded(child: Text(wawasan)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text('Peringkat streak', style: Theme.of(context).textTheme.titleSmall),
                for (final h in urut)
                  Builder(builder: (context) {
                    final s = store.streak(h);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Color(h.warna).withAlpha(40),
                        child: Icon(ikonDari(h.ikon), color: Color(h.warna)),
                      ),
                      title: Text(h.nama),
                      subtitle: Text('Terpanjang: ${s.longest} ${s.unit}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department,
                              color: Color(0xFFF57C00), size: 20),
                          Text(' ${s.current} ${s.unit}'),
                        ],
                      ),
                      onTap: () => buka(context, HabitDetailScreen(habitId: h.id)),
                    );
                  }),
                const SizedBox(height: 16),
                Text('Lencana', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final b in lencana)
                      Tooltip(
                        message: b.deskripsi,
                        child: Chip(
                          avatar: Icon(b.diraih ? b.ikon : Icons.lock_outline,
                              size: 18,
                              color: b.diraih ? const Color(0xFFF57C00) : null),
                          label: Text(b.nama),
                          backgroundColor:
                              b.diraih ? cs.primaryContainer : cs.surfaceContainerHighest,
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Kotak extends StatelessWidget {
  const _Kotak(this.nilai, this.label);
  final String nilai;
  final String label;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nilai,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}
