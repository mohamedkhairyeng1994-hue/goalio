import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/services/api_service.dart';
import 'reset_password_page.dart';
import 'dart:ui';
import '../../core/utils/size_config.dart';
import '../../core/utils/messages.dart';
import '../../l10n/app_localizations.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [const Color(0xFF0F172A), const Color(0xFF020617)]
                          : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                ),
              ),
            ),
          ),
          // Decorative Blobs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GoalioColors.greenAccent.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200.w,
              height: 200.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GoalioColors.blueAccent.withValues(alpha: 0.1),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 16.w, top: 16.h),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: GoalioColors.greenAccent,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_reset_rounded,
                            size: 80.w,
                            color: GoalioColors.greenAccent,
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            AppLocalizations.of(context)!.resetPassword,
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color:
                                  isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.forgotPasswordSubtitle,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 48.h),

                          _buildInputField(
                            controller: _emailController,
                            hintText:
                                AppLocalizations.of(context)!.emailAddress,
                            icon: Icons.email_outlined,
                            isDark: isDark,
                          ),
                          SizedBox(height: 32.h),

                          Container(
                            height: 56.h,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.w),
                              gradient: const LinearGradient(
                                colors: [
                                  GoalioColors.greenAccent,
                                  GoalioColors.blueAccent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: GoalioColors.greenAccent.withValues(alpha: 0.3,),
                                  blurRadius: 12.w,
                                  offset: Offset(0.w, 4.h),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                final email = _emailController.text.trim();
                                if (email.isEmpty) {
                                  GoalioMessages.showError(
                                    context,
                                    AppLocalizations.of(context)!.enterEmail,
                                  );
                                  return;
                                }

                                // Show loading
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

                                final response =
                                    await ApiService.forgotPassword(email);

                                if (mounted) {
                                  Navigator.pop(context); // Close loading
                                }

                                if (response.containsKey('error')) {
                                  if (mounted) {
                                    GoalioMessages.showError(
                                      context,
                                      response['message'] ?? response['error'],
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    GoalioMessages.showSuccess(
                                      context,
                                      AppLocalizations.of(
                                        context,
                                      )!.verificationCodeSent,
                                    );
                                    // Navigate to Reset Password Page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                ResetPasswordPage(email: email),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.w),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.sendResetLink,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isDark = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16.w),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: Icon(
                    icon,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(20.w),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
