// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get account => 'Account';

  @override
  String get teamsManager => 'Teams Manager';

  @override
  String get leaguesManager => 'Leagues Manager';

  @override
  String get logout => 'Logout';

  @override
  String get goalio => 'Goalio';

  @override
  String get appSlogan => 'Your ultimate football companion';

  @override
  String get home => 'Home';

  @override
  String get fixtures => 'Fixtures';

  @override
  String get news => 'News';

  @override
  String get leagues => 'Leagues';

  @override
  String get featuredMatch => 'FEATURED MATCH';

  @override
  String get live => 'LIVE';

  @override
  String get upcomingMatches => 'UPCOMING MATCHES';

  @override
  String get seeAll => 'See All';

  @override
  String get noMatchesToday => 'No matches scheduled today.';

  @override
  String get trendingNews => 'TRENDING NEWS';

  @override
  String get noNewsAvailable => 'No news available.';

  @override
  String noNewsAvailableFor(Object league) {
    return 'No news available for $league';
  }

  @override
  String get leagueStandings => 'LEAGUES STANDINGS';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get fixturesTitle => 'FIXTURES';

  @override
  String get searchHint => 'Search for any team...';

  @override
  String get sortByFavorite => 'Sort by Favorite';

  @override
  String get sortAZ => 'Sort A-Z';

  @override
  String get favoriteMatches => 'FAVORITE MATCHES';

  @override
  String get matches => 'Matches';

  @override
  String get latestNews => 'LATEST NEWS';

  @override
  String get refresh => 'Refresh';

  @override
  String get newsTag => 'NEWS';

  @override
  String get leaguesTitle => 'LEAGUES';

  @override
  String get searchLeaguesHint => 'Search leagues...';

  @override
  String get noLeaguesAvailable => 'NO LEAGUES AVAILABLE';

  @override
  String get standingsTab => 'STANDINGS';

  @override
  String get playersTab => 'PLAYERS';

  @override
  String get retry => 'Retry';

  @override
  String get checkAgain => 'Check Again';

  @override
  String get goals => 'Goals';

  @override
  String get assists => 'Assists';

  @override
  String get apps => 'Apps';

  @override
  String get challengeTitle => 'Challenge';

  @override
  String get predictions => 'Predictions';

  @override
  String get overview => 'OVERVIEW';

  @override
  String get timeline => 'TIMELINE';

  @override
  String get lineup => 'LINEUP';

  @override
  String get endOfMatch => 'End of match';

  @override
  String get kickOff => 'Kick off';

  @override
  String get leaderboard => 'LEADERBOARD';

  @override
  String get createLeague => 'Create Custom League';

  @override
  String get joinLeague => 'Join League';

  @override
  String get leagueName => 'League Name';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get done => 'Done';

  @override
  String get join => 'Join';

  @override
  String get welcomeBack => 'WELCOME BACK';

  @override
  String get signInSubtitle => 'Sign in to follow your favorite matches';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get loginLabel => 'SIGN IN';

  @override
  String get signUpLabel => 'Sign Up';

  @override
  String get forgotPasswordLabel => 'Forgot Password?';

  @override
  String get orContinueWith => 'OR CONTINUE WITH';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get createAccount => 'CREATE ACCOUNT';

  @override
  String get joinCommunity => 'Join the Goalio community today';

  @override
  String get fullName => 'Full Name';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get halftime => 'HT';

  @override
  String get fulltime => 'FT';

  @override
  String get resetPassword => 'RESET PASSWORD';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we\'ll send you a link to reset your password.';

  @override
  String get sendResetLink => 'SEND RESET LINK';

  @override
  String get enterEmail => 'Please enter your email';

  @override
  String get verificationCodeSent =>
      'Verification code sent! Please check your email.';

  @override
  String get matchOverview => 'MATCH OVERVIEW';

  @override
  String get predictMatch => 'PREDICT MATCH';

  @override
  String get randomizeAnswers => 'Randomize Answers';

  @override
  String get answersRandomized => 'All answers randomized! 🎲';

  @override
  String get answerAtLeastOne => 'Please answer at least one question.';

  @override
  String get predictionsSubmitted => 'Predictions submitted successfully!';

  @override
  String get submitPrediction => 'SUBMIT PREDICTION';

  @override
  String get draw => 'Draw';

  @override
  String get none => 'None';

  @override
  String get enterPredictionHint => 'Enter your prediction';

  @override
  String get pickYourTeams => 'PICK YOUR TEAMS';

  @override
  String selectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get searchHintTeams => 'Search for any team...';

  @override
  String get showingSelectedTeamsOnly => 'Showing selected teams only';

  @override
  String get noSelectedTeamsFound => 'No selected teams found';

  @override
  String get noTeamsFound => 'No teams found';

  @override
  String get selectAtLeastOneTeam => 'Select at least one team';

  @override
  String saveChangesCount(Object count) {
    return 'Save Changes ($count)';
  }

  @override
  String get selectFavoriteLeagues => 'Select Favorite Leagues';

  @override
  String get searchHintLeagues => 'Search leagues...';

  @override
  String get showingSelectedLeaguesOnly => 'Showing selected leagues only';

  @override
  String get noSelectedLeaguesFound => 'No selected leagues found';

  @override
  String get noLeaguesFound => 'No leagues found';

  @override
  String get showAllLeagues => 'Show all leagues';

  @override
  String get saving => 'Saving...';

  @override
  String continueWithCount(Object count) {
    return 'Continue ($count selected)';
  }

  @override
  String get selectAtLeastOneLeague => 'Select at least one league';

  @override
  String savedLeaguesSuccess(Object count) {
    return 'Successfully saved $count favorite leagues!';
  }

  @override
  String get errorLoadingLeagues => 'Error loading leagues';

  @override
  String get errorLoadingTeams => 'Error loading teams';

  @override
  String get errorSavingLeagues => 'Error saving leagues';

  @override
  String get errorSavingTeams => 'Error saving teams';

  @override
  String savedTeamsSuccess(Object count) {
    return 'Successfully saved $count favorite teams!';
  }

  @override
  String get newPassword => 'NEW PASSWORD';

  @override
  String resetCodeSubtitle(Object email) {
    return 'Enter the 6-digit code sent to $email and your new password.';
  }

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get updatePassword => 'UPDATE PASSWORD';

  @override
  String get fillAllFields => 'Please fill all fields';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordResetSuccess =>
      'Password reset successfully! You can now log in.';

  @override
  String get matchday => 'MATCHDAY';

  @override
  String get points => 'POINTS';

  @override
  String get pts => 'PTS';

  @override
  String get start => 'START';

  @override
  String get edit => 'EDIT';

  @override
  String get overall => 'OVERALL';

  @override
  String get predictAndEarn => 'PREDICT & EARN MATCHDAY POINTS';

  @override
  String get leagueCreated => 'League Created!';

  @override
  String get enterLeagueName => 'Enter league name';

  @override
  String get leagueCreatedSubtitle =>
      'Your league has been created. Share this code with your friends to join:';

  @override
  String get codeCopied => 'Code copied to clipboard!';

  @override
  String get joinLeagueSubtitle =>
      'Enter the unique league code to join your friends.';

  @override
  String get leagueCodeHint => 'e.g. GX-1234';

  @override
  String joinedLeagueSuccess(Object code) {
    return 'Joined league $code successfully!';
  }

  @override
  String get premierLeague => 'ENGLAND - PREMIER LEAGUE';

  @override
  String get noMatchesOnDate =>
      'No Premier League matches scheduled\nfor this date.';

  @override
  String get noMatchesFound => 'No Matches Found';

  @override
  String get joinLeagueLabel => 'JOIN LEAGUE';

  @override
  String get createLeagueLabel => 'CREATE LEAGUE';

  @override
  String get myClassicLeagues => 'MY CLASSIC LEAGUES';

  @override
  String get generalLeagues => 'GENERAL LEAGUES';

  @override
  String playersCount(Object count) {
    return '$count players';
  }

  @override
  String get rank => 'RANK';

  @override
  String lastUpdated(Object time) {
    return 'LAST UPDATED: $time';
  }

  @override
  String get pos => 'POS';

  @override
  String get playerMe => 'ME';

  @override
  String get playerYou => 'YOU';

  @override
  String globalRank(Object rank) {
    return 'GLOBAL RANK #$rank';
  }

  @override
  String get errorLoadingLeaderboard => 'Error loading leaderboard';

  @override
  String get selectMode => 'SELECT MODE';

  @override
  String get fullMatchday => 'Full Matchday';

  @override
  String get fullMatchdaySubtitle =>
      'Predict all 10 matches for maximum points.';

  @override
  String get activeModeSubtitle => 'Active Mode';

  @override
  String get topFixtures => 'Top 5 Fixtures';

  @override
  String get topFixturesSubtitle => 'Focus on the biggest games of the week.';

  @override
  String get rivalryRound => 'Rivalry Round';

  @override
  String get rivalryRoundSubtitle => 'Double points on derby matches.';

  @override
  String get couldNotLoadMatches => 'Could not load matches.';

  @override
  String get noLiveMatches => 'No Live Matches';

  @override
  String get noLiveMatchesSubtitle =>
      'There are no matches currently in progress.';

  @override
  String get noFavoriteMatches => 'No Favorite Matches';

  @override
  String get noFavoriteMatchesSubtitle =>
      'None of your favorite teams have matches scheduled.';

  @override
  String noMatchesScheduled(Object date) {
    return 'No matches scheduled for $date.';
  }

  @override
  String get noMatchesFoundSubtitle =>
      'Try selecting different filters or checking all leagues.';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get postponed => 'Postponed';

  @override
  String get suspended => 'Suspension';

  @override
  String byAuthor(Object author) {
    return 'By $author';
  }

  @override
  String get fullContentNotAvailable =>
      'Full content is not available for this article.';

  @override
  String get noTitle => 'No Title';

  @override
  String get loading => 'Loading...';

  @override
  String get vs => 'VS';

  @override
  String get fullStory => 'Full Story';

  @override
  String get away => 'Away';

  @override
  String get homeTeam => 'Home';

  @override
  String get awayTeam => 'Away';

  @override
  String get noMatchDetails =>
      'No match details link available for this match.';

  @override
  String get failedToLoadDetails => 'Failed to load match details';

  @override
  String get serverConnectionError => 'Could not connect to server.';

  @override
  String get matchStats => 'MATCH STATS';

  @override
  String get matchInfoNotAvailable =>
      'Match information is not available yet.\nCheck back closer to kick-off.';

  @override
  String get matchOverviewLabel => 'MATCH OVERVIEW';

  @override
  String get matchStatsNotAvailable =>
      'Match statistics will appear here once available.';

  @override
  String get matchTimeline => 'MATCH TIMELINE';

  @override
  String get timelineKey => 'Timeline Key';

  @override
  String get goalLabel => 'Goal';

  @override
  String get ownGoal => 'Own goal';

  @override
  String get assist => 'Assist';

  @override
  String get secondYellow => 'Second yellow';

  @override
  String get injury => 'Injury';

  @override
  String get penaltyGoal => 'Penalty goal';

  @override
  String get penaltyMissed => 'Penalty missed';

  @override
  String get redCard => 'Red card';

  @override
  String get redCards => 'Red Cards';

  @override
  String get yellowCard => 'Yellow card';

  @override
  String get yellowCardsLabel => 'Yellow Cards';

  @override
  String get substitutionLabel => 'Substitution';

  @override
  String get varLabel => 'VAR';

  @override
  String get teamForm => 'TEAM FORM';

  @override
  String get last5Matches => 'Last 5 Matches';

  @override
  String get teamLineups => 'TEAM LINEUPS';

  @override
  String get lineupsLabel => 'LINEUPS';

  @override
  String get benchLabel => 'Substitute Bench';

  @override
  String get playedShort => 'P';

  @override
  String get wonShort => 'W';

  @override
  String get drawnShort => 'D';

  @override
  String get lostShort => 'L';

  @override
  String get goalDiffShort => 'GD';

  @override
  String get ptsShort => 'PTS';

  @override
  String get noStandingsData => 'NO STANDINGS DATA';

  @override
  String get liveUpdatesSoon => 'Live updates will appear here soon';

  @override
  String get scorers => 'SCORERS';

  @override
  String get shotsOnTarget => 'SHOTS';

  @override
  String get foulsCommitted => 'FOULS COMMITTED';

  @override
  String get foulsWon => 'FOULS WON';

  @override
  String get tackles => 'TACKLES';

  @override
  String get offsides => 'OFFSIDES';

  @override
  String get team => 'Team';

  @override
  String hoursShort(Object count) {
    return '${count}h';
  }

  @override
  String minutesShort(Object count) {
    return '${count}m';
  }

  @override
  String get browseTeams => 'Browse Teams';

  @override
  String get tbd => 'TBD';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get notStarted => 'Not Started';

  @override
  String get ns => 'NS';

  @override
  String get fixture => 'FIXTURE';

  @override
  String get result => 'RESULT';

  @override
  String get aet => 'AET';

  @override
  String get pen => 'PEN';

  @override
  String errorFetchingQuestions(Object error) {
    return 'Error fetching questions: $error';
  }

  @override
  String errorPrefix(Object error) {
    return 'Error: $error';
  }

  @override
  String get closeGamePrediction => 'It will be a very close game.';

  @override
  String get manyGoalsPrediction => 'I expect many goals today!';

  @override
  String get tacticalMasterclassPrediction => 'A tactical masterclass.';

  @override
  String get hardToPredictPrediction => 'Hard to predict this one.';

  @override
  String get oneTeamDominatePrediction => 'One team will easily dominate.';

  @override
  String get unknown => 'Unknown';

  @override
  String noLeaguesFoundMatching(Object query) {
    return 'No results match your search term \"$query\". Try a different spelling or clearer name.';
  }

  @override
  String get noLeaguesInDatabase =>
      'We couldn\'t find any leagues in the database. Please try scraping some data or check your connection.';

  @override
  String get clearSearch => 'Clear Search';

  @override
  String get failedToLoadNews => 'Failed to load news';

  @override
  String modeSelected(Object mode) {
    return '$mode selected';
  }

  @override
  String get drawLabel => 'Draw';

  @override
  String get noneLabel => 'None';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get passwordLabel => 'Password';

  @override
  String get enterName => 'Please enter your full name';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get selectDate => 'Select Date';

  @override
  String get feedbackAndSuggestions => 'Feedback & Suggestions';

  @override
  String get feedbackAndSuggestionsSubtitle =>
      'Help us improve Goalio by sharing your thoughts';

  @override
  String get feedbackDescription =>
      'We value your feedback! Whether it\'s a suggestion for a new feature or a complaint about an issue, please let us know.';

  @override
  String get feedbackType => 'FEEDBACK TYPE';

  @override
  String get suggestion => 'Suggestion';

  @override
  String get complaint => 'Complaint';

  @override
  String get feedbackContent => 'YOUR MESSAGE';

  @override
  String get feedbackHint =>
      'Write your feedback here (minimum 5 characters)...';

  @override
  String get submit => 'SUBMIT';

  @override
  String get pleaseEnterFeedback => 'Please enter your feedback';

  @override
  String get feedbackTooShort => 'Feedback is too short (min 5 characters)';

  @override
  String get feedbackSentSuccess => 'Thank you! Your feedback has been sent.';

  @override
  String get feedbackSentError =>
      'Failed to send feedback. Please try again later.';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get matchNotificationsEnabled => 'Match notifications enabled';

  @override
  String get matchNotificationsDisabled => 'Match notifications disabled';

  @override
  String get mdSmall => 'MD';

  @override
  String get totalSmall => 'TOTAL';

  @override
  String get notificationsTitle => 'NOTIFICATIONS';

  @override
  String get notifications => 'NOTIFICATIONS';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get userPredictions => 'User Predictions';

  @override
  String get noPredictionsFound => 'No predictions found by this user.';

  @override
  String get question => 'Question';

  @override
  String get answer => 'Answer';

  @override
  String get statistics => 'STATISTICS';

  @override
  String get lastUpdatedLabel => 'Last Updated: January 29, 2026';

  @override
  String get privacyPolicyIntro =>
      'Your privacy is important to us. This Privacy Policy explains how Goalio collects, uses, and protects your information when you use our mobile application.';

  @override
  String get privacySection1Title => '1. Information We Collect';

  @override
  String get privacySection1Content =>
      'We collect information you provide directly to us when you create an account, such as your fullname and email address. We also store your \'Favorite Teams\' preferences as part of your user profile to personalize your experience.';

  @override
  String get privacySection2Title => '2. How We Use Your Information';

  @override
  String get privacySection2Content =>
      'We use the information we collect to:\n• Provide, maintain, and improve our services.\n• Personalize your experience by showing your favorite teams first.\n• Communicate with you about updates or security alerts.\n• Protect the safety and integrity of our services.';

  @override
  String get privacySection3Title => '3. Data Persistence';

  @override
  String get privacySection3Content =>
      'Your account data and favorite teams are stored securely in our backend database. We do not sell or share your personal data with third-party advertisers.';

  @override
  String get privacySection4Title => '4. Security';

  @override
  String get privacySection4Content =>
      'We implement industry-standard security measures to protect your data, including hashed passwords and encrypted communication (HTTPS). However, no method of transmission over the internet is 100% secure.';

  @override
  String get privacySection5Title => '5. Your Choices';

  @override
  String get privacySection5Content =>
      'You can update your favorite teams at any time within the app. You may also contact us to request the deletion of your account and personal data.';

  @override
  String get privacySection6Title => '6. Contact Us';

  @override
  String get privacySection6Content =>
      'If you have any questions about this Privacy Policy, please reach out via our support channels.';

  @override
  String get allRightsReserved => '© 2026 Goalio. All rights reserved.';

  @override
  String get termsSection1Title => '1. Acceptance of Terms';

  @override
  String get termsSection1Content =>
      'By accessing and using the Goalio application, you agree to comply with and be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.';

  @override
  String get termsSection2Title => '2. Use of Services';

  @override
  String get termsSection2Content =>
      'Goalio provides football fixtures, news, and personalized features. You agree to use the services only for lawful purposes and in a manner that does not infringe the rights of others.';

  @override
  String get termsSection3Title => '3. User Accounts';

  @override
  String get termsSection3Content =>
      'When you create an account, you are responsible for maintaining the confidentiality of your credentials and for all activities that occur under your account.';

  @override
  String get termsSection4Title => '4. Intellectual Property';

  @override
  String get termsSection4Content =>
      'The content, features, and functionality of Goalio are owned by Goalio and are protected by international copyright, trademark, and other intellectual property laws.';

  @override
  String get termsSection5Title => '5. Disclaimer of Warranties';

  @override
  String get termsSection5Content =>
      'Goalio is provided \'as is\' without warranties of any kind. While we strive for accuracy, we do not guarantee that match data, scores, or news will always be error-free or up-to-the-minute.';

  @override
  String get termsSection6Title => '6. Limitation of Liability';

  @override
  String get termsSection6Content =>
      'In no event shall Goalio be liable for any indirect, incidental, or consequential damages arising out of your use or inability to use the application.';

  @override
  String get termsSection7Title => '7. Changes to Terms';

  @override
  String get termsSection7Content =>
      'We reserve the right to modify these Terms of Service at any time. Your continued use of the app after such changes constitutes acceptance of the new terms.';

  @override
  String get selectLeague => 'Select League';

  @override
  String get tapToSearch => 'Tap to search & select...';

  @override
  String get searchPlaceholder => 'Search...';

  @override
  String get minutesAbbr => 'm';

  @override
  String get hoursAbbr => 'h';

  @override
  String get daysAbbr => 'd';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get notificationsSubtitle =>
      'Enable or disable receiving notifications from the app';

  @override
  String get fantasyHub => 'FANTASY';

  @override
  String get dreamTeam => 'DREAM TEAM';

  @override
  String get dreamTeamSubs => 'Substitutes';

  @override
  String get dreamTeamRound => 'Round Team of the Week';

  @override
  String get updateAvailableTitle => 'Update Available';

  @override
  String get updateAvailableMessage =>
      'A new version of Goalio is available. Please update to continue enjoying the latest features and improvements.';

  @override
  String get updateNow => 'Update Now';

  @override
  String get later => 'Later';

  @override
  String get notificationManager => 'Notification Manager';

  @override
  String get notificationManagerSubtitle =>
      'Customize which alerts you receive';

  @override
  String get matchEvents => 'Match Events';

  @override
  String get matchEventsSubtitle =>
      'Pick which in-match alerts you want to receive for the matches you follow.';

  @override
  String get newsAlerts => 'News Alerts';

  @override
  String get newsAlertsSubtitle =>
      'How often should we push fresh news from your favorite leagues?';

  @override
  String get eventGoal => 'Goals';

  @override
  String get eventAssist => 'Assists';

  @override
  String get eventYellowCard => 'Yellow cards';

  @override
  String get eventRedCard => 'Red cards';

  @override
  String get eventSubstitution => 'Substitutions';

  @override
  String get eventVar => 'VAR reviews';

  @override
  String get eventPenalty => 'Penalties (scored & missed)';

  @override
  String get eventMatchStart => 'Match start';

  @override
  String get eventMatchEnd => 'Match end';

  @override
  String get eventHalfTime => 'Half time';

  @override
  String get eventPreMatch => 'Pre-match reminder (10 min before)';

  @override
  String get newsEnabled => 'Enable news notifications';

  @override
  String get newsFrequency => 'Frequency';

  @override
  String get freqEveryMinute => 'Every 1 minute';

  @override
  String get freqEvery5Minutes => 'Every 5 minutes';

  @override
  String get freqEvery15Minutes => 'Every 15 minutes';

  @override
  String get freqEvery30Minutes => 'Every 30 minutes';

  @override
  String get freqEveryHour => 'Every 1 hour';

  @override
  String get freqEvery2Hours => 'Every 2 hours';

  @override
  String get freqEvery4Hours => 'Every 4 hours';

  @override
  String get freqEvery8Hours => 'Every 8 hours';

  @override
  String get freqEvery12Hours => 'Every 12 hours';

  @override
  String get freqEveryDay => 'Once a day';

  @override
  String get preferencesSaved => 'Preferences saved';

  @override
  String get preferencesSaveFailed =>
      'Couldn\'t save your preferences. Try again.';

  @override
  String get save => 'Save';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editProfileSubtitle => 'Update your name and password';

  @override
  String get email => 'Email';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordOptional =>
      'Leave blank to keep your current password';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get profileUpdateFailed => 'Couldn\'t update your profile. Try again.';

  @override
  String get socialAccountPasswordHint =>
      'You signed in with a social account — password change isn\'t available.';
}
