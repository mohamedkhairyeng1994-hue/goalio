import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

// Managers & Utils
import 'core/theme/theme_manager.dart';
import 'core/constants/constants.dart';
import 'core/services/api_service.dart';
import 'core/services/widget_bridge.dart';
import 'core/utils/size_config.dart';
import 'core/localization/language_manager.dart';
import 'core/utils/http_overrides.dart';
import 'dart:io';
import 'l10n/app_localizations.dart';

// Screens
import 'screens/news/news_page.dart';
import 'screens/news/news_detail_page.dart';
import 'screens/home/home_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/fixtures/fixtures_page.dart';
import 'screens/leagues/leagues_page.dart';
import 'screens/settings/settings_page.dart';
import 'screens/challenges/challenge_page.dart';
import 'screens/challenges/challenge_providers.dart';
import 'screens/auth/splash_page.dart';
import 'screens/favorites/favorite_teams_page.dart';
import 'screens/fixtures/match_detail_page.dart';
import 'screens/social/social_page.dart';
import 'core/utils/ad_manager.dart';
import 'core/utils/app_update_checker.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Check preference before reporting or handling
  final prefs = await SharedPreferences.getInstance();
  final isEnabled = prefs.getBool('notifications_enabled') ?? true;
  if (!isEnabled) return;

  if (message.messageId != null) {
    // When the app is in the background or killed, we still report as received
    await ApiService.markNotificationAsReceived(message.messageId!);
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// AdMob initialization is decoupled from ATT. The system prompt is requested
// later from Initializer.initState (see [requestAttIfNeeded]) once the app is
// in the .active state — Apple's requestTrackingAuthorization is a silent
// no-op while the app is still launching. AdMob serves non-personalized ads
// until ATT resolves and switches to personalized once consent is granted, so
// initializing first is safe.
Future<void> _initMobileAds() async {
  await MobileAds.instance.initialize();
}

/// Show the ATT system prompt when the iOS user hasn't decided yet. Must be
/// called *after* the first frame has rendered so the UIApplication is in
/// the .active state — otherwise iOS silently no-ops without ever prompting,
/// which is exactly the behavior Apple's reviewer reports.
///
/// The 200ms delay handles a race where the keyWindow's scene activation
/// hasn't fully transitioned by the time addPostFrameCallback fires on
/// certain iPad / iOS 17+ combos.
Future<void> requestAttIfNeeded() async {
  if (!Platform.isIOS) return;
  try {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  } catch (e) {
    if (kDebugMode) debugPrint('ATT request failed: $e');
  }
}

// Lets other screens (e.g. the notifications page) ask the currently-mounted
// MainPage to switch tabs without needing a GlobalKey. MainPage registers its
// handler in initState and clears it in dispose.
void Function(int index)? mainPageTabSwitcher;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    if (kDebugMode) debugPrint("Firebase init failed: $e");
  }

  // Robust SizeConfig initialization
  try {
    final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    if (view != null) {
      final size = view.physicalSize / view.devicePixelRatio;
      SizeConfig.initFromSize(size);
    }
  } catch (e) {
    if (kDebugMode) debugPrint("SizeConfig early init failed: $e");
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Managers (Wait for them to load preferences)
  await Future.wait([
    LanguageManager.initialize(),
    ThemeManager.initialize(),
    _initMobileAds(),
  ]);

  // Push the current API base URL to the home-screen widgets so they don't
  // hardcode an environment. Picks up local in dev, production in release —
  // see ApiConstants.authBaseUrl.
  await WidgetBridge.setBaseUrl(ApiConstants.authBaseUrl);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure the logout callback is registered (moved here to support Hot Reload)
    ApiService.onUnauthorized = () async {
      await ApiService.clearAuth();
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Initializer()),
          (route) => false,
        );
      }
    };

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager(),
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LanguageManager(),
          builder: (context, locale, _) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Goalio',
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              // DARK THEME
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                scaffoldBackgroundColor: const Color(0xFF0F172A),
                primaryColor: const Color(0xFF34D399),
                cardColor: const Color(0xFF1E293B),
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF34D399),
                  secondary: Color(0xFF3B82F6),
                  surface: Color(0xFF1E293B),
                  onSurface: Colors.white,
                ),
                appBarTheme: AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  titleTextStyle: TextStyle(
                    fontFamily: 'RobotoCondensed',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  iconTheme: const IconThemeData(
                    color: GoalioColors.greenAccent,
                  ),
                ),
                useMaterial3: true,
              ),
              // LIGHT THEME
              theme: ThemeData(
                brightness: Brightness.light,
                scaffoldBackgroundColor: const Color(0xFFF1F5F9),
                primaryColor: const Color(0xFF34D399),
                cardColor: Colors.white,
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF34D399),
                  secondary: Color(0xFF3B82F6),
                  surface: Colors.white,
                  onSurface: Color(0xFF0F172A),
                ),
                appBarTheme: AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  titleTextStyle: TextStyle(
                    fontFamily: 'RobotoCondensed',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                  iconTheme: const IconThemeData(
                    color: GoalioColors.greenAccent,
                  ),
                ),
                useMaterial3: true,
              ),
              home: const Initializer(),
            );
          },
        );
      },
    );
  }
}

