import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/size_config.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/time_utils.dart';
import 'notifications_providers.dart';
import '../../core/services/api_service.dart';
import '../fixtures/match_detail_page.dart';
import '../challenges/challenge_providers.dart';
import '../../core/utils/number_utils.dart';
import '../../main.dart'; // to access navigatorKey and MainPage if needed, or we can just pop to home

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          l10n.notificationsTitle,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontFamily: 'RobotoCondensed',
            color: GoalioColors.greenAccent,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20.w,
            color: GoalioColors.greenAccent,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllAsRead(),
            icon: Icon(
              Icons.done_all,
              size: 24.w,
              color: GoalioColors.greenAccent,
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: notificationsState.when(
        data: (data) {
          final List<dynamic> list = data['data'] ?? [];
          if (list.isEmpty) {
            return _buildEmptyState(isDark, l10n);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            color: GoalioColors.greenAccent,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              itemCount: list.length + 1,
              itemBuilder: (context, index) {
                if (index == list.length) {
                  final hasMore =
                      (data['current_page'] ?? 1) < (data['last_page'] ?? 1);
                  return hasMore
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: GoalioColors.greenAccent,
                          ),
                        ),
                      )
                      : const SizedBox.shrink();
                }

                final item = list[index];
                return _buildNotificationItem(item, isDark);
              },
            ),
          );
        },
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: GoalioColors.greenAccent),
            ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildNotificationItem(dynamic item, bool isDark) {
    final isRead = item['is_read'] == 1 || item['is_read'] == true;
    final title = item['title'] ?? '';
    final body = item['body'] ?? '';
    final createdAt =
        item['created_at'] != null
            ? DateTime.parse(item['created_at'])
            : DateTime.now();
    final timeStr = formatRelativeTime(
      createdAt.toLocal().toString(), 
      AppLocalizations.of(context)!
    ).toArabicNumbers(context);

    // Fallback icon
    IconData iconData = Icons.notifications_active_rounded;
    Color iconColor = GoalioColors.greenAccent;

    // Determine icon based on type from data if available
    final data = item['data'];
    if (data != null && data is Map) {
      final type = data['type'];
      switch (type) {
        case 'matchday_notification':
          iconData = Icons.sports_soccer;
          iconColor = GoalioColors.blueAccent;
          break;
        case 'score_notification':
          iconData = Icons.emoji_events;
          iconColor = Colors.amber;
          break;
        case 'match_event':
          iconData = Icons.flash_on;
          if (title.toLowerCase().contains('goal')) {
            iconColor = GoalioColors.greenAccent;
          } else if (title.toLowerCase().contains('red card')) {
            iconColor = Colors.redAccent;
          } else if (title.toLowerCase().contains('yellow card')) {
            iconColor = Colors.amber;
          }
          break;
        case 'match_reminder':
          iconData = Icons.alarm;
          iconColor = Colors.orangeAccent;
          break;
      }
    }

    if (isRead) {
      iconColor = isDark ? Colors.white30 : Colors.black26;
    }

    return GestureDetector(
      onTap: () => _handleNotificationTap(item),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color:
              isDark
                  ? (isRead
                      ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                      : const Color(0xFF1E293B))
                  : (isRead ? Colors.white.withValues(alpha: 0.6) : Colors.white),
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.w),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isRead) Container(width: 4.w, color: iconColor),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color:
                                isRead
                                    ? (isDark
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05))
                                    : iconColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, size: 18.w, color: iconColor),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight:
                                            isRead
                                                ? FontWeight.w500
                                                : FontWeight.bold,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color:
                                          isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                body,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(dynamic item) {
    final isRead = item['is_read'] == 1 || item['is_read'] == true;
    if (!isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(item['id']);
    }

    final data = item['data'];
    if (data == null || data is! Map) return;

    final type = data['type'];
    if (type == 'matchday_notification' || type == 'score_notification') {
      final leagueIdStr = data['league_id'];
      final dateStr = data['date'];

      if (leagueIdStr != null) {
        final leaguesAsync = ref.read(challengeLeaguesListProvider);
        leaguesAsync.whenData((leagues) {
          try {
            final leagueId = int.parse(leagueIdStr);
            final league = leagues.firstWhere((l) => l.id == leagueId);
            ref
                .read(selectedChallengeLeagueProvider.notifier)
                .selectLeague(league);

            if (type == 'score_notification' && dateStr != null) {
              try {
                final date = DateTime.parse(dateStr);
                ref
                    .read(selectedChallengeDateProvider.notifier)
                    .selectDate(date);
              } catch (_) {}
            }
          } catch (_) {}
        });
      }

      // Close notifications page and go to Challenge tab
      Navigator.popUntil(context, (route) => route.isFirst);
      mainPageTabSwitcher?.call(3);
    } else if (type == 'match_status' ||
        type == 'match_event' ||
        type == 'match_reminder') {
      final matchIdStr = data['match_id'];
      if (matchIdStr != null) {
        // Fetch match and show detail page
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(
                child: CircularProgressIndicator(
                  color: GoalioColors.greenAccent,
                ),
              ),
        );

        ApiService.getMatchById(matchIdStr)
            .then((match) {
              if (mounted) Navigator.pop(context); // close dialog
              if (match != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MatchDetailPage(match: match),
                  ),
                );
              }
            })
            .catchError((_) {
              if (mounted) Navigator.pop(context); // close dialog
            });
      }
    }
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80.w,
            color: isDark ? Colors.white10 : Colors.black12,
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.noNotificationsYet,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}
