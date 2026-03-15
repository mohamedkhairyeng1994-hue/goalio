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
                          // Responsive grid: 1 column for small screens, 2 for medium, 3 for large
                          int crossAxisCount = 1;
                          double childAspectRatio = 5.0;

                          if (constraints.maxWidth > 1200) {
                            crossAxisCount = 3;
                            childAspectRatio = 5.5;
                          } else if (constraints.maxWidth > 800) {
                            crossAxisCount = 2;
                            childAspectRatio = 5.8;
                          } else if (constraints.maxWidth > 600) {
                            crossAxisCount = 2;
                            childAspectRatio = 6.0;
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
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              // Logo with enhanced styling
                                              Container(
                                                width: 52,
                                                height: 52,
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
                                                      league['name']
                                                              ?.toString() ??
                                                          'Unknown',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: textColor,
                                                        fontWeight:
                                                            FontWeight.bold,
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
