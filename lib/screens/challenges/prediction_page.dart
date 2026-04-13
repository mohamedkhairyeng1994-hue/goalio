import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'challenge_providers.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/size_config.dart';
import '../../core/utils/logo_utils.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/messages.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/time_utils.dart';
import '../../core/utils/number_utils.dart';
import '../../core/utils/name_translator.dart';

String _formatFullDateTime(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final dt = DateTime.parse(raw).toLocal();
    final datePart = DateFormat('EEE, d MMM', Intl.defaultLocale).format(dt);
    final timePart = DateFormat('HH:mm', Intl.defaultLocale).format(dt);
    return '$datePart · $timePart';
  } catch (_) {
    return raw;
  }
}

class PredictionPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> match;
  final bool isReadOnly;

  const PredictionPage({
    super.key,
    required this.match,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends ConsumerState<PredictionPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<dynamic> _questions = [];
  Map<int, dynamic> _answers = {};

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final questions = await ApiService.getPredictionQuestions(
        widget.match['id'],
      );
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
          for (var q in _questions) {
            if (q['user_answer'] != null) {
              _answers[q['id']] = q['user_answer'];
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        GoalioMessages.showError(
          context,
          AppLocalizations.of(context)!.errorFetchingQuestions(e.toString()),
        );
      }
    }
  }

  void _randomizeAnswers() {
    final random = Random();

    setState(() {
      for (var q in _questions) {
        final qId = q['id'];
        switch (q['type']) {
          case 'team_select':
            final opts = ['home', 'away', 'draw'];
            _answers[qId] = opts[random.nextInt(opts.length)];
            break;
          case 'team_select_none':
            final opts = ['home', 'away', 'none'];
            _answers[qId] = opts[random.nextInt(opts.length)];
            break;
          case 'select':
          case 'boolean':
            List<String> opts =
                (q['options'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
            if (opts.isNotEmpty) {
              _answers[qId] = opts[random.nextInt(opts.length)];
            }
            break;
          case 'score':
            int homeScore = random.nextInt(4); // 0 to 3
            int awayScore = random.nextInt(4); // 0 to 3
            _answers[qId] = '$homeScore-$awayScore';
            break;
          case 'text':
          default:
            final opts = [
              AppLocalizations.of(context)!.closeGamePrediction,
              AppLocalizations.of(context)!.manyGoalsPrediction,
              AppLocalizations.of(context)!.tacticalMasterclassPrediction,
              AppLocalizations.of(context)!.hardToPredictPrediction,
              AppLocalizations.of(context)!.oneTeamDominatePrediction,
            ];
            _answers[qId] = opts[random.nextInt(opts.length)];
            break;
        }
      }
    });

    GoalioMessages.showInfo(
      context,
      AppLocalizations.of(context)!.answersRandomized,
    );
  }

  Future<void> _submitPredictions() async {
    if (_answers.isEmpty) {
      GoalioMessages.showError(
        context,
        AppLocalizations.of(context)!.answerAtLeastOne,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    List<Map<String, dynamic>> answersList = [];
    _answers.forEach((key, value) {
      answersList.add({'question_id': key, 'answer': value.toString()});
    });

    final result = await ApiService.submitMatchPredictions(
      widget.match['id'],
      answersList,
    );

    setState(() => _isSubmitting = false);

    if (result.containsKey('error')) {
      if (mounted) {
        GoalioMessages.showError(
          context,
          AppLocalizations.of(context)!.errorPrefix(result['error'].toString()),
        );
      }
    } else {
      if (mounted) {
        GoalioMessages.showSuccess(
          context,
          AppLocalizations.of(context)!.predictionsSubmitted,
        );
        // Invalidate all relevant providers to update the parent screen automatically
        final date = ref.read(selectedChallengeDateProvider);
        ref.invalidate(challengeDataByDateProvider(date));
        ref.invalidate(userTotalPointsProvider);
        ref.invalidate(groupsProvider);

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeTeam = widget.match['home_team'] ?? l10n.homeTeam;
    final awayTeam = widget.match['away_team'] ?? l10n.awayTeam;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF070B14) : const Color(0xFFF1F5F9),
      extendBodyBehindAppBar: true, // Extended for immersive gradient
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Fully transparent
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0, // Prevent color shift on scroll
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16.w,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isReadOnly
              ? AppLocalizations.of(context)!.matchOverview
              : AppLocalizations.of(context)!.predictMatch,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: 2.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!widget.isReadOnly && _questions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: Icon(
                    Icons.casino_rounded, // Dice icon
                    size: 16.w,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                onPressed: _randomizeAnswers,
                tooltip: AppLocalizations.of(context)!.randomizeAnswers,
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // ── DYNAMIC BACKGROUND ──
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    isDark
                        ? [const Color(0xFF0F172A), const Color(0xFF070B14)]
                        : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
              ),
            ),
          ),
          if (isDark) ...[
            // Subtle neon glow (Top Left)
            Positioned(
              top: -100.w,
              left: -100.w,
              child: Container(
                width: 300.w,
                height: 300.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GoalioColors.greenAccent.withOpacity(0.05),
                  boxShadow: [
                    BoxShadow(
                      color: GoalioColors.greenAccent.withOpacity(0.08),
                      blurRadius: 120,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
            // Subtle neon glow (Bottom Right)
            Positioned(
              bottom: -50.w,
              right: -100.w,
              child: Container(
                width: 250.w,
                height: 250.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GoalioColors.blueAccent.withOpacity(0.03),
                  boxShadow: [
                    BoxShadow(
                      color: GoalioColors.blueAccent.withOpacity(0.05),
                      blurRadius: 100,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── FOREGROUND CONTENT ──
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: 10.h),
                _buildStadiumHeader(isDark, homeTeam, awayTeam),
                Expanded(
                  child:
                      _isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              color: GoalioColors.greenAccent,
                              strokeWidth: 2,
                            ),
                          )
                          : Stack(
                            children: [
                              ListView(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                  16.w,
                                  6.h,
                                  16.w,
                                  120.h,
                                ), // Increased bottom padding for floating submit
                                physics: const ClampingScrollPhysics(),
                                children: [
                                  ..._questions.map(
                                    (q) => _buildDynamicQuestion(
                                      q,
                                      isDark,
                                      homeTeam,
                                      awayTeam,
                                    ),
                                  ),
                                ],
                              ),
                              if (!widget.isReadOnly)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: _buildStickySubmitArea(isDark),
                                ),
                            ],
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickySubmitArea(bool isDark) {
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        20.w,
        40.h,
        20.w,
        32.h,
      ), // Increased top padding for smoother fade
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.4],
          colors:
              isDark
                  ? [
                    const Color(0xFF070B14).withOpacity(0.0),
                    const Color(0xFF070B14).withOpacity(0.95),
                  ]
                  : [
                    const Color(0xFFE2E8F0).withOpacity(0.0),
                    const Color(0xFFE2E8F0).withOpacity(0.95),
                  ],
        ),
      ),
      child: _buildSubmitButton(isDark),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56.h, // Slightly taller for premium feel
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.w), // Full pill-shape
        gradient: LinearGradient(
          colors: [
            GoalioColors.greenAccent,
            const Color(0xFF059669),
          ], // Brighter gradient tone
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: GoalioColors.greenAccent.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8), // Deeper floating shadow
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitPredictions,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.w),
          ),
        ),
        child:
            _isSubmitting
                ? SizedBox(
                  height: 24.h,
                  width: 24.h,
                  child: const CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 3,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons
                          .check_circle_rounded, // Filled circle looks more grounded inside pill
                      color: Colors.black87,
                      size: 20.w,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.submitPrediction.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildDynamicQuestion(
    Map<String, dynamic> q,
    bool isDark,
    String homeTeam,
    String awayTeam,
  ) {
    Widget child;
    final qId = q['id'];
    final currentAnswer = _answers[qId];

    switch (q['type']) {
      case 'team_select':
        child = _buildSegmentedButtons(
          options: [homeTeam, AppLocalizations.of(context)!.draw, awayTeam],
          selectedValue: currentAnswer,
          onChanged: (val) {
            String dbVal;
            if (val == homeTeam)
              dbVal = 'home';
            else if (val == awayTeam)
              dbVal = 'away';
            else
              dbVal = 'draw';
            setState(() => _answers[qId] = dbVal);
          },
          isDark: isDark,
          displayMapper: (val) {
            if (val == 'home') return homeTeam;
            if (val == 'away') return awayTeam;
            if (val == 'draw') return AppLocalizations.of(context)!.draw;
            return val;
          },
        );
        break;
      case 'team_select_none':
        child = _buildSegmentedButtons(
          options: [homeTeam, AppLocalizations.of(context)!.none, awayTeam],
          selectedValue: currentAnswer,
          onChanged: (val) {
            String dbVal;
            if (val == homeTeam)
              dbVal = 'home';
            else if (val == awayTeam)
              dbVal = 'away';
            else
              dbVal = 'none';
            setState(() => _answers[qId] = dbVal);
          },
          isDark: isDark,
          displayMapper: (val) {
            if (val == 'home') return homeTeam;
            if (val == 'away') return awayTeam;
            if (val == 'none') return AppLocalizations.of(context)!.none;
            return val;
          },
        );
        break;
      case 'select':
      case 'boolean':
        List<String> opts =
            (q['options'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        if (opts.length > 5) {
          child = _buildDropdownSelector(
            options: opts,
            selectedValue: currentAnswer,
            onChanged: (val) => setState(() => _answers[qId] = val),
            isDark: isDark,
          );
        } else {
          child = _buildSegmentedButtons(
            options: opts,
            selectedValue: currentAnswer,
            onChanged: (val) => setState(() => _answers[qId] = val),
            isDark: isDark,
          );
        }
        break;
      case 'score':
        int homeScore = 0;
        int awayScore = 0;
        if (currentAnswer != null && currentAnswer.contains('-')) {
          final parts = currentAnswer.split('-');
          if (parts.length == 2) {
            homeScore = int.tryParse(parts[0]) ?? 0;
            awayScore = int.tryParse(parts[1]) ?? 0;
          }
        }
        child = Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildScoreSelector(
              homeTeam,
              homeScore,
              (val) => setState(() => _answers[qId] = "$val-$awayScore"),
              isDark,
            ),
            Text(
              ":",
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            _buildScoreSelector(
              awayTeam,
              awayScore,
              (val) => setState(() => _answers[qId] = "$homeScore-$val"),
              isDark,
            ),
          ],
        );
        break;
      case 'text':
      default:
        child = _buildTextInput(
          hint: AppLocalizations.of(context)!.enterPredictionHint,
          isDark: isDark,
          initialValue: widget.isReadOnly && currentAnswer != null 
              ? currentAnswer.toArabicNumbers(context)
              : (currentAnswer ?? ""),
          onChanged: (val) => _answers[qId] = val,
        );
        break;
    }

    return _buildQuestionCard(
      isDark: isDark,
      number: q['order_num'] ?? 0,
      points: q['points'] ?? 0,
      question: ArabicNameExtension(q['question']?.toString() ?? "").toArabicName(context).toArabicNumbers(context),
      isCorrect:
          widget.isReadOnly
              ? (q['is_correct'] == true || q['is_correct'] == 1)
              : null,
      child: child,
    );
  }

  Widget _buildStadiumHeader(bool isDark, String homeTeam, String awayTeam) {
    final status = widget.match['status']?.toString() ?? 'TBD';
    final bool started =
        status != 'PRE' &&
        status != 'TBD' &&
        status != 'VS' &&
        status != 'Scheduled' &&
        status != 'Not Started' &&
        status != 'NS' &&
        !status.contains(':');

    // Robust score extraction
    String homeScore =
        (widget.match['home_score'] == null ||
                widget.match['home_score'] == 'N/A')
            ? '0'
            : widget.match['home_score'].toString();
    String awayScore =
        (widget.match['away_score'] == null ||
                widget.match['away_score'] == 'N/A')
            ? '0'
            : widget.match['away_score'].toString();

    // Add penalty support if available
    if (widget.match['home_score_pen'] != null &&
        widget.match['away_score_pen'] != null) {
      homeScore += "(${widget.match['home_score_pen']})";
      awayScore += "(${widget.match['away_score_pen']})";
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsetsDirectional.fromSTEB(16.w, 0, 16.w, 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(
          color: GoalioColors.greenAccent.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: GoalioColors.greenAccent.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.w),
        child: Stack(
          children: [
            // Split background
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      color:
                          isDark
                              ? const Color(0xFF0D1B2A)
                              : const Color(0xFF1B3A5C),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color:
                          isDark
                              ? const Color(0xFF1A0D2A)
                              : const Color(0xFF2D1B5C),
                    ),
                  ),
                ],
              ),
            ),
            // Green center divider
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 1.5,
                  color: GoalioColors.greenAccent.withOpacity(0.3),
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                children: [
                  // Home team
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            homeTeam.toArabicName(context),
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          width: 44.w,
                          height: 44.w,
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.2),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: buildTeamLogo(
                            widget.match['home_logo'],
                            size: 25.w,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // VS center section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        started
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    homeScore.toString().toArabicNumbers(context),
                                    style: TextStyle(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w900,
                                      color: GoalioColors.greenAccent,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  Text(
                                    "-",
                                    style: TextStyle(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w900,
                                      color: GoalioColors.greenAccent,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  Text(
                                    awayScore.toString().toArabicNumbers(context),
                                    style: TextStyle(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w900,
                                      color: GoalioColors.greenAccent,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                Localizations.maybeLocaleOf(context)?.languageCode == 'ar' ? "ضد" : "VS",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: GoalioColors.greenAccent,
                                  letterSpacing: 2,
                                ),
                              ),
                        SizedBox(height: 4.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: GoalioColors.greenAccent.withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(8.w),
                            border: Border.all(
                              color: GoalioColors.greenAccent.withOpacity(
                                0.25,
                              ),
                            ),
                          ),
                          child: Text(
                            started &&
                                    (status == 'HT' ||
                                        status == 'FT' ||
                                        status.contains("'"))
                                ? localizeMatchStatus(context, status).toArabicNumbers(context)
                                : _formatFullDateTime(
                                    widget.match['match_time']?.toString(),
                                  ).toArabicNumbers(context),
                            style: TextStyle(
                              fontSize: 7.5.sp,
                              fontWeight: FontWeight.w800,
                              color: GoalioColors.greenAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Away team
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44.w,
                          height: 44.w,
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.2),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: buildTeamLogo(
                            widget.match['away_logo'],
                            size: 25.w,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            awayTeam.toArabicName(context),
                            textAlign: TextAlign.start,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildQuestionCard({
    required bool isDark,
    required int number,
    required int points,
    required String question,
    bool? isCorrect,
    required Widget child,
  }) {
    Color accentColor = GoalioColors.greenAccent;
    Color cardBg = isDark ? const Color(0xFF111827) : Colors.white;

    Color headerStart =
        isDark
            ? GoalioColors.greenAccent.withOpacity(0.15)
            : GoalioColors.greenAccent.withOpacity(0.08);
    Color headerEnd =
        isDark
            ? GoalioColors.blueAccent.withOpacity(0.15)
            : GoalioColors.blueAccent.withOpacity(0.08);

    if (widget.isReadOnly && isCorrect != null) {
      accentColor = isCorrect ? GoalioColors.greenAccent : Colors.redAccent;
      headerStart =
          isCorrect
              ? (isDark
                  ? const Color(0xFF064E3B).withOpacity(0.6)
                  : const Color(0xFFD1FAE5))
              : (isDark
                  ? const Color(0xFF7F1D1D).withOpacity(0.6)
                  : const Color(0xFFFEE2E2));
      headerEnd =
          isCorrect
              ? (isDark
                  ? const Color(0xFF022C22).withOpacity(0.8)
                  : const Color(0xFFA7F3D0))
              : (isDark
                  ? const Color(0xFF450A0A).withOpacity(0.8)
                  : const Color(0xFFFECACA));
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: accentColor.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER (Modern Sports Card) ──────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 14.w, 10.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [headerStart, headerEnd],
                ),
                border: Border(
                  bottom: BorderSide(
                    color:
                        isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Q Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6.w),
                      border: Border.all(
                        color: accentColor.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      '$number'.toArabicNumbers(context),
                      style: TextStyle(
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  // Question
                  Expanded(
                    child: Text(
                      ArabicNameExtension(question).toArabicName(context),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  // Points
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.ptsShort.toUpperCase(),
                        style: TextStyle(
                          fontSize: 6.sp,
                          fontWeight: FontWeight.w900,
                          color: accentColor.withOpacity(0.6),
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '+$points'.toArabicNumbers(context),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── BODY ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedButtons({
    required List<String> options,
    required String? selectedValue,
    required Function(String) onChanged,
    required bool isDark,
    String? Function(String)? displayMapper,
  }) {
    String? displaySelectedValue =
        selectedValue != null
            ? (displayMapper?.call(selectedValue) ?? selectedValue)
            : null;

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 8.w,
        runSpacing: 6.h,
        alignment: WrapAlignment.center,
        children:
            options.map((option) {
              final isSelected = displaySelectedValue == option;
              return GestureDetector(
                onTap: widget.isReadOnly ? null : () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCirc,
                  width:
                      options.length <= 3
                          ? null
                          : null, // Let it wrap naturally but efficiently
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? GoalioColors.greenAccent
                            : (isDark
                                ? Colors.white.withOpacity(0.03)
                                : Colors.white),
                    borderRadius: BorderRadius.circular(8.w),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: GoalioColors.greenAccent.withOpacity(
                                  0.4,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                            : [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                            ],
                  ),
                  child: Text(
                    ArabicNameExtension(option.toString()).toArabicName(context).toArabicNumbers(context),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight:
                          isSelected ? FontWeight.w900 : FontWeight.w700,
                      letterSpacing: isSelected ? 0.2 : 0,
                      color:
                          isSelected
                              ? const Color(
                                0xFF0F172A,
                              ) // Deep dark for contrast on green
                              : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569)),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildDropdownSelector({
    required List<String> options,
    required String? selectedValue,
    required Function(String) onChanged,
    required bool isDark,
  }) {
    // Determine the active selection (must match exactly or stay null)
    final String? effectiveValue =
        options.contains(selectedValue) ? selectedValue : null;

    return InkWell(
      onTap:
          widget.isReadOnly
              ? null
              : () {
                _showSearchableBottomSheet(
                  context: context,
                  options: options,
                  selectedValue: effectiveValue,
                  onChanged: onChanged,
                  isDark: isDark,
                );
              },
      borderRadius: BorderRadius.circular(12.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161F2C) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          effectiveValue == null
                              ? AppLocalizations.of(context)!.tapToSearch
                              : (effectiveValue.contains(' - ')
                                  ? ArabicNameExtension(effectiveValue.split(' - ')[0]).toArabicName(context).toArabicNumbers(context)
                                  : ArabicNameExtension(effectiveValue).toArabicName(context).toArabicNumbers(context)),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight:
                            effectiveValue == null
                                ? FontWeight.normal
                                : FontWeight.w600,
                        color:
                            effectiveValue == null
                                ? (isDark ? Colors.white54 : Colors.black54)
                                : (isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A)),
                        fontFamily: 'RobotoCondensed',
                      ),
                    ),
                    if (effectiveValue != null &&
                        effectiveValue.contains(' - '))
                      TextSpan(
                        text: "   ${ArabicNameExtension(effectiveValue.split(' - ').last).toArabicName(context)}",
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white38 : Colors.black45,
                          fontFamily: 'RobotoCondensed',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Icon(
              Icons.search_rounded,
              color: GoalioColors.greenAccent,
              size: 20.w,
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchableBottomSheet({
    required BuildContext context,
    required List<String> options,
    required String? selectedValue,
    required Function(String) onChanged,
    required bool isDark,
  }) {
    String searchQuery = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final filteredOptions =
                options
                    .where(
                      (opt) =>
                          opt.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          ArabicNameExtension(opt).toArabicName(context).toLowerCase().contains(searchQuery.toLowerCase()),
                    )
                    .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.w)),
              ),
              child: Column(
                children: [
                  // Handle indicator
                  Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 12.h),
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 8.h,
                    ),
                    child: TextField(
                      autofocus: true,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onChanged: (val) {
                        setState(() {
                          searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchPlaceholder,
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: GoalioColors.greenAccent,
                          size: 22.w,
                        ),
                        filled: true,
                        fillColor:
                            isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.w),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // Options List
                  Expanded(
                    child:
                        filteredOptions.isEmpty
                            ? Center(
                              child: Text(
                                AppLocalizations.of(context)!.noMatchesFound,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color:
                                      isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            )
                            : ListView.builder(
                              itemCount: filteredOptions.length,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              itemBuilder: (context, index) {
                                final option = filteredOptions[index];
                                final isSelected = option == selectedValue;

                                return InkWell(
                                  onTap: () {
                                    onChanged(option);
                                    Navigator.pop(ctx);
                                  },
                                  borderRadius: BorderRadius.circular(12.w),
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 6.h),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 14.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? GoalioColors.greenAccent
                                                  .withOpacity(0.1)
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12.w),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? GoalioColors.greenAccent
                                                    .withOpacity(0.3)
                                                : (isDark
                                                    ? Colors.white.withOpacity(
                                                      0.05,
                                                    )
                                                    : Colors.black.withOpacity(
                                                      0.03,
                                                    )),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: RichText(
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      option.contains(' - ')
                                                          ? ArabicNameExtension(option.split(' - ')[0]).toArabicName(context).toArabicNumbers(context)
                                                          : ArabicNameExtension(option).toArabicName(context).toArabicNumbers(context),
                                                  style: TextStyle(
                                                    fontSize: 13.sp,
                                                    fontWeight:
                                                        isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.w500,
                                                    color:
                                                        isDark
                                                            ? Colors.white
                                                            : const Color(
                                                              0xFF0F172A,
                                                            ),
                                                    fontFamily:
                                                        'RobotoCondensed',
                                                  ),
                                                ),
                                                if (option.contains(' - '))
                                                  TextSpan(
                                                    text:
                                                        "   ${ArabicNameExtension(option.split(' - ').last).toArabicName(context).toArabicNumbers(context)}",
                                                    style: TextStyle(
                                                      fontSize: 11.5.sp,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color:
                                                          isDark
                                                              ? Colors.white54
                                                              : Colors.black45,
                                                      fontFamily:
                                                          'RobotoCondensed',
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: GoalioColors.greenAccent,
                                            size: 20.w,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScoreSelector(
    String team,
    int score,
    Function(int) onChanged,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          team.toUpperCase(), // ALL CAPS for sports feel
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161F2C) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(30.w), // Full pill shape
            border: Border.all(
              color:
                  isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildScoreButton(
                icon: Icons.remove_rounded,
                onPressed:
                    (!widget.isReadOnly && score > 0)
                        ? () => onChanged(score - 1)
                        : null,
                isDark: isDark,
                active: !widget.isReadOnly && score > 0,
              ),
              Container(
                width: 36.w,
                alignment: Alignment.center,
                child: Text(
                  '$score'.toArabicNumbers(context),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              _buildScoreButton(
                icon: Icons.add_rounded,
                onPressed:
                    widget.isReadOnly ? null : () => onChanged(score + 1),
                isDark: isDark,
                active: !widget.isReadOnly,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isDark,
    required bool active,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color:
              active
                  ? GoalioColors.greenAccent
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
          shape: BoxShape.circle,
          boxShadow:
              active
                  ? [
                    BoxShadow(
                      color: GoalioColors.greenAccent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                  ],
        ),
        child: Icon(
          icon,
          size: 14.w,
          color:
              active
                  ? const Color(
                    0xFF0F172A,
                  ) // Dark icon on neon background for max contrast
                  : (isDark ? Colors.white54 : Colors.black54),
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required String hint,
    required bool isDark,
    required String initialValue,
    required Function(String) onChanged,
  }) {
    final controller = TextEditingController(text: initialValue);
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F2C) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24.w), // Sleek pill shape
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: widget.isReadOnly,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
          filled: false,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 16.h,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24.w),
            borderSide: BorderSide(color: GoalioColors.greenAccent, width: 2),
          ),
        ),
      ),
    );
  }
}
