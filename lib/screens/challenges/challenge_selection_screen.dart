import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/size_config.dart';
import '../../core/utils/messages.dart';
import '../../l10n/app_localizations.dart';

class ChallengeSelectionScreen extends StatelessWidget {
  const ChallengeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 18.w,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.selectMode.toUpperCase(),
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: GoalioColors.greenAccent,
            letterSpacing: 1.0,
            fontFamily: 'RobotoCondensed',
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0F172A), Color(0xFF020617)],
                  )
                  : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                  ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20.w),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildModeCard(
              context,
              title: AppLocalizations.of(context)!.fullMatchday,
              subtitle: AppLocalizations.of(context)!.fullMatchdaySubtitle,
              icon: Icons.calendar_view_week,
              isDark: isDark,
            ),
            SizedBox(height: 16.h),
            _buildModeCard(
              context,
              title: AppLocalizations.of(context)!.topFixtures,
              subtitle: AppLocalizations.of(context)!.topFixturesSubtitle,
              icon: Icons.star_outline,
              isDark: isDark,
            ),
            SizedBox(height: 16.h),
            _buildModeCard(
              context,
              title: AppLocalizations.of(context)!.rivalryRound,
              subtitle: AppLocalizations.of(context)!.rivalryRoundSubtitle,
              icon: Icons.local_fire_department_outlined,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        GoalioMessages.showInfo(
          context,
          AppLocalizations.of(context)!.modeSelected(title),
        );
      },
      borderRadius: BorderRadius.circular(20.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20.w),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 56.w,
              width: 56.w,
              decoration: BoxDecoration(
                color: GoalioColors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.w),
              ),
              child: Icon(icon, color: GoalioColors.greenAccent, size: 28.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 16.w,
            ),
          ],
        ),
      ),
    );
  }
}
