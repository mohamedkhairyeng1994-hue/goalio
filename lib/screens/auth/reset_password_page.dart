import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/services/api_service.dart';
import 'dart:ui';
import '../../core/utils/size_config.dart';
import '../../core/utils/messages.dart';
import '../../l10n/app_localizations.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;

  Future<void> _handleReset() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (code.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      GoalioMessages.showError(
        context,
        AppLocalizations.of(context)!.fillAllFields,
      );
      return;
    }

    if (password != confirmPassword) {
      GoalioMessages.showError(
        context,
        AppLocalizations.of(context)!.passwordsDoNotMatch,
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: GoalioColors.greenAccent),
          ),
    );

    final response = await ApiService.resetPassword(
      email: widget.email,
      token: code,
      password: password,
      passwordConfirmation: confirmPassword,
    );

    if (mounted) Navigator.pop(context); // Close loading

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
          AppLocalizations.of(context)!.passwordResetSuccess,
        );
        // Go back to login
        Navigator.pop(context); // Close Reset screen
        Navigator.pop(context); // Close Forgot screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
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
                            Icons.verified_user_rounded,
                            size: 80.w,
                            color: GoalioColors.greenAccent,
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            AppLocalizations.of(context)!.newPassword,
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color:
                                  isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.resetCodeSubtitle(widget.email),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 32.h),
                          _buildInputField(
                            controller: _codeController,
                            hintText:
                                AppLocalizations.of(context)!.verificationCode,
                            icon: Icons.numbers,
                            isDark: isDark,
                          ),
                          SizedBox(height: 16.h),
                          _buildInputField(
                            controller: _passwordController,
                            hintText: AppLocalizations.of(context)!.newPassword,
                            icon: Icons.lock_outline,
                            isDark: isDark,
                            isPassword: true,
                          ),
                          SizedBox(height: 16.h),
                          _buildInputField(
                            controller: _confirmPasswordController,
                            hintText:
                                AppLocalizations.of(
                                  context,
                                )!.confirmNewPassword,
                            icon: Icons.lock_reset,
                            isDark: isDark,
                            isPassword: true,
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
                                  color: GoalioColors.greenAccent.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 12.w,
                                  offset: Offset(0.w, 4.h),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _handleReset,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.w),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.updatePassword,
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
    bool isPassword = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.w),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16.w),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !_isPasswordVisible,
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
              suffixIcon:
                  isPassword
                      ? IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                        onPressed:
                            () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            ),
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20.w),
            ),
          ),
        ),
      ),
    );
  }
}
