import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/screens/focused_quiz_screen.dart';
import 'package:gravity_app/services/tts_service.dart';

class AssignmentScreen extends StatefulWidget {
  final List<Map<String, String>> wrongAnswers;
  final int score;
  final int total;
  final String preferredLanguage;

  const AssignmentScreen({
    super.key,
    required this.wrongAnswers,
    required this.score,
    required this.total,
    required this.preferredLanguage,
  });

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final TtsService _ttsService = TtsService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surface;
    final subtitleColor = colorScheme.onSurfaceVariant;

    final scoreColor = widget.total > 0 && (widget.score / widget.total) >= 0.7
        ? Colors.greenAccent
        : Colors.orangeAccent;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Review Mistakes"),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.fact_check_rounded, color: scoreColor, size: 46)
                      .animate()
                      .scale(duration: 420.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 12),
                  Text(
                    "${widget.score}/${widget.total}",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Review these answers, then retake the quiz.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.list_alt_rounded, color: subtitleColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Incorrect Answers (${widget.wrongAnswers.length})",
                  style: TextStyle(
                    color: subtitleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.wrongAnswers.map((e) {
              final word = e['word'] ?? '';
              final type = e['type'] ?? 'vocab';
              final correct = e['correct_answer'] ?? '';
              return _buildItem(
                title: word,
                type: type,
                correctAnswer: correct,
              );
            }),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FocusedQuizScreen(),
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
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Retake Quiz"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatType(String type) {
    switch (type.trim().toLowerCase()) {
      case 'verb':
        return 'Verb';
      case 'sentence':
        return 'Sentence';
      case 'vocab':
        return 'Vocabulary';
      default:
        return 'Word';
    }
  }

  Widget _buildItem({
    required String title,
    required String type,
    required String correctAnswer,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<bool>(
      future: _ttsService.isWordRead(title),
      builder: (context, snapshot) {
        final isRead = snapshot.data ?? false;
        final safeTitle = title.trim().isEmpty ? 'Unknown' : title.trim();
        final safeCorrect = correctAnswer.trim().isEmpty
            ? 'No answer available.'
            : correctAnswer.trim();
        final typeLabel = _formatType(type);
        final answerLabel = type.trim().toLowerCase() == 'verb'
            ? 'Correct form'
            : 'Correct answer';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 2,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              iconColor: colorScheme.onSurfaceVariant,
              collapsedIconColor: colorScheme.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: Icon(
                isRead ? Icons.check_circle_rounded : Icons.circle,
                size: isRead ? 18 : 10,
                color: isRead
                    ? Colors.greenAccent
                    : colorScheme.onSurfaceVariant,
              ),
              title: Text(
                safeTitle,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                typeLabel,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      size: 16,
                      color: Colors.amber.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: '$answerLabel: ',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: safeCorrect),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.volume_up_rounded,
                        color: isRead
                            ? Colors.greenAccent
                            : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () async {
                        await _ttsService.speak(safeTitle);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
