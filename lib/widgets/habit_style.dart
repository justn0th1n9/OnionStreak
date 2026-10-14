import 'package:flutter/material.dart';

import '../models/frequency.dart';

const Map<String, IconData> kIkon = {
  'check': Icons.check_circle_outline,
  'water': Icons.water_drop,
  'run': Icons.directions_run,
  'book': Icons.menu_book,
  'sleep': Icons.bedtime,
  'food': Icons.restaurant,
  'meditate': Icons.self_improvement,
  'study': Icons.school,
  'code': Icons.code,
  'music': Icons.music_note,
  'money': Icons.savings,
  'clean': Icons.cleaning_services,
  'heart': Icons.favorite,
  'walk': Icons.directions_walk,
  'write': Icons.edit_note,
  'sun': Icons.wb_sunny,
};

IconData ikonDari(String key) => kIkon[key] ?? Icons.check_circle_outline;

const List<int> kWarna = [
  0xFF7B3F8C, 0xFF1E88E5, 0xFF00897B, 0xFF43A047,
  0xFFF57C00, 0xFFE53935, 0xFFD81B60, 0xFF6D4C41,
];

class HabitTemplate {
  final String nama;
  final String ikon;
  final int warna;
  final Frequency frekuensi;
  final int? targetAngka;
  final String? satuan;
  const HabitTemplate(this.nama, this.ikon, this.warna, this.frekuensi,
      {this.targetAngka, this.satuan});
}

final List<HabitTemplate> kTemplates = [
  const HabitTemplate('Minum air', 'water', 0xFF1E88E5, Frequency.daily(),
      targetAngka: 8, satuan: 'gelas'),
  HabitTemplate('Olahraga', 'run', 0xFFF57C00, const Frequency.onDays({1, 3, 5})),
  const HabitTemplate('Membaca', 'book', 0xFF7B3F8C, Frequency.daily(),
      targetAngka: 20, satuan: 'halaman'),
  const HabitTemplate('Tidur cukup', 'sleep', 0xFF3949AB, Frequency.daily()),
  const HabitTemplate('Meditasi', 'meditate', 0xFF00897B, Frequency.perWeek(4)),
];
