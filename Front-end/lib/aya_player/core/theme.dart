import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadTheme();
    return true;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? true;
    state = isDark;
  }

  Future<void> toggleTheme([bool? isDark]) async {
    final newValue = isDark ?? !state;
    state = newValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', newValue);
  }
}