import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/utils/time_utils.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../core/constants/constants.dart';
import '../../core/utils/logo_utils.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/size_config.dart';
import '../../core/utils/number_utils.dart';
import '../../core/utils/name_translator.dart';
import '../../screens/fixtures/match_detail_page.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/messages.dart';
import '../../core/widgets/native_ad_widget.dart';

enum FixtureSortMode { favorites, alphabetical }

class FixturesPage extends StatefulWidget {
  const FixturesPage({super.key});

  @override
  State<FixturesPage> createState() => FixturesPageState();
}

class FixturesPageState extends State<FixturesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showLiveOnly = false;
  bool _showFavoritesOnly =
      false; // Note: kept as variable for backwards compat if needed, but UI toggle removed.
  FixtureSortMode _sortMode = FixtureSortMode.favorites;
  final ValueNotifier<int> _refreshNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> _todayHasLive = ValueNotifier<bool>(false);
  final TextEditingController _searchController = TextEditingController();

  // Stable keys to access FixtureListState
  final GlobalKey<_FixtureListState> _yesterdayKey =
      GlobalKey<_FixtureListState>();
  final GlobalKey<_FixtureListState> _todayKey = GlobalKey<_FixtureListState>();
  final GlobalKey<_FixtureListState> _tomorrowKey =
      GlobalKey<_FixtureListState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  void refreshMatches() {
    _refreshNotifier.value++;
  }

  void resetState() {
    setState(() {
      _tabController.animateTo(1);
      _searchController.clear();
      _showLiveOnly = false;
      _showFavoritesOnly = false;
      _sortMode = FixtureSortMode.favorites;
    });

    // Reset scroll positions
    _yesterdayKey.currentState?.resetScroll();
    _todayKey.currentState?.resetScroll();
    _tomorrowKey.currentState?.resetScroll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshNotifier.dispose();
    _todayHasLive.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [_buildMainContent(context), _buildHeader(context)],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 80.h),
        _buildTabBar(context),
        _buildSearchField(),
        Expanded(child: _buildTabBarView()),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Container(
        height: 40.h,
        margin: EdgeInsets.all(15.w),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(25.w),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabAlignment: TabAlignment.fill,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.all(4.w),
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [GoalioColors.greenAccent, GoalioColors.blueAccent],
            ),
            borderRadius: BorderRadius.circular(25.w),
            boxShadow: [
              BoxShadow(
                color: GoalioColors.greenAccent.withOpacity(0.3),
                blurRadius: 8.w,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13.sp,
          ),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.yesterday),
            Tab(text: AppLocalizations.of(context)!.today),
            Tab(text: AppLocalizations.of(context)!.tomorrow),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    final now = DateTime.now();
    final today = _formatDate(now);
    final yesterday = _formatDate(now.subtract(const Duration(days: 1)));
    final tomorrow = _formatDate(now.add(const Duration(days: 1)));

    // TabBarView enables smooth swiping between tabs and keeps them in sync with the top bar.
    return TabBarView(
      controller: _tabController,
      children: [
        FixtureList(
          key: _yesterdayKey,
          day: yesterday,
          showLiveOnly: _showLiveOnly,
          showFavoritesOnly: _showFavoritesOnly,
          showAllLeagues: true,
          sortMode: _sortMode,
          refreshNotifier: _refreshNotifier,
          searchQuery: _searchController.text,
        ),
        FixtureList(
          key: _todayKey,
          day: today,
          showLiveOnly: _showLiveOnly,
          showFavoritesOnly: _showFavoritesOnly,
          showAllLeagues: true,
          sortMode: _sortMode,
          refreshNotifier: _refreshNotifier,
          onLiveChanged: (hasLive) => _todayHasLive.value = hasLive,
          searchQuery: _searchController.text,
        ),
        FixtureList(
          key: _tomorrowKey,
          day: tomorrow,
          showFavoritesOnly: _showFavoritesOnly,
          showAllLeagues: true,
          sortMode: _sortMode,
          refreshNotifier: _refreshNotifier,
          searchQuery: _searchController.text,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Widget _buildHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Expanded(child: _buildHeaderTitle()),
              _buildHeaderActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Text(
      AppLocalizations.of(context)!.fixturesTitle,
      style: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        fontFamily: 'RobotoCondensed',
        color: GoalioColors.greenAccent,
      ),
    );
  }

  Widget _buildSearchField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      height: 44.h,
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14.sp,
        ),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchHint,
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 14.sp,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: GoalioColors.greenAccent,
            size: 20.w,
          ),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: isDark ? Colors.white54 : Colors.black54,
                      size: 18.w,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                      });
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLiveFilterButton(),
        SizedBox(width: 4.w),
        IconButton(
          padding: EdgeInsets.all(8.w),
          constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
          icon: Icon(
            Icons.calendar_today_rounded,
            color: GoalioColors.greenAccent,
            size: 20.w,
          ),
          onPressed: () => _selectDate(context),
        ),
        SizedBox(width: 2.w),
        _buildSortMenu(),
      ],
    );
  }

  Widget _buildSortMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<dynamic>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: GoalioColors.greenAccent,
        size: 24.w,
      ),
      constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
      offset: Offset(0, 48.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.w),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 1,
        ),
      ),
      elevation: 8,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value is FixtureSortMode) {
          setState(() {
            _sortMode = value;
          });
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: FixtureSortMode.favorites,
              child: Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color:
                        _sortMode == FixtureSortMode.favorites
                            ? Colors.amber
                            : (isDark ? Colors.white38 : Colors.black26),
                    size: 22.w,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    AppLocalizations.of(context)!.sortByFavorite,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight:
                          _sortMode == FixtureSortMode.favorites
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (_sortMode == FixtureSortMode.favorites) ...[
                    const Spacer(),
                    Icon(
                      Icons.check_circle_rounded,
                      color: GoalioColors.greenAccent,
                      size: 16.w,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuItem(
              value: FixtureSortMode.alphabetical,
              child: Row(
                children: [
                  Icon(
                    Icons.sort_by_alpha_rounded,
                    color:
                        _sortMode == FixtureSortMode.alphabetical
                            ? GoalioColors.blueAccent
                            : (isDark ? Colors.white38 : Colors.black26),
                    size: 22.w,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    AppLocalizations.of(context)!.sortAZ,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight:
                          _sortMode == FixtureSortMode.alphabetical
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (_sortMode == FixtureSortMode.alphabetical) ...[
                    const Spacer(),
                    Icon(
                      Icons.check_circle_rounded,
                      color: GoalioColors.greenAccent,
                      size: 16.w,
                    ),
                  ],
                ],
              ),
            ),
          ],
    );
  }

  Widget _buildLiveFilterButton() {
    final enabled = _tabController.index <= 1;
    final activeColor =
        _showLiveOnly ? Colors.redAccent : GoalioColors.greenAccent;
    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: IconButton(
        padding: EdgeInsets.all(8.w),
        constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
        icon: Icon(
          _showLiveOnly ? Icons.live_tv_rounded : Icons.live_tv_outlined,
          color:
              enabled
                  ? activeColor
                  : Theme.of(context).disabledColor.withOpacity(0.6),
          size: 20.w,
        ),
        onPressed:
            enabled
                ? () => setState(() => _showLiveOnly = !_showLiveOnly)
                : null,
      ),
    );
  }

  // Removed _buildFavoritesFilterButton as requested to hide the heart icon.

  Widget _buildModalLiveFilterButton(StateSetter setModalState) {
    final activeColor =
        _showLiveOnly ? Colors.redAccent : GoalioColors.greenAccent;
    return IconButton(
      padding: EdgeInsets.all(4.w),
      constraints: BoxConstraints(minWidth: 28.w, minHeight: 28.h),
      icon: Icon(
        _showLiveOnly ? Icons.live_tv_rounded : Icons.live_tv_outlined,
        color: activeColor,
        size: 20.w,
      ),
      onPressed: () {
        setModalState(() {
          _showLiveOnly = !_showLiveOnly;
        });
        setState(() {}); // Sync with main state
      },
    );
  }

  // Removed _buildModalFavoritesFilterButton

  Widget _buildModalCalendarButton(
    BuildContext modalContext,
    DateTime currentDate,
  ) {
    return IconButton(
      padding: EdgeInsets.all(4.w),
      constraints: BoxConstraints(minWidth: 28.w, minHeight: 28.h),
      icon: Icon(
        Icons.calendar_today_rounded,
        color: GoalioColors.greenAccent,
        size: 20.w,
      ),
      onPressed:
          () => _selectDate(
            modalContext,
            shouldPop: true,
            initialDate: currentDate,
          ),
    );
  }

  Widget _buildModalSortMenu(
    StateSetter setModalState,
    BuildContext modalContext,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<dynamic>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: GoalioColors.greenAccent,
        size: 24.w,
      ),
      constraints: BoxConstraints(minWidth: 28.w, minHeight: 28.h),
      offset: Offset(0, 48.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.w),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 1,
        ),
      ),
      elevation: 8,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value is FixtureSortMode) {
          setModalState(() {
            _sortMode = value;
          });
          setState(() {}); // Sync with main state
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: FixtureSortMode.favorites,
              child: Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color:
                        _sortMode == FixtureSortMode.favorites
                            ? Colors.amber
                            : (isDark ? Colors.white38 : Colors.black26),
                    size: 22.w,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    AppLocalizations.of(context)!.sortByFavorite,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight:
                          _sortMode == FixtureSortMode.favorites
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (_sortMode == FixtureSortMode.favorites) ...[
                    const Spacer(),
                    Icon(
                      Icons.check_circle_rounded,
                      color: GoalioColors.greenAccent,
                      size: 16.w,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuItem(
              value: FixtureSortMode.alphabetical,
              child: Row(
                children: [
                  Icon(
                    Icons.sort_by_alpha_rounded,
                    color:
                        _sortMode == FixtureSortMode.alphabetical
                            ? GoalioColors.blueAccent
                            : (isDark ? Colors.white38 : Colors.black26),
                    size: 22.w,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    AppLocalizations.of(context)!.sortAZ,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight:
                          _sortMode == FixtureSortMode.alphabetical
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (_sortMode == FixtureSortMode.alphabetical) ...[
                    const Spacer(),
                    Icon(
                      Icons.check_circle_rounded,
                      color: GoalioColors.greenAccent,
                      size: 16.w,
                    ),
                  ],
                ],
              ),
            ),
          ],
    );
  }

  Future<void> _selectDate(
    BuildContext context, {
    bool shouldPop = false,
    DateTime? initialDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: GoalioColors.greenAccent,
              primary: GoalioColors.greenAccent,
              onPrimary: Colors.black,
              surface: Theme.of(context).cardColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (shouldPop) {
        Navigator.pop(context); // Close the modal context
      }
      final dateStr =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      _showDateMatches(dateStr);
    }
  }

  void _showDateMatches(String dateStr) {
    DateTime currentDate = DateTime.parse(dateStr);
    String modalSearchQuery = '';
    final TextEditingController modalSearchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (_, controller) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20.w),
                    ),
                  ),
                  child: StatefulBuilder(
                    builder: (modalContext, setModalState) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final currentDateStr = _formatDate(currentDate);
                      final todayStr = _formatDate(DateTime.now());
                      final yesterdayStr = _formatDate(
                        DateTime.now().subtract(const Duration(days: 1)),
                      );
                      final isLiveAvailable =
                          currentDateStr == todayStr ||
                          currentDateStr == yesterdayStr;

                      return Column(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 12.h),
                            height: 4.h,
                            width: 40.w,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(2.w),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 20.w),
                                        child: Text(
                                          AppLocalizations.of(
                                            modalContext,
                                          )!.matches,
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            color: GoalioColors.greenAccent,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(
                                              minWidth: 28.w,
                                              minHeight: 28.h,
                                            ),
                                            icon: Icon(
                                              Icons.chevron_left_rounded,
                                              color: GoalioColors.greenAccent,
                                              size: 22.w,
                                            ),
                                            onPressed: () {
                                              setModalState(() {
                                                currentDate = currentDate
                                                    .subtract(
                                                      const Duration(days: 1),
                                                    );
                                                modalSearchQuery = '';
                                                modalSearchController.clear();
                                              });
                                            },
                                          ),
                                          Text(
                                            _formatDate(currentDate),
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color:
                                                  isDark
                                                      ? Colors.white54
                                                      : Colors.black54,
                                            ),
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(
                                              minWidth: 28.w,
                                              minHeight: 28.h,
                                            ),
                                            icon: Icon(
                                              Icons.chevron_right_rounded,
                                              color: GoalioColors.greenAccent,
                                              size: 22.w,
                                            ),
                                            onPressed: () {
                                              setModalState(() {
                                                currentDate = currentDate.add(
                                                  const Duration(days: 1),
                                                );
                                                modalSearchQuery = '';
                                                modalSearchController.clear();
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isLiveAvailable)
                                      _buildModalLiveFilterButton(
                                        setModalState,
                                      ),
                                    _buildModalCalendarButton(
                                      modalContext,
                                      currentDate,
                                    ),
                                    _buildModalSortMenu(
                                      setModalState,
                                      modalContext,
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.all(4.w),
                                      constraints: BoxConstraints(
                                        minWidth: 28.w,
                                        minHeight: 28.h,
                                      ),
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color:
                                            isDark
                                                ? Colors.white70
                                                : Colors.black45,
                                        size: 24.w,
                                      ),
                                      onPressed:
                                          () => Navigator.pop(modalContext),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.white12
                                      : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12.w),
                            ),
                            child: TextField(
                              controller: modalSearchController,
                              onChanged: (value) {
                                setModalState(() {
                                  modalSearchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                icon: Icon(
                                  Icons.search,
                                  size: 20.w,
                                  color: GoalioColors.greenAccent,
                                ),
                                border: InputBorder.none,
                                hintText:
                                    AppLocalizations.of(
                                      modalContext,
                                    )!.searchHint,
                                hintStyle: TextStyle(
                                  color:
                                      isDark ? Colors.white54 : Colors.black45,
                                  fontSize: 14.sp,
                                ),
                                suffixIcon:
                                    modalSearchQuery.isNotEmpty
                                        ? GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              modalSearchQuery = '';
                                              modalSearchController.clear();
                                            });
                                          },
                                          child: Icon(
                                            Icons.clear,
                                            size: 18.w,
                                            color:
                                                isDark
                                                    ? Colors.white70
                                                    : Colors.black45,
                                          ),
                                        )
                                        : null,
                              ),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          Expanded(
                            child: FixtureList(
                              day: _formatDate(currentDate),
                              showLiveOnly:
                                  isLiveAvailable ? _showLiveOnly : false,
                              showFavoritesOnly: _showFavoritesOnly,
                              showAllLeagues: true,
                              sortMode: _sortMode,
                              refreshNotifier:
                                  isLiveAvailable ? _refreshNotifier : null,
                              searchQuery: modalSearchQuery,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
          ),
    );
  }
}

