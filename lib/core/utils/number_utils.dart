import 'package:flutter/material.dart';

extension ArabicNumbersExtension on String {
  /// Converts Western Arabic numerals (0-9) to Eastern Arabic numerals (٠-٩)
  /// based on the current context locale.
  String toArabicNumbers(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    if (langCode != 'ar') return this;

    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String res = this;
    for (int i = 0; i < english.length; i++) {
      res = res.replaceAll(english[i], arabic[i]);
    }
    return res;
  }
}
