import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/messages.dart';
import '../../l10n/app_localizations.dart';

class ManageLeaguesPage extends StatefulWidget {
  const ManageLeaguesPage({super.key});

  @override
  State<ManageLeaguesPage> createState() => _ManageLeaguesPageState();
}

class _ManageLeaguesPageState extends State<ManageLeaguesPage> {
  List<Map<String, dynamic>> _allLeagues = [];
  List<Map<String, dynamic>> _filteredLeagues = [];
  Set<String> _selectedLeagues = {};
  final Map<String, Map<String, dynamic>> _knownLeagueData = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isSaving = false;
  bool _showSelectedOnly = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && !_isLoading && !_showSelectedOnly) {
        _fetchMoreLeagues();
      }
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadLeagues(isInitial: true);
      }
    });
  }

  Future<void> _loadInitialData() async {
    await _loadLeagues(isInitial: true);
    await _loadFavoriteLeagues();
  }

  Future<void> _loadLeagues({bool isInitial = true}) async {
    if (isInitial) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _allLeagues.clear();
        _hasMore = true;
      });
    }

    try {
      final response = await ApiService.getAllLeagues(
        page: _currentPage,
        search: _searchController.text,
        favoritesOnly: _showSelectedOnly,
      );
      final List<dynamic> rawLeagues =
          (response is Map) ? (response['data'] ?? []) : response;

      final List<Map<String, dynamic>> leaguesList = [];
      for (var league in rawLeagues) {
        Map<String, dynamic>? leagueMap;
        if (league is Map<String, dynamic>) {
          leagueMap = league;
        } else if (league is Map) {
          leagueMap = Map<String, dynamic>.from(league);
        }

        if (leagueMap != null) {
          leaguesList.add(leagueMap);
          final id = leagueMap['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            _knownLeagueData[id] = leagueMap;
          }
        }
      }

      final meta = response is Map ? response['meta'] : null;

      setState(() {
        if (isInitial) {
          _allLeagues = leaguesList;
        } else {
          _allLeagues.addAll(leaguesList);
        }

        if (meta != null) {
          _hasMore = meta['current_page'] < meta['last_page'];
        } else {
          _hasMore = rawLeagues.length == 100;
        }

        _isLoading = false;
        _isLoadingMore = false;
        _filterLeagues();
      });
    } catch (e) {
      debugPrint('Error loading leagues: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) {
        GoalioMessages.showError(
          context,
          '${AppLocalizations.of(context)!.errorLoadingLeagues}: $e',
        );
      }
    }
  }

  Future<void> _fetchMoreLeagues() async {
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _loadLeagues(isInitial: false);
  }

  Future<void> _loadFavoriteLeagues() async {
    try {
      final List<dynamic> favoriteLeagues =
          await ApiService.getFavoriteLeagues();

      final Set<String> newSelected = {};

      for (var fav in favoriteLeagues) {
        if (fav is Map<String, dynamic>) {
          final id = fav['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            newSelected.add(id);
            _knownLeagueData[id] = {
              'id': id,
              'name': fav['name']?.toString() ?? '',
              'logo_url': fav['image']?.toString() ?? '',
            };
          }
        }
      }

      setState(() {
        _selectedLeagues = newSelected;
      });
      debugPrint("Loaded ${_selectedLeagues.length} favorite leagues");
    } catch (e) {
      debugPrint("Error loading favorite leagues: $e");
    }
  }

  void _filterLeagues() {
    setState(() {
      _filteredLeagues = List.from(_allLeagues);
    });
  }

  void _toggleLeague(String leagueId) {
    setState(() {
      if (_selectedLeagues.contains(leagueId)) {
        _selectedLeagues.remove(leagueId);
      } else {
        _selectedLeagues.add(leagueId);
      }
    });
    _filterLeagues();
  }

  Future<void> _saveChanges() async {
    if (_selectedLeagues.isEmpty) {
      GoalioMessages.showWarning(
        context,
        AppLocalizations.of(context)!.selectAtLeastOneLeague,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final List<Map<String, dynamic>> leaguesToSave = [];
      for (var id in _selectedLeagues) {
        final league =
            _knownLeagueData[id] ??
            <String, dynamic>{'id': id, 'name': '', 'image': ''};
        leaguesToSave.add({
          'id': league['id'],
          'name': league['name'],
          'image': league['logo_url'] ?? league['image'] ?? '',
        });
      }

      final success = await ApiService.saveFavoriteLeagues(leaguesToSave);

      if (!success) {
        if (mounted) {
          GoalioMessages.showError(
            context,
            "Failed to save changes. Please login again.",
          );
        }
      } else {
        if (mounted) {
          GoalioMessages.showSuccess(
            context,
            AppLocalizations.of(
              context,
            )!.savedLeaguesSuccess(_selectedLeagues.length.toString()),
          );

          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving favorite leagues: $e');
      if (mounted) {
        GoalioMessages.showError(
          context,
          '${AppLocalizations.of(context)!.errorSavingLeagues}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: GoalioColors.greenAccent,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsetsDirectional.only(end: 16.0),
          child: Text(AppLocalizations.of(context)!.leaguesManager),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (_selectedLeagues.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16.0),
              child: Center(
                child: Text(
                  AppLocalizations.of(
                    context,
                  )!.selectedCount(_selectedLeagues.length.toString()),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      Theme.of(context).brightness == Brightness.dark
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
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchLeaguesHint,
                  hintStyle: TextStyle(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54
                            : Colors.black54,
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
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _debounceTimer?.cancel();
                            _loadLeagues(isInitial: true);
                          },
                        ),
                      if (_selectedLeagues.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            _showSelectedOnly
                                ? Icons.filter_list
                                : Icons.filter_list_off,
                            color:
                                _showSelectedOnly
                                    ? GoalioColors.greenAccent
                                    : null,
                          ),
                          onPressed: () {
                            setState(() {
                              _showSelectedOnly = !_showSelectedOnly;
                            });
                            _loadLeagues(isInitial: true);
                          },
                        ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),

          // Filter hint
          if (_showSelectedOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.showingSelectedLeaguesOnly,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Leagues Grid
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredLeagues.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: 64,
                            color: Theme.of(context).disabledColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showSelectedOnly
                                ? AppLocalizations.of(
                                  context,
                                )!.noSelectedLeaguesFound
                                : AppLocalizations.of(context)!.noLeaguesFound,
                            style: TextStyle(
                              color: Theme.of(context).disabledColor,
                              fontSize: 16,
                            ),
                          ),
                          if (_showSelectedOnly)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showSelectedOnly = false;
                                });
                                _loadLeagues(isInitial: true);
                              },
                              child: Text(
                                AppLocalizations.of(context)!.showAllLeagues,
                              ),
                            ),
                        ],
                      ),
                    )
                    : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _filteredLeagues.length,
                      itemBuilder: (context, index) {
                        final league = _filteredLeagues[index];
                        final isSelected = _selectedLeagues.contains(
                          league['id']?.toString(),
                        );
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;

                        return GestureDetector(
                          onTap:
                              () =>
                                  _toggleLeague(league['id']?.toString() ?? ''),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  isSelected
                                      ? GoalioColors.greenAccent.withValues(alpha: isDark ? 0.2 : 0.1,)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : const Color(0xFFF8FAFC)),
                                  isSelected
                                      ? GoalioColors.greenAccent.withValues(alpha: isDark ? 0.05 : 0.02,)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.02)
                                          : Colors.white),
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
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: GoalioColors.greenAccent
                                              .withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                      : [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04,),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  // League Logo Container
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? GoalioColors.greenAccent
                                                    .withValues(alpha: 0.5)
                                                : Colors.black.withValues(alpha: 0.05,),
                                        width: 1,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child:
                                        league['logo_url'] != null &&
                                                league['logo_url'].isNotEmpty
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Image.network(
                                                league['logo_url'],
                                                fit: BoxFit.contain,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return const Icon(
                                                    Icons.emoji_events,
                                                    size: 20,
                                                    color:
                                                        GoalioColors
                                                            .greenAccent,
                                                  );
                                                },
                                              ),
                                            )
                                            : const Icon(
                                              Icons.emoji_events,
                                              size: 20,
                                              color: GoalioColors.greenAccent,
                                            ),
                                  ),
                                  const SizedBox(width: 10),

                                  // League Name
                                  Expanded(
                                    child: Text(
                                      (() {
                                        final isAr =
                                            Localizations.localeOf(
                                              context,
                                            ).languageCode ==
                                            'ar';
                                        return (isAr
                                                ? league['name_ar'] ??
                                                    league['name']
                                                : league['name']) ??
                                            'Unknown';
                                      })(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
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
                                  ),

                                  // Selection Indicator
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: GoalioColors.greenAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: GoalioColors.greenAccent,
                ),
              ),
            ),

          // Save Button
          Container(
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
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text(
                          _selectedLeagues.isEmpty
                              ? AppLocalizations.of(
                                context,
                              )!.selectAtLeastOneLeague
                              : AppLocalizations.of(context)!.saveChangesCount(
                                _selectedLeagues.length.toString(),
                              ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