class FixtureList extends StatefulWidget {
  final String day;
  final bool showLiveOnly;
  final bool showFavoritesOnly;
  final bool showAllLeagues;
  final String searchQuery;
  final ValueListenable<int>? refreshNotifier;
  final ValueChanged<bool>? onLiveChanged;
  final FixtureSortMode sortMode;

  const FixtureList({
    super.key,
    required this.day,
    this.showLiveOnly = false,
    this.showFavoritesOnly = false,
    this.showAllLeagues = false,
    this.searchQuery = '',
    this.refreshNotifier,
    this.onLiveChanged,
    this.sortMode = FixtureSortMode.favorites,
  });

  @override
  State<FixtureList> createState() => _FixtureListState();
}

class _FixtureListState extends State<FixtureList>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _competitions = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _expandedLeagues = {};
  bool _isFavoritesExpanded = true;

  final ScrollController _scrollController = ScrollController();

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _matchKey(Map<String, dynamic> match) {
    final id = match['id']?.toString();
    if (id != null && id.isNotEmpty) return 'id:$id';

    final matchUrl = match['match_url']?.toString();
    if (matchUrl != null && matchUrl.isNotEmpty) return 'url:$matchUrl';

    final date = match['match_date']?.toString() ?? widget.day;
    final home = match['home_team']?.toString() ?? '';
    final away = match['away_team']?.toString() ?? '';
    return '$date|$home|$away';
  }

  List<Map<String, dynamic>> _mergeIncomingMatches(List<dynamic> data) {
    final previousByKey = <String, Map<String, dynamic>>{};

    for (final competition in _competitions) {
      final matches = List<Map<String, dynamic>>.from(
        competition['matches'] as List? ?? const [],
      );
      for (final match in matches) {
        previousByKey[_matchKey(match)] = match;
      }
    }

    return data.map<Map<String, dynamic>>((item) {
      final match = Map<String, dynamic>.from(item as Map);
      final previous = previousByKey[_matchKey(match)];

      if (previous != null) {
        final previousHomeRed = _asInt(previous['home_red_cards']);
        final previousAwayRed = _asInt(previous['away_red_cards']);
        final incomingHomeRed = _asInt(match['home_red_cards']);
        final incomingAwayRed = _asInt(match['away_red_cards']);

        // Keep previous data if incoming count is lower (data lag prevention)
        // but preserve the original object (which may contain names)
        if (incomingHomeRed < previousHomeRed) {
          match['home_red_cards'] = previous['home_red_cards'];
        }
        if (incomingAwayRed < previousAwayRed) {
          match['away_red_cards'] = previous['away_red_cards'];
        }
      }

      return match;
    }).toList();
  }

  Map<String, Map<String, dynamic>> _groupMatchesByCompetition(
    List<Map<String, dynamic>> matches,
  ) {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final match in matches) {
      final compName = match['competition'] ?? 'Unknown';
      grouped.putIfAbsent(
        compName,
        () => {
          'name': compName,
          'image': match['competition_image'],
          'league_id': match['league_id'],
          'is_favorite_league': match['is_favorite_league'] ?? false,
          'matches': <Map<String, dynamic>>[],
        },
      );
      (grouped[compName]!['matches'] as List<Map<String, dynamic>>).add(match);
    }

    return grouped;
  }

  void resetScroll() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
    widget.refreshNotifier?.addListener(_handleRefresh);
  }

  @override
  void didUpdateWidget(FixtureList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshNotifier != widget.refreshNotifier) {
      oldWidget.refreshNotifier?.removeListener(_handleRefresh);
      widget.refreshNotifier?.addListener(_handleRefresh);
    }
    if (oldWidget.day != widget.day) {
      _loadMatches();
    }
    // Note: showFavoritesOnly / showLiveOnly / sortMode are client-side filters
    // handled in _getFilteredCompetitions — no server reload needed.
  }

  void _handleRefresh() {
    // Show DB data immediately, then scrape in background
    _loadMatches(forceScrape: false);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_handleRefresh);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches({bool forceScrape = false}) async {
    if (!mounted) return;
    // Capture widget values NOW before any await
    final date = widget.day;

    setState(() {
      if (_competitions.isEmpty) _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (forceScrape) {
        await ApiService.scrapeMatches(date: date);
      }

      final List<dynamic> data = await ApiService.getMatches(date: date);
      final mergedData = _mergeIncomingMatches(data);

      final bool hasLive = mergedData.any(
        (m) => isLiveMatch(m['status'] as String?),
      );
      widget.onLiveChanged?.call(hasLive);

      final grouped = _groupMatchesByCompetition(mergedData);

      if (mounted) {
        setState(() {
          if (mergedData.isNotEmpty || _competitions.isEmpty) {
            _competitions = grouped.values.toList();
          }
          _isLoading = false;
          for (var comp in _competitions)
            _expandedLeagues.add(comp['name'].toString());
        });
      }

      if (!forceScrape) {
        _scrapeInBackground();
      }
    } catch (e) {
      debugPrint("Error loading matches for $date: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_competitions.isEmpty)
            _errorMessage = AppLocalizations.of(context)!.couldNotLoadMatches;
        });
      }
      if (!forceScrape) _scrapeInBackground();
    }
  }

  void _scrapeInBackground() async {
    final bool startsEmpty = _competitions.isEmpty;
    if (startsEmpty && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await ApiService.scrapeMatches(date: widget.day);

      final List<dynamic> data = await ApiService.getMatches(date: widget.day);

      if (!mounted) return;

      if (data.isEmpty) {
        if (startsEmpty) {
          setState(() {
            _isLoading = false;
            _competitions = [];
          });
        }
        return;
      }

      final mergedData = _mergeIncomingMatches(data);
      final bool hasLive = mergedData.any(
        (m) => isLiveMatch(m['status'] as String?),
      );
      widget.onLiveChanged?.call(hasLive);

      final grouped = _groupMatchesByCompetition(mergedData);

      if (mounted) {
        setState(() {
          _competitions = grouped.values.toList();
          _isLoading = false;
          for (var comp in _competitions)
            _expandedLeagues.add(comp['name'].toString());
        });
      }
    } catch (_) {
      if (mounted && startsEmpty) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Always wrap in RefreshIndicator so pull-to-refresh works in every state
    return RefreshIndicator(
      color: GoalioColors.greenAccent,
      onRefresh: () => _loadMatches(forceScrape: true),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: GoalioColors.greenAccent),
      );
    }

    if (_errorMessage != null) {
      // Use CustomScrollView so pull-to-refresh gesture still works on error
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      );
    }

    final rawFilteredCompetitions = _getFilteredCompetitions();

    // Extract favorite matches from filtered competitions and remove them from the original list
    final List<Map<String, dynamic>> favoriteMatches = [];
    final List<Map<String, dynamic>> filteredCompetitions = [];

    for (var comp in rawFilteredCompetitions) {
      final matches = List<Map<String, dynamic>>.from(comp['matches'] as List);
      final nonFavoriteMatches =
          matches.where((m) {
            if (m['is_favorite_team'] == true) {
              favoriteMatches.add(m);
              return false; // Remove from original league group
            }
            return true;
          }).toList();

      if (nonFavoriteMatches.isNotEmpty) {
        filteredCompetitions.add({...comp, 'matches': nonFavoriteMatches});
      }
    }

    final hasFavorites = favoriteMatches.isNotEmpty;

    if (favoriteMatches.isEmpty && filteredCompetitions.isEmpty) {
      // Use CustomScrollView so pull-to-refresh gesture still works when empty
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [SliverFillRemaining(child: _buildEmptyState())],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        12.w,
        12.h,
        12.w,
        MediaQuery.of(context).padding.bottom + 84.h,
      ),
      itemCount:
          (hasFavorites ? 1 : 0) +
          filteredCompetitions.length +
          (filteredCompetitions.length ~/ 5),
      itemBuilder: (context, index) {
        int currentIndex = index;
        if (hasFavorites) {
          if (index == 0) {
            return _buildFavoriteMatchesPinnedSection(favoriteMatches);
          }
          currentIndex = index - 1;
        }

        // Show Native Ad after every 5 competitions
        if (currentIndex > 0 && currentIndex % 6 == 5) {
          return const GoalioNativeAdWidget();
        }

        // Calculate correct competition item index
        final adOffset = ((currentIndex + 1) / 6).floor();
        final actualCompIndex = currentIndex - adOffset;

        if (actualCompIndex < 0 ||
            actualCompIndex >= filteredCompetitions.length) {
          return const SizedBox.shrink();
        }

        return _buildCompetitionGroup(filteredCompetitions[actualCompIndex]);
      },
    );
  }

  Widget _buildFavoriteMatchesPinnedSection(
    List<Map<String, dynamic>> matches,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isFavoritesExpanded = !_isFavoritesExpanded;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            margin: EdgeInsets.only(bottom: 8.h),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withOpacity(isDark ? 0.2 : 0.1),
                  GoalioColors.greenAccent.withOpacity(isDark ? 0.2 : 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12.w),
              border: Border.all(
                color:
                    isDark
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.amber.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber, size: 18.w),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.favoriteMatches.toUpperCase(),
                    style: TextStyle(
                      color: isDark ? Colors.amber[300] : Colors.orange[800],
                      fontWeight: FontWeight.w900,
                      fontSize: 12.sp,
                      letterSpacing: 1.1,
                      fontFamily: 'RobotoCondensed',
                    ),
                  ),
                ),
                Icon(
                  _isFavoritesExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: isDark ? Colors.amber[300] : Colors.orange[800],
                  size: 20.w,
                ),
              ],
            ),
          ),
        ),
        if (_isFavoritesExpanded) ...[
          ...matches
              .map(
                (m) =>
                    MatchCard(match: m, onToggleFavorite: _toggleFavoriteTeam),
              )
              .toList(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Divider(
              color: isDark ? Colors.white10 : Colors.black12,
              thickness: 1,
              indent: 20.w,
              endIndent: 20.w,
            ),
          ),
        ],
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredCompetitions() {
    final List<Map<String, dynamic>> filtered =
        _competitions
            .map((comp) {
              var matches = List<Map<String, dynamic>>.from(
                comp['matches'] as List,
              );

              if (widget.showLiveOnly) {
                matches =
                    matches.where((m) => isLiveMatch(m['status'])).toList();
              }

              // Client-side favorites filter — uses is_favorite_team and is_favorite_league flags stamped by backend
              if (widget.showFavoritesOnly) {
                matches =
                    matches
                        .where(
                          (m) =>
                              m['is_favorite_team'] == true ||
                              m['is_favorite_league'] == true,
                        )
                        .toList();
              }

              if (widget.searchQuery.isNotEmpty) {
                final query = widget.searchQuery.toLowerCase();
                matches =
                    matches.where((m) {
                      final home =
                          (m['home_team']?.toString() ?? '').toLowerCase();
                      final away =
                          (m['away_team']?.toString() ?? '').toLowerCase();
                      return home.contains(query) || away.contains(query);
                    }).toList();
              }

              if (matches.isEmpty) return null;
              return {...comp, 'matches': matches};
            })
            .whereType<Map<String, dynamic>>()
            .toList();

    // "Favorites" mode: server already returned with favor leagues/teams first, keep that order.
    // "Alphabetical" mode: re-sort purely A-Z on the client.
    if (widget.sortMode == FixtureSortMode.alphabetical) {
      filtered.sort((a, b) {
        final aName = (a['name']?.toString() ?? '').toLowerCase();
        final bName = (b['name']?.toString() ?? '').toLowerCase();
        return aName.compareTo(bName);
      });
    }
    // FixtureSortMode.favorites → keep server order (no sort needed)

    return filtered;
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String title;
    String subtitle;
    IconData icon;
    Color iconColor;

    if (widget.showLiveOnly) {
      title = AppLocalizations.of(context)!.noLiveMatches;
      subtitle = AppLocalizations.of(context)!.noLiveMatchesSubtitle;
      icon = Icons.sensors_off_rounded;
      iconColor = Colors.redAccent;
    } else if (widget.showFavoritesOnly) {
      title = AppLocalizations.of(context)!.noFavoriteMatches;
      subtitle = AppLocalizations.of(context)!.noFavoriteMatchesSubtitle;
      icon = Icons.favorite_border_rounded;
      iconColor = Colors.amber;
    } else if (widget.showAllLeagues) {
      title =
          AppLocalizations.of(
            context,
          )!.noMatchesToday; // Reusing home string or scheduled one? Let's use scheduled
      title = AppLocalizations.of(context)!.noMatchesToday;
      subtitle = AppLocalizations.of(context)!.noMatchesScheduled(widget.day);
      icon = Icons.calendar_today_outlined;
      iconColor = GoalioColors.greenAccent;
    } else {
      title =
          AppLocalizations.of(
            context,
          )!.noMatchesFound; // Need to add this or reuse
      title = AppLocalizations.of(context)!.noMatchesToday;
      subtitle = AppLocalizations.of(context)!.noMatchesFoundSubtitle;
      icon = Icons.sports_soccer_rounded;
      iconColor = GoalioColors.blueAccent;
    }

    return Center(
      child: Container(
        padding: EdgeInsets.all(30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(icon, size: 60.w, color: iconColor.withOpacity(0.8)),
            ),
            SizedBox(height: 24.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionGroup(Map<String, dynamic> comp) {
    final leagueName = comp['name'].toString();
    final isExpanded = _expandedLeagues.contains(leagueName);

    return Column(
      children: [
        _buildCompetitionHeader(comp, isExpanded, () {
          setState(() {
            if (isExpanded) {
              _expandedLeagues.remove(leagueName);
            } else {
              _expandedLeagues.add(leagueName);
            }
          });
        }),
        if (isExpanded)
          ...() {
            final List<Widget> listItems = [];
            final matches = comp['matches'] as List;
            for (int i = 0; i < matches.length; i++) {
              listItems.add(
                MatchCard(
                  match: matches[i],
                  onToggleFavorite: _toggleFavoriteTeam,
                ),
              );
            }
            return listItems;
          }(),
        SizedBox(height: 16.h),
      ],
    );
  }

  void _updateLeagueInState(dynamic leagueId, String name, bool newValue) {
    for (var c in _competitions) {
      if (c['league_id'] == leagueId || c['name'] == name) {
        c['is_favorite_league'] = newValue;
        if (c['matches'] != null) {
          for (var m in (c['matches'] as List)) {
            m['is_favorite_league'] = newValue;
          }
        }
      }
    }
  }

  Widget _buildCompetitionHeader(
    Map<String, dynamic> comp,
    bool isExpanded,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isFav = comp['is_favorite_league'] == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDark
                    ? [
                      GoalioColors.greenAccent.withOpacity(0.15),
                      GoalioColors.blueAccent.withOpacity(0.15),
                    ]
                    : [
                      GoalioColors.greenAccent.withOpacity(0.08),
                      GoalioColors.blueAccent.withOpacity(0.08),
                    ],
          ),
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            buildTeamLogo(comp['image'], size: 20.w),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                comp['name'],
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _toggleFavoriteLeague(comp),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Icon(
                  isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                  color:
                      isFav
                          ? Colors.amber
                          : (isDark ? Colors.white38 : Colors.black26),
                  size: 22.w,
                ),
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 20.w,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavoriteLeague(Map<String, dynamic> comp) async {
    final leagueId = comp['league_id'];
    final name = comp['name'];
    final image = comp['image'];

    // Optimistic UI update
    setState(() {
      final newValue = !(comp['is_favorite_league'] ?? false);
      _updateLeagueInState(leagueId, name, newValue);
      // Also update the local reference used in the current build context
      comp['is_favorite_league'] = newValue;
      if (comp['matches'] != null) {
        for (var match in comp['matches']) {
          match['is_favorite_league'] = newValue;
        }
      }
    });

    final result = await ApiService.toggleFavoriteLeague(
      leagueId: leagueId,
      name: name,
      image: image,
    );

    if (result.containsKey('error')) {
      // Revert on error
      setState(() {
        final newValue = !(comp['is_favorite_league'] ?? false);
        _updateLeagueInState(leagueId, name, newValue);
        comp['is_favorite_league'] = newValue;
        if (comp['matches'] != null) {
          for (var match in comp['matches']) {
            match['is_favorite_league'] = newValue;
          }
        }
      });
      if (mounted) {
        GoalioMessages.showError(
          context,
          result['error'] ?? 'Error updating favorite',
        );
      }
    } else {
      if (mounted) {
        final isFavorite = comp['is_favorite_league'] == true;
        GoalioMessages.showSuccess(
          context,
          isFavorite
              ? AppLocalizations.of(context)!.addedToFavorites
              : AppLocalizations.of(context)!.removedFromFavorites,
        );
      }
    }
  }

  Future<void> _toggleFavoriteTeam(
    Map<String, dynamic> match,
    bool isHome,
  ) async {
    final teamId = isHome ? match['home_team_id'] : match['away_team_id'];
    final teamName = isHome ? match['home_team'] : match['away_team'];
    final teamLogo =
        isHome ? match['home_team_image'] : match['away_team_image'];
    final fieldName = isHome ? 'home_is_favorite' : 'away_is_favorite';

    if (teamId == null) {
      if (mounted)
        GoalioMessages.showError(context, "Cannot favorite team: missing ID");
      return;
    }

    // Optimistic UI update
    setState(() {
      match[fieldName] = !(match[fieldName] == true);
    });

    final result = await ApiService.toggleFavoriteTeam(
      teamId: teamId,
      name: teamName,
      logo: teamLogo,
      leagueName: match['competition'],
    );

    if (result.containsKey('error')) {
      // Revert on error
      setState(() {
        match[fieldName] = !(match[fieldName] == true);
      });
      if (mounted) {
        GoalioMessages.showError(
          context,
          result['error'] ?? 'Error updating favorite',
        );
      }
    } else {
      if (mounted) {
        final isFavorite = match[fieldName] == true;
        GoalioMessages.showSuccess(
          context,
          isFavorite
              ? AppLocalizations.of(context)!.addedToFavorites
              : AppLocalizations.of(context)!.removedFromFavorites,
        );
      }
    }
  }
}

// isLiveMatch is now moved to time_utils.dart as isLiveStatus,
// keeping this shim to avoid breaking other files if any, but will use isLiveStatus locally.
bool isLiveMatch(String? status) => isLiveStatus(status);

class MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final Function(Map<String, dynamic>, bool)? onToggleFavorite;
  const MatchCard({super.key, required this.match, this.onToggleFavorite});

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final status = match['status'];
    final bool isLive = isLiveMatch(status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeRedCards = match['home_red_cards'];
    final awayRedCards = match['away_red_cards'];

    return InkWell(
      borderRadius: BorderRadius.circular(12.w),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MatchDetailPage(match: match)),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.w),
          boxShadow:
              isDark
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8.w,
                      offset: Offset(0, 2.h),
                    ),
                  ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((match['home_is_favorite'] == true ||
                    match['away_is_favorite'] == true) &&
                match['competition'] != null &&
                match['competition'].toString().isNotEmpty) ...[
              Text(
                match['competition']
                    .toString()
                    .toArabicName(context)
                    .toUpperCase(),
                style: TextStyle(
                  fontSize: 7.sp,
                  color: GoalioColors.greenAccent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 10.h),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTeamInfo(
                  context,
                  match['home_team'],
                  match['home_team_image'],
                  true,
                  isDark,
                  match['home_is_favorite'] == true,
                  homeRedCards,
                ),
                _buildMatchStatus(context, status, isLive, isDark),
                _buildTeamInfo(
                  context,
                  match['away_team'],
                  match['away_team_image'],
                  false,
                  isDark,
                  match['away_is_favorite'] == true,
                  awayRedCards,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamInfo(
    BuildContext context,
    String? name,
    String? logo,
    bool isHome,
    bool isDark,
    bool isFavorite,
    dynamic redCards,
  ) {
    return Expanded(
      flex: 4,
      child: Row(
        mainAxisAlignment:
            isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Home Favorite Star (Pinned Left)
          if (isHome) ...[
            GestureDetector(
              onTap: () => onToggleFavorite?.call(match, true),
              child: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color:
                    isFavorite
                        ? Colors.amber
                        : (isDark ? Colors.white24 : Colors.black12),
                size: 14.w,
              ),
            ),
            SizedBox(width: 8.w),
          ],

          // Away Logo
          if (!isHome) ...[buildTeamLogo(logo), SizedBox(width: 8.w)],

          // Team Name & Red Cards
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isHome ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (name ?? '-').toString().toArabicName(context),
                  textAlign: isHome ? TextAlign.end : TextAlign.start,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (redCards != null && (redCards is! int || redCards > 0)) ...[
                  SizedBox(height: 3.h),
                  Align(
                    alignment:
                        isHome ? Alignment.centerRight : Alignment.centerLeft,
                    child: _buildRedCardBadge(context, redCards, isHome),
                  ),
                ],
              ],
            ),
          ),

          // Home Logo
          if (isHome) ...[SizedBox(width: 8.w), buildTeamLogo(logo)],

          // Away Favorite Star (Pinned Right)
          if (!isHome) ...[
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => onToggleFavorite?.call(match, false),
              child: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color:
                    isFavorite
                        ? Colors.amber
                        : (isDark ? Colors.white24 : Colors.black12),
                size: 14.w,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRedCardBadge(
    BuildContext context,
    dynamic redCardsData,
    bool isHome,
  ) {
    if (redCardsData == null) return const SizedBox.shrink();

    List<String> playerNames = [];
    int count = 0;

    if (redCardsData is int) {
      count = redCardsData;
    } else if (redCardsData is List) {
      count = redCardsData.length;
      playerNames =
          redCardsData
              .map((e) {
                if (e is Map) {
                  return e['player']?.toString() ?? e['name']?.toString() ?? '';
                }
                return e.toString();
              })
              .where((e) => e.isNotEmpty)
              .toList();
    } else if (redCardsData is String) {
      if (redCardsData.startsWith('[') || redCardsData.startsWith('{')) {
        try {
          final decoded = json.decode(redCardsData);
          return _buildRedCardBadge(context, decoded, isHome);
        } catch (e) {
          // Fallback to plain string
        }
      }
      final parsed = int.tryParse(redCardsData);
      if (parsed != null) {
        count = parsed;
      } else if (redCardsData.isNotEmpty) {
        count = 1;
        playerNames = [redCardsData];
      }
    }

    if (count == 0) return const SizedBox.shrink();

    // If we have names, we show them as rows like in match detail page
    if (playerNames.isNotEmpty) {
      return Column(
        crossAxisAlignment:
            isHome ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children:
            playerNames.map((name) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 1.h),
                child: Row(
                  mainAxisAlignment:
                      isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children:
                      isHome
                          ? [
                            Flexible(
                              child: Text(
                                name.toArabicName(context),
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 7.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            _buildSingleRedCardIcon(),
                          ]
                          : [
                            _buildSingleRedCardIcon(),
                            SizedBox(width: 3.w),
                            Flexible(
                              child: Text(
                                name.toArabicName(context),
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 7.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                ),
              );
            }).toList(),
      );
    }

    // Fallback: if no player names but we have a count, show that many red card icons
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: List.generate(count, (index) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 1.w),
        child: _buildSingleRedCardIcon(),
      )),
    );
  }

  Widget _buildSingleRedCardIcon() {
    return Container(
      width: 5.w,
      height: 7.h,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(1.w),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 0.4,
        ),
      ),
    );
  }

  Widget _buildMatchStatus(
    BuildContext context,
    dynamic status,
    bool isLive,
    bool isDark,
  ) {
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          if (isLive || isFinishedStatus(status.toString()))
            _buildScoreBoard(
              context,
              isDark,
              isFinishedStatus(status.toString()),
            )
          else
            _buildTimeOrSpecialStatus(context, status, isDark),
          if (isLive)
            Text(
              ((status.toString().toUpperCase() == 'LIVE' ||
                          status.toString().toUpperCase() == 'HT') &&
                      match['time'] != null &&
                      match['time'].toString().isNotEmpty &&
                      (match['time'].toString().contains("'") ||
                          RegExp(r'^\d+$').hasMatch(match['time'].toString())))
                  ? (match['time'].toString().contains("'")
                      ? match['time']
                      : "${match['time']}'")
                  : localizeMatchStatus(context, status),
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard(BuildContext context, bool isDark, bool isFinished) {
    final homeScore = match['home_score'] == 'N/A' ? '0' : match['home_score'];
    final awayScore = match['away_score'] == 'N/A' ? '0' : match['away_score'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              homeScore.toString().toArabicNumbers(context),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color:
                    isFinished
                        ? (isDark ? Colors.white54 : Colors.black45)
                        : Colors.redAccent,
              ),
            ),
            Text(
              " - ",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color:
                    isFinished
                        ? (isDark ? Colors.white54 : Colors.black45)
                        : Colors.redAccent,
              ),
            ),
            Text(
              awayScore.toString().toArabicNumbers(context),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color:
                    isFinished
                        ? (isDark ? Colors.white54 : Colors.black45)
                        : Colors.redAccent,
              ),
            ),
          ],
        ),
        if (match['home_score_pen'] != null && match['home_score_pen'] != 'N/A')
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "(",
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.amber[300] : Colors.orange[700],
                ),
              ),
              Text(
                "${match['home_score_pen']}".toArabicNumbers(context),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.amber[300] : Colors.orange[700],
                ),
              ),
              Text(
                " - ",
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.amber[300] : Colors.orange[700],
                ),
              ),
              Text(
                "${match['away_score_pen']}".toArabicNumbers(context),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.amber[300] : Colors.orange[700],
                ),
              ),
              Text(
                ")",
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.amber[300] : Colors.orange[700],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTimeOrSpecialStatus(
    BuildContext context,
    dynamic status,
    bool isDark,
  ) {
    String text;
    switch (status) {
      case 'CAN':
        text = 'Cancelled';
        break;
      case 'POS':
        text = 'Postponed';
        break;
      case 'SUSP':
        text = 'Suspension';
        break;
      default:
        text = formatMatchTime(match['time']);
    }
    return Text(
      localizeMatchStatus(context, text).toArabicNumbers(context),
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
    );
  }
}
