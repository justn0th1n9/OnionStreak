import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_mode.dart';
import '../state/habit_store.dart';

/// Awalnya pengguna masuk sebagai tamu (anonim). Dengan menautkan email,
/// akun yang sama dipertahankan sehingga data bisa dipulihkan di perangkat lain.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  bool _sibuk = false;
  String? _pesan;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  String _terjemah(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return 'Email ini sudah dipakai. Pilih "Masuk" untuk memakai akun tersebut.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return 'Email atau kata sandi salah.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'operation-not-allowed':
        return 'Metode Email/Password belum diaktifkan di Firebase Console.';
      default:
        return 'Gagal (${e.code}).';
    }
  }

  Future<void> _jalankan(Future<void> Function() aksi, {bool muat = false}) async {
    setState(() {
      _sibuk = true;
      _pesan = null;
    });
    try {
      await aksi();
      if (muat && mounted) await context.read<HabitStore>().reload();
    } on FirebaseAuthException catch (e) {
      _pesan = _terjemah(e);
    } catch (e) {
      _pesan = 'Terjadi kesalahan: $e';
    }
    if (mounted) setState(() => _sibuk = false);
  }

  Future<void> _tautkan() => _jalankan(() async {
        final cred = EmailAuthProvider.credential(
            email: _email.text.trim(), password: _sandi.text);
        await FirebaseAuth.instance.currentUser!.linkWithCredential(cred);
        _pesan = 'Akun berhasil ditautkan. Datamu kini punya cadangan.';
      });

  Future<void> _masuk() => _jalankan(() async {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _email.text.trim(), password: _sandi.text);
        _pesan = 'Berhasil masuk. Data akunmu dimuat.';
      }, muat: true);

  Future<void> _keluar() => _jalankan(() async {
        await FirebaseAuth.instance.signOut();
        await FirebaseAuth.instance.signInAnonymously();
        _pesan = 'Kamu keluar dan kembali sebagai tamu.';
      }, muat: true);

  @override
  Widget build(BuildContext context) {
    final demo = context.read<AppMode>().demo;
    return Scaffold(
      appBar: AppBar(title: const Text('Akun dan cadangan')),
      body: demo
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Aplikasi sedang berjalan dalam mode demo karena Firebase belum dikonfigurasi. '
                'Jalankan "flutterfire configure", lalu jalankan ulang aplikasi untuk memakai akun dan sinkronisasi cloud.',
              ),
            )
          : StreamBuilder<User?>(
              stream: FirebaseAuth.instance.userChanges(),
              builder: (context, snap) {
                final u = snap.data ?? FirebaseAuth.instance.currentUser;
                final tamu = u == null || u.isAnonymous;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: ListTile(
                        leading: Icon(tamu ? Icons.person_outline : Icons.verified_user_outlined),
                        title: Text(tamu ? 'Akun tamu' : (u.email ?? 'Akun terhubung')),
                        subtitle: Text(tamu
                            ? 'Datamu tersimpan di cloud, tetapi bisa hilang kalau aplikasi dihapus. Tautkan email untuk memulihkannya di perangkat lain.'
                            : 'Datamu tercadangkan dan bisa dipulihkan di perangkat lain.'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (tamu) ...[
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'Email', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _sandi,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Kata sandi (min. 6 karakter)',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                          onPressed: _sibuk ? null : _tautkan,
                          child: const Text('Tautkan akun (cadangkan data)')),
                      const SizedBox(height: 8),
                      OutlinedButton(
                          onPressed: _sibuk ? null : _masuk,
                          child: const Text('Masuk ke akun yang sudah ada')),
                      const SizedBox(height: 8),
                      Text(
                        'Catatan: "Masuk" memuat data akun lama dan meninggalkan data tamu di perangkat ini.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ] else
                      OutlinedButton(
                          onPressed: _sibuk ? null : _keluar, child: const Text('Keluar')),
                    if (_sibuk)
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator())),
                    if (_pesan != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(_pesan!),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
