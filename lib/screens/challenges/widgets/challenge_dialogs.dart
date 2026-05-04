import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/size_config.dart';
import '../../../core/utils/messages.dart';
import '../../../l10n/app_localizations.dart';
import '../challenge_providers.dart';

void showCreateLeagueDialog(BuildContext context, WidgetRef ref) {
  final TextEditingController controller = TextEditingController();
  String? generatedCode;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final isSuccess = generatedCode != null;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.w),
            ),
            title: Text(
              isSuccess
                  ? AppLocalizations.of(context)!.leagueCreated
                  : AppLocalizations.of(context)!.createLeague,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isSuccess)
                  TextField(
                    controller: controller,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.enterLeagueName,
                      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.w),
                        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.w),
                        borderSide: const BorderSide(color: GoalioColors.greenAccent),
                      ),
                    ),
                    autofocus: true,
                  )
                else ...[
                  Text(
                    AppLocalizations.of(context)!.leagueCreatedSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 10.sp),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12.w),
                      border: Border.all(color: GoalioColors.greenAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          generatedCode!,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w900,
                            color: GoalioColors.greenAccent,
                            letterSpacing: 4,
                          ),
                        ),
                        SizedBox(width: 15.w),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: generatedCode!));
                            GoalioMessages.showInfo(context, AppLocalizations.of(context)!.codeCopied);
                          },
                          icon: Icon(Icons.copy_rounded, color: GoalioColors.greenAccent, size: 20.w),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (!isSuccess) ...[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (controller.text.isNotEmpty) {
                      final code = await ref.read(groupsProvider.notifier).addCustomLeague(controller.text);
                      if (code != null) {
                        setState(() {
                          generatedCode = code;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GoalioColors.greenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
                  ),
                  child: Text(AppLocalizations.of(context)!.create),
                ),
              ] else
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GoalioColors.greenAccent,
                      foregroundColor: Colors.black,
                      minimumSize: Size(double.infinity, 40.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
                    ),
                    child: Text(AppLocalizations.of(context)!.done),
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}

void showJoinLeagueDialog(BuildContext context, WidgetRef ref) {
  final TextEditingController controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.w)),
        title: Text(
          AppLocalizations.of(context)!.joinLeague,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.joinLeagueSubtitle,
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 10.sp),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.leagueCodeHint,
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.w),
                  borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.w),
                  borderSide: const BorderSide(color: GoalioColors.greenAccent),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final success = await ref.read(groupsProvider.notifier).joinLeagueByCode(controller.text);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  GoalioMessages.showSuccess(
                    context,
                    AppLocalizations.of(context)!.joinedLeagueSuccess(controller.text),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GoalioColors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
            ),
            child: Text(AppLocalizations.of(context)!.join),
          ),
        ],
      );
    },
  );
}
