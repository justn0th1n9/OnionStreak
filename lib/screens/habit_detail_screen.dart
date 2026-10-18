import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/habit.dart';
import '../services/stats_service.dart';
import '../state/habit_store.dart';
import '../utils/nav.dart';
import '../utils/tanggal.dart';
import '../widgets/day_sheet.dart';
import '../widgets/habit_style.dart';
import '../widgets/mini_bar_chart.dart';
import '../widgets/onion_mascot.dart';
import 'habit_form_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId});
  final String habitId;

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  DateTime _fokus = dayOnly(DateTime.now());

  Future<void> _menu(String aksi, Habit h) async {
    final store = context.read<HabitStore>();
    switch (aksi) {
      case 'jeda':
        final hari = dayOnly(DateTime.now());
        final p = await showDatePicker(
          context: context,
          initialDate: addDays(hari, 7),
          firstDate: hari,
          lastDate: addDays(hari, 365),
          helpText: 'Jeda sampai tanggal',
        );
        if (p != null) await store.jeda(h, p);
        break;
      case 'lanjut':
        await store.lanjutkan(h);
        break;
      case 'arsip':
        await store.setArsip(h, true);
        if (mounted) Navigator.pop(context);
        break;
      case 'hapus':
        final ya = await konfirmasi(context, 'Hapus "${h.nama}"?',
            'Seluruh riwayat kebiasaan ini ikut terhapus dan tidak bisa dikembalikan.',
            aksi: 'Hapus');
        if (ya) {
          await store.deleteHabit(h);
          if (mounted) Navigator.pop(context);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HabitStore>();
    final h = store.byId(widget.habitId);
    if (h == null) {
      return Scaffold(
          appBar: AppBar(), body: const Center(child: Text('Kebiasaan tidak ditemukan.')));
    }
    final today = dayOnly(DateTime.now());
    final warna = Color(h.warna);
    final cs = Theme.of(context).colorScheme;
    final selesai = store.doneKeys(h.id);
    final s = store.streak(h);
    final r30 = StatsService.hitung(h, selesai, addDays(today, -29), today, today).rasio;

    // grafik 8 minggu terakhir
    final nilai = <double>[];
    final label = <String>[];
    for (var i = 7; i >= 0; i--) {
      final ws = addDays(weekStart(today), -7 * i);
      var c = 0;
      for (var k = 0; k < 7; k++) {
        final d = addDays(ws, k);
        if (!d.isAfter(today) && selesai.contains(dateKey(d))) c++;
      }
      nilai.add(c.toDouble());
      label.add(DateFormat('d/M').format(ws));
    }

    final catatan = store.logsOf(h.id).values
        .where((l) => (l.catatan ?? '').isNotEmpty)
        .toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    Widget sel(DateTime day, {bool hariIni = false, bool redup = false}) {
      final k = dateKey(day);
      final done = selesai.contains(k);
      final terjadwal = h.isScheduledOn(day);
      final lewat = !day.isAfter(today);
      Color? isi;
      Color teks = redup ? cs.onSurface.withAlpha(90) : cs.onSurface;
      BoxBorder? garis;
      if (done) {
        isi = warna;
        teks = Colors.white;
      } else if (terjadwal && lewat && !sameDay(day, today)) {
        garis = Border.all(color: warna.withAlpha(110));
      }
      if (hariIni) garis = Border.all(color: cs.primary, width: 2);
      return Container(
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: isi, border: garis),
        child: Text('${day.day}', style: TextStyle(color: teks)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(h.nama),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => buka(context, HabitFormScreen(habit: h)),
          ),
          PopupMenuButton<String>(
            onSelected: (a) => _menu(a, h),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: h.jedaSampai != null ? 'lanjut' : 'jeda',
                child: Text(h.jedaSampai != null ? 'Lanjutkan kebiasaan' : 'Jeda kebiasaan'),
              ),
              const PopupMenuItem(value: 'arsip', child: Text('Arsipkan')),
              const PopupMenuItem(value: 'hapus', child: Text('Hapus')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (h.jedaSampai != null)
            Card(
              color: cs.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                    'Kebiasaan dijeda sampai ${h.jedaSampai}. Hari jeda tidak memutus streak.'),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  OnionMascot(streak: s.perMinggu ? s.current * 7 : s.current, size: 96),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(ikonDari(h.ikon), color: warna, size: 18),
                            const SizedBox(width: 6),
                            Expanded(child: Text(h.frekuensi.label)),
                          ],
                        ),
                        if (h.punyaTarget)
                          Text('Target: ${h.targetAngka} ${h.satuan ?? ''}'),
                        if (h.punyaPengingat) Text('Pengingat: ${h.pengingat.join(', ')}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _Angka('${s.current}', 'saat ini (${s.unit})'),
                            _Angka('${s.longest}', 'terpanjang (${s.unit})'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _Metrik('${selesai.length}', 'total selesai')),
              const SizedBox(width: 8),
              Expanded(
                  child: _Metrik(
                      r30 == null ? '-' : '${(r30 * 100).round()}%', '30 hari terakhir')),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  TableCalendar(
                    locale: 'id_ID',
                    firstDay: DateTime(2020, 1, 1),
                    lastDay: today,
                    focusedDay: _fokus,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {CalendarFormat.month: 'Bulan'},
                    headerStyle: const HeaderStyle(
                        formatButtonVisible: false, titleCentered: true),
                    rowHeight: 44,
                    onPageChanged: (f) => _fokus = f,
                    onDaySelected: (d, f) {
                      setState(() => _fokus = f);
                      showDaySheet(context, h, dayOnly(d));
                    },
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (c, d, f) => sel(d),
                      todayBuilder: (c, d, f) => sel(d, hariIni: true),
                      outsideBuilder: (c, d, f) => sel(d, redup: true),
                      disabledBuilder: (c, d, f) => sel(d, redup: true),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Ketuk tanggal untuk mengoreksi atau menambah catatan. Streak ikut menyesuaikan.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hari selesai per minggu',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  MiniBarChart(
                      values: nilai, labels: label, maxY: 7, interval: 1, color: warna),
                ],
              ),
            ),
          ),
          if (catatan.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Catatan terbaru',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (final l in catatan.take(5))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${l.tanggal}: ${l.catatan}'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Angka extends StatelessWidget {
  const _Angka(this.nilai, this.label);
  final String nilai;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nilai,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

class _Metrik extends StatelessWidget {
  const _Metrik(this.nilai, this.label);
  final String nilai;
  final String label;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
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
