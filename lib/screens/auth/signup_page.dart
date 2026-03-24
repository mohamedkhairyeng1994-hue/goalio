import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/constants/constants.dart';
import '../../core/services/api_service.dart';
import '../../screens/favorites/favorite_teams_page.dart';
import '../../core/utils/size_config.dart';
import '../../core/utils/messages.dart';
import '../../l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback onSignupSuccess;

  const SignupPage({super.key, required this.onSignupSuccess});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }
    
    final result = await ApiService.signup(name, email, password, fcmToken: fcmToken);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.containsKey('data')) {
        GoalioMessages.showSuccess(
          context,
          "Account created! Verify your team preferences.",
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const FavoriteTeamsPage(isOnboarding: true),
          ),
        );
      } else {
        GoalioMessages.showError(
          context,
          result['detail'] ?? result['error'] ?? "Signup failed",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Decorative Blobs
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300.w,
                height: 300.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GoalioColors.greenAccent.withOpacity(0.1),
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
                  color: GoalioColors.blueAccent.withOpacity(0.1),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 10.h),
                        // Logo and Title
                        Image.asset(
                          isDark
                              ? 'assets/goalio_logo.png'
                              : 'assets/goalio_logo_light.png',
                          height: MediaQuery.of(context).size.height * 0.18,
                          errorBuilder:
                              (c, e, s) => Icon(
                                Icons.sports_soccer,
                                size: 100.w,
                                color: GoalioColors.greenAccent,
                              ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          AppLocalizations.of(context)!.createAccount,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: isDark ? Colors.white : Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          AppLocalizations.of(context)!.joinCommunity,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 48.h),

                        _buildInputField(
                          controller: _nameController,
                          hintText: AppLocalizations.of(context)!.fullName,
                          icon: Icons.person_outline,
                          isDark: isDark,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return AppLocalizations.of(context)!.enterName;
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        _buildInputField(
                          controller: _emailController,
                          hintText: AppLocalizations.of(context)!.emailAddress,
                          icon: Icons.email_outlined,
                          isDark: isDark,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return AppLocalizations.of(context)!.enterEmail;
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value))
                              return AppLocalizations.of(context)!.invalidEmail;
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        _buildInputField(
                          controller: _passwordController,
                          hintText: AppLocalizations.of(context)!.passwordLabel,
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isDark: isDark,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: GoalioColors.greenAccent,
                            ),
                            onPressed:
                                () => setState(
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                ),
                          ),
                          obscureText: !_isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return AppLocalizations.of(
                                context,
                              )!.enterPassword;
                            if (value.length < 6)
                              return AppLocalizations.of(
                                context,
                              )!.passwordTooShort;
                            return null;
                          },
                        ),
                        SizedBox(height: 40.h),

                        Container(
                          height: 56.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.w),
                            gradient: const LinearGradient(
                              colors: [
                                GoalioColors.greenAccent,
                                GoalioColors.blueAccent,
                              ],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.w),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? SizedBox(
                                      height: 20.h,
                                      width: 20.w,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.signUpLabel.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                        SizedBox(height: 32.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.alreadyHaveAccount,
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                AppLocalizations.of(context)!.loginLabel,
                                style: const TextStyle(
                                  color: GoalioColors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool isDark = true,
    Widget? suffixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
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
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                validator: validator,
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
                  suffixIcon: suffixIcon,
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
