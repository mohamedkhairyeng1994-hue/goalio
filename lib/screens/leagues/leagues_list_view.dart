import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';

class LeaguesListView extends StatelessWidget {
  final List<Map<String, dynamic>> leagues;
  final bool isLoading;
  final bool isScraping;
  final String? scrapingLeagueName;
  final Map<String, dynamic>? selectedLeague;
  final Future<void> Function() onRefresh;
  final Function(Map<String, dynamic>) onLeagueTap;
  final Function(Map<String, dynamic>)? onToggleFavorite;
  final bool isLoadingMore;
  final List<String> enabledLeagues;
  final ScrollController? controller;

  const LeaguesListView({
    super.key,
    required this.leagues,
    required this.isLoading,
    this.isLoadingMore = false,
    required this.isScraping,
    this.scrapingLeagueName,
    this.selectedLeague,
    required this.onRefresh,
    required this.onLeagueTap,
    this.onToggleFavorite,
    this.enabledLeagues = const [],
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    return Column(
      children: [
        // Leagues grid - Responsive
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            color: GoalioColors.greenAccent,
            backgroundColor:
                isDark ? GoalioColors.cardBackground : Colors.white,
            child:
                isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: GoalioColors.greenAccent,
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 1;
                          double childAspectRatio = 4.8; // Increased from 3.2 to decrease height

                          if (constraints.maxWidth > 1200) {
                            crossAxisCount = 3;
                            childAspectRatio = 4.0;
                          } else if (constraints.maxWidth > 800) {
                            crossAxisCount = 2;
                            childAspectRatio = 4.2;
                          } else if (constraints.maxWidth > 600) {
                            crossAxisCount = 2;
                            childAspectRatio = 4.5;
                          }

                          if (leagues.isEmpty) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: constraints.maxHeight * 0.3),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.sports_soccer,
                                        size: 48,
                                        color: secondaryTextColor.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No leagues found',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          return GridView.builder(
                            controller: controller,
                            physics: const AlwaysScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: childAspectRatio,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: leagues.length + (isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == leagues.length) {
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
                              if (index < 0 || index >= leagues.length) {
                                return const SizedBox.shrink();
                              }
                              final league = leagues[index];
                              final isSelected =
                                  selectedLeague != null &&
                                  selectedLeague!['name'] == league['name'];
                              final isEnabled =
                                  enabledLeagues.isEmpty ||
                                  enabledLeagues.contains(
                                    league['original_name'] ?? league['name'],
                                  );

                              return GestureDetector(
                                key: ValueKey(
                                  '${league['id']}_${league['is_favorite_league']}',
                                ),
                                onTap: () {
                                  if (isScraping || !isEnabled) return;
                                  onLeagueTap(league);
                                },
                                child: Opacity(
                                  opacity: isEnabled ? 1.0 : 0.6,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          isSelected
                                              ? GoalioColors.greenAccent
                                                  .withOpacity(
                                                    isDark ? 0.25 : 0.15,
                                                  )
                                              : (isDark
                                                  ? Colors.white.withOpacity(
                                                    0.05,
                                                  )
                                                  : const Color(0xFFF8FAFC)),
                                          isSelected
                                              ? GoalioColors.greenAccent
                                                  .withOpacity(
                                                    isDark ? 0.1 : 0.05,
                                                  )
                                              : (isDark
                                                  ? Colors.white.withOpacity(
                                                    0.02,
                                                  )
                                                  : Colors.white),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? GoalioColors.greenAccent
                                                : (isDark
                                                    ? Colors.white.withOpacity(
                                                      0.1,
                                                    )
                                                    : const Color(0xFFE2E8F0)),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow:
                                          isSelected
                                              ? [
                                                BoxShadow(
                                                  color: GoalioColors
                                                      .greenAccent
                                                      .withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                              : (isDark
                                                  ? []
                                                  : [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.04),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ]),
                                    ),
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8, // Decreased from 12
                                          ),
                                          child: Row(
                                            children: [
                                              // Logo with enhanced styling
                                              Container(
                                                width: 44, // Decreased from 52
                                                height: 44, // Decreased from 52
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                        isSelected
                                                            ? GoalioColors
                                                                .greenAccent
                                                            : Colors.black
                                                                .withOpacity(
                                                                  0.05,
                                                                ),
                                                    width: 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          isSelected
                                                              ? GoalioColors
                                                                  .greenAccent
                                                                  .withOpacity(
                                                                    0.2,
                                                                  )
                                                              : Colors.black
                                                                  .withOpacity(
                                                                    0.05,
                                                                  ),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child:
                                                    league['logo_url'] !=
                                                                null &&
                                                            league['logo_url']
                                                                .toString()
                                                                .isNotEmpty
                                                        ? Image.network(
                                                          league['logo_url'],
                                                          fit: BoxFit.contain,
                                                          errorBuilder:
                                                              (
                                                                c,
                                                                o,
                                                                s,
                                                              ) => const Icon(
                                                                Icons
                                                                    .emoji_events,
                                                                color:
                                                                    GoalioColors
                                                                        .greenAccent,
                                                                size: 24,
                                                              ),
                                                        )
                                                        : const Icon(
                                                          Icons.emoji_events,
                                                          color:
                                                              GoalioColors
                                                                  .greenAccent,
                                                          size: 24,
                                                        ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        (() {
                                                          final isAr = Localizations.localeOf(context).languageCode == 'ar';
                                                          return (isAr ? league['name_ar'] ?? league['name'] : league['name']) ?? 'Unknown';
                                                        })(),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          color: textColor,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    if (!isEnabled)
                                                      Text(
                                                        'COMING SOON',
                                                        style: TextStyle(
                                                          color: GoalioColors
                                                              .greenAccent
                                                              .withOpacity(0.5),
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          fontSize: 8,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              if (!isEnabled)
                                                Icon(
                                                  Icons.lock_outline,
                                                  size: 16,
                                                  color: secondaryTextColor
                                                      .withOpacity(0.3),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (isEnabled && onToggleFavorite != null)
                                          PositionedDirectional(
                                            top: 8,
                                            end: 8,
                                            child: GestureDetector(
                                              onTap: () => onToggleFavorite!(league),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  league['is_favorite_league'] == true
                                                      ? Icons.star_rounded
                                                      : Icons.star_outline_rounded,
                                                  color: league['is_favorite_league'] == true
                                                      ? Colors.amber
                                                      : (isDark ? Colors.white38 : Colors.black26),
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
          ),
        ),
      ],
    );
  }
}
