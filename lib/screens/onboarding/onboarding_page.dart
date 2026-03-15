import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/messages.dart';
import '../../main.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/size_config.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  List<dynamic> _allLeagues = [];
  List<dynamic> _filteredLeagues = [];
  List<dynamic> _selectedLeagues = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showSelectedOnly = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  final Set<String> _seenLeagueIds = {};
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLeagues(isInitial: true);
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

  Future<void> _loadLeagues({bool isInitial = true}) async {
    if (isInitial) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _allLeagues.clear();
        _seenLeagueIds.clear();
        _hasMore = true;
      });
    }

    try {
      final response = await ApiService.getAllLeagues(
        page: _currentPage,
        search: _searchController.text,
        favoritesOnly: _showSelectedOnly,
      );
      final List<dynamic> leaguesData = 
          (response is Map) ? (response['data'] ?? []) : (response is List ? response : []);

      final meta = response is Map ? response['meta'] : null;

      final List<dynamic> leaguesList = [];
      for (var l in leaguesData) {
        final id = l['id']?.toString() ?? '';
        if (id.isNotEmpty && !_seenLeagueIds.contains(id)) {
          _seenLeagueIds.add(id);
          leaguesList.add(l);
        }
      }

      if (mounted) {
        setState(() {
          if (isInitial) {
            _allLeagues = leaguesList;
          } else {
            _allLeagues.addAll(leaguesList);
          }

          if (meta != null) {
            _hasMore = meta['current_page'] < meta['last_page'];
          } else {
            _hasMore = leaguesData.length == 100; // Using 100 as per backend pagination
          }

          _isLoading = false;
          _isLoadingMore = false;
          _filterLeagues();
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading leagues: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
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

  void _filterLeagues() {
    setState(() {
      _filteredLeagues = List.from(_allLeagues);
    });
  }

  void _toggleLeague(dynamic leagueId) {
    setState(() {
      if (_selectedLeagues.contains(leagueId)) {
        _selectedLeagues.remove(leagueId);
      } else {
        _selectedLeagues.add(leagueId);
      }
    });
    _filterLeagues();
  }

  Future<void> _saveAndContinue() async {
    if (_selectedLeagues.isEmpty) {
      GoalioMessages.showWarning(
        context,
        AppLocalizations.of(context)!.selectAtLeastOneLeague,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Prepare leagues data for saving
      final List<Map<String, dynamic>> leaguesToSave = [];
      for (var leagueId in _selectedLeagues) {
        final league = _allLeagues.firstWhere(
          (l) => l['id'] == leagueId,
          orElse: () => null,
        );

        if (league != null) {
          leaguesToSave.add({
            'id': league['id'],
            'name': league['name'],
            'image': league['logo_url'] ?? league['image'] ?? '',
          });
        }
      }

      // Save to server
      final success = await ApiService.saveFavoriteLeagues(leaguesToSave);

      if (mounted) {
        if (success) {
          GoalioMessages.showSuccess(
            context,
            AppLocalizations.of(
              context,
            )!.savedLeaguesSuccess(_selectedLeagues.length.toString()),
          );

          // Navigate to main app
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainPage()),
            (route) => false,
          );
        } else {
          GoalioMessages.showError(
            context,
            AppLocalizations.of(context)!.errorSavingLeagues,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving favorite leagues: $e');
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
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsetsDirectional.only(start: 16.w, end: 16.w),
          child: Text(
            AppLocalizations.of(context)!.selectFavoriteLeagues,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: GoalioColors.greenAccent,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          if (_selectedLeagues.isNotEmpty)
            Padding(
              padding: EdgeInsetsDirectional.only(end: 16.w),
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
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchHintLeagues,
                prefixIcon: const Icon(Icons.search),
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
                                  ? Theme.of(context).colorScheme.primary
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
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
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _filteredLeagues.length,
                      itemBuilder: (context, index) {
                        final league = _filteredLeagues[index];
                        final isSelected = _selectedLeagues.contains(
                          league['id'],
                        );

                        return GestureDetector(
                          onTap: () => _toggleLeague(league['id']),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  // League Logo
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                    ),
                                    child:
                                        league['logo_url'] != null &&
                                                league['logo_url'].isNotEmpty
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Image.network(
                                                league['logo_url'],
                                                width: 32,
                                                height: 32,
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Icon(
                                                    Icons.sports_soccer,
                                                    size: 20,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).disabledColor,
                                                  );
                                                },
                                              ),
                                            )
                                            : Icon(
                                              Icons.sports_soccer,
                                              size: 20,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).disabledColor,
                                            ),
                                  ),
                                  const SizedBox(width: 8),

                                  // League Name
                                  Expanded(
                                    child: Text(
                                      league['name'] ?? 'Unknown League',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        color:
                                            isSelected
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                                : Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium?.color,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Selection Indicator
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 20,
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

          // Continue Button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAndContinue,
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
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(AppLocalizations.of(context)!.saving),
                          ],
                        )
                        : Text(
                          _selectedLeagues.isEmpty
                              ? AppLocalizations.of(
                                context,
                              )!.selectAtLeastOneLeague
                              : AppLocalizations.of(context)!.continueWithCount(
                                _selectedLeagues.length.toString(),
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
