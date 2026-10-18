import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/frequency.dart';
import '../models/habit.dart';
import '../state/habit_store.dart';
import '../utils/tanggal.dart';
import '../widgets/habit_style.dart';

class HabitFormScreen extends StatefulWidget {
  const HabitFormScreen({super.key, this.habit, this.template});

  /// Diisi saat mengedit.
  final Habit? habit;

  /// Diisi saat memulai dari template.
  final HabitTemplate? template;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _kunci = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _target;
  late final TextEditingController _satuan;
  late String _ikon;
  late int _warna;
  late FrequencyType _tipe;
  late Set<int> _hari;
  late int _perMinggu;
  late bool _punyaTarget;
  late List<String> _pengingat;

  bool get _edit => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    final t = widget.template;
    _nama = TextEditingController(text: h?.nama ?? t?.nama ?? '');
    _ikon = h?.ikon ?? t?.ikon ?? 'check';
    _warna = h?.warna ?? t?.warna ?? kWarna.first;
    final f = h?.frekuensi ?? t?.frekuensi ?? const Frequency.daily();
    _tipe = f.type;
    _hari = f.type == FrequencyType.hariTertentu ? {...f.days} : {1, 3, 5};
    _perMinggu = f.type == FrequencyType.perMinggu ? f.timesPerWeek : 3;
    final target = h?.targetAngka ?? t?.targetAngka;
    _punyaTarget = target != null;
    _target = TextEditingController(text: target?.toString() ?? '');
    _satuan = TextEditingController(text: h?.satuan ?? t?.satuan ?? '');
    _pengingat = List<String>.of(h?.pengingat ?? const <String>[]);
  }

  @override
  void dispose() {
    _nama.dispose();
    _target.dispose();
    _satuan.dispose();
    super.dispose();
  }

  Frequency _frekuensi() {
    switch (_tipe) {
      case FrequencyType.harian:
        return const Frequency.daily();
      case FrequencyType.hariTertentu:
        return Frequency.onDays({..._hari});
      case FrequencyType.perMinggu:
        return Frequency.perWeek(_perMinggu);
    }
  }

  Future<void> _pilihJam() async {
    Future<void> _tambahJam() async {
    if (_pengingat.length >= kMaksPengingat) return;
    final t = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 7, minute: 0));
    if (t == null || !mounted) return;
    final jam =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (_pengingat.contains(jam)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Pengingat $jam sudah ada')));
      return;
    }
    setState(() => _pengingat = [..._pengingat, jam]..sort());
    await context.read<HabitStore>().notifications.mintaIzin();
  }

  Future<void> _simpan() async {
    if (!_kunci.currentState!.validate()) return;
    if (_tipe == FrequencyType.hariTertentu && _hari.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih minimal satu hari')));
      return;
    }
    final lama = widget.habit;
    final satuan = _satuan.text.trim();
    final h = Habit(
      id: lama?.id ?? '',
      nama: _nama.text.trim(),
      ikon: _ikon,
      warna: _warna,
      frekuensi: _frekuensi(),
      targetAngka: _punyaTarget ? int.parse(_target.text.trim()) : null,
      satuan: _punyaTarget && satuan.isNotEmpty ? satuan : null,
      pengingat: _pengingat,
      tanggalMulai: lama?.tanggalMulai ?? dateKey(DateTime.now()),
      diarsipkan: lama?.diarsipkan ?? false,
      urutan: lama?.urutan ?? 0,
      jedaDari: lama?.jedaDari,
      jedaSampai: lama?.jedaSampai,
    );
    final store = context.read<HabitStore>();
    if (_edit) {
      await store.updateHabit(h);
    } else {
      await store.addHabit(h);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_edit ? 'Edit kebiasaan' : 'Kebiasaan baru')),
      body: Form(
        key: _kunci,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nama,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Nama kebiasaan', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Isi nama kebiasaan' : null,
            ),
            const SizedBox(height: 20),
            Text('Ikon', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in kIkon.entries)
                  ChoiceChip(
                    label: Icon(e.value, size: 20),
                    selected: _ikon == e.key,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _ikon = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Warna', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final w in kWarna)
                  GestureDetector(
                    onTap: () => setState(() => _warna = w),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(w),
                        shape: BoxShape.circle,
                        border: _warna == w
                            ? Border.all(color: cs.onSurface, width: 3)
                            : null,
                      ),
                      child: _warna == w
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Frekuensi', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<FrequencyType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: FrequencyType.harian, label: Text('Harian')),
                ButtonSegment(value: FrequencyType.hariTertentu, label: Text('Pilih hari')),
                ButtonSegment(value: FrequencyType.perMinggu, label: Text('Per minggu')),
              ],
              selected: {_tipe},
              onSelectionChanged: (s) => setState(() => _tipe = s.first),
            ),
            if (_tipe == FrequencyType.hariTertentu) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      label: Text(namaHariPendek[d - 1]),
                      selected: _hari.contains(d),
                      onSelected: (v) =>
                          setState(() => v ? _hari.add(d) : _hari.remove(d)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Hari yang tidak dipilih tidak memutus streak.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (_tipe == FrequencyType.perMinggu) ...[
              const SizedBox(height: 8),
              Text('Target: $_perMinggu kali per minggu'),
              Slider(
                min: 1,
                max: 7,
                divisions: 6,
                value: _perMinggu.toDouble(),
                label: '$_perMinggu',
                onChanged: (v) => setState(() => _perMinggu = v.round()),
              ),
              Text('Streak dihitung per minggu (Senin-Minggu).',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            const Divider(height: 32),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Target angka'),
              subtitle: const Text('Contoh: 8 gelas, 20 halaman'),
              value: _punyaTarget,
              onChanged: (v) => setState(() => _punyaTarget = v),
            ),
            if (_punyaTarget)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _target,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Target', border: OutlineInputBorder()),
                      validator: (v) {
                        if (!_punyaTarget) return null;
                        final n = int.tryParse((v ?? '').trim());
                        return (n == null || n <= 0) ? 'Isi angka lebih dari 0' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _satuan,
                      decoration: const InputDecoration(
                          labelText: 'Satuan', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            const Divider(height: 32),
             Row(
              children: [
                const Icon(Icons.alarm),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Pengingat harian',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  onPressed:
                      _pengingat.length >= kMaksPengingat ? null : _tambahJam,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah jam'),
                ),
              ],
            ),
            if (_pengingat.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 4),
                child: Text('Tidak aktif', style: Theme.of(context).textTheme.bodyMedium),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final jam in _pengingat)
                      InputChip(
                        label: Text(jam),
                        onDeleted: () => setState(() =>
                            _pengingat = _pengingat.where((e) => e != jam).toList()),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: Text(
                'Maksimal $kMaksPengingat jam. Pengingat tidak muncul bila kebiasaan hari itu sudah dicentang.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _simpan, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}
