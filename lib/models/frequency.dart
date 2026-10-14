import '../utils/tanggal.dart';

enum FrequencyType { harian, hariTertentu, perMinggu }

class Frequency {
  final FrequencyType type;

  /// Untuk hariTertentu: 1 = Senin ... 7 = Minggu.
  final Set<int> days;

  /// Untuk perMinggu: target hari selesai dalam satu minggu (Senin-Minggu).
  final int timesPerWeek;

  const Frequency.daily()
      : type = FrequencyType.harian,
        days = const {1, 2, 3, 4, 5, 6, 7},
        timesPerWeek = 7;

  const Frequency.onDays(this.days)
      : type = FrequencyType.hariTertentu,
        timesPerWeek = 0;

  const Frequency.perWeek(this.timesPerWeek)
      : type = FrequencyType.perMinggu,
        days = const {1, 2, 3, 4, 5, 6, 7};

  bool isScheduled(DateTime d) {
    switch (type) {
      case FrequencyType.harian:
        return true;
      case FrequencyType.hariTertentu:
        return days.contains(d.weekday);
      case FrequencyType.perMinggu:
        return true;
    }
  }

  String get label {
    switch (type) {
      case FrequencyType.harian:
        return 'Setiap hari';
      case FrequencyType.hariTertentu:
        final list = days.toList()..sort();
        return list.map((d) => namaHariPendek[d - 1]).join(', ');
      case FrequencyType.perMinggu:
        return '$timesPerWeek kali per minggu';
    }
  }

  Map<String, dynamic> toMap() => {
        'tipe': type.name,
        'hari': (days.toList()..sort()),
        'targetPerMinggu': timesPerWeek,
      };

  factory Frequency.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const Frequency.daily();
    final type = FrequencyType.values.firstWhere((e) => e.name == m['tipe'],
        orElse: () => FrequencyType.harian);
    switch (type) {
      case FrequencyType.harian:
        return const Frequency.daily();
      case FrequencyType.hariTertentu:
        final hari = ((m['hari'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toSet();
        return Frequency.onDays(hari.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : hari);
      case FrequencyType.perMinggu:
        final n = ((m['targetPerMinggu'] as num?) ?? 3).toInt().clamp(1, 7);
        return Frequency.perWeek(n);
    }
  }
}
