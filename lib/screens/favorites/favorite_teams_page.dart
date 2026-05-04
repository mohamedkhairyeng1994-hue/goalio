import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/constants/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/messages.dart';
import '../../screens/onboarding/onboarding_page.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/size_config.dart';
import '../../core/utils/logo_utils.dart';

class FavoriteTeamsPage extends StatefulWidget {
  final bool isOnboarding;

  const FavoriteTeamsPage({super.key, this.isOnboarding = false});

  @override
  State<FavoriteTeamsPage> createState() => _FavoriteTeamsPageState();
}

class _FavoriteTeamsPageState extends State<FavoriteTeamsPage> {
  final List<Map<String, dynamic>> _teams = [];
  final Set<String> _selectedTeams = {};
  bool _showSelectedOnly = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String _searchQuery = '';
  final Map<String, Map<String, dynamic>> _knownTeamData = {};
  Timer? _debounce;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && !_isLoading && !_showSelectedOnly) {
        _fetchMoreTeams();
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    // 1. Load existing favorites
    if (!widget.isOnboarding) {
      try {
        final favorites = await ApiService.getFavoriteTeams();
        _selectedTeams.clear();
        for (var fav in favorites) {
          if (fav is Map<String, dynamic>) {
            final id = fav['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              _selectedTeams.add(id);
              // Store details
              _knownTeamData[id] = {
                'id': id,
                'name': fav['name']?.toString() ?? '',
                'logo':
                    fav['logo']?.toString() ??
                    fav['logo_url']?.toString() ??
                    '',
                'league_name': fav['league_name']?.toString() ?? '',
                'leagues': fav['leagues'] ?? [],
              };
            }
          }
        }
      } catch (e) {
        debugPrint("Error loading favorites: $e");
      }
    }

    // 2. Fetch first page of teams
    await _fetchTeams(isInitial: true);
  }

  Future<void> _fetchTeams({bool isInitial = true}) async {
    if (isInitial) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _teams.clear();
        _hasMore = true;
      });
    }

    try {
      final response = await ApiService.getTeams(
        page: _currentPage,
        search: _searchQuery,
        favoritesOnly: _showSelectedOnly,
      );

      if (!mounted) return;

      if (response.containsKey('data')) {
        final List<dynamic> data = response['data'];
        final meta = response['meta'];

        setState(() {
          for (var team in data) {
            if (team is Map) {
              final teamMap = {
                'id': team['id']?.toString() ?? '',
                'name': team['name']?.toString() ?? '',
                'original_name':
                    team['original_name']?.toString() ??
                    team['name']?.toString() ??
                    '',
                'logo': team['logo_url']?.toString() ?? '',
                'league_name': team['league_name']?.toString() ?? '',
                'leagues': team['leagues'] ?? [],
              };
              _teams.add(teamMap);
              final String tid = teamMap['id'] ?? '';
              if (tid.isNotEmpty) {
                _knownTeamData[tid] = teamMap;
              }
            }
          }
          _isLoading = false;
          _isLoadingMore = false;

          if (meta != null) {
            _hasMore = meta['current_page'] < meta['last_page'];
          } else {
            _hasMore = data.length == 50;
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching teams: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _fetchMoreTeams() async {
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _fetchTeams(isInitial: false);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _fetchTeams();
    });
  }

  void _toggleSelectedFilter() {
    setState(() {
      _showSelectedOnly = !_showSelectedOnly;
      _currentPage = 1;
      _teams.clear();
      _isLoading = true;
    });
    _fetchTeams(isInitial: true);
  }

  Future<bool> _saveChanges() async {
    if (_selectedTeams.isEmpty) {
      GoalioMessages.showWarning(
        context,
        AppLocalizations.of(context)!.selectAtLeastOneTeam,
      );
      return false;
    }
    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> teamsToSave = [];
      for (var teamId in _selectedTeams) {
        final team =
            _knownTeamData[teamId] ??
            {'id': teamId, 'name': '', 'logo': '', 'league_name': null};
        teamsToSave.add({
          'id': team['id'],
          'name': team['name'],
          'logo': team['logo'] ?? team['logo_url'],
          'league_name': team['league_name'],
          'leagues': team['leagues'],
        });
      }

      final success = await ApiService.saveFavoriteTeams(teamsToSave);

      if (success && mounted) {
        GoalioMessages.showSuccess(
          context,
          AppLocalizations.of(
            context,
          )!.savedTeamsSuccess(_selectedTeams.length.toString()),
        );
      }
      return success;
    } catch (e) {
      if (mounted) {
        GoalioMessages.showError(
          context,
          '${AppLocalizations.of(context)!.errorSavingTeams}: $e',
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTeam(String teamId) async {
    setState(() {
      if (_selectedTeams.contains(teamId)) {
        _selectedTeams.remove(teamId);
      } else {
        _selectedTeams.add(teamId);
      }
    });
    // Fallback if needed, but we mostly care about our _selectedTeams set
    // await FavoritesManager.toggleFavorite(teamName);
  }

  void _onContinue() async {
    final success = await _saveChanges();
    if (!success || !mounted) return;

    if (widget.isOnboarding) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OnboardingPage()),
        (route) => false,
      );
    } else {
      // Small delay to ensure they see the success toast
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsetsDirectional.only(
            start: widget.isOnboarding ? 16.w : 0,
            end: 16.w,
          ),
          child: Text(
            widget.isOnboarding
                ? AppLocalizations.of(context)!.pickYourTeams
                : AppLocalizations.of(context)!.teamsManager,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: GoalioColors.greenAccent,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading:
            widget.isOnboarding
                ? null
                : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: GoalioColors.greenAccent,
                ),
        actions: [
          if (_selectedTeams.isNotEmpty)
            Padding(
              padding: EdgeInsetsDirectional.only(end: 16.w),
              child: Center(
                child: Text(
                  AppLocalizations.of(
                    context,
                  )!.selectedCount(_selectedTeams.length.toString()),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          if (widget.isOnboarding)
            Padding(
              padding: EdgeInsetsDirectional.only(end: 8.w),
              child: TextButton(
                onPressed: _onContinue,
                child: Text(
                  AppLocalizations.of(context)!.done.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          if (_showSelectedOnly) _buildFilterHint(),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildContent(context),
          ),
          if (!widget.isOnboarding) _buildSaveButton(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 15.sp,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchHintTeams,
            hintStyle: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 15.sp,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: GoalioColors.greenAccent,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: isDark ? Colors.white54 : Colors.black54,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _debounce?.cancel();
                      _fetchTeams(isInitial: true);
                    },
                  ),
                if (_selectedTeams.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      _showSelectedOnly
                          ? Icons.filter_list
                          : Icons.filter_list_off,
                      color:
                          _showSelectedOnly ? GoalioColors.greenAccent : null,
                    ),
                    onPressed: _toggleSelectedFilter,
                  ),
              ],
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 14.h,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterHint() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 4.h),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list,
            color: GoalioColors.greenAccent,
            size: 14,
          ),
          SizedBox(width: 8.w),
          Text(
            AppLocalizations.of(context)!.showingSelectedTeamsOnly,
            style: TextStyle(
              color: GoalioColors.greenAccent,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: GoalioColors.greenAccent),
    );
  }

  Widget _buildContent(BuildContext context) {
    List<Map<String, dynamic>> displayTeams = _teams;
    if (_showSelectedOnly) {
      displayTeams =
          _teams.where((t) => _selectedTeams.contains(t['id'])).toList();
    }

    if (displayTeams.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer,
              size: 64.w,
              color: Theme.of(context).disabledColor,
            ),
            SizedBox(height: 16.h),
            Text(
              _showSelectedOnly
                  ? AppLocalizations.of(context)!.noSelectedTeamsFound
                  : AppLocalizations.of(context)!.noTeamsFound,
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(10.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.95,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: displayTeams.length + (_hasMore && !_showSelectedOnly ? 4 : 0),
      itemBuilder: (context, index) {
        if (index < displayTeams.length) {
          final team = displayTeams[index];
          final isSelected = _selectedTeams.contains(team['id']);
          return _buildTeamCard(team, isSelected);
        } else {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                color: GoalioColors.greenAccent,
                strokeWidth: 2,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team, bool isSelected) {
    final name = team['name'] as String;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _toggleTeam(team['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isSelected
                  ? GoalioColors.greenAccent.withValues(alpha: isDark ? 0.2 : 0.1)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF8FAFC)),
              isSelected
                  ? GoalioColors.greenAccent.withValues(alpha: isDark ? 0.05 : 0.02)
                  : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? GoalioColors.greenAccent
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected
                                  ? GoalioColors.greenAccent.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: buildTeamLogo(team['logo'], size: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.sp,
                        height: 1.1,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color:
                            isSelected
                                ? (isDark
                                    ? GoalioColors.greenAccent
                                    : const Color(0xFF065F46))
                                : (isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A)),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (team['league_name'] != null && team['league_name'].isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Text(
                          team['league_name'].toString().toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 6.sp,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? GoalioColors.greenAccent.withValues(alpha: 0.8)
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: const BoxDecoration(
                    color: GoalioColors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: GoalioColors.greenAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                  : Text(
                    _selectedTeams.isEmpty
                        ? AppLocalizations.of(context)!.selectAtLeastOneTeam
                        : AppLocalizations.of(
                          context,
                        )!.saveChangesCount(_selectedTeams.length.toString()),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),
      ),
    );
  }
}
