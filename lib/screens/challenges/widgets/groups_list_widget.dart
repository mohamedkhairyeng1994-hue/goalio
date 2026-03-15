import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/size_config.dart';
import '../../../core/utils/messages.dart';
import '../../../l10n/app_localizations.dart';
import '../challenge_models.dart';
import '../challenge_providers.dart';
import 'challenge_dialogs.dart';

class GroupsListWidget extends ConsumerWidget {
  final bool isDark;

  const GroupsListWidget({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 0),
      sliver: SliverToBoxAdapter(
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24.w),
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  )
                : null,
            boxShadow: [
              if (isDark)
                BoxShadow(
                  color: GoalioColors.greenAccent.withValues(alpha: 0.1),
                  blurRadius: 20.w,
                  offset: Offset(0, 8.h),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Join & Create Buttons Row
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 32.h,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showJoinLeagueDialog(context, ref);
                          },
                          icon: Icon(Icons.group_add, size: 12.w),
                          label: Text(
                            AppLocalizations.of(context)!.joinLeagueLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: GoalioColors.greenAccent,
                            side: const BorderSide(
                              color: GoalioColors.greenAccent,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.w),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: SizedBox(
                        height: 32.h,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showCreateLeagueDialog(context, ref);
                          },
                          icon: Icon(Icons.add_circle, size: 12.w),
                          label: Text(
                            AppLocalizations.of(context)!.createLeagueLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GoalioColors.greenAccent,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.w),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. The Leagues List inside the card
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: groupsAsync.when(
                  skipLoadingOnRefresh: true,
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => Center(child: Text("Error: $e")),
                  data: (groups) {
                    final generalLeagues = groups
                        .where((g) => g.name == 'World' || g.type == 'general')
                        .toList();
                    final myLeagues = groups
                        .where((g) => g.name != 'World' && g.type != 'general')
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (myLeagues.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                            child: Text(
                              AppLocalizations.of(context)!.myClassicLeagues.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                                color: GoalioColors.greenAccent,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          ...myLeagues.map((group) {
                            final isLast = myLeagues.last == group;
                            return _GroupItemWidget(
                              group: group,
                              isDark: isDark,
                              isLast: isLast,
                            );
                          }),
                        ],
                        if (generalLeagues.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
                            child: Text(
                              AppLocalizations.of(context)!.generalLeagues.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                                color: GoalioColors.greenAccent,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          ...generalLeagues.map((group) {
                            final isLast = generalLeagues.last == group;
                            return _GroupItemWidget(
                              group: group,
                              isDark: isDark,
                              isLast: isLast,
                            );
                          }),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupItemWidget extends ConsumerWidget {
  final Group group;
  final bool isDark;
  final bool isLast;

  const _GroupItemWidget({
    required this.group,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6.h),
      child: InkWell(
        onTap: () => ref.read(selectedGroupProvider.notifier).selectGroup(group),
        borderRadius: BorderRadius.circular(12.w),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12.w),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 30.w,
                width: 30.w,
                decoration: BoxDecoration(
                  color: _getLeagueColor(group.type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.w),
                  border: Border.all(
                    color: _getLeagueColor(group.type).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    group.type == 'general' ? Icons.public : Icons.group,
                    color: _getLeagueColor(group.type),
                    size: 14.w,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (group.isAdmin && group.code != null) ...[
                          SizedBox(width: 4.w),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: group.code!));
                                GoalioMessages.showInfo(context, AppLocalizations.of(context)!.codeCopied);
                              },
                              borderRadius: BorderRadius.circular(8.w),
                              child: Padding(
                                padding: EdgeInsets.all(4.w),
                                child: Icon(Icons.copy_rounded, size: 13.w, color: GoalioColors.greenAccent),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      AppLocalizations.of(context)!.playersCount(group.totalUsers.toString()),
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 18.h,
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                margin: EdgeInsets.symmetric(horizontal: 10.w),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.rank.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white38 : Colors.black38,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    _formatNumber(group.userRank),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      color: GoalioColors.greenAccent,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward_ios,
                size: 11.w,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLeagueColor(String type) {
    return type == 'general' ? const Color(0xFF3B82F6) : const Color(0xFF10B981);
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}
