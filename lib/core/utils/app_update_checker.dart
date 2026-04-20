import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/constants.dart';
import '../../l10n/app_localizations.dart';

/// Checks whether the user is running an outdated build and prompts an update.
///
/// Fetches `min_app_version`, `play_store_url` and `app_store_url` from
/// `GET /dashboard/settings` (public endpoint). If the local build is
/// older than `min_app_version`, a localized dialog is shown with an
/// "Update Now" button that opens the relevant store.
class AppUpdateChecker {
  static bool _checkedThisSession = false;

  static Future<void> checkAndPrompt(BuildContext context) async {
    if (_checkedThisSession) return;
    _checkedThisSession = true;

    final settings = await _fetchSettings();
    if (settings == null) return;

    final minVersion = (settings['min_app_version'] as String?)?.trim();
    if (minVersion == null || minVersion.isEmpty) return;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    if (!_isOlder(currentVersion, minVersion)) return;
    if (!context.mounted) return;

    final storeUrl = Platform.isIOS
        ? (settings['app_store_url'] as String?)
        : (settings['play_store_url'] as String?);

    await _showDialog(context, storeUrl);
  }

  static Future<Map<String, dynamic>?> _fetchSettings() async {
    try {
      final uri = Uri.parse('${ApiConstants.authBaseUrl}/dashboard/settings');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Returns true when `current` is strictly older than `minimum`.
  /// Versions are compared as dotted integer segments; any non-numeric
  /// suffix (e.g. "+1" build metadata) is ignored per-segment.
  static bool _isOlder(String current, String minimum) {
    final cur = _parseSegments(current);
    final min = _parseSegments(minimum);
    final length = cur.length > min.length ? cur.length : min.length;
    for (var i = 0; i < length; i++) {
      final c = i < cur.length ? cur[i] : 0;
      final m = i < min.length ? min[i] : 0;
      if (c < m) return true;
      if (c > m) return false;
    }
    return false;
  }

  static List<int> _parseSegments(String version) {
    return version
        .split(RegExp(r'[.\-+]'))
        .map((s) {
          final digits = RegExp(r'\d+').firstMatch(s)?.group(0);
          return int.tryParse(digits ?? '') ?? 0;
        })
        .toList();
  }

  static Future<void> _showDialog(BuildContext context, String? storeUrl) async {
    final l = AppLocalizations.of(context);
    final title = l?.updateAvailableTitle ?? 'Update Available';
    final message = l?.updateAvailableMessage ??
        'A new version is available. Please update to continue.';
    final updateLabel = l?.updateNow ?? 'Update Now';
    final laterLabel = l?.later ?? 'Later';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(laterLabel),
          ),
          FilledButton(
            onPressed: () async {
              if (storeUrl != null && storeUrl.isNotEmpty) {
                final uri = Uri.parse(storeUrl);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: Text(updateLabel),
          ),
        ],
      ),
    );
  }
}
