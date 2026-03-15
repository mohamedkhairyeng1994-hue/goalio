import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';

String formatMatchTime(String? timeStr) {
  if (timeStr == null ||
      timeStr == 'N/A' ||
      timeStr == 'TBD' ||
      timeStr == 'VS' ||
      timeStr.contains("'")) {
    return timeStr ?? 'VS';
  }

  try {
    // Check if it's ISO 8601 format (e.g., 2026-01-29T20:00:00Z)
    if (timeStr.contains('T') && timeStr.endsWith('Z')) {
      final date = DateTime.parse(timeStr).toLocal();
      return DateFormat('HH:mm', Intl.defaultLocale).format(date);
    }
  } catch (e) {
    // Fallback to original string if parsing fails
  }

  return timeStr;
}

String formatHumanDetailedDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  try {
    final date = DateTime.parse(dateStr).toLocal();
    return DateFormat('EEEE, MMMM d, yyyy', Intl.defaultLocale).format(date);
  } catch (e) {
    return dateStr;
  }
}

bool isLiveStatus(String? status) {
  if (status == null) return false;
  final s = status.toUpperCase();
  return s == 'LIVE' || s == 'HT' || s.contains("'");
}

bool isFinishedStatus(String? status) {
  if (status == null) return false;
  final s = status.toUpperCase();
  return s == 'FT' ||
      s == 'AET' ||
      s == 'PEN' ||
      s == 'RESULT' ||
      s == 'FINISHED' ||
      s == 'FULL TIME' ||
      s == 'FINAL';
}

String localizeMatchStatus(dynamic contextOrAppLocalizations, String? status) {
  if (status == null) return '';
  final l10n =
      contextOrAppLocalizations is BuildContext
          ? AppLocalizations.of(contextOrAppLocalizations)!
          : contextOrAppLocalizations as AppLocalizations;

  final s = status.toUpperCase();
  switch (s) {
    case 'HT':
      return l10n.halftime;
    case 'FT':
    case 'FINISHED':
    case 'FULL TIME':
    case 'FINAL':
    case 'RESULT':
      return l10n.fulltime;
    case 'CAN':
    case 'CANCELLED':
      return l10n.cancelled;
    case 'POS':
    case 'POSTPONED':
      return l10n.postponed;
    case 'SUSP':
    case 'SUSPENDED':
    case 'SUSPENSION':
      return l10n.suspended;
    case 'LIVE':
      return l10n.live;
    case 'TBD':
      return l10n.tbd;
    case 'SCHEDULED':
      return l10n.scheduled;
    case 'NOT STARTED':
    case 'NS':
      return l10n.notStarted;
    case 'FIXTURE':
      return l10n.fixture;
    case 'AET':
      return l10n.aet;
    case 'PEN':
      return l10n.pen;
    default:
      if (s.contains("'")) return status;
      return formatMatchTime(status);
  }
}
