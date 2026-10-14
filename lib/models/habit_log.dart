class HabitLog {
  /// ID dokumen = tanggal "YYYY-MM-DD" (mencegah centang ganda pada hari yang sama).
  final String tanggal;
  final bool selesai;
  final num? jumlah;
  final String? catatan;

  const HabitLog({
    required this.tanggal,
    required this.selesai,
    this.jumlah,
    this.catatan,
  });

  Map<String, dynamic> toMap() => {
        'selesai': selesai,
        if (jumlah != null) 'jumlah': jumlah,
        if (catatan != null && catatan!.trim().isNotEmpty) 'catatan': catatan!.trim(),
      };

  factory HabitLog.fromMap(String id, Map<String, dynamic> m) => HabitLog(
        tanggal: id,
        selesai: (m['selesai'] ?? false) as bool,
        jumlah: m['jumlah'] as num?,
        catatan: m['catatan'] as String?,
      );
}
