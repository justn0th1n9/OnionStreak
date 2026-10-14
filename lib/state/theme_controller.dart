import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._mode);

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  static Future<ThemeController> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final i = p.getInt('tema') ?? 0;
      return ThemeController(ThemeMode.values[i.clamp(0, 2)]);
    } catch (_) {
      return ThemeController(ThemeMode.system);
    }
  }

  Future<void> set(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('tema', m.index);
    } catch (_) {}
  }
}
