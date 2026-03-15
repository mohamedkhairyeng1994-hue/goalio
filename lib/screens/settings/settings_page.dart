import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/theme_manager.dart';
import '../../core/constants/constants.dart';
import '../../screens/favorites/favorite_teams_page.dart';
import '../../screens/favorites/manage_leagues_page.dart';
import '../../screens/settings/privacy_policy_page.dart';
import '../../screens/settings/terms_of_service_page.dart';
import '../../screens/settings/feedback_page.dart';
import '../../core/utils/size_config.dart';
import '../../core/localization/language_manager.dart';
import '../../l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onLogout;
  const SettingsPage({super.key, required this.onLogout});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = "..."; // Will be updated in build or initState

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = "${packageInfo.version}+${packageInfo.buildNumber}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _version = "1.0.0"; // Fallback
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeManager(),
        builder: (context, themeMode, _) {
          final bool isDarkMode = themeMode == ThemeMode.dark;

          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              _buildSectionHeader(
                context,
                AppLocalizations.of(context)!.appearance,
              ),
              _buildSettingTile(
                context,
                icon: Icons.dark_mode,
                title: AppLocalizations.of(context)!.darkMode,
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (v) {
                    ThemeManager().toggleTheme(v);
                  },
                  activeColor: GoalioColors.greenAccent,
                ),
              ),

              ValueListenableBuilder<Locale>(
                valueListenable: LanguageManager(),
                builder: (context, locale, _) {
                  final isArabic = locale.languageCode == 'ar';
                  return _buildSettingTile(
                    context,
                    icon: Icons.language,
                    title: AppLocalizations.of(context)!.language,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArabic
                              ? AppLocalizations.of(context)!.english
                              : AppLocalizations.of(context)!.arabic,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Switch(
                          value: isArabic,
                          onChanged: (v) {
                            LanguageManager().setLanguage(v ? 'ar' : 'en');
                          },
                          activeColor: GoalioColors.greenAccent,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // SizedBox(height: 24.h),
              // _buildSectionHeader(context, "Notifications"),
              // _buildSettingTile(
              //   context,
              //   icon: Icons.notifications_active,
              //   title: "Match Alerts",
              //   trailing: Switch(
              //     value: true,
              //     onChanged: (v) {},
              //     activeColor: GoalioColors.greenAccent,
              //   ),
              // ),
              // _buildSettingTile(
              //   context,
              //   icon: Icons.newspaper,
              //   title: "News Digest",
              //   trailing: Switch(
              //     value: false,
              //     onChanged: (v) {},
              //     activeColor: GoalioColors.greenAccent,
              //   ),
              // ),
              SizedBox(height: 24.h),
              _buildSectionHeader(context, AppLocalizations.of(context)!.about),
              _buildSettingTile(
                context,
                icon: Icons.info_outline,
                title: AppLocalizations.of(context)!.version,
                trailing: Text(
                  _version == "..."
                      ? AppLocalizations.of(context)!.loading
                      : _version,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
              _buildSettingTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: AppLocalizations.of(context)!.privacyPolicy,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
              _buildSettingTile(
                context,
                icon: Icons.description_outlined,
                title: AppLocalizations.of(context)!.termsOfService,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServicePage(),
                    ),
                  );
                },
              ),
              _buildSettingTile(
                context,
                icon: Icons.feedback_outlined,
                title: AppLocalizations.of(context)!.feedbackAndSuggestions,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeedbackPage(),
                    ),
                  );
                },
              ),

              SizedBox(height: 24.h),
              _buildSectionHeader(
                context,
                AppLocalizations.of(context)!.account,
              ),
              _buildSettingTile(
                context,
                icon: Icons.groups_outlined,
                title: AppLocalizations.of(context)!.teamsManager,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoriteTeamsPage(),
                    ),
                  );
                },
              ),
              _buildSettingTile(
                context,
                icon: Icons.emoji_events_outlined,
                title: AppLocalizations.of(context)!.leaguesManager,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageLeaguesPage(),
                    ),
                  );
                },
              ),
              _buildSettingTile(
                context,
                icon: Icons.logout,
                title: AppLocalizations.of(context)!.logout,
                titleColor: Colors.redAccent,
                iconColor: Colors.redAccent,
                onTap: widget.onLogout,
              ),

              SizedBox(
                height: 80.h,
              ), // Space for bottom nav bar because of extendBody: true

              SizedBox(height: 40.h),
              Center(
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.goalio,
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      AppLocalizations.of(context)!.appSlogan,
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 12.h, start: 4.w),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: GoalioColors.greenAccent,
          fontWeight: FontWeight.bold,
          fontSize: 12.sp,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? titleColor,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.w),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4.w,
                    offset: Offset(0.w, 2.h),
                  ),
                ],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? GoalioColors.blueAccent),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing:
            trailing ??
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
            ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.w),
        ),
      ),
    );
  }
}
