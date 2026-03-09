import 'package:flutter/material.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/screens/daily_quiz_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/tts_service.dart';
import 'package:gravity_app/services/stage_content_service.dart';

class DailyReviewScreen extends StatefulWidget {
  final int? stage; // Optional level-specific review
  final DateTime? date; // Optional specific date
  final List<DateTime> missedDates; // New: Aggregated dates for recovery

  const DailyReviewScreen({
    super.key,
    this.stage,
    this.date,
    this.missedDates = const [],
  });

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> {
  final DataService _dataService = DataService();
  final TtsService _ttsService = TtsService();
  bool _isLoading = true;
  List<Map<String, String>> _vocabList = [];
  List<Map<String, String>> _verbList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      List<Map<String, String>> allVocab = [];
      List<Map<String, String>> allVerbs = [];

      if (widget.missedDates.isNotEmpty) {
        // AGGREGATION MODE (Recovery)
        for (final d in widget.missedDates) {
          final vocab = await _dataService.getItemsForDate('vocabulary', d);
          final verbs = await _dataService.getItemsForDate('verbs', d);
          allVocab.addAll(vocab);
          allVerbs.addAll(verbs);
        }
      } else if (widget.stage != null && widget.stage! > 0) {
        // LEVEL MODE (Assessment entry)
        final preferredLanguage = await _dataService.getUserLanguage();
        allVocab = await StageContentService().getVocabularyMapsForStage(
          widget.stage!,
          preferredLanguage: preferredLanguage,
        );
        allVerbs = await StageContentService().getVerbMapsForStage(
          widget.stage!,
          preferredLanguage: preferredLanguage,
        );
      } else {
        // SINGLE DAY / YESTERDAY MODE
        final targetDate =
            widget.date ?? DateTime.now().subtract(const Duration(days: 1));
        allVocab = await _dataService.getItemsForDate('vocabulary', targetDate);
        allVerbs = await _dataService.getItemsForDate('verbs', targetDate);
      }

      if (mounted) {
        setState(() {
          _vocabList = allVocab;
          _verbList = allVerbs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRecovery = widget.missedDates.isNotEmpty;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isRecovery ? "Recovery Session" : "Daily Review"),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isRecovery
                        ? "Missed Lessons Recovery"
                        : "Yesterday's Lessons",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRecovery
                        ? "Catch up on ${widget.missedDates.length} missed days."
                        : "Quick review before your daily quiz.",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Vocab Section
                  if (_vocabList.isNotEmpty) ...[
                    _buildSectionHeader("Vocabulary"),
                    ..._vocabList.map(
                      (item) => _buildReviewCard(
                        title:
                            "${item['word'] ?? ''} (${item['pos'] ?? 'Word'})",
                        subtitle:
                            item['tamil_meaning'] ?? (item['meaning'] ?? ''),
                        icon: Icons.book_rounded,
                        color: const Color(0xFF4FACFE),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Verbs Section (unchanged)
                  if (_verbList.isNotEmpty) ...[
                    _buildSectionHeader("Verbs"),
                    ..._verbList.map(
                      (item) => _buildReviewCard(
                        title: item['word'] ?? '',
                        subtitle:
                            "${item['forms'] ?? ''}\n${item['tamil_meaning'] ?? ''}",
                        icon: Icons.change_circle_rounded,
                        color: const Color(0xFFC779D0),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],

                  // Start Quiz Button
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: () async {
                        final preferredLanguage = await _dataService
                            .getUserLanguage();
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DailyQuizScreen(
                              vocabList: _vocabList,
                              verbList: _verbList,
                              preferredLanguage: preferredLanguage,
                              stage: widget.stage,
                              date: widget.date, // Pass single date if exists
                              coveredDates: widget
                                  .missedDates, // Pass list for aggregation
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Start Quiz",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FutureBuilder<bool>(
            future: _ttsService.isWordRead(title.split(' (')[0]),
            builder: (context, snapshot) {
              final isRead = snapshot.data ?? false;
              return IconButton(
                onPressed: () async {
                  await _ttsService.speak(title.split(' (')[0]);
                  setState(() {});
                },
                icon: Icon(
                  Icons.volume_up_rounded,
                  color: isRead
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }
}
