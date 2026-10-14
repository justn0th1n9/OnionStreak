import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_mode.dart';
import '../state/habit_store.dart';
import '../state/theme_controller.dart';
import '../utils/nav.dart';
import 'account_screen.dart';
import 'archive_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<ThemeController>();
    final store = context.watch<HabitStore>();
    final demo = context.read<AppMode>().demo;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tema', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('Terang')),
              ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Gelap')),
            ],
            selected: {tema.mode},
            onSelectionChanged: (s) => tema.set(s.first),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Akun dan cadangan'),
            subtitle: Text(demo ? 'Mode demo (Firebase belum dikonfigurasi)' : 'Tautkan email agar data aman'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => buka(context, const AccountScreen()),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Arsip'),
            subtitle: Text('${store.archived.length} kebiasaan diarsipkan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => buka(context, const ArchiveScreen()),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Izin notifikasi'),
            subtitle: const Text('Diperlukan agar pengingat harian muncul'),
            onTap: () async {
              final ok = await store.notifications.mintaIzin();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Notifikasi diizinkan' : 'Notifikasi belum diizinkan')));
              }
            },
          ),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'OnionStreak',
            applicationVersion: '1.0.0',
            aboutBoxChildren: [
              Text('Pelacak kebiasaan harian dengan streak.\nTIK3171 Pengembangan Aplikasi Mobile, Universitas Sam Ratulangi.'),
            ],
          ),
        ],
      ),
    );
  }
}