class Initializer extends StatefulWidget {
  const Initializer({super.key});

  @override
  State<Initializer> createState() => _InitializerState();

  static Future<void> navigateAfterAuth(BuildContext context) async {
    // Show a loading dialog if needed, but here we just fetch profile
    final profile = await ApiService.getUserProfile();
    if (profile != null) {
      final teamsCount = profile['favorite_teams_count'] ?? 0;
      final leaguesCount = profile['favorite_leagues_count'] ?? 0;

      if (context.mounted) {
        if (teamsCount > 0 && leaguesCount > 0) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const Initializer()),
            (_) => false,
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const FavoriteTeamsPage(isOnboarding: true),
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Initializer()),
          (_) => false,
        );
      }
    }
  }
}

class _InitializerState extends State<Initializer> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _hasFavorites = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    // ATT prompt must fire *after* the first frame so iOS sees the app as
    // active — calling it during main() / pre-runApp returns notDetermined
    // without ever displaying the dialog (the App Review rejection cause).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestAttIfNeeded();
    });
  }

  Future<void> _checkAuth() async {
    final token = await ApiService.getToken();
    if (token != null && token.isNotEmpty) {
      final profile = await ApiService.getUserProfile();
      if (profile != null) {
        final teamsCount = profile['favorite_teams_count'] ?? 0;
        final leaguesCount = profile['favorite_leagues_count'] ?? 0;

        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _hasFavorites = teamsCount > 0 && leaguesCount > 0;
            _isLoading = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        _hasFavorites =
            false; // Will be checked again if we fetch profile later
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    if (_isLoading) {
      return const SplashPage();
    }

    if (_isLoggedIn) {
      if (_hasFavorites) {
        return const MainPage();
      } else {
        return const FavoriteTeamsPage(isOnboarding: true);
      }
    }

    return LoginPage(
      onLoginSuccess: () => Initializer.navigateAfterAuth(context),
    );
  }
}

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => MainPageState();
}

class MainPageState extends ConsumerState<MainPage> {
  int _currentIndex = 0;
  final List<int> _navigationHistory = [0];
  // Keys to access screen states for automatic refresh
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();
  final GlobalKey<NewsPageState> _newsKey = GlobalKey<NewsPageState>();
  final GlobalKey<FixturesPageState> _fixturesKey =
      GlobalKey<FixturesPageState>();
  final GlobalKey<LeaguesPageState> _leaguesKey = GlobalKey<LeaguesPageState>();
  final GlobalKey<ChallengePageState> _challengeKey =
      GlobalKey<ChallengePageState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    mainPageTabSwitcher = onDestinationSelected;
    _setupFirebaseMessaging();
    LanguageManager().addListener(_onLanguageChanged);

    // 3. Handle notification that opened the app
    _handleInitialNotification();

    // Pre-load interstitial ad so it's ready for tab switching
    AdManager.loadInterstitial();

