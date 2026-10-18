import '../utils/tanggal.dart';
import 'frequency.dart';
const int kMaksPengingat = 5;

class Habit {
  final String id;
  final String nama;
  final String ikon;
  final int warna;
  final Frequency frekuensi;
  final int? targetAngka;
  final String? satuan;
  final List<String> pengingat; // "HH:mm"
  final String tanggalMulai; // YYYY-MM-DD
  final bool diarsipkan;
  final int urutan;
  final String? jedaDari; // YYYY-MM-DD
  final String? jedaSampai; // YYYY-MM-DD

  const Habit({
    required this.id,
    required this.nama,
    required this.ikon,
    required this.warna,
    required this.frekuensi,
    this.targetAngka,
    this.satuan,
    this.pengingat = const [],
    required this.tanggalMulai,
    this.diarsipkan = false,
    this.urutan = 0,
    this.jedaDari,
    this.jedaSampai,
  });

  bool get punyaTarget => targetAngka != null && targetAngka! > 0;
  
 bool get punyaPengingat => pengingat.isNotEmpty;

  static List<String> bacaPengingat(Object? v) {
    final Iterable<String> mentah;
    if (v is String) {
      mentah = v.isEmpty ? const <String>[] : [v];
    } else if (v is List) {
      mentah = v.whereType<String>();
    } else {
      return const [];
    }
    final rapi = mentah.where((e) => RegExp(r'^\d{2}:\d{2}$').hasMatch(e)).toSet().toList()
      ..sort();
    return rapi.length > kMaksPengingat ? rapi.sublist(0, kMaksPengingat) : rapi;
  }
  
  bool isPausedOn(DateTime d) {
    if (jedaDari == null || jedaSampai == null) return false;
    final k = dateKey(d);
    return k.compareTo(jedaDari!) >= 0 && k.compareTo(jedaSampai!) <= 0;
  }

  bool get sedangDijedaHariIni => isPausedOn(DateTime.now());

  /// Hari yang dihitung dalam streak: sesuai jadwal, tidak dijeda, dan setelah tanggal mulai.
  bool isScheduledOn(DateTime d) =>
      frekuensi.isScheduled(d) &&
      !isPausedOn(d) &&
      dateKey(d).compareTo(tanggalMulai) >= 0;

  static const Object _u = Object();

  Habit copyWith({
    String? id,
    String? nama,
    String? ikon,
    int? warna,
    Frequency? frekuensi,
    Object? targetAngka = _u,
    Object? satuan = _u,
    List<String>? pengingat,
    String? tanggalMulai,
    bool? diarsipkan,
    int? urutan,
    Object? jedaDari = _u,
    Object? jedaSampai = _u,
  }) =>
      Habit(
        id: id ?? this.id,
        nama: nama ?? this.nama,
        ikon: ikon ?? this.ikon,
        warna: warna ?? this.warna,
        frekuensi: frekuensi ?? this.frekuensi,
        targetAngka:
            identical(targetAngka, _u) ? this.targetAngka : targetAngka as int?,
        satuan: identical(satuan, _u) ? this.satuan : satuan as String?,
        pengingat: pengingat ?? this.pengingat,
        tanggalMulai: tanggalMulai ?? this.tanggalMulai,
        diarsipkan: diarsipkan ?? this.diarsipkan,
        urutan: urutan ?? this.urutan,
        jedaDari: identical(jedaDari, _u) ? this.jedaDari : jedaDari as String?,
        jedaSampai:
            identical(jedaSampai, _u) ? this.jedaSampai : jedaSampai as String?,
      );

  Map<String, dynamic> toMap() => {
        'nama': nama,
        'ikon': ikon,
        'warna': warna,
        'frekuensi': frekuensi.toMap(),
        'targetAngka': targetAngka,
        'satuan': satuan,
        'pengingat': pengingat,
        'tanggalMulai': tanggalMulai,
        'diarsipkan': diarsipkan,
        'urutan': urutan,
        'jedaDari': jedaDari,
        'jedaSampai': jedaSampai,
      };

  factory Habit.fromMap(String id, Map<String, dynamic> m) => Habit(
        id: id,
        nama: (m['nama'] ?? '') as String,
        ikon: (m['ikon'] ?? 'check') as String,
        warna: (m['warna'] as num?)?.toInt() ?? 0xFF7B3F8C,
        frekuensi: Frequency.fromMap(m['frekuensi'] as Map<String, dynamic>?),
        targetAngka: (m['targetAngka'] as num?)?.toInt(),
        satuan: m['satuan'] as String?,
        pengingat: bacaPengingat(m['pengingat']),
        tanggalMulai:
            (m['tanggalMulai'] ?? dateKey(DateTime.now())) as String,
        diarsipkan: (m['diarsipkan'] ?? false) as bool,
        urutan: (m['urutan'] as num?)?.toInt() ?? 0,
        jedaDari: m['jedaDari'] as String?,
        jedaSampai: m['jedaSampai'] as String?,
      );
}
