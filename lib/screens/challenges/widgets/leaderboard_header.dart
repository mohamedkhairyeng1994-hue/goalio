import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/utils/size_config.dart';
import '../../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/number_utils.dart';

class LeaderboardHeaderWidget extends StatelessWidget {
  final bool isDark;

  const LeaderboardHeaderWidget({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: LeaderboardHeaderDelegate(
        isDark: isDark,
        context: context,
      ),
    );
  }
}

class LeaderboardHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isDark;
  final BuildContext context;

  LeaderboardHeaderDelegate({
    required this.isDark,
    required this.context,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(
      height: maxExtent,
      child: Container(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLastUpdateInfo(context, isDark),
            _buildLeaderboardTableHeader(context, isDark)
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdateInfo(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 12.h, 20.w, 8.h),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          AppLocalizations.of(context)!.lastUpdated(
            DateFormat("dd MMM yyyy, HH:mm").format(DateTime.now()).toUpperCase().toArabicNumbers(context),
          ),
          style: TextStyle(
            fontSize: 9.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white54 : Colors.black54,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTableHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.w)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.8),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 55.w,
                  child: Text(
                    AppLocalizations.of(context)!.pos.toUpperCase(),
                    style: _tableHeaderStyle(isDark),
                  ),
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.fullName.toUpperCase(),
                    style: _tableHeaderStyle(isDark),
                  ),
                ),
                SizedBox(
                  width: 45.w,
                  child: Text(
                    AppLocalizations.of(context)!.mdSmall.toUpperCase(),
                    textAlign: TextAlign.end,
                    style: _tableHeaderStyle(isDark),
                  ),
                ),
                SizedBox(
                  width: 55.w,
                  child: Text(
                    AppLocalizations.of(context)!.totalSmall.toUpperCase(),
                    textAlign: TextAlign.end,
                    style: _tableHeaderStyle(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _tableHeaderStyle(bool isDark) {
    return TextStyle(
      fontSize: 8.sp,
      fontWeight: FontWeight.w900,
      color: isDark ? Colors.white54 : Colors.black54,
      letterSpacing: 0.5,
    );
  }

  @override
  double get maxExtent => 88.h;
  @override
  double get minExtent => 87.9.h;

  @override
  bool shouldRebuild(LeaderboardHeaderDelegate oldDelegate) {
    return isDark != oldDelegate.isDark;
  }
}
