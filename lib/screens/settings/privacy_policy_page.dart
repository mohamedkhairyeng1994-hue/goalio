import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/size_config.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
            _buildHeader("Privacy Policy"),
            _buildSection(
              context,
              "Last Updated: January 29, 2026",
              "Your privacy is important to us. This Privacy Policy explains how Goalio collects, uses, and protects your information when you use our mobile application.",
            ),
            _buildSection(
              context,
              "1. Information We Collect",
              "We collect information you provide directly to us when you create an account, such as your fullname and email address. We also store your 'Favorite Teams' preferences as part of your user profile to personalize your experience.",
            ),
            _buildSection(
              context,
              "2. How We Use Your Information",
              "We use the information we collect to:\n• Provide, maintain, and improve our services.\n• Personalize your experience by showing your favorite teams first.\n• Communicate with you about updates or security alerts.\n• Protect the safety and integrity of our services.",
            ),
            _buildSection(
              context,
              "3. Data Persistence",
              "Your account data and favorite teams are stored securely in our backend database. We do not sell or share your personal data with third-party advertisers.",
            ),
            _buildSection(
              context,
              "4. Security",
              "We implement industry-standard security measures to protect your data, including hashed passwords and encrypted communication (HTTPS). However, no method of transmission over the internet is 100% secure.",
            ),
            _buildSection(
              context,
              "5. Your Choices",
              "You can update your favorite teams at any time within the app. You may also contact us to request the deletion of your account and personal data.",
            ),
            _buildSection(
              context,
              "6. Contact Us",
              "If you have any questions about this Privacy Policy, please reach out via our support channels.",
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
