import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/constants/constants.dart';
import '../../screens/auth/signup_page.dart';
import '../../screens/auth/forgot_password_page.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/size_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../core/utils/messages.dart';
import 'dart:io' show Platform;
import '../../l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoginLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _isFacebookLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoginLoading = true);
    
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }
    
    final result = await ApiService.login(email, password, fcmToken: fcmToken);

    if (mounted) {
      setState(() => _isLoginLoading = false);

      if (result.containsKey('data')) {
        widget.onLoginSuccess();
      } else {
        GoalioMessages.showError(context, result['error'] ?? "Login failed");
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }

    try {
      final googleSignIn = GoogleSignIn(
        clientId:
            Platform.isIOS
                ? '1039306559815-b4m9stbq0jldg6u32ja8f2vkiq8kje62.apps.googleusercontent.com'
                : null,
        serverClientId:
            '1039306559815-t8egv3tivv56apg7k61479v2h1kd5h1a.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );

        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        final user = userCredential.user;

        if (user != null) {
          final result = await ApiService.socialLogin(
            provider: 'google',
            token: user.uid,
            email: user.email,
            name: user.displayName,
            fcmToken: fcmToken,
          );

          if (mounted) {
            if (result.containsKey('data') || result.containsKey('token')) {
              widget.onLoginSuccess();
            } else {
              GoalioMessages.showError(
                context,
                result['error'] ?? "Google sign-in failed on server",
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      if (mounted) {
        String errorMessage = "Google Sign-In Error";
        if (e.toString().contains("PlatformException(10,")) {
          errorMessage = "Configuration Error (10). Please check your SHA-1 in Google Play Console.";
        } else if (e.toString().contains("PlatformException(12500,")) {
          errorMessage = "Internal Error (12500). Please check your Google Services configuration.";
        } else if (e.toString().contains("PlatformException(12501,")) {
          errorMessage = "Sign-in cancelled by user.";
        } else {
          errorMessage = "Google Error: $e";
        }
        GoalioMessages.showError(context, errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isAppleLoading = true);
    
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }

    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithProvider(appleProvider);
      final user = userCredential.user;

      if (user != null) {
        final result = await ApiService.socialLogin(
          provider: 'apple',
          token: user.uid, // This is the stable Apple/Firebase User ID
          email: user.email,
          name: user.displayName,
          fcmToken: fcmToken,
        );

        if (mounted) {
          if (result.containsKey('data') || result.containsKey('token')) {
            widget.onLoginSuccess();
          } else {
            GoalioMessages.showError(
              context,
              result['error'] ?? "Apple sign-in failed",
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Apple Sign-In Error: $e');
      if (mounted) {
        GoalioMessages.showError(context, "Apple Sign-In Error: $e");
      }
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() => _isFacebookLoading = true);
    
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }

    try {
      final LoginResult fbResult = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email']
      );
      
      if (fbResult.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();

        final result = await ApiService.socialLogin(
          provider: 'facebook',
          token: userData['id'],
          email: userData['email'],
          name: userData['name'],
          fcmToken: fcmToken,
        );

        if (mounted) {
          if (result.containsKey('data') || result.containsKey('token')) {
            widget.onLoginSuccess();
          } else {
            GoalioMessages.showError(
              context,
              result['error'] ?? "Facebook sign-in failed",
            );
          }
        }
      } else {
        if (mounted) {
          GoalioMessages.showError(
            context,
            "Facebook Sign-In Error: ${fbResult.message}",
          );
        }
      }
    } catch (e) {
      debugPrint('Facebook Sign-In Error: $e');
      if (mounted) {
        GoalioMessages.showError(context, "Facebook Sign-In Error: $e");
      }
    } finally {
      if (mounted) setState(() => _isFacebookLoading = false);
    }
  }

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
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and Title (No Hero to avoid transition issues causing black screen)
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
                      SizedBox(height: 5.h),
                      Text(
                        AppLocalizations.of(context)!.welcomeBack,
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
                        AppLocalizations.of(context)!.signInSubtitle,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 48.h),

                      // Input Fields with Glassmorphism
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
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                        ),
                        obscureText: !_isPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return AppLocalizations.of(context)!.enterPassword;
                          return null;
                        },
                      ),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: Text(
                            AppLocalizations.of(context)!.forgotPasswordLabel,
                            style: TextStyle(
                              color: GoalioColors.blueAccent,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Login Button
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
                          boxShadow: [
                            BoxShadow(
                              color: GoalioColors.greenAccent.withOpacity(0.3),
                              blurRadius: 12.w,
                              offset: Offset(0.w, 4.h),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoginLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.w),
                            ),
                          ),
                          child:
                              _isLoginLoading
                                  ? SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    AppLocalizations.of(context)!.loginLabel,
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

                      // Social Login (Mock)
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white10)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              AppLocalizations.of(context)!.orContinueWith,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: isDark ? Colors.white24 : Colors.black26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white10)),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            child: Image.network(
                              'https://www.gstatic.com/images/branding/product/2x/googleg_96dp.png',
                              height: 24.w,
                              width: 24.w,
                              errorBuilder:
                                  (context, error, stackTrace) => FaIcon(
                                    FontAwesomeIcons.google,
                                    color: const Color(0xFFEA4335),
                                    size: 24.w,
                                  ),
                            ),
                            isLoading: _isGoogleLoading,
                            isDark: isDark,
                            onTap: _handleGoogleSignIn,
                          ),
                          if (Platform.isIOS) ...[
                            SizedBox(width: 16.w),
                            _buildSocialButton(
                              icon: FontAwesomeIcons.apple,
                              isLoading: _isAppleLoading,
                              isDark: isDark,
                              onTap: _handleAppleSignIn,
                            ),
                          ],
                          SizedBox(width: 16.w),
                          _buildSocialButton(
                            icon: FontAwesomeIcons.facebook,
                            iconColor: const Color(0xFF1877F2),
                            isLoading: _isFacebookLoading,
                            isDark: isDark,
                            onTap: _handleFacebookSignIn,
                          ),
                        ],
                      ),
                      SizedBox(height: 28.h),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.dontHaveAccount,
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => SignupPage(
                                        onSignupSuccess: widget.onLoginSuccess,
                                      ),
                                ),
                              );
                            },
                            child: Text(
                              AppLocalizations.of(context)!.signUpLabel,
                              style: const TextStyle(
                                color: GoalioColors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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

  Widget _buildSocialButton({
    IconData? icon,
    Color? iconColor,
    Widget? child,
    bool isLoading = false,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 56.w,
        height: 56.w,
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Center(
          child:
              isLoading
                  ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: GoalioColors.greenAccent,
                    ),
                  )
                  : (child ??
                      FaIcon(
                        icon,
                        color:
                            iconColor ??
                            (isDark ? Colors.white : Colors.black87),
                        size: 24.w,
                      )),
        ),
      ),
    );
  }
}
