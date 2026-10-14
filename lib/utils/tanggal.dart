import 'package:intl/intl.dart';

/// Semua tanggal kebiasaan disimpan sebagai teks "YYYY-MM-DD" (bukan timestamp)
/// supaya bebas dari masalah zona waktu dan pergantian hari.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseKey(String k) {
  final p = k.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Memakai konstruktor DateTime(y, m, d + n) agar aman terhadap pergantian bulan/tahun.
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Awal minggu (Senin).
DateTime weekStart(DateTime d) => addDays(dayOnly(d), -(d.weekday - 1));

const List<String> namaHariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const List<String> namaHariPanjang = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
];

String tanggalPanjang(DateTime d) =>
    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(d);

String fmtNum(num n) =>
    n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);
