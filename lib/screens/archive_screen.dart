import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/habit_store.dart';
import '../utils/nav.dart';
import '../widgets/habit_style.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HabitStore>();
    final daftar = store.archived;
    return Scaffold(
      appBar: AppBar(title: const Text('Arsip')),
      body: daftar.isEmpty
          ? const Center(child: Text('Belum ada kebiasaan yang diarsipkan.'))
          : ListView(
              children: [
                for (final h in daftar)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(h.warna).withAlpha(40),
                      child: Icon(ikonDari(h.ikon), color: Color(h.warna)),
                    ),
                    title: Text(h.nama),
                    subtitle: Text(h.frekuensi.label),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Aktifkan lagi',
                          icon: const Icon(Icons.unarchive_outlined),
                          onPressed: () => store.setArsip(h, false),
                        ),
                        IconButton(
                          tooltip: 'Hapus permanen',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ya = await konfirmasi(context, 'Hapus "${h.nama}"?',
                                'Seluruh riwayat ikut terhapus dan tidak bisa dikembalikan.',
                                aksi: 'Hapus');
                            if (ya) await store.deleteHabit(h);
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
