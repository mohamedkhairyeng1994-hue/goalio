import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @teamsManager.
  ///
  /// In en, this message translates to:
  /// **'Teams Manager'**
  String get teamsManager;

  /// No description provided for @leaguesManager.
  ///
  /// In en, this message translates to:
  /// **'Leagues Manager'**
  String get leaguesManager;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @goalio.
  ///
  /// In en, this message translates to:
  /// **'Goalio'**
  String get goalio;

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Your ultimate football companion'**
  String get appSlogan;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @fixtures.
  ///
  /// In en, this message translates to:
  /// **'Fixtures'**
  String get fixtures;

  /// No description provided for @news.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get news;

  /// No description provided for @leagues.
  ///
  /// In en, this message translates to:
  /// **'Leagues'**
  String get leagues;

  /// No description provided for @featuredMatch.
  ///
  /// In en, this message translates to:
  /// **'FEATURED MATCH'**
  String get featuredMatch;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @upcomingMatches.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING MATCHES'**
  String get upcomingMatches;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @noMatchesToday.
  ///
  /// In en, this message translates to:
  /// **'No matches scheduled today.'**
  String get noMatchesToday;

  /// No description provided for @trendingNews.
  ///
  /// In en, this message translates to:
  /// **'TRENDING NEWS'**
  String get trendingNews;

  /// No description provided for @noNewsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No news available.'**
  String get noNewsAvailable;

  /// No description provided for @noNewsAvailableFor.
  ///
  /// In en, this message translates to:
  /// **'No news available for {league}'**
  String noNewsAvailableFor(Object league);

  /// No description provided for @leagueStandings.
  ///
  /// In en, this message translates to:
  /// **'LEAGUES STANDINGS'**
  String get leagueStandings;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @fixturesTitle.
  ///
  /// In en, this message translates to:
  /// **'FIXTURES'**
  String get fixturesTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for any team...'**
  String get searchHint;

  /// No description provided for @sortByFavorite.
  ///
  /// In en, this message translates to:
  /// **'Sort by Favorite'**
  String get sortByFavorite;

  /// No description provided for @sortAZ.
  ///
  /// In en, this message translates to:
  /// **'Sort A-Z'**
  String get sortAZ;

  /// No description provided for @favoriteMatches.
  ///
  /// In en, this message translates to:
  /// **'FAVORITE MATCHES'**
  String get favoriteMatches;

  /// No description provided for @matches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matches;

  /// No description provided for @latestNews.
  ///
  /// In en, this message translates to:
  /// **'LATEST NEWS'**
  String get latestNews;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @newsTag.
  ///
  /// In en, this message translates to:
  /// **'NEWS'**
  String get newsTag;

  /// No description provided for @leaguesTitle.
  ///
  /// In en, this message translates to:
  /// **'LEAGUES'**
  String get leaguesTitle;

  /// No description provided for @searchLeaguesHint.
  ///
  /// In en, this message translates to:
  /// **'Search leagues...'**
  String get searchLeaguesHint;

  /// No description provided for @noLeaguesAvailable.
  ///
  /// In en, this message translates to:
  /// **'NO LEAGUES AVAILABLE'**
  String get noLeaguesAvailable;

  /// No description provided for @standingsTab.
  ///
  /// In en, this message translates to:
  /// **'STANDINGS'**
  String get standingsTab;

  /// No description provided for @playersTab.
  ///
  /// In en, this message translates to:
  /// **'PLAYERS'**
  String get playersTab;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check Again'**
  String get checkAgain;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @assists.
  ///
  /// In en, this message translates to:
  /// **'Assists'**
  String get assists;

  /// No description provided for @apps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get apps;

  /// No description provided for @challengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challengeTitle;

  /// No description provided for @predictions.
  ///
  /// In en, this message translates to:
  /// **'Predictions'**
  String get predictions;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'OVERVIEW'**
  String get overview;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'TIMELINE'**
  String get timeline;

  /// No description provided for @lineup.
  ///
  /// In en, this message translates to:
  /// **'LINEUP'**
  String get lineup;

  /// No description provided for @endOfMatch.
  ///
  /// In en, this message translates to:
  /// **'End of match'**
  String get endOfMatch;

  /// No description provided for @kickOff.
  ///
  /// In en, this message translates to:
  /// **'Kick off'**
  String get kickOff;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'LEADERBOARD'**
  String get leaderboard;

  /// No description provided for @createLeague.
  ///
  /// In en, this message translates to:
  /// **'Create Custom League'**
  String get createLeague;

  /// No description provided for @joinLeague.
  ///
  /// In en, this message translates to:
  /// **'Join League'**
  String get joinLeague;

  /// No description provided for @leagueName.
  ///
  /// In en, this message translates to:
  /// **'League Name'**
  String get leagueName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow your favorite matches'**
  String get signInSubtitle;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @loginLabel.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get loginLabel;

  /// No description provided for @signUpLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLabel;

  /// No description provided for @forgotPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordLabel;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'OR CONTINUE WITH'**
  String get orContinueWith;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCOUNT'**
  String get createAccount;

  /// No description provided for @joinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join the Goalio community today'**
  String get joinCommunity;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @halftime.
  ///
  /// In en, this message translates to:
  /// **'HT'**
  String get halftime;

  /// No description provided for @fulltime.
  ///
  /// In en, this message translates to:
  /// **'FT'**
  String get fulltime;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'RESET PASSWORD'**
  String get resetPassword;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'SEND RESET LINK'**
  String get sendResetLink;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmail;

  /// No description provided for @verificationCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent! Please check your email.'**
  String get verificationCodeSent;

  /// No description provided for @matchOverview.
  ///
  /// In en, this message translates to:
  /// **'MATCH OVERVIEW'**
  String get matchOverview;

  /// No description provided for @predictMatch.
  ///
  /// In en, this message translates to:
  /// **'PREDICT MATCH'**
  String get predictMatch;

  /// No description provided for @randomizeAnswers.
  ///
  /// In en, this message translates to:
  /// **'Randomize Answers'**
  String get randomizeAnswers;

  /// No description provided for @answersRandomized.
  ///
  /// In en, this message translates to:
  /// **'All answers randomized! 🎲'**
  String get answersRandomized;

  /// No description provided for @answerAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Please answer at least one question.'**
  String get answerAtLeastOne;

  /// No description provided for @predictionsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Predictions submitted successfully!'**
  String get predictionsSubmitted;

  /// No description provided for @submitPrediction.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT PREDICTION'**
  String get submitPrediction;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @enterPredictionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your prediction'**
  String get enterPredictionHint;

  /// No description provided for @pickYourTeams.
  ///
  /// In en, this message translates to:
  /// **'PICK YOUR TEAMS'**
  String get pickYourTeams;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(Object count);

  /// No description provided for @searchHintTeams.
  ///
  /// In en, this message translates to:
  /// **'Search for any team...'**
  String get searchHintTeams;

  /// No description provided for @showingSelectedTeamsOnly.
  ///
  /// In en, this message translates to:
  /// **'Showing selected teams only'**
  String get showingSelectedTeamsOnly;

  /// No description provided for @noSelectedTeamsFound.
  ///
  /// In en, this message translates to:
  /// **'No selected teams found'**
  String get noSelectedTeamsFound;

  /// No description provided for @noTeamsFound.
  ///
  /// In en, this message translates to:
  /// **'No teams found'**
  String get noTeamsFound;

  /// No description provided for @selectAtLeastOneTeam.
  ///
  /// In en, this message translates to:
  /// **'Select at least one team'**
  String get selectAtLeastOneTeam;

  /// No description provided for @saveChangesCount.
  ///
  /// In en, this message translates to:
  /// **'Save Changes ({count})'**
  String saveChangesCount(Object count);

  /// No description provided for @selectFavoriteLeagues.
  ///
  /// In en, this message translates to:
  /// **'Select Favorite Leagues'**
  String get selectFavoriteLeagues;

  /// No description provided for @searchHintLeagues.
  ///
  /// In en, this message translates to:
  /// **'Search leagues...'**
  String get searchHintLeagues;

  /// No description provided for @showingSelectedLeaguesOnly.
  ///
  /// In en, this message translates to:
  /// **'Showing selected leagues only'**
  String get showingSelectedLeaguesOnly;

  /// No description provided for @noSelectedLeaguesFound.
  ///
  /// In en, this message translates to:
  /// **'No selected leagues found'**
  String get noSelectedLeaguesFound;

  /// No description provided for @noLeaguesFound.
  ///
  /// In en, this message translates to:
  /// **'No leagues found'**
  String get noLeaguesFound;

  /// No description provided for @showAllLeagues.
  ///
  /// In en, this message translates to:
  /// **'Show all leagues'**
  String get showAllLeagues;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @continueWithCount.
  ///
  /// In en, this message translates to:
  /// **'Continue ({count} selected)'**
  String continueWithCount(Object count);

  /// No description provided for @selectAtLeastOneLeague.
  ///
  /// In en, this message translates to:
  /// **'Select at least one league'**
  String get selectAtLeastOneLeague;

  /// No description provided for @savedLeaguesSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully saved {count} favorite leagues!'**
  String savedLeaguesSuccess(Object count);

  /// No description provided for @errorLoadingLeagues.
  ///
  /// In en, this message translates to:
  /// **'Error loading leagues'**
  String get errorLoadingLeagues;

  /// No description provided for @errorLoadingTeams.
  ///
  /// In en, this message translates to:
  /// **'Error loading teams'**
  String get errorLoadingTeams;

  /// No description provided for @errorSavingLeagues.
  ///
  /// In en, this message translates to:
  /// **'Error saving leagues'**
  String get errorSavingLeagues;

  /// No description provided for @errorSavingTeams.
  ///
  /// In en, this message translates to:
  /// **'Error saving teams'**
  String get errorSavingTeams;

  /// No description provided for @savedTeamsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully saved {count} favorite teams!'**
  String savedTeamsSuccess(Object count);

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'NEW PASSWORD'**
  String get newPassword;

  /// No description provided for @resetCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {email} and your new password.'**
  String resetCodeSubtitle(Object email);

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'UPDATE PASSWORD'**
  String get updatePassword;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully! You can now log in.'**
  String get passwordResetSuccess;

  /// No description provided for @matchday.
  ///
  /// In en, this message translates to:
  /// **'MATCHDAY'**
  String get matchday;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'POINTS'**
  String get points;

  /// No description provided for @pts.
  ///
  /// In en, this message translates to:
  /// **'PTS'**
  String get pts;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get start;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'EDIT'**
  String get edit;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'OVERALL'**
  String get overall;

  /// No description provided for @predictAndEarn.
  ///
  /// In en, this message translates to:
  /// **'PREDICT & EARN MATCHDAY POINTS'**
  String get predictAndEarn;

  /// No description provided for @leagueCreated.
  ///
  /// In en, this message translates to:
  /// **'League Created!'**
  String get leagueCreated;

  /// No description provided for @enterLeagueName.
  ///
  /// In en, this message translates to:
  /// **'Enter league name'**
  String get enterLeagueName;

  /// No description provided for @leagueCreatedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your league has been created. Share this code with your friends to join:'**
  String get leagueCreatedSubtitle;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard!'**
  String get codeCopied;

  /// No description provided for @joinLeagueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the unique league code to join your friends.'**
  String get joinLeagueSubtitle;

  /// No description provided for @leagueCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. GX-1234'**
  String get leagueCodeHint;

  /// No description provided for @joinedLeagueSuccess.
  ///
  /// In en, this message translates to:
  /// **'Joined league {code} successfully!'**
  String joinedLeagueSuccess(Object code);

  /// No description provided for @premierLeague.
  ///
  /// In en, this message translates to:
  /// **'ENGLAND - PREMIER LEAGUE'**
  String get premierLeague;

  /// No description provided for @noMatchesOnDate.
  ///
  /// In en, this message translates to:
  /// **'No Premier League matches scheduled\nfor this date.'**
  String get noMatchesOnDate;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No Matches Found'**
  String get noMatchesFound;

  /// No description provided for @joinLeagueLabel.
  ///
  /// In en, this message translates to:
  /// **'JOIN LEAGUE'**
  String get joinLeagueLabel;

  /// No description provided for @createLeagueLabel.
  ///
  /// In en, this message translates to:
  /// **'CREATE LEAGUE'**
  String get createLeagueLabel;

  /// No description provided for @myClassicLeagues.
  ///
  /// In en, this message translates to:
  /// **'MY CLASSIC LEAGUES'**
  String get myClassicLeagues;

  /// No description provided for @generalLeagues.
  ///
  /// In en, this message translates to:
  /// **'GENERAL LEAGUES'**
  String get generalLeagues;

  /// No description provided for @playersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String playersCount(Object count);

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'RANK'**
  String get rank;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'LAST UPDATED: {time}'**
  String lastUpdated(Object time);

  /// No description provided for @pos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get pos;

  /// No description provided for @playerMe.
  ///
  /// In en, this message translates to:
  /// **'ME'**
  String get playerMe;

  /// No description provided for @playerYou.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get playerYou;

  /// No description provided for @globalRank.
  ///
  /// In en, this message translates to:
  /// **'GLOBAL RANK #{rank}'**
  String globalRank(Object rank);

  /// No description provided for @errorLoadingLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Error loading leaderboard'**
  String get errorLoadingLeaderboard;

  /// No description provided for @selectMode.
  ///
  /// In en, this message translates to:
  /// **'SELECT MODE'**
  String get selectMode;

  /// No description provided for @fullMatchday.
  ///
  /// In en, this message translates to:
  /// **'Full Matchday'**
  String get fullMatchday;

  /// No description provided for @fullMatchdaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Predict all 10 matches for maximum points.'**
  String get fullMatchdaySubtitle;

  /// No description provided for @activeModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active Mode'**
  String get activeModeSubtitle;

  /// No description provided for @topFixtures.
  ///
  /// In en, this message translates to:
  /// **'Top 5 Fixtures'**
  String get topFixtures;

  /// No description provided for @topFixturesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Focus on the biggest games of the week.'**
  String get topFixturesSubtitle;

  /// No description provided for @rivalryRound.
  ///
  /// In en, this message translates to:
  /// **'Rivalry Round'**
  String get rivalryRound;

  /// No description provided for @rivalryRoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Double points on derby matches.'**
  String get rivalryRoundSubtitle;

  /// No description provided for @couldNotLoadMatches.
  ///
  /// In en, this message translates to:
  /// **'Could not load matches.'**
  String get couldNotLoadMatches;

  /// No description provided for @noLiveMatches.
  ///
  /// In en, this message translates to:
  /// **'No Live Matches'**
  String get noLiveMatches;

  /// No description provided for @noLiveMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'There are no matches currently in progress.'**
  String get noLiveMatchesSubtitle;

  /// No description provided for @noFavoriteMatches.
  ///
  /// In en, this message translates to:
  /// **'No Favorite Matches'**
  String get noFavoriteMatches;

  /// No description provided for @noFavoriteMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'None of your favorite teams have matches scheduled.'**
  String get noFavoriteMatchesSubtitle;

  /// No description provided for @noMatchesScheduled.
  ///
  /// In en, this message translates to:
  /// **'No matches scheduled for {date}.'**
  String noMatchesScheduled(Object date);

  /// No description provided for @noMatchesFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try selecting different filters or checking all leagues.'**
  String get noMatchesFoundSubtitle;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @postponed.
  ///
  /// In en, this message translates to:
  /// **'Postponed'**
  String get postponed;

  /// No description provided for @suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspension'**
  String get suspended;

  /// No description provided for @byAuthor.
  ///
  /// In en, this message translates to:
  /// **'By {author}'**
  String byAuthor(Object author);

  /// No description provided for @fullContentNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Full content is not available for this article.'**
  String get fullContentNotAvailable;

  /// No description provided for @noTitle.
  ///
  /// In en, this message translates to:
  /// **'No Title'**
  String get noTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @vs.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get vs;

  /// No description provided for @fullStory.
  ///
  /// In en, this message translates to:
  /// **'Full Story'**
  String get fullStory;

  /// No description provided for @away.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get away;

  /// No description provided for @homeTeam.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTeam;

  /// No description provided for @awayTeam.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get awayTeam;

  /// No description provided for @noMatchDetails.
  ///
  /// In en, this message translates to:
  /// **'No match details link available for this match.'**
  String get noMatchDetails;

  /// No description provided for @failedToLoadDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load match details'**
  String get failedToLoadDetails;

  /// No description provided for @serverConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to server.'**
  String get serverConnectionError;

  /// No description provided for @matchStats.
  ///
  /// In en, this message translates to:
  /// **'MATCH STATS'**
  String get matchStats;

  /// No description provided for @matchInfoNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Match information is not available yet.\nCheck back closer to kick-off.'**
  String get matchInfoNotAvailable;

  /// No description provided for @matchOverviewLabel.
  ///
  /// In en, this message translates to:
  /// **'MATCH OVERVIEW'**
  String get matchOverviewLabel;

  /// No description provided for @matchStatsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Match statistics will appear here once available.'**
  String get matchStatsNotAvailable;

  /// No description provided for @matchTimeline.
  ///
  /// In en, this message translates to:
  /// **'MATCH TIMELINE'**
  String get matchTimeline;

  /// No description provided for @timelineKey.
  ///
  /// In en, this message translates to:
  /// **'Timeline Key'**
  String get timelineKey;

  /// No description provided for @goalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalLabel;

  /// No description provided for @ownGoal.
  ///
  /// In en, this message translates to:
  /// **'Own goal'**
  String get ownGoal;

  /// No description provided for @assist.
  ///
  /// In en, this message translates to:
  /// **'Assist'**
  String get assist;

  /// No description provided for @secondYellow.
  ///
  /// In en, this message translates to:
  /// **'Second yellow'**
  String get secondYellow;

  /// No description provided for @injury.
  ///
  /// In en, this message translates to:
  /// **'Injury'**
  String get injury;

  /// No description provided for @penaltyGoal.
  ///
  /// In en, this message translates to:
  /// **'Penalty goal'**
  String get penaltyGoal;

  /// No description provided for @penaltyMissed.
  ///
  /// In en, this message translates to:
  /// **'Penalty missed'**
  String get penaltyMissed;

  /// No description provided for @redCard.
  ///
  /// In en, this message translates to:
  /// **'Red card'**
  String get redCard;

  /// No description provided for @redCards.
  ///
  /// In en, this message translates to:
  /// **'Red Cards'**
  String get redCards;

  /// No description provided for @yellowCard.
  ///
  /// In en, this message translates to:
  /// **'Yellow card'**
  String get yellowCard;

  /// No description provided for @yellowCardsLabel.
  ///
  /// In en, this message translates to:
  /// **'Yellow Cards'**
  String get yellowCardsLabel;

  /// No description provided for @substitutionLabel.
  ///
  /// In en, this message translates to:
  /// **'Substitution'**
  String get substitutionLabel;

  /// No description provided for @varLabel.
  ///
  /// In en, this message translates to:
  /// **'VAR'**
  String get varLabel;

  /// No description provided for @tvChannelsLabel.
  ///
  /// In en, this message translates to:
  /// **'TV CHANNELS'**
  String get tvChannelsLabel;

  /// No description provided for @teamForm.
  ///
  /// In en, this message translates to:
  /// **'TEAM FORM'**
  String get teamForm;

  /// No description provided for @last5Matches.
  ///
  /// In en, this message translates to:
  /// **'Last 5 Matches'**
  String get last5Matches;

  /// No description provided for @teamLineups.
  ///
  /// In en, this message translates to:
  /// **'TEAM LINEUPS'**
  String get teamLineups;

  /// No description provided for @lineupsLabel.
  ///
  /// In en, this message translates to:
  /// **'LINEUPS'**
  String get lineupsLabel;

  /// No description provided for @benchLabel.
  ///
  /// In en, this message translates to:
  /// **'Substitute Bench'**
  String get benchLabel;

  /// No description provided for @playedShort.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get playedShort;

  /// No description provided for @wonShort.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get wonShort;

  /// No description provided for @drawnShort.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get drawnShort;

  /// No description provided for @lostShort.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get lostShort;

  /// No description provided for @goalDiffShort.
  ///
  /// In en, this message translates to:
  /// **'GD'**
  String get goalDiffShort;

  /// No description provided for @ptsShort.
  ///
  /// In en, this message translates to:
  /// **'PTS'**
  String get ptsShort;

  /// No description provided for @noStandingsData.
  ///
  /// In en, this message translates to:
  /// **'NO STANDINGS DATA'**
  String get noStandingsData;

  /// No description provided for @liveUpdatesSoon.
  ///
  /// In en, this message translates to:
  /// **'Live updates will appear here soon'**
  String get liveUpdatesSoon;

  /// No description provided for @scorers.
  ///
  /// In en, this message translates to:
  /// **'SCORERS'**
  String get scorers;

  /// No description provided for @shotsOnTarget.
  ///
  /// In en, this message translates to:
  /// **'SHOTS'**
  String get shotsOnTarget;

  /// No description provided for @foulsCommitted.
  ///
  /// In en, this message translates to:
  /// **'FOULS COMMITTED'**
  String get foulsCommitted;

  /// No description provided for @foulsWon.
  ///
  /// In en, this message translates to:
  /// **'FOULS WON'**
  String get foulsWon;

  /// No description provided for @tackles.
  ///
  /// In en, this message translates to:
  /// **'TACKLES'**
  String get tackles;

  /// No description provided for @offsides.
  ///
  /// In en, this message translates to:
  /// **'OFFSIDES'**
  String get offsides;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String hoursShort(Object count);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String minutesShort(Object count);

  /// No description provided for @browseTeams.
  ///
  /// In en, this message translates to:
  /// **'Browse Teams'**
  String get browseTeams;

  /// No description provided for @tbd.
  ///
  /// In en, this message translates to:
  /// **'TBD'**
  String get tbd;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get notStarted;

  /// No description provided for @ns.
  ///
  /// In en, this message translates to:
  /// **'NS'**
  String get ns;

  /// No description provided for @fixture.
  ///
  /// In en, this message translates to:
  /// **'FIXTURE'**
  String get fixture;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'RESULT'**
  String get result;

  /// No description provided for @aet.
  ///
  /// In en, this message translates to:
  /// **'AET'**
  String get aet;

  /// No description provided for @pen.
  ///
  /// In en, this message translates to:
  /// **'PEN'**
  String get pen;

  /// No description provided for @errorFetchingQuestions.
  ///
  /// In en, this message translates to:
  /// **'Error fetching questions: {error}'**
  String errorFetchingQuestions(Object error);

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(Object error);

  /// No description provided for @closeGamePrediction.
  ///
  /// In en, this message translates to:
  /// **'It will be a very close game.'**
  String get closeGamePrediction;

  /// No description provided for @manyGoalsPrediction.
  ///
  /// In en, this message translates to:
  /// **'I expect many goals today!'**
  String get manyGoalsPrediction;

  /// No description provided for @tacticalMasterclassPrediction.
  ///
  /// In en, this message translates to:
  /// **'A tactical masterclass.'**
  String get tacticalMasterclassPrediction;

  /// No description provided for @hardToPredictPrediction.
  ///
  /// In en, this message translates to:
  /// **'Hard to predict this one.'**
  String get hardToPredictPrediction;

  /// No description provided for @oneTeamDominatePrediction.
  ///
  /// In en, this message translates to:
  /// **'One team will easily dominate.'**
  String get oneTeamDominatePrediction;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @noLeaguesFoundMatching.
  ///
  /// In en, this message translates to:
  /// **'No results match your search term \"{query}\". Try a different spelling or clearer name.'**
  String noLeaguesFoundMatching(Object query);

  /// No description provided for @noLeaguesInDatabase.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any leagues in the database. Please try scraping some data or check your connection.'**
  String get noLeaguesInDatabase;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clearSearch;

  /// No description provided for @failedToLoadNews.
  ///
  /// In en, this message translates to:
  /// **'Failed to load news'**
  String get failedToLoadNews;

  /// No description provided for @modeSelected.
  ///
  /// In en, this message translates to:
  /// **'{mode} selected'**
  String modeSelected(Object mode);

  /// No description provided for @drawLabel.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get drawLabel;

  /// No description provided for @noneLabel.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneLabel;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get enterName;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @feedbackAndSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Suggestions'**
  String get feedbackAndSuggestions;

  /// No description provided for @feedbackAndSuggestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us improve Goalio by sharing your thoughts'**
  String get feedbackAndSuggestionsSubtitle;

  /// No description provided for @feedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'We value your feedback! Whether it\'s a suggestion for a new feature or a complaint about an issue, please let us know.'**
  String get feedbackDescription;

  /// No description provided for @feedbackType.
  ///
  /// In en, this message translates to:
  /// **'FEEDBACK TYPE'**
  String get feedbackType;

  /// No description provided for @suggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get suggestion;

  /// No description provided for @complaint.
  ///
  /// In en, this message translates to:
  /// **'Complaint'**
  String get complaint;

  /// No description provided for @feedbackContent.
  ///
  /// In en, this message translates to:
  /// **'YOUR MESSAGE'**
  String get feedbackContent;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Write your feedback here (minimum 5 characters)...'**
  String get feedbackHint;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT'**
  String get submit;

  /// No description provided for @pleaseEnterFeedback.
  ///
  /// In en, this message translates to:
  /// **'Please enter your feedback'**
  String get pleaseEnterFeedback;

  /// No description provided for @feedbackTooShort.
  ///
  /// In en, this message translates to:
  /// **'Feedback is too short (min 5 characters)'**
  String get feedbackTooShort;

  /// No description provided for @feedbackSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your feedback has been sent.'**
  String get feedbackSentSuccess;

  /// No description provided for @feedbackSentError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send feedback. Please try again later.'**
  String get feedbackSentError;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @matchNotificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Match notifications enabled'**
  String get matchNotificationsEnabled;

  /// No description provided for @matchNotificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Match notifications disabled'**
  String get matchNotificationsDisabled;

  /// No description provided for @mdSmall.
  ///
  /// In en, this message translates to:
  /// **'MD'**
  String get mdSmall;

  /// No description provided for @totalSmall.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get totalSmall;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notificationsTitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @userPredictions.
  ///
  /// In en, this message translates to:
  /// **'User Predictions'**
  String get userPredictions;

  /// No description provided for @noPredictionsFound.
  ///
  /// In en, this message translates to:
  /// **'No predictions found by this user.'**
  String get noPredictionsFound;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'STATISTICS'**
  String get statistics;

  /// No description provided for @lastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Updated: January 29, 2026'**
  String get lastUpdatedLabel;

  /// No description provided for @privacyPolicyIntro.
  ///
  /// In en, this message translates to:
  /// **'Your privacy is important to us. This Privacy Policy explains how Goalio collects, uses, and protects your information when you use our mobile application.'**
  String get privacyPolicyIntro;

  /// No description provided for @privacySection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Information We Collect'**
  String get privacySection1Title;

  /// No description provided for @privacySection1Content.
  ///
  /// In en, this message translates to:
  /// **'We collect information you provide directly to us when you create an account, such as your fullname and email address. We also store your \'Favorite Teams\' preferences as part of your user profile to personalize your experience.'**
  String get privacySection1Content;

  /// No description provided for @privacySection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. How We Use Your Information'**
  String get privacySection2Title;

  /// No description provided for @privacySection2Content.
  ///
  /// In en, this message translates to:
  /// **'We use the information we collect to:\n• Provide, maintain, and improve our services.\n• Personalize your experience by showing your favorite teams first.\n• Communicate with you about updates or security alerts.\n• Protect the safety and integrity of our services.'**
  String get privacySection2Content;

  /// No description provided for @privacySection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Data Persistence'**
  String get privacySection3Title;

  /// No description provided for @privacySection3Content.
  ///
  /// In en, this message translates to:
  /// **'Your account data and favorite teams are stored securely in our backend database. We do not sell or share your personal data with third-party advertisers.'**
  String get privacySection3Content;

  /// No description provided for @privacySection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Security'**
  String get privacySection4Title;

  /// No description provided for @privacySection4Content.
  ///
  /// In en, this message translates to:
  /// **'We implement industry-standard security measures to protect your data, including hashed passwords and encrypted communication (HTTPS). However, no method of transmission over the internet is 100% secure.'**
  String get privacySection4Content;

  /// No description provided for @privacySection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Your Choices'**
  String get privacySection5Title;

  /// No description provided for @privacySection5Content.
  ///
  /// In en, this message translates to:
  /// **'You can update your favorite teams at any time within the app. You may also contact us to request the deletion of your account and personal data.'**
  String get privacySection5Content;

  /// No description provided for @privacySection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Contact Us'**
  String get privacySection6Title;

  /// No description provided for @privacySection6Content.
  ///
  /// In en, this message translates to:
  /// **'If you have any questions about this Privacy Policy, please reach out via our support channels.'**
  String get privacySection6Content;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Goalio. All rights reserved.'**
  String get allRightsReserved;

  /// No description provided for @termsSection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get termsSection1Title;

  /// No description provided for @termsSection1Content.
  ///
  /// In en, this message translates to:
  /// **'By accessing and using the Goalio application, you agree to comply with and be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.'**
  String get termsSection1Content;

  /// No description provided for @termsSection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Use of Services'**
  String get termsSection2Title;

  /// No description provided for @termsSection2Content.
  ///
  /// In en, this message translates to:
  /// **'Goalio provides football fixtures, news, and personalized features. You agree to use the services only for lawful purposes and in a manner that does not infringe the rights of others.'**
  String get termsSection2Content;

  /// No description provided for @termsSection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. User Accounts'**
  String get termsSection3Title;

  /// No description provided for @termsSection3Content.
  ///
  /// In en, this message translates to:
  /// **'When you create an account, you are responsible for maintaining the confidentiality of your credentials and for all activities that occur under your account.'**
  String get termsSection3Content;

  /// No description provided for @termsSection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Intellectual Property'**
  String get termsSection4Title;

  /// No description provided for @termsSection4Content.
  ///
  /// In en, this message translates to:
  /// **'The content, features, and functionality of Goalio are owned by Goalio and are protected by international copyright, trademark, and other intellectual property laws.'**
  String get termsSection4Content;

  /// No description provided for @termsSection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Disclaimer of Warranties'**
  String get termsSection5Title;

  /// No description provided for @termsSection5Content.
  ///
  /// In en, this message translates to:
  /// **'Goalio is provided \'as is\' without warranties of any kind. While we strive for accuracy, we do not guarantee that match data, scores, or news will always be error-free or up-to-the-minute.'**
  String get termsSection5Content;

  /// No description provided for @termsSection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Limitation of Liability'**
  String get termsSection6Title;

  /// No description provided for @termsSection6Content.
  ///
  /// In en, this message translates to:
  /// **'In no event shall Goalio be liable for any indirect, incidental, or consequential damages arising out of your use or inability to use the application.'**
  String get termsSection6Content;

  /// No description provided for @termsSection7Title.
  ///
  /// In en, this message translates to:
  /// **'7. Changes to Terms'**
  String get termsSection7Title;

  /// No description provided for @termsSection7Content.
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to modify these Terms of Service at any time. Your continued use of the app after such changes constitutes acceptance of the new terms.'**
  String get termsSection7Content;

  /// No description provided for @selectLeague.
  ///
  /// In en, this message translates to:
  /// **'Select League'**
  String get selectLeague;

  /// No description provided for @tapToSearch.
  ///
  /// In en, this message translates to:
  /// **'Tap to search & select...'**
  String get tapToSearch;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// No description provided for @minutesAbbr.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minutesAbbr;

  /// No description provided for @hoursAbbr.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursAbbr;

  /// No description provided for @daysAbbr.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get daysAbbr;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable or disable receiving notifications from the app'**
  String get notificationsSubtitle;

  /// No description provided for @fantasyHub.
  ///
  /// In en, this message translates to:
  /// **'FANTASY'**
  String get fantasyHub;

  /// No description provided for @dreamTeam.
  ///
  /// In en, this message translates to:
  /// **'DREAM TEAM'**
  String get dreamTeam;

  /// No description provided for @dreamTeamSubs.
  ///
  /// In en, this message translates to:
  /// **'Substitutes'**
  String get dreamTeamSubs;

  /// No description provided for @dreamTeamRound.
  ///
  /// In en, this message translates to:
  /// **'Round Team of the Week'**
  String get dreamTeamRound;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of Goalio is available. Please update to continue enjoying the latest features and improvements.'**
  String get updateAvailableMessage;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @notificationManager.
  ///
  /// In en, this message translates to:
  /// **'Notification Manager'**
  String get notificationManager;

  /// No description provided for @notificationManagerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize which alerts you receive'**
  String get notificationManagerSubtitle;

  /// No description provided for @matchEvents.
  ///
  /// In en, this message translates to:
  /// **'Match Events'**
  String get matchEvents;

  /// No description provided for @matchEventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick which in-match alerts you want to receive for the matches you follow.'**
  String get matchEventsSubtitle;

  /// No description provided for @newsAlerts.
  ///
  /// In en, this message translates to:
  /// **'News Alerts'**
  String get newsAlerts;

  /// No description provided for @newsAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How often should we push fresh news from your favorite leagues?'**
  String get newsAlertsSubtitle;

  /// No description provided for @eventGoal.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get eventGoal;

  /// No description provided for @eventAssist.
  ///
  /// In en, this message translates to:
  /// **'Assists'**
  String get eventAssist;

  /// No description provided for @eventYellowCard.
  ///
  /// In en, this message translates to:
  /// **'Yellow cards'**
  String get eventYellowCard;

  /// No description provided for @eventRedCard.
  ///
  /// In en, this message translates to:
  /// **'Red cards'**
  String get eventRedCard;

  /// No description provided for @eventSubstitution.
  ///
  /// In en, this message translates to:
  /// **'Substitutions'**
  String get eventSubstitution;

  /// No description provided for @eventVar.
  ///
  /// In en, this message translates to:
  /// **'VAR reviews'**
  String get eventVar;

  /// No description provided for @eventPenalty.
  ///
  /// In en, this message translates to:
  /// **'Penalties (scored & missed)'**
  String get eventPenalty;

  /// No description provided for @eventMatchStart.
  ///
  /// In en, this message translates to:
  /// **'Match start'**
  String get eventMatchStart;

  /// No description provided for @eventMatchEnd.
  ///
  /// In en, this message translates to:
  /// **'Match end'**
  String get eventMatchEnd;

  /// No description provided for @eventHalfTime.
  ///
  /// In en, this message translates to:
  /// **'Half time'**
  String get eventHalfTime;

  /// No description provided for @eventPreMatch.
  ///
  /// In en, this message translates to:
  /// **'Pre-match reminder (10 min before)'**
  String get eventPreMatch;

  /// No description provided for @newsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable news notifications'**
  String get newsEnabled;

  /// No description provided for @newsFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get newsFrequency;

  /// No description provided for @freqEveryMinute.
  ///
  /// In en, this message translates to:
  /// **'Every 1 minute'**
  String get freqEveryMinute;

  /// No description provided for @freqEvery5Minutes.
  ///
  /// In en, this message translates to:
  /// **'Every 5 minutes'**
  String get freqEvery5Minutes;

  /// No description provided for @freqEvery15Minutes.
  ///
  /// In en, this message translates to:
  /// **'Every 15 minutes'**
  String get freqEvery15Minutes;

  /// No description provided for @freqEvery30Minutes.
  ///
  /// In en, this message translates to:
  /// **'Every 30 minutes'**
  String get freqEvery30Minutes;

  /// No description provided for @freqEveryHour.
  ///
  /// In en, this message translates to:
  /// **'Every 1 hour'**
  String get freqEveryHour;

  /// No description provided for @freqEvery2Hours.
  ///
  /// In en, this message translates to:
  /// **'Every 2 hours'**
  String get freqEvery2Hours;

  /// No description provided for @freqEvery4Hours.
  ///
  /// In en, this message translates to:
  /// **'Every 4 hours'**
  String get freqEvery4Hours;

  /// No description provided for @freqEvery8Hours.
  ///
  /// In en, this message translates to:
  /// **'Every 8 hours'**
  String get freqEvery8Hours;

  /// No description provided for @freqEvery12Hours.
  ///
  /// In en, this message translates to:
  /// **'Every 12 hours'**
  String get freqEvery12Hours;

  /// No description provided for @freqEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Once a day'**
  String get freqEveryDay;

  /// No description provided for @preferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved'**
  String get preferencesSaved;

  /// No description provided for @preferencesSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your preferences. Try again.'**
  String get preferencesSaveFailed;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your name and password'**
  String get editProfileSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordOptional.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep your current password'**
  String get changePasswordOptional;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your profile. Try again.'**
  String get profileUpdateFailed;

  /// No description provided for @socialAccountPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'You signed in with a social account — password change isn\'t available.'**
  String get socialAccountPasswordHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
