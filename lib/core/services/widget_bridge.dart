import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Bridge that mirrors values the home-screen widgets need (auth token, API
// base URL) into the place each platform's widget reads from:
//
//   • Android Glance widget reads FlutterSharedPreferences directly — Dart
//     writes here (the `shared_preferences` plugin namespaces keys under
//     `flutter.` automatically), and the widget's AuthTokenReader / WidgetGraph
//     pick the values up.
//   • iOS WidgetKit extension is sandboxed in a separate process, so it can't
//     read NSUserDefaults.standard from the host app. We forward the same
//     values into the App Group's UserDefaults via this MethodChannel; the
//     extension reads from there.
class WidgetBridge {
  WidgetBridge._();

  static const _channel = MethodChannel('com.goalio.widget/bridge');

  static const _baseUrlPrefKey = 'widget_base_url';

  static Future<void> setAuthToken(String? token) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('setAuthToken', {'token': token});
      await _channel.invokeMethod<void>('reloadTimelines');
    } on PlatformException {
      // Channel not registered yet (e.g. cold start before AppDelegate runs).
      // The next save will succeed; missing the first mirror is safe — the
      // widget will just show "no favorite teams" until then.
    }
  }

  // Pushes the current API base URL to the widgets so they don't have to
  // hardcode an environment. Call this once at app startup with
  // `ApiConstants.authBaseUrl` — local in dev, production in release.
  static Future<void> setBaseUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;

    // Android side — the Glance widget reads FlutterSharedPreferences itself.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlPrefKey, trimmed);

    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('setBaseUrl', {'url': trimmed});
      await _channel.invokeMethod<void>('reloadTimelines');
    } on PlatformException {
      // See setAuthToken — first call before the channel registers is safe to ignore.
    }
  }
}
