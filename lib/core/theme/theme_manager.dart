import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ValueNotifier<ThemeMode> {
  static const String _themeKey = 'user_theme_mode';

  // Singleton instance
  static final ThemeManager _instance = ThemeManager._internal();

  factory ThemeManager() {
    return _instance;
  }

  ThemeManager._internal() : super(ThemeMode.dark);

  static Future<void> initialize() async {
    await _instance._loadTheme();
  }

  void _updateSystemUI(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeKey);

      if (savedMode == 'light') {
        value = ThemeMode.light;
      } else if (savedMode == 'dark') {
        value = ThemeMode.dark;
      } else {
        // Default to system or dark if not set
        value = ThemeMode.dark;
      }
      _updateSystemUI(value);
    } catch (e) {
      debugPrint('ThemeManager: Error loading theme: $e');
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    if (value == newMode) return;

    value = newMode;
    _updateSystemUI(value);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, isDark ? 'dark' : 'light');
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  bool get isDarkMode => value == ThemeMode.dark;
}
