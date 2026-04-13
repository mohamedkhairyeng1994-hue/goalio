import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GoalioColors {
  // We keep brand colors static as they are identity
  static const Color greenAccent = Color(0xFF34D399); // Emeral/Neon Green
  static const Color blueAccent = Color(0xFF3B82F6); // Bright Blue

  // These are kept for legacy reference or forcing dark mode elements,
  // but main app should use Theme.of(context)
  static const Color background = Color(0xFF0A0F1A);
  static const Color cardBackground = Color(0xFF1E293B);
}

class ApiConstants {
  static String currentEnvironment = 'local';

  static String get authBaseUrl {
    switch (currentEnvironment) {
      case 'local':
        if (kIsWeb) return 'http://scrapping.test/goalio_backend/public/api';
        if (defaultTargetPlatform == TargetPlatform.android) {
          return 'http://10.0.2.2/scrapping/goalio_backend/public/api';
        }
        return 'http://scrapping.test/goalio_backend/public/api';
      case 'production':
        return 'https://goalio.smartoo.site/api';
      default:
        return 'https://goalio.smartoo.site/api';
    }
  }
}
