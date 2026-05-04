import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/messages.dart';
import '../../core/utils/size_config.dart';
import '../../l10n/app_localizations.dart';

class NotificationManagerPage extends StatefulWidget {
  const NotificationManagerPage({super.key});

  @override
  State<NotificationManagerPage> createState() =>
      _NotificationManagerPageState();
}

class _NotificationManagerPageState extends State<NotificationManagerPage> {
  static const List<int> _frequencyOptions = [
    5,
    15,
    30,
    60,
    120,
    240,
    480,
    720,
    1440,
  ];

  bool _loading = true;
  bool _saving = false;

  // Match-event toggles. Defaults mirror the backend defaults so the UI
  // shows the right state even before the first GET resolves.
  final Map<String, bool> _events = {
    'notify_goal': true,
    'notify_assist': true,
    'notify_yellow_card': true,
    'notify_red_card': true,
    'notify_substitution': false,
    'notify_var': true,
    'notify_penalty': true,
    'notify_match_start': true,
    'notify_match_end': true,
    'notify_half_time': true,
    'notify_pre_match': true,
  };

  bool _newsEnabled = true;
  int _newsFrequencyMinutes = 240;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await ApiService.getNotificationPreferences();
    if (!mounted) return;
    setState(() {
      if (prefs != null) {
        for (final key in _events.keys) {
          if (prefs[key] is bool) _events[key] = prefs[key] as bool;
        }
        if (prefs['news_enabled'] is bool) {
          _newsEnabled = prefs['news_enabled'] as bool;
        }
        if (prefs['news_frequency_minutes'] is int) {
          _newsFrequencyMinutes = prefs['news_frequency_minutes'] as int;
        } else if (prefs['news_frequency_minutes'] is num) {
          _newsFrequencyMinutes =
              (prefs['news_frequency_minutes'] as num).toInt();
        }
        if (!_frequencyOptions.contains(_newsFrequencyMinutes)) {
          _newsFrequencyMinutes = _closestFrequency(_newsFrequencyMinutes);
        }
      }
      _loading = false;
    });
  }

  int _closestFrequency(int value) {
    return _frequencyOptions.reduce(
      (a, b) => (value - a).abs() < (value - b).abs() ? a : b,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final payload = <String, dynamic>{
      ..._events,
      'news_enabled': _newsEnabled,
      'news_frequency_minutes': _newsFrequencyMinutes,
    };

    final result = await ApiService.updateNotificationPreferences(payload);
    if (!mounted) return;

    setState(() => _saving = false);
    final loc = AppLocalizations.of(context)!;
    if (result != null) {
      GoalioMessages.showSuccess(context, loc.preferencesSaved);
    } else {
      GoalioMessages.showError(context, loc.preferencesSaveFailed);
    }
  }

  String _frequencyLabel(int minutes, AppLocalizations loc) {
    switch (minutes) {
      case 5:
        return loc.freqEvery5Minutes;
      case 15:
        return loc.freqEvery15Minutes;
      case 30:
        return loc.freqEvery30Minutes;
      case 60:
        return loc.freqEveryHour;
      case 120:
        return loc.freqEvery2Hours;
      case 240:
        return loc.freqEvery4Hours;
      case 480:
        return loc.freqEvery8Hours;
      case 720:
        return loc.freqEvery12Hours;
      case 1440:
        return loc.freqEveryDay;
      default:
        return '$minutes ${loc.minutesAbbr}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          loc.notificationManager,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                children: [
                  _sectionHeader(loc.matchEvents, loc.matchEventsSubtitle),
                  _eventTile(loc.eventGoal, 'notify_goal', Icons.sports_soccer),
                  _eventTile(
                    loc.eventAssist,
                    'notify_assist',
                    Icons.handshake_outlined,
                  ),
                  _eventTile(
                    loc.eventYellowCard,
                    'notify_yellow_card',
                    Icons.square_rounded,
                    iconColor: Colors.amber,
                  ),
                  _eventTile(
                    loc.eventRedCard,
                    'notify_red_card',
                    Icons.square_rounded,
                    iconColor: Colors.redAccent,
                  ),
                  _eventTile(
                    loc.eventPenalty,
                    'notify_penalty',
                    Icons.gps_fixed,
                  ),
                  _eventTile(loc.eventVar, 'notify_var', Icons.tv_outlined),
                  _eventTile(
                    loc.eventSubstitution,
                    'notify_substitution',
                    Icons.swap_horiz,
                  ),
                  _eventTile(
                    loc.eventMatchStart,
                    'notify_match_start',
                    Icons.play_circle_outline,
                  ),
                  _eventTile(
                    loc.eventHalfTime,
                    'notify_half_time',
                    Icons.timer_outlined,
                  ),
                  _eventTile(
                    loc.eventMatchEnd,
                    'notify_match_end',
                    Icons.flag_outlined,
                  ),
                  _eventTile(
                    loc.eventPreMatch,
                    'notify_pre_match',
                    Icons.notifications_outlined,
                  ),

                  SizedBox(height: 24.h),
                  _sectionHeader(loc.newsAlerts, loc.newsAlertsSubtitle),
                  _card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: _newsEnabled,
                          onChanged: (v) => setState(() => _newsEnabled = v),
                          activeThumbColor: GoalioColors.greenAccent,
                          secondary: Icon(
                            Icons.article_outlined,
                            color: GoalioColors.blueAccent,
                          ),
                          title: Text(loc.newsEnabled),
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.2),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: GoalioColors.blueAccent,
                              ),
                              SizedBox(width: 16.w),
                              Expanded(child: Text(loc.newsFrequency)),
                              DropdownButton<int>(
                                value: _newsFrequencyMinutes,
                                underline: const SizedBox(),
                                onChanged:
                                    _newsEnabled
                                        ? (v) {
                                          if (v == null) return;
                                          setState(
                                            () => _newsFrequencyMinutes = v,
                                          );
                                        }
                                        : null,
                                items:
                                    _frequencyOptions
                                        .map(
                                          (m) => DropdownMenuItem<int>(
                                            value: m,
                                            child: Text(
                                              _frequencyLabel(m, loc),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GoalioColors.greenAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                      ),
                      onPressed: _saving ? null : _save,
                      child:
                          _saving
                              ? SizedBox(
                                height: 20.h,
                                width: 20.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                loc.save,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 12.h, start: 4.w, end: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: GoalioColors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.w),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4.w,
                    offset: Offset(0.w, 2.h),
                  ),
                ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(12.w), child: child),
    );
  }

  Widget _eventTile(
    String title,
    String key,
    IconData icon, {
    Color? iconColor,
  }) {
    return _card(
      child: SwitchListTile(
        value: _events[key] ?? true,
        onChanged: (v) => setState(() => _events[key] = v),
        activeThumbColor: GoalioColors.greenAccent,
        secondary: Icon(icon, color: iconColor ?? GoalioColors.blueAccent),
        title: Text(title),
      ),
    );
  }
}
