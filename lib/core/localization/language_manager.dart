import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(() {
  return AppLocaleNotifier();
});

class AppLocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final manager = LanguageManager();
    // We listen to the ValueNotifier
    manager.addListener(_listener);
    ref.onDispose(() => manager.removeListener(_listener));
    return manager.value;
  }

  void _listener() {
    state = LanguageManager().value;
  }
}

class LanguageManager extends ValueNotifier<Locale> {
  static const String _languageKey = 'user_language_code';

  // Singleton instance
  static final LanguageManager _instance = LanguageManager._internal();

  factory LanguageManager() {
    return _instance;
  }

  LanguageManager._internal() : super(const Locale('en'));

  static Future<void> initialize() async {
    debugPrint('LanguageManager: Initializing...');
    await _instance._loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey);
      debugPrint('LanguageManager: Loaded language code: $savedLanguageCode');

      if (savedLanguageCode != null) {
        value = Locale(savedLanguageCode);
        Intl.defaultLocale = savedLanguageCode;
      } else {
        // Default to English if no preference saved
        value = const Locale('en');
        Intl.defaultLocale = 'en';
      }
    } catch (e) {
      debugPrint('LanguageManager: Error loading language: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    final newLocale = Locale(languageCode);
    if (value == newLocale) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }

    value = newLocale;
    Intl.defaultLocale = languageCode;
  }

  bool get isArabic => value.languageCode == 'ar';
}
