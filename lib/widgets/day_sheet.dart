import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../state/habit_store.dart';
import '../utils/tanggal.dart';
import 'celebration.dart';

/// Centang cepat untuk hari ini. Kebiasaan bertarget angka membuka lembar isian.
Future<void> centangHari(BuildContext context, Habit h, DateTime hari) async {
  if (h.punyaTarget) {
    await showDaySheet(context, h, hari);
    return;
  }
  final m = await context.read<HabitStore>().toggleDay(h, hari);
  if (m != null && context.mounted) await showCelebration(context, h, m);
}

/// Lembar untuk mengisi atau mengoreksi satu hari (centang, jumlah, catatan).
Future<void> showDaySheet(BuildContext context, Habit habit, DateTime date) async {
  final m = await showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DaySheet(habit: habit, date: date),
  );
  if (m != null && context.mounted) await showCelebration(context, habit, m);
}

class _DaySheet extends StatefulWidget {
  const _DaySheet({required this.habit, required this.date});
  final Habit habit;
  final DateTime date;

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  late bool _selesai;
  late num _jumlah;
  late final TextEditingController _catatan;

  Habit get h => widget.habit;

  @override
  void initState() {
    super.initState();
    final log = context.read<HabitStore>().logOn(h, widget.date);
    _selesai = log?.selesai ?? false;
    _jumlah = log?.jumlah ?? 0;
    _catatan = TextEditingController(text: log?.catatan ?? '');
  }

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  void _ubahJumlah(num delta) {
    setState(() {
      _jumlah = (_jumlah + delta).clamp(0, 100000);
      _selesai = _jumlah >= h.targetAngka!;
    });
  }

  Future<void> _simpan() async {
    final store = context.read<HabitStore>();
    final m = await store.saveDay(h, widget.date,
        done: _selesai,
        amount: h.punyaTarget ? _jumlah : null,
        note: _catatan.text);
    if (mounted) Navigator.pop(context, m);
  }

  @override
  Widget build(BuildContext context) {
    final terjadwal = h.isScheduledOn(widget.date);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h.nama, style: Theme.of(context).textTheme.titleLarge),
            Text(tanggalPanjang(widget.date)),
            if (!terjadwal)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Hari ini tidak dijadwalkan, jadi tidak memengaruhi streak.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 8),
            if (h.punyaTarget)
              Row(
                children: [
                  IconButton.filledTonal(
                      onPressed: () => _ubahJumlah(-1),
                      icon: const Icon(Icons.remove),
                      tooltip: 'Kurangi'),
                  Expanded(
                    child: Text(
                      '${fmtNum(_jumlah)} / ${h.targetAngka} ${h.satuan ?? ''}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton.filledTonal(
                      onPressed: () => _ubahJumlah(1),
                      icon: const Icon(Icons.add),
                      tooltip: 'Tambah'),
                ],
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Selesai'),
              value: _selesai,
              onChanged: (v) => setState(() {
                _selesai = v;
                if (h.punyaTarget) _jumlah = v ? h.targetAngka! : 0;
              }),
            ),
            TextField(
              controller: _catatan,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _simpan, child: const Text('Simpan')),
            ),
          ],
        ),
      ),
    );
  }
}
