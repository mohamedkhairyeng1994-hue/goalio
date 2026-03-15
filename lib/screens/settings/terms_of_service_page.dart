import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/size_config.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
            _buildHeader("Terms of Service"),
            _buildSection(
              context,
              "1. Acceptance of Terms",
              "By accessing and using the Goalio application, you agree to comply with and be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.",
            ),
            _buildSection(
              context,
              "2. Use of Services",
              "Goalio provides football fixtures, news, and personalized features. You agree to use the services only for lawful purposes and in a manner that does not infringe the rights of others.",
            ),
            _buildSection(
              context,
              "3. User Accounts",
              "When you create an account, you are responsible for maintaining the confidentiality of your credentials and for all activities that occur under your account.",
            ),
            _buildSection(
              context,
              "4. Intellectual Property",
              "The content, features, and functionality of Goalio are owned by Goalio and are protected by international copyright, trademark, and other intellectual property laws.",
            ),
            _buildSection(
              context,
              "5. Disclaimer of Warranties",
              "Goalio is provided 'as is' without warranties of any kind. While we strive for accuracy, we do not guarantee that match data, scores, or news will always be error-free or up-to-the-minute.",
            ),
            _buildSection(
              context,
              "6. Limitation of Liability",
              "In no event shall Goalio be liable for any indirect, incidental, or consequential damages arising out of your use or inability to use the application.",
            ),
            _buildSection(
              context,
              "7. Changes to Terms",
              "We reserve the right to modify these Terms of Service at any time. Your continued use of the app after such changes constitutes acceptance of the new terms.",
            ),
            SizedBox(height: 40.h),
            Center(
              child: Text(
                "© 2026 Goalio. All rights reserved.",
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
              ).textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
