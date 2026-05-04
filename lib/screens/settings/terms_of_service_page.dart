import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/size_config.dart';
import '../../l10n/app_localizations.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.termsOfService),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: GoalioColors.greenAccent,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(AppLocalizations.of(context)!.termsOfService),
            _buildSection(
              context,
              AppLocalizations.of(context)!.termsSection1Title,
              AppLocalizations.of(context)!.termsSection1Content,
            ),
            _buildSection(
              context,
              AppLocalizations.of(context)!.termsSection2Title,
              AppLocalizations.of(context)!.termsSection2Content,
            ),
            _buildSection(
              context,
              AppLocalizations.of(context)!.termsSection3Title,
              AppLocalizations.of(context)!.termsSection3Content,
            ),
            _buildSection(
              context,
              AppLocalizations.of(context)!.termsSection4Title,
              AppLocalizations.of(context)!.termsSection4Content,
            ),
            _buildSection(
              context,
              AppLocalizations.of(context)!.termsSection5Title,
              AppLocalizations.of(context)!.termsSection5Content,
            ),
            _buildSection(
              context,
              AppLocalizations.of(context)!.termsSection6Title,
              AppLocalizations.of(context)!.termsSection6Content,
            ),
            _buildSection(
              context,
              AppLocalizations.of(context)!.termsSection7Title,
              AppLocalizations.of(context)!.termsSection7Content,
            ),
            SizedBox(height: 40.h),
            Center(
              child: Text(
                AppLocalizations.of(context)!.allRightsReserved,
                style: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black26,
                  fontSize: 12.sp,
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: GoalioColors.greenAccent,
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 15.sp,
              height: 1.6.h,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
