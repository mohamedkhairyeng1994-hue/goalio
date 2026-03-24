import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/size_config.dart';
import '../../../l10n/app_localizations.dart';
import '../challenge_models.dart';
import '../challenge_providers.dart';
import 'league_selector.dart';

class ChallengeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Group? selectedGroup;
  final bool isDark;

  const ChallengeAppBar({
    super.key,
    required this.selectedGroup,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isViewingGroup = selectedGroup != null;
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leading:
          isViewingGroup
              ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20.w,
                  color: GoalioColors.greenAccent,
                ),
                onPressed:
                    () => ref
                        .read(selectedGroupProvider.notifier)
                        .selectGroup(null),
              )
              : null,
      title: Padding(
        padding: EdgeInsetsDirectional.only(
          start: isViewingGroup ? 0 : 20.w,
          end: 20.w,
        ),
        child: Text(
          isViewingGroup
              ? (selectedGroup!.name.toUpperCase())
              : AppLocalizations.of(context)!.challengeTitle.toUpperCase(),
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontFamily: 'RobotoCondensed',
            color: GoalioColors.greenAccent,
          ),
        ),
      ),
      actions: [
        if (!isViewingGroup)
          Padding(
            padding: EdgeInsetsDirectional.only(end: 20.w),
            child: ChallengeLeagueSelector(isDark: isDark),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