    // One-time-per-session update prompt (only shows if backend's min_app_version > installed version)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppUpdateChecker.checkAndPrompt(context);
    });
  }

  @override
  void dispose() {
    if (identical(mainPageTabSwitcher, onDestinationSelected)) {
      mainPageTabSwitcher = null;
    }
    LanguageManager().removeListener(_onLanguageChanged);
    super.dispose();
  }

  Future<void> _handleInitialNotification() async {
    // Check if app was opened via a notification when it was terminated
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationMessage(initialMessage.data);
    }
  }

  void _handleNotificationMessage(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('notifications_enabled') ?? true;
    if (!isEnabled) return;

    final type = data['type'];

    if (type == 'matchday_notification' || type == 'score_notification') {
      final leagueIdStr = data['league_id'];
      final dateStr = data['date'];

      if (leagueIdStr != null) {
        // Find the league and select it
        try {
          final leagueId = int.parse(leagueIdStr);

          // We wait until leagues are available (at most 5 seconds)
          int retries = 0;
          while (ref.read(challengeLeaguesListProvider).isLoading &&
              retries < 10) {
            await Future.delayed(const Duration(milliseconds: 500));
            retries++;
          }

          final leaguesAsync = ref.read(challengeLeaguesListProvider);
          leaguesAsync.whenData((leagues) {
            final league = leagues.firstWhere((l) => l.id == leagueId);
            ref
                .read(selectedChallengeLeagueProvider.notifier)
                .selectLeague(league);

            // If it's a score notification and we have a date, jump to it
            if (type == 'score_notification' && dateStr != null) {
              try {
                final date = DateTime.parse(dateStr);
                ref
                    .read(selectedChallengeDateProvider.notifier)
                    .selectDate(date);
              } catch (_) {}
            }
          });
        } catch (e) {
          debugPrint("Error selecting league from notification: $e");
        }
      }

      // Navigate to Challenge Tab
      onDestinationSelected(3);
    } else if (type == 'match_status' || type == 'match_event') {
      final matchIdStr = data['match_id'];
      if (matchIdStr != null) {
        // Fetch the match object and navigate to MatchDetailPage
        ApiService.getMatchById(matchIdStr).then((match) {
          if (match != null && navigatorKey.currentState != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => MatchDetailPage(match: match),
              ),
            );
          }
        });
      }
    } else if (type == 'league_news') {
      final newsIdStr = data['news_id'];
      if (newsIdStr == null) return;

      final newsId = int.tryParse(newsIdStr.toString());
      if (newsId == null) return;

      ApiService.getNewsDetail(newsId).then((article) {
        if (article != null && navigatorKey.currentState != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => NewsDetailPage(article: Map<String, dynamic>.from(article)),
            ),
          );
        }
      });
    }
  }

  Future<void> _syncTokenOnLanguageChange() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          return;
        }
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        ApiService.updateFcmToken(token);
      }
    } catch (e) {
      debugPrint("Failed to sync FCM token on language change: $e");
    }
  }

  void _onLanguageChanged() {
    if (mounted) {
      // Sync language change with backend for push notifications
      _syncTokenOnLanguageChange();

      // Refresh all screens that support it
      _homeKey.currentState?.resetState();
      _homeKey.currentState?.loadData(forceScrape: true);

      _fixturesKey.currentState?.resetState();
      _fixturesKey.currentState?.refreshMatches();

      _newsKey.currentState?.resetState();
      _newsKey.currentState?.loadNews(silent: true);

      _leaguesKey.currentState?.resetState();
      _leaguesKey.currentState?.refreshData(silent: true);
      // Refresh Challenge providers silenty (keep old data visible while loading new language)
      // ignore: unused_result
      ref.refresh(selectedChallengeDateProvider);
      // ignore: unused_result
      ref.refresh(allChallengeMatchesProvider);
      // ignore: unused_result
      ref.refresh(challengeDataRawProvider);
      // ignore: unused_result
      ref.refresh(groupsProvider);
      // ignore: unused_result
      ref.refresh(userTotalPointsProvider);
      // ignore: unused_result
      ref.refresh(groupRanksProvider);
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 1. Create a Notification Channel for Android (Required for API 26+).
      // NOTE: channel settings (sound, importance) are immutable once created on a device,
      // so we use a versioned id ("_v2") to force-recreate with sound enabled when the
      // previous channel was installed without it.
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'goalio_notifications_v2', // Must match the 'channel_id' in the Laravel backend
        'Goalio Notifications',
        description: 'Match reminders, live events, and campaign alerts.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // 1.5 Initialize Local Notifications (use monochrome notification icon, not the full-color launcher)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/notification_logo');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            try {
              final Map<String, dynamic> data = jsonDecode(response.payload!);
              _handleNotificationMessage(data);
            } catch (e) {
              debugPrint("Error handling local notification click: $e");
            }
          }
        },
      );

      // 2. Set foreground notification presentation options
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await messaging.getToken();
        if (token != null) {
          await ApiService.updateFcmToken(token);
        }

        // 1. Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          final prefs = await SharedPreferences.getInstance();
          final isEnabled = prefs.getBool('notifications_enabled') ?? true;
          if (!isEnabled) return;

          if (message.messageId != null) {
            ApiService.markNotificationAsReceived(message.messageId!);
          }

          // Force local notification presentation for ALL messages in foreground
          // Handle both 'notification' payload and 'data' payload for display
          String? title = message.notification?.title ?? message.data['title'];
          String? body = message.notification?.body ?? message.data['body'];

          if (title != null || body != null) {
            final notificationId =
                message.messageId != null
                    ? message.messageId.hashCode
                    : DateTime.now().millisecond;

            flutterLocalNotificationsPlugin.show(
              id: notificationId,
              title: title,
              body: body,
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                  enableVibration: true,
                  icon: '@drawable/notification_logo',
                ),
                iOS: const DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              payload: jsonEncode(message.data),
            );
          }
        });

        // 2. Handle background message clicks
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotificationMessage(message.data);
        });

        // Listen for token updates
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          ApiService.updateFcmToken(newToken);
        });
      }
    } catch (e) {
      debugPrint("FCM Setup Error: $e");
    }
  }

  Widget _buildSettingsDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SettingsPage(
        onLogout: () async {
          await ApiService.clearToken();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder:
                    (context) => LoginPage(
                      onLoginSuccess:
                          () => Initializer.navigateAfterAuth(context),
                    ),
              ),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        // 1. Let current screen handle back press if it has internal navigation
        if (_currentIndex == 3) {
          if (_challengeKey.currentState?.onBackPressed() ?? false) {
            return;
          }
        }
        if (_currentIndex == 4) {
          if (_leaguesKey.currentState?.onBackPressed() ?? false) {
            return;
          }
        }

        // 2. Go back through navigation history
        if (_navigationHistory.length > 1) {
          setState(() {
            _navigationHistory.removeLast();
            _currentIndex = _navigationHistory.last;
          });
          return;
        }

        // 3. If on non-home tab and history is empty, go to home
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _navigationHistory.add(0);
          });
          return;
        }

        // 4. Default: Exit the app
        SystemNavigator.pop();
      },
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: _buildSettingsDrawer(),
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  HomePage(
                    key: _homeKey,
                    onNavigateToFixtures: () => onDestinationSelected(1),
                    onNavigateToNews: () => onDestinationSelected(2),
                    onNavigateToLeagues: () => onDestinationSelected(4),
                    onLeagueTap: (league) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LeaguesPage(initialLeague: league),
                        ),
                      );
                    },
                    onOpenSettings: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
                  FixturesPage(key: _fixturesKey),
                  NewsPage(key: _newsKey),
                  ChallengePage(key: _challengeKey),
                  LeaguesPage(key: _leaguesKey),
                ],
              ),
            ),
          ],
        ),
        extendBody: true,
        bottomNavigationBar: _buildBeautifulNavBar(),
        floatingActionButton: _buildSocialFab(),
      ),
    );
  }

  Widget _buildSocialFab() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => const SocialPage()),
        );
      },
      child: Container(
        width: 60.w,
        height: 60.w,
        margin: EdgeInsets.only(bottom: 12.h, right: 4.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GoalioColors.greenAccent,
              Color(0xFF0F766E), // Deep elegant green
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: GoalioColors.greenAccent.withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.dynamic_feed,
          color: Colors.white,
          size: 28.w,
        ),
      ),
    );
  }

  Widget _buildBeautifulNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 55.h + bottomPadding,
      padding: EdgeInsets.only(bottom: (bottomPadding - 8).clamp(0.0, double.infinity)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.w)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                0,
                Icons.home_outlined,
                Icons.home,
                AppLocalizations.of(context)?.home ?? 'Home',
              ),
              _buildNavItem(
                1,
                Icons.sports_soccer_outlined,
                Icons.sports_soccer,
                AppLocalizations.of(context)?.fixtures ?? 'Fixtures',
              ),
              SizedBox(width: 50.w), // Space for center button
              _buildNavItem(
                2,
                Icons.newspaper_outlined,
                Icons.newspaper,
                AppLocalizations.of(context)?.news ?? 'News',
              ),
              _buildNavItem(
                4,
                Icons.groups_outlined,
                Icons.groups,
                AppLocalizations.of(context)?.leagues ?? 'Leagues',
              ),
            ],
          ),
          Positioned(top: -18.h, child: _buildCenterChallengeButton()),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 52.w, // Reduced width to accommodate more items
      child: GestureDetector(
        onTap: () => onDestinationSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color:
                  isSelected
                      ? GoalioColors.greenAccent
                      : (isDark ? Colors.white60 : Colors.black45),
              size: 26.w,
            ),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? GoalioColors.greenAccent
                        : (isDark ? Colors.white60 : Colors.black45),
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            SizedBox(height: 6.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterChallengeButton() {
    final isSelected = _currentIndex == 3;

    return GestureDetector(
      onTap: () => onDestinationSelected(3),
      child: Container(
        width: 58.w,
        height: 58.w,
        decoration: BoxDecoration(
          color:
              isSelected ? GoalioColors.greenAccent : const Color(0xFF1E293B),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: GoalioColors.greenAccent.withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: GoalioColors.greenAccent.withValues(alpha: isSelected ? 0.8 : 0.2),
            width: 3,
          ),
        ),
        child: Icon(
          Icons.local_play,
          color: isSelected ? Colors.white : GoalioColors.greenAccent,
          size: 30.w,
        ),
      ),
    );
  }


  void onDestinationSelected(int index) {
    bool isSameTab = _currentIndex == index;

    // INTERSTITIAL DEACTIVATED (Keeping code for future use)
    // if (!isSameTab && index > 0 && index % 2 == 0) {
    //   AdManager.showInterstitial(() {
    //     if (mounted) _handleTabSwitch(index, isSameTab);
    //   });
    // } else {
    //   _handleTabSwitch(index, isSameTab);
    // }
    
    _handleTabSwitch(index, isSameTab);
  }

  void _handleTabSwitch(int index, bool isSameTab) {
    // Reset/Refresh logic
    switch (index) {
      case 0:
        if (isSameTab) {
          _homeKey.currentState?.resetState();
          _homeKey.currentState?.loadData(forceScrape: true, silent: true);
        } else {
          _homeKey.currentState?.loadData(silent: true);
        }
        break;
      case 1:
        if (isSameTab) {
          _fixturesKey.currentState?.resetState();
          _fixturesKey.currentState?.refreshMatches();
        } else {
          _fixturesKey.currentState?.refreshMatches();
        }
        break;
      case 2:
        if (isSameTab) {
          _newsKey.currentState?.resetState();
          _newsKey.currentState?.loadNews(forceScrape: true, silent: true);
        } else {
          // When navigating to the news tab, run a quick scraper pass and append new items.
          _newsKey.currentState?.appendLatestNews(silent: true);
        }
        break;
      case 3:
        // Always refresh leagues list and active dates when navigating to/clicking challenge
        // ignore: unused_result
        ref.refresh(challengeLeaguesListProvider);
        // ignore: unused_result
        ref.refresh(allChallengeMatchesProvider);

        if (isSameTab) {
          // If already on challenge tab, refresh the data
          // ignore: unused_result
          ref.refresh(challengeDataRawProvider);
          // ignore: unused_result
          ref.refresh(groupsProvider);
          // ignore: unused_result
          ref.refresh(userTotalPointsProvider);

          // Return to main challenge view if we were in a group leaderboard, as requested
          ref.read(selectedGroupProvider.notifier).selectGroup(null);

          // Force jump to latest/today date
          ref.read(selectedChallengeDateProvider.notifier).jumpToLatest();
        } else {
          // Navigating to challenge tab from another tab
          // Ensure we also refresh dashboard specific data
          // ignore: unused_result
          ref.refresh(challengeDataRawProvider);
          // ignore: unused_result
          ref.refresh(userTotalPointsProvider);

          // Return to main challenge view if we were in a group leaderboard, as requested
          ref.read(selectedGroupProvider.notifier).selectGroup(null);

          // Also ensure we go to latest date
          ref.read(selectedChallengeDateProvider.notifier).jumpToLatest();
        }
        break;
      case 4:
        if (isSameTab) {
          _leaguesKey.currentState?.resetState();
          _leaguesKey.currentState?.refreshData(silent: true);
        } else {
          _leaguesKey.currentState?.refreshData(silent: true);
        }
        break;
    }

    if (isSameTab) return;

    setState(() {
      _currentIndex = index;
      _navigationHistory.remove(index); // Remove if exists to move to end
      _navigationHistory.add(index);
    });
  }
}
