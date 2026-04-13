import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../screens/leagues/leagues_list_view.dart';
import '../../screens/leagues/league_fantasy_tab.dart';

import '../../core/constants/constants.dart';
import '../../core/services/api_service.dart';
import '../../screens/news/news_detail_page.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/size_config.dart';
import '../../core/utils/messages.dart';
import '../../core/utils/number_utils.dart';
import '../../core/utils/name_translator.dart';

class LeaguesPage extends StatefulWidget {
  final Map<String, dynamic>? initialLeague;
  const LeaguesPage({super.key, this.initialLeague});

  @override
  State<LeaguesPage> createState() => LeaguesPageState();
}

class LeaguesPageState extends State<LeaguesPage>
    with TickerProviderStateMixin {
  bool _isPremierLeague(Map<String, dynamic>? league) {
    if (league == null) return false;
    final id = league['id']?.toString();
    return id == '1';
  }

  List<Map<String, dynamic>> _allLeagues = [];
  Map<String, dynamic>? _selectedLeague;
  bool _isLoading = true;
  bool _isScraping = false;
  String? _scrapingLeague;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _showFavoritesOnly = false;
  String _searchQuery = '';
  Timer? _debounce;
  String _selectedPlayerStat = 'goals';
  List<dynamic> _leagueStandings = [];
  Map<String, List<dynamic>> _topPlayers = {};
  bool _isLoadingStandings = false;
  bool _isLoadingPlayers = false;

  final ScrollController _mainListController = ScrollController();
  final ScrollController _newsListController = ScrollController();
  final ScrollController _standingsListController = ScrollController();
  final ScrollController _playersListController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _isPremierLeague(widget.initialLeague) ? 4 : 3,
      vsync: this,
    );
    _loadLeagues(silent: true);
    _mainListController.addListener(_onScroll);

    if (widget.initialLeague != null) {
      _selectLeagueAndScrape(widget.initialLeague!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _mainListController.dispose();
    _newsListController.dispose();
    _standingsListController.dispose();
    _playersListController.dispose();
    super.dispose();
  }

  bool onBackPressed() {
    if (_selectedLeague != null) {
      // If we came from Home directly, back should pop the screen
      if (widget.initialLeague != null) {
        return false; // let system pop
      }

      setState(() {
        _selectedLeague = null;
      });
      return true;
    }
    return false;
  }

  void resetState() {
    setState(() {
      _selectedLeague = null;
      _searchController.clear();
      _tabController.index = 0;
    });

    if (_mainListController.hasClients) {
      _mainListController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
    if (_newsListController.hasClients) {
      _newsListController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
    if (_standingsListController.hasClients) {
      _standingsListController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
    if (_playersListController.hasClients) {
      _playersListController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> refreshData({bool silent = false}) async {
    if (!mounted) return;

    if (_selectedLeague != null) {
      await _selectLeagueAndScrape(_selectedLeague!);
    } else {
      await _loadLeagues(silent: silent);
    }
  }

  Future<void> refreshDataSilent() async {
    final mainLeagues = [
      'England - Premier League',
      'Spain - LaLiga',
      'Italy - Serie A',
      'Germany - Bundesliga',
      'France - Ligue 1',
      'Saudi Arabia - Saudi Pro League',
    ];

    // Skip showing loaders, just trigger background scrapes
    for (var league in mainLeagues) {
      ApiService.scrapeStandingsForLeague(league).catchError((_) => false);
      ApiService.scrapeNewsForLeague(league).catchError((_) => false);
      ApiService.scrapeTopPlayersForLeague(league).catchError((_) => false);
    }

    // Refresh general leagues/standings as well
    try {
      ApiService.scrapeAllLeagues();
    } catch (_) {}

    // Reload local state from DB
    await _loadLeagues(silent: true);
  }

  Future<void> _loadLeagues({
    bool isInitial = true,
    bool silent = false,
  }) async {
    if (!mounted) return;

    if (isInitial) {
      if (mounted) {
        setState(() {
          // If we have no data, we MUST show a loader even in silent mode
          _isLoading = !silent || _allLeagues.isEmpty;
          _currentPage = 1;
          _hasMore = true;
          if (!silent) _allLeagues.clear();
        });
      }
    }

    try {
      final response = await ApiService.getAllLeagues(
        page: _currentPage,
        search: _searchQuery,
        favoritesOnly: _showFavoritesOnly,
      );

      if (!mounted) return;

      List<dynamic> rawData = [];
      Map<String, dynamic>? meta;

      if (response is Map) {
        if (response.containsKey('data')) {
          rawData = response['data'];
          meta = response['meta'];
        } else {
          // It's a map but doesn't have data key? Maybe raw object.
          rawData = [response];
        }
      } else if (response is List) {
        rawData = response;
      }

      if (rawData.isNotEmpty || !isInitial) {
        final List<Map<String, dynamic>> enrichedLeagues = [];
        for (var l in rawData) {
          if (l is! Map) continue;
          final entry = Map<String, dynamic>.from(l);
          enrichedLeagues.add({
            'id': entry['id'],
            'name': entry['name']?.toString() ?? '',
            'name_ar': entry['name_ar']?.toString(),
            'original_name': entry['original_name']?.toString() ?? '',
            'logo_url': entry['logo_url'] ?? '',
            'is_favorite_league': entry['is_favorite_league'] ?? false,
            'teams_count': _getRandomTeamCount(),
            'matches_today': _getRandomMatchesCount(),
            'season': '2024/25',
          });
        }

        setState(() {
          if (isInitial) {
            _allLeagues = enrichedLeagues;
          } else {
            _allLeagues.addAll(enrichedLeagues);
          }
          _isLoading = false;
          _isLoadingMore = false;
          if (meta != null) {
            _hasMore = meta['current_page'] < meta['last_page'];
          } else {
            _hasMore = rawData.length == 50;
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _hasMore = false;
        });
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Error loading leagues: $e');
        debugPrint('Stack trace: $stack');
      }
      if (mounted) {
        GoalioMessages.showError(
          context,
          '${AppLocalizations.of(context)!.errorLoadingLeagues}: $e',
        );
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_mainListController.position.pixels >=
        _mainListController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore &&
          _hasMore &&
          !_isLoading &&
          _selectedLeague == null) {
        _fetchMoreLeagues();
      }
    }
  }

  Future<void> _fetchMoreLeagues() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _loadLeagues(isInitial: false);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _loadLeagues(isInitial: true);
    });
  }

  List<dynamic> _leagueNews = [];
  bool _isLoadingNews = false;
  String? _newsError;

  Future<void> _loadLeagueNews({String? leagueName, dynamic leagueId}) async {
    final targetLeagueName = leagueName ?? _selectedLeague?['name']?.toString();
    final targetLeagueId = leagueId ?? _selectedLeague?['id'];
    if (targetLeagueName == null && targetLeagueId == null) return;

    setState(() {
      _isLoadingNews = true;
      _newsError = null;
    });

    try {
      final news = await ApiService.getNewsForLeague(
        targetLeagueName ?? '',
        leagueId: targetLeagueId,
      );

      if (mounted) {
        setState(() {
          _leagueNews = news;
          _isLoadingNews = false;
          _newsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingNews = false;
          _newsError = AppLocalizations.of(context)!.failedToLoadNews;
        });
      }
    }
  }

  Future<void> _loadStandings({String? leagueName, dynamic leagueId}) async {
    final targetLeagueName = leagueName ?? _selectedLeague?['name']?.toString();
    final targetLeagueId = leagueId ?? _selectedLeague?['id'];
    if (targetLeagueName == null && targetLeagueId == null) return;

    setState(() => _isLoadingStandings = true);
    try {
      final data = await ApiService.getStandings(
        leagueName: targetLeagueName,
        leagueId: targetLeagueId,
      );
      if (mounted) {
        setState(() {
          _leagueStandings = data;
          _isLoadingStandings = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStandings = false);
    }
  }

  Future<void> _loadTopPlayers({String? leagueName, dynamic leagueId}) async {
    final targetLeagueName = leagueName ?? _selectedLeague?['name']?.toString();
    final targetLeagueId = leagueId ?? _selectedLeague?['id'];
    if (targetLeagueName == null && targetLeagueId == null) return;

    setState(() => _isLoadingPlayers = true);
    try {
      final data = await ApiService.getTopPlayersForLeague(
        targetLeagueName ?? '',
        leagueId: targetLeagueId,
      );
      if (mounted) {
        setState(() {
          _topPlayers = data;
          _isLoadingPlayers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPlayers = false);
    }
  }

  void selectLeague(Map<String, dynamic> league) {
    _selectLeagueAndScrape(league);
  }

  Future<void> _selectLeagueAndScrape(Map<String, dynamic> league) async {
    final leagueName = league['name']?.toString() ?? ''; // For UI
    final originalName =
        league['original_name']?.toString() ?? leagueName; // For API
    final isDifferentLeague = _selectedLeague?['name'] != leagueName;

    final leagueId = league['id'];

    setState(() {
      _selectedLeague = league;
      _scrapingLeague = leagueName;

      if (isDifferentLeague) {
        final newLength = _isPremierLeague(league) ? 4 : 3;
        if (_tabController.length != newLength) {
          _tabController.dispose();
          _tabController = TabController(length: newLength, vsync: this);
        }

        _leagueNews = [];
        _leagueStandings = [];
        _topPlayers = {};
        _tabController.index = 0;
        _selectedPlayerStat = 'goals';
        // Only show blocking scraper if we have absolutely no data
        _isScraping = true;
      }
    });

    // 1. Initial fetch of existing data from DB (FAST)
    await Future.wait([
      _loadLeagueNews(leagueName: originalName, leagueId: leagueId),
      _loadStandings(leagueName: originalName, leagueId: leagueId),
      _loadTopPlayers(leagueName: originalName, leagueId: leagueId),
    ]);

    // If we already have some data, we can stop the blocking scraper and continue in background
    if (_leagueNews.isNotEmpty ||
        _leagueStandings.isNotEmpty ||
        _topPlayers.isNotEmpty) {
      if (mounted) setState(() => _isScraping = false);
    }

    // 2. Trigger background scraping in parallel
    if (kDebugMode)
      debugPrint(
        'Starting background scraping for: $originalName (ID: $leagueId)',
      );

    try {
      final results = await Future.wait([
        ApiService.scrapeStandingsForLeague(
          originalName,
          leagueId: leagueId,
        ).catchError((e) {
          if (kDebugMode) debugPrint('Error scraping standings: $e');
          return false;
        }),
        ApiService.scrapeNewsForLeague(
          originalName,
          leagueId: leagueId,
        ).catchError((e) {
          if (kDebugMode) debugPrint('Error scraping news: $e');
          return false;
        }),
        ApiService.scrapeTopPlayersForLeague(
          originalName,
          leagueId: leagueId,
        ).catchError((e) {
          if (kDebugMode) debugPrint('Error scraping players: $e');
          return false;
        }),
      ]);

      final allSuccess = results.every((res) => res == true);
      if (kDebugMode) {
        debugPrint(
          'Background scraping for $originalName finished. Success: $allSuccess',
        );
      }

      if (!mounted) return;

      // 3. Reload data from DB after scraping is done
      await Future.wait([
        _loadLeagueNews(leagueName: originalName, leagueId: leagueId),
        _loadStandings(leagueName: originalName, leagueId: leagueId),
        _loadTopPlayers(leagueName: originalName, leagueId: leagueId),
      ]);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error in background scraping: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScraping = false;
          _scrapingLeague = null;
        });
      }
    }
  }

  int _getRandomTeamCount() =>
      [18, 20, 22, 24].elementAt(DateTime.now().millisecond % 4);
  int _getRandomMatchesCount() =>
      [8, 10, 12, 14].elementAt(DateTime.now().millisecond % 4);

  List<Map<String, dynamic>> get _filteredLeagues {
    final query = _searchController.text.toLowerCase();
    final mainLeagueIds = [
      1, // England - Premier League
      16, // Spain - LaLiga
      17, // Italy - Serie A
      99, // Germany - Bundesliga
      98, // France - Ligue 1
      61, // Saudi Arabia - Saudi Pro League
    ];

    final filtered =
        _allLeagues.where((league) {
          final name = league['name'].toString().toLowerCase();
          final origName =
              (league['original_name'] ?? '').toString().toLowerCase();
          return name.contains(query) || origName.contains(query);
        }).toList();

    // Sort: Main leagues first in the order of mainLeagueIds list, then everything else alphabetically
    filtered.sort((a, b) {
      final nameA = (a['name'] ?? '').toString();
      final nameB = (b['name'] ?? '').toString();
      final idA = int.tryParse(a['id']?.toString() ?? '') ?? -1;
      final idB = int.tryParse(b['id']?.toString() ?? '') ?? -1;

      final indexA = mainLeagueIds.indexOf(idA);
      final indexB = mainLeagueIds.indexOf(idB);

      final isA = indexA != -1;
      final isB = indexB != -1;

      if (isA && !isB) return -1;
      if (!isA && isB) return 1;
      if (indexA != indexB) return indexA.compareTo(indexB);

      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (onBackPressed()) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading:
              _selectedLeague != null
                  ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: GoalioColors.greenAccent,
                    ),
                    onPressed: () {
                      if (widget.initialLeague != null) {
                        Navigator.pop(context);
                      } else {
                        setState(() => _selectedLeague = null);
                      }
                    },
                  )
                  : null,
          titleSpacing: 0,
          title: Padding(
            padding: EdgeInsetsDirectional.only(
              start: _selectedLeague != null ? 0 : 16.w,
              end: 16.w,
            ),
            child: Text(
              _selectedLeague != null
                  ? ArabicNameExtension(
                    _selectedLeague!['name'] ?? '',
                  ).toArabicName(context)
                  : AppLocalizations.of(context)!.leaguesTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GoalioColors.greenAccent,
                letterSpacing: 1.2,
              ),
            ),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: false,
          actions: const [],
        ),
        body:
            _selectedLeague != null
                ? _buildLeagueDetails()
                : Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child:
                          _isLoading
                              ? const Center(
                                child: CircularProgressIndicator(
                                  color: GoalioColors.greenAccent,
                                ),
                              )
                              : _allLeagues.isEmpty
                              ? _buildEmptyState()
                              : _buildLeaguesList(),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchLeaguesHint,
          hintStyle: TextStyle(color: secondaryTextColor, fontSize: 16),
          prefixIcon: const Icon(
            Icons.search,
            color: GoalioColors.greenAccent,
            size: 24,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: secondaryTextColor, size: 20),
                  onPressed: () {
                    _debounce?.cancel();
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                    _loadLeagues(isInitial: true);
                  },
                ),
              IconButton(
                icon: Icon(
                  _showFavoritesOnly
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: _showFavoritesOnly ? Colors.amber : secondaryTextColor,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _showFavoritesOnly = !_showFavoritesOnly;
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
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final isSearching = _searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(
              isSearching ? Icons.search_off : Icons.leaderboard,
              size: 80,
              color: GoalioColors.greenAccent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearching
                ? AppLocalizations.of(context)!.noLeaguesFound
                : AppLocalizations.of(context)!.noLeaguesAvailable,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isSearching
                  ? AppLocalizations.of(
                    context,
                  )!.noLeaguesFoundMatching(_searchQuery)
                  : AppLocalizations.of(context)!.noLeaguesInDatabase,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 16,
              ),
            ),
          ),
          if (isSearching) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GoalioColors.greenAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(AppLocalizations.of(context)!.clearSearch),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaguesList() {
    return LeaguesListView(
      leagues: _filteredLeagues,
      isLoading: _isLoading,
      isLoadingMore: _isLoadingMore,
      isScraping: _isScraping,
      scrapingLeagueName: _scrapingLeague,
      selectedLeague: _selectedLeague,
      onRefresh: () => _loadLeagues(silent: true),
      onLeagueTap: _selectLeagueAndScrape,
      onToggleFavorite: _toggleFavoriteLeague,
      controller: _mainListController,
      enabledLeagues: const [
        'England - Premier League',
        'Spain - LaLiga',
        'Italy - Serie A',
        'Germany - Bundesliga',
        'France - Ligue 1',
        'Saudi Arabia - Saudi Pro League',
      ],
    );
  }

  Future<void> _toggleFavoriteLeague(Map<String, dynamic> league) async {
    final leagueId = league['id'];
    final name = league['original_name'] ?? league['name'];
    final image = league['logo_url'];

    setState(() {
      final index = _allLeagues.indexWhere((l) => l['id'] == leagueId);
      if (index != -1) {
        _allLeagues[index]['is_favorite_league'] =
            !(_allLeagues[index]['is_favorite_league'] ?? false);
      } else {
        // Fallback for current reference
        league['is_favorite_league'] = !(league['is_favorite_league'] ?? false);
      }
    });

    final result = await ApiService.toggleFavoriteLeague(
      leagueId: leagueId,
      name: name,
      image: image,
    );

    if (result.containsKey('error')) {
      setState(() {
        final index = _allLeagues.indexWhere((l) => l['id'] == leagueId);
        if (index != -1) {
          _allLeagues[index]['is_favorite_league'] =
              !(_allLeagues[index]['is_favorite_league'] ?? false);
        } else {
          league['is_favorite_league'] =
              !(league['is_favorite_league'] ?? false);
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
        final isFavorite = league['is_favorite_league'] == true;
        GoalioMessages.showSuccess(
          context,
          isFavorite
              ? AppLocalizations.of(context)!.addedToFavorites
              : AppLocalizations.of(context)!.removedFromFavorites,
        );
      }
    }
  }

  Widget _buildLeagueDetails() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Column(
      children: [
        // Premium TabBar
        Container(
          margin: EdgeInsets.fromLTRB(
            isLargeScreen ? 20 : 16,
            isLargeScreen ? 20 : 16,
            isLargeScreen ? 20 : 16,
            8,
          ),
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: isDark ? Colors.black : Colors.white,
            unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: GoalioColors.greenAccent,
              boxShadow: [
                BoxShadow(
                  color: GoalioColors.greenAccent.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            dividerColor: Colors.transparent,
            labelStyle: TextStyle(
              fontSize: isLargeScreen ? 14 : 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: isLargeScreen ? 14 : 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.article_outlined, size: isLargeScreen ? 20 : 18),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.newsTag),
                  ],
                ),
              ),
              Tab(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      size: isLargeScreen ? 20 : 18,
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.standingsTab),
                  ],
                ),
              ),
              Tab(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline, size: isLargeScreen ? 20 : 18),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.playersTab),
                  ],
                ),
              ),
              if (_isPremierLeague(_selectedLeague))
                Tab(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: isLargeScreen ? 20 : 18,
                      ),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.fantasyHub),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: Container(
            margin: EdgeInsets.fromLTRB(
              isLargeScreen ? 12 : 10,
              8,
              isLargeScreen ? 12 : 10,
              20,
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      isDark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNewsTab(),
                  _buildStandingsTab(),
                  _buildTopPlayersTab(),
                  if (_isPremierLeague(_selectedLeague))
                    LeagueFantasyTab(
                      leagueId:
                          int.tryParse(
                            _selectedLeague!['id']?.toString() ?? '1',
                          ) ??
                          1,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    if (_selectedLeague == null) {
      return Center(
        child: Text(
          'Select a league to view news',
          style: TextStyle(color: secondaryTextColor, fontSize: 16),
        ),
      );
    }

    if (_isLoadingNews && _leagueNews.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: GoalioColors.greenAccent),
      );
    }

    if (_newsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              _newsError!,
              style: TextStyle(color: secondaryTextColor, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadLeagueNews,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: GoalioColors.greenAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_leagueNews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.newspaper_outlined,
              size: 64,
              color: GoalioColors.greenAccent.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noNewsAvailableFor(
                _selectedLeague!['name'].toString().toArabicName(context),
              ),
              style: TextStyle(color: secondaryTextColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadLeagueNews,
              style: ElevatedButton.styleFrom(
                backgroundColor: GoalioColors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.checkAgain,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: GoalioColors.greenAccent,
      onRefresh: _loadLeagueNews,
      child: ListView.separated(
        controller: _newsListController,
        padding: const EdgeInsets.all(20),
        itemCount: _leagueNews.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final article = _leagueNews[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => NewsDetailPage(
                        article: Map<String, dynamic>.from(article),
                        heroTag: 'league_news_${article['id']}',
                      ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withOpacity(0.02)
                        : Colors.black.withOpacity(0.01),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.04),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article['image_url'] != null &&
                      article['image_url'].toString().isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      child: Hero(
                        tag: 'league_news_${article['url']}',
                        child: Image.network(
                          article['image_url'],
                          width: 120,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                width: 120,
                                height: 110,
                                color:
                                    isDark
                                        ? Colors.grey[900]
                                        : Colors.grey[200],
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: secondaryTextColor,
                                ),
                              ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: secondaryTextColor,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatNewsDate(article['published_at']),
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            article['title'] ?? 'No Title',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (article['author'] != null &&
                              article['author'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: GoalioColors.greenAccent
                                          .withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 10,
                                      color: GoalioColors.greenAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      article['author'],
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatNewsDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inHours < 24) {
        if (diff.inHours > 0) return "${diff.inHours}h ago";
        return "${diff.inMinutes}m ago";
      }
      return '${date.day}/${date.month}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildStandingsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: _buildStandingsTable())],
      ),
    );
  }

  Widget _buildStandingsTable() {
    if (_isLoadingStandings && _leagueStandings.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: GoalioColors.greenAccent),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    if (_leagueStandings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.query_stats_outlined,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noStandingsData,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.liveUpdatesSoon,
              style: TextStyle(color: secondaryTextColor, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final rawData = _leagueStandings;
    final Set<String> seenTeams = {};
    final List<Map<String, dynamic>> standings = [];

    // Normalize data for display
    for (var item in rawData) {
      if (item is! Map) continue;

      // Try multiple keys for team name
      final teamName =
          (item['team'] ?? item['name'] ?? item['team_name'] ?? '').toString();

      if (teamName.isNotEmpty && !seenTeams.contains(teamName)) {
        seenTeams.add(teamName);

        // Create a normalized map
        final normalized = Map<String, dynamic>.from(item);
        normalized['display_name'] = teamName;

        // Handle variations in stat keys
        normalized['p'] = item['played'] ?? item['p'] ?? item['P'] ?? '0';
        normalized['w'] =
            item['wins'] ?? item['won'] ?? item['w'] ?? item['W'] ?? '0';
        normalized['d'] =
            item['draws'] ?? item['drawn'] ?? item['d'] ?? item['D'] ?? '0';
        normalized['l'] =
            item['losses'] ?? item['lost'] ?? item['l'] ?? item['L'] ?? '0';
        normalized['gd'] =
            item['goal_difference'] ?? item['gd'] ?? item['GD'] ?? '0';
        normalized['pts'] = item['points'] ?? item['pts'] ?? item['PTS'] ?? '0';
        normalized['pos'] =
            item['position'] ?? item['pos'] ?? item['rank'] ?? '0';
        normalized['logo'] =
            item['team_logo'] ?? item['logo'] ?? item['team_image'] ?? '';

        standings.add(normalized);
      }
    }

    if (standings.isEmpty) {
      return Center(
        child: Text(
          'No valid standings data found',
          style: TextStyle(color: secondaryTextColor),
        ),
      );
    }

    final headerTextColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final headerBgColor =
        isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.04);

    return Column(
      children: [
        // Improved Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: headerBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildHeaderCell('#', 1, headerTextColor, TextAlign.center),
              _buildHeaderCell(
                AppLocalizations.of(context)!.team,
                8,
                headerTextColor,
                TextAlign.start,
              ),
              _buildHeaderCell(
                AppLocalizations.of(context)!.playedShort,
                1,
                headerTextColor,
                TextAlign.center,
              ),
              _buildHeaderCell(
                AppLocalizations.of(context)!.wonShort,
                1,
                headerTextColor,
                TextAlign.center,
              ),
              _buildHeaderCell(
                AppLocalizations.of(context)!.drawnShort,
                1,
                headerTextColor,
                TextAlign.center,
              ),
              _buildHeaderCell(
                AppLocalizations.of(context)!.lostShort,
                1,
                headerTextColor,
                TextAlign.center,
              ),
              _buildHeaderCell(
                AppLocalizations.of(context)!.goalDiffShort,
                1,
                headerTextColor,
                TextAlign.center,
              ),
              _buildHeaderCell(
                AppLocalizations.of(context)!.ptsShort,
                2,
                GoalioColors.greenAccent,
                TextAlign.center,
              ),
            ],
          ),
        ),
        // Rows
        Expanded(
          child: ListView.builder(
            controller: _standingsListController,
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: standings.length,
            itemBuilder: (context, index) {
              final team = standings[index];
              final position = int.tryParse(team['pos'].toString()) ?? 0;
              final isChampionsLeague = position > 0 && position <= 4;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color:
                      isChampionsLeague
                          ? (isDark
                              ? Colors.blue.withOpacity(0.08)
                              : const Color(0xFFEFF6FF))
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      isChampionsLeague
                          ? Border.all(
                            color: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
                            width: 1,
                          )
                          : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        team['pos'].toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isChampionsLeague ? Colors.blue : textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: Row(
                        children: [
                          // Team Logo
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child:
                                  team['logo'] != null &&
                                          team['logo'].toString().isNotEmpty
                                      ? Image.network(
                                        team['logo'],
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (c, e, s) => const Icon(
                                              Icons.shield,
                                              size: 12,
                                              color: Colors.grey,
                                            ),
                                      )
                                      : Icon(
                                        Icons.sports_soccer,
                                        size:
                                            12, // Changed from 48 to 12 to fit container
                                        color: secondaryTextColor.withOpacity(
                                          0.5,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              team['display_name'].toString().length > 20
                                  ? team['display_name'].toString().substring(
                                    0,
                                    20,
                                  )
                                  : team['display_name'].toString(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildDataCell(team['p'].toString(), 1, secondaryTextColor),
                    _buildDataCell(team['w'].toString(), 1, secondaryTextColor),
                    _buildDataCell(team['d'].toString(), 1, secondaryTextColor),
                    _buildDataCell(team['l'].toString(), 1, secondaryTextColor),
                    _buildDataCell(
                      team['gd'].toString(),
                      1,
                      secondaryTextColor,
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        team['pts'].toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: GoalioColors.greenAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(
    String text,
    int flex,
    Color color, [
    TextAlign align = TextAlign.center,
  ]) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11,
          color: color,
          letterSpacing: 0.8,
        ),
        textAlign: align,
      ),
    );
  }

  Widget _buildDataCell(String text, int flex, Color color) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTopPlayersTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    return Column(
      children: [
        // Premium Filter Buttons
        Container(
          height: 40,
          margin: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildStatFilterChip(
                AppLocalizations.of(context)!.scorers,
                'goals',
                Icons.sports_soccer,
              ),
              const SizedBox(width: 10),
              _buildStatFilterChip(
                AppLocalizations.of(context)!.assists.toUpperCase(),
                'assists',
                Icons.assistant_navigation,
              ),
              const SizedBox(width: 10),
              _buildStatFilterChip(
                AppLocalizations.of(context)!.redCards,
                'red_cards',
                Icons.style,
              ),
              const SizedBox(width: 10),
              _buildStatFilterChip(
                AppLocalizations.of(context)!.yellowCardsLabel,
                'yellow_cards',
                Icons.style,
              ),
              const SizedBox(width: 10),
              _buildStatFilterChip(
                AppLocalizations.of(context)!.shotsOnTarget,
                'shots_on_target',
                Icons.sports_kabaddi,
              ),
              const SizedBox(width: 10),
              _buildStatFilterChip(
                AppLocalizations.of(context)!.foulsCommitted,
                'fouls_committed',
                Icons.sports,
              ),
              const SizedBox(width: 10),
              _buildStatFilterChip(
                AppLocalizations.of(context)!.foulsWon,
                'fouls_won',
                Icons.sports_handball,
              ),
              const SizedBox(width: 10),
              _buildStatFilterChip(
                AppLocalizations.of(context)!.tackles,
                'tackles',
                Icons.directions_run,
              ),
              const SizedBox(width: 10),
              _buildStatFilterChip(
                AppLocalizations.of(context)!.offsides,
                'offsides',
                Icons.flag,
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: Builder(
            builder: (context) {
              if (_isLoadingPlayers && _topPlayers.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: GoalioColors.greenAccent,
                  ),
                );
              }

              if (_topPlayers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 64,
                        color:
                            isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No player stats available',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final players = _topPlayers[_selectedPlayerStat] ?? [];

              if (players.isEmpty) {
                return Center(
                  child: Text(
                    'No $_selectedPlayerStat data found',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                );
              }

              return ListView.separated(
                controller: _playersListController,
                padding: const EdgeInsets.all(20),
                itemCount: players.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final player = players[index];
                  return _buildPlayerCard(player, index + 1);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatFilterChip(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedPlayerStat == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlayerStat = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? GoalioColors.greenAccent
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: GoalioColors.greenAccent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  isSelected
                      ? Colors.black
                      : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? Colors.black
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(dynamic playerArg, int rank) {
    if (playerArg is! Map) return const SizedBox.shrink();
    final Map<String, dynamic> player = Map<String, dynamic>.from(playerArg);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? Colors.white70 : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withOpacity(0.02)
                : Colors.black.withOpacity(0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      rank <= 3
                          ? [
                            GoalioColors.greenAccent,
                            GoalioColors.greenAccent.withOpacity(0.6),
                          ]
                          : [
                            isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05),
                            isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05),
                          ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$rank'.toArabicNumbers(context),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: rank <= 3 ? Colors.black : textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Player Profile
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: GoalioColors.greenAccent.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child:
                    player['player_image'] != null &&
                            player['player_image'].toString().isNotEmpty
                        ? Image.network(
                          player['player_image'],
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Icon(
                                Icons.person,
                                color: secondaryTextColor,
                                size: 30,
                              ),
                        )
                        : Icon(
                          Icons.person,
                          color: secondaryTextColor,
                          size: 30,
                        ),
              ),
            ),
            const SizedBox(width: 16),

            // Name & Team
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (player['player_name']?.toString() ?? 'Unknown')
                        .toArabicName(context),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    player['team_name']?.toString().toUpperCase() ?? '',
                    style: TextStyle(
                      color: GoalioColors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Stats
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${player['stat_value']}'.toArabicNumbers(context),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  Text(
                    _selectedPlayerStat.toUpperCase(),
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
