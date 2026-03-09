import 'package:flutter/material.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/screens/daily_review_screen.dart'; // Reuse the review screen, might need modification
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class MissedLessonsScreen extends StatefulWidget {
  const MissedLessonsScreen({super.key});

  @override
  State<MissedLessonsScreen> createState() => _MissedLessonsScreenState();
}

class _MissedLessonsScreenState extends State<MissedLessonsScreen> {
  final DataService _dataService = DataService();
  bool _isLoading = true;
  List<DateTime> _missedDates = [];

  @override
  void initState() {
    super.initState();
    _loadMissedDates();
  }

  Future<void> _loadMissedDates() async {
    final dates = await _dataService.getMissedDates();
    if (mounted) {
      setState(() {
        _missedDates = dates;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Missed Lessons"),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _missedDates.isEmpty
          ? _buildEmptyState()
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orangeAccent,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "${_missedDates.length} Missed Lessons",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Recover at your own pace - one day at a time.",
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Passive List for Reference
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Missed Dates:",
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceContainerHigh.withValues(
                                alpha: 0.65,
                              )
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _missedDates.length,
                        separatorBuilder: (_, __) => Divider(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.45,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final date = _missedDates[index];
                          final dateStr = DateFormat(
                            'MMMM d, yyyy',
                          ).format(date);
                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(
                                dateStr,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                "Tap to recover this day",
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6C63FF,
                                  ).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Color(0xFF6C63FF),
                                  size: 16,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DailyReviewScreen(missedDates: [date]),
                                  ),
                                ).then((_) => _loadMissedDates());
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Keep _buildEmptyState as is from previous code...
  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.greenAccent,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            "All Caught Up!",
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You have no missed lessons.\nKeep up the great work!",
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}
