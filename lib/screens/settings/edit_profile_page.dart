import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/messages.dart';
import '../../core/utils/size_config.dart';
import '../../l10n/app_localizations.dart';

/// Edit-profile screen reachable from Settings → Account.
///
/// Loads the current user via `/user/me`, lets the user rename themselves,
/// and (for password-auth users) optionally change the password. Email is
/// shown read-only — changing it is intentionally out of scope here because
/// it's the auth identifier and would need a re-verification flow.
///
/// Social-login users (no password set on the server) see a hint instead of
/// the password fields, mirroring the backend's 422 guard.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoadingProfile = true;
  bool _isSaving = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  // null until we know — drives whether to render the password block.
  bool? _passwordChangeAvailable;

  String? _email;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await ApiService.getUserProfile();
    if (!mounted) return;
    if (profile == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }
    setState(() {
      _nameController.text = profile['fullname']?.toString() ?? '';
      _email = profile['email']?.toString();
      // Backend hides `password` and `provider` from /me, so we infer:
      // social-only accounts always have a `provider` set on the user row.
      // The me payload in this app exposes neither, so we fall back to
      // showing the password block by default and let the server reject
      // with the 422 hint if it's a social-only account. UX: the user can
      // tap save and learn it's not allowed — far rarer than the happy path.
      _passwordChangeAvailable = true;
      _isLoadingProfile = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    final newPwd = _newPasswordController.text;
    final currentPwd = _currentPasswordController.text;
    final confirmPwd = _confirmPasswordController.text;

    final wantsPasswordChange = newPwd.isNotEmpty;

    setState(() => _isSaving = true);

    final result = await ApiService.updateProfile(
      fullname: newName,
      currentPassword: wantsPasswordChange ? currentPwd : null,
      newPassword: wantsPasswordChange ? newPwd : null,
      newPasswordConfirmation: wantsPasswordChange ? confirmPwd : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.containsKey('error')) {
      GoalioMessages.showError(
        context,
        result['message']?.toString() ??
            result['error']?.toString() ??
            AppLocalizations.of(context)!.profileUpdateFailed,
      );
      return;
    }

    GoalioMessages.showSuccess(
      context,
      AppLocalizations.of(context)!.profileUpdated,
    );
    if (wantsPasswordChange) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l.editProfile,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: GoalioColors.greenAccent),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.editProfileSubtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _buildField(
                      label: l.fullName,
                      controller: _nameController,
                      icon: Icons.person_outline,
                      isDark: isDark,
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return l.fillAllFields;
                        if (t.length < 2) return l.fillAllFields;
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    _buildField(
                      label: l.email,
                      icon: Icons.alternate_email,
                      isDark: isDark,
                      readOnly: true,
                      controllerText: _email ?? '',
                    ),
                    SizedBox(height: 28.h),
                    Text(
                      l.changePassword,
                      style: TextStyle(
                        color: GoalioColors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      l.changePasswordOptional,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    if (_passwordChangeAvailable == false)
                      _buildSocialHint(isDark, l.socialAccountPasswordHint)
                    else ...[
                      _buildField(
                        label: l.currentPassword,
                        controller: _currentPasswordController,
                        icon: Icons.lock_outline,
                        isDark: isDark,
                        isPassword: true,
                        passwordVisible: _showCurrentPassword,
                        onToggleVisibility: () => setState(
                          () => _showCurrentPassword = !_showCurrentPassword,
                        ),
                        validator: (v) {
                          if (_newPasswordController.text.isEmpty) return null;
                          if ((v ?? '').isEmpty) return l.fillAllFields;
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      _buildField(
                        label: l.newPassword,
                        controller: _newPasswordController,
                        icon: Icons.lock_reset,
                        isDark: isDark,
                        isPassword: true,
                        passwordVisible: _showNewPassword,
                        onToggleVisibility: () => setState(
                          () => _showNewPassword = !_showNewPassword,
                        ),
                        validator: (v) {
                          final t = v ?? '';
                          if (t.isEmpty) return null; // optional
                          if (t.length < 6) return l.fillAllFields;
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      _buildField(
                        label: l.confirmNewPassword,
                        controller: _confirmPasswordController,
                        icon: Icons.lock_clock,
                        isDark: isDark,
                        isPassword: true,
                        passwordVisible: _showNewPassword,
                        validator: (v) {
                          if (_newPasswordController.text.isEmpty) return null;
                          if ((v ?? '') != _newPasswordController.text) {
                            return l.passwordsDoNotMatch;
                          }
                          return null;
                        },
                      ),
                    ],
                    SizedBox(height: 32.h),
                    SizedBox(
                      height: 52.h,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GoalioColors.greenAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.w),
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 22.w,
                                height: 22.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                l.save,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required bool isDark,
    TextEditingController? controller,
    String? controllerText,
    bool isPassword = false,
    bool readOnly = false,
    bool passwordVisible = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    final effectiveController = controller ??
        TextEditingController(text: controllerText ?? '');

    return TextFormField(
      controller: effectiveController,
      readOnly: readOnly,
      obscureText: isPassword && !passwordVisible,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 13.sp,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white60 : Colors.black45,
        ),
        suffixIcon: isPassword && onToggleVisibility != null
            ? IconButton(
                icon: Icon(
                  passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: readOnly
            ? (isDark ? Colors.white10 : Colors.black12.withValues(alpha: 0.4))
            : (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.w),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.w),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.w),
          borderSide: const BorderSide(color: GoalioColors.greenAccent),
        ),
      ),
    );
  }

  Widget _buildSocialHint(bool isDark, String text) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: GoalioColors.blueAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(
          color: GoalioColors.blueAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: GoalioColors.blueAccent, size: 20.w),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 12.5.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
