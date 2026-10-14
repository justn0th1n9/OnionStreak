// FILE PENGGANTI SEMENTARA.
// Jalankan `flutterfire configure` di folder proyek: perintah itu akan
// menimpa file ini dengan konfigurasi Firebase yang asli.
// Selama file ini masih berupa pengganti, aplikasi berjalan dalam MODE DEMO
// (data contoh di memori, tidak disimpan ke cloud).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
      'Firebase belum dikonfigurasi. Jalankan: flutterfire configure');
}
