import 'package:flutter/material.dart';
import 'package:gravity_app/features/dashboard/widgets/daily_checklist.dart';
import 'package:gravity_app/features/dashboard/widgets/daily_task_card.dart';
import 'package:gravity_app/features/dashboard/widgets/games_unlocked_cta.dart';
import 'package:gravity_app/features/dashboard/widgets/section_header.dart';
import 'package:gravity_app/features/daily_sentences/daily_sentence_card.dart';

class DailyTasksTab extends StatelessWidget {
  final GlobalKey? dailyChecklistKey;

  // Progress Flags
  final bool isVocabDone;
  final bool isVerbsDone;
  final bool isSpeakingDone;
  final bool isQuizDone;

  // Scores
  final int vocabScore;
  final int verbsScore;
  final int speakingScore;
  final int quizScore;

  final double savedDailyWordCount;

  final String? vocabDayLabel;
  final String? verbsDayLabel;
  final String preferredLanguage;

  // Callbacks
  final VoidCallback onVocabularyTap;
  final VoidCallback onVerbsTap;
  final VoidCallback onPronunciationTap;
  final VoidCallback onYesterdayTap;
  final VoidCallback onGamesUnlockTap;
  final VoidCallback? onSentenceCompleted;

  const DailyTasksTab({
    super.key,
    this.dailyChecklistKey,
    required this.isVocabDone,
    required this.isVerbsDone,
    required this.isSpeakingDone,
    required this.isQuizDone,
    required this.vocabScore,
    required this.verbsScore,
    required this.speakingScore,
    required this.quizScore,
    required this.savedDailyWordCount,
    this.vocabDayLabel,
    this.verbsDayLabel,
    required this.onVocabularyTap,
    required this.onVerbsTap,
    required this.onPronunciationTap,
    required this.onYesterdayTap,
    required this.onGamesUnlockTap,
    required this.preferredLanguage,
    this.onSentenceCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8), // Give room for floating badge
          // 1. Learning Checklist
          DailyChecklist(
            tutorialKey: dailyChecklistKey,
            isVocabDone: isVocabDone,
            isVerbsDone: isVerbsDone,
            isSpeakingDone: isSpeakingDone,
            isQuizDone: isQuizDone,
            dayLabel: vocabDayLabel,
            onVocabTap: onVocabularyTap,
            onVerbsTap: onVerbsTap,
            onSpeakingTap: onPronunciationTap,
            onQuizTap: onYesterdayTap,
          ),

          if (isVocabDone && isVerbsDone && isSpeakingDone) ...[
            const SizedBox(height: 16),
            GamesUnlockedCTA(onTap: onGamesUnlockTap),
          ],

          const SizedBox(height: 16),

          const SectionHeader(title: "Learning Activities"),

          // Previous Level Review (Priority)
          DailyTaskCard(
            title: "Assessment",
            subtitle:
                "Complete this checkpoint to unlock the next learning step",
            icon: Icons.history_edu_rounded,
            color: const Color(0xFFFF6B6B),
            animationType: 'stamp',
            isDone: isQuizDone,
            scorePercentage: quizScore,
            onTap: onYesterdayTap,
          ),
          const SizedBox(height: 10),

          // Vocabulary Practice
          DailyTaskCard(
            title: "Vocabulary Practice",
            subtitle:
                "Learn ${savedDailyWordCount.round()} words for this step",
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF4FACFE),
            animationType: 'hop',
            isDone: isVocabDone,
            scorePercentage: vocabScore,
            showCompletedLabel: false,
            showScoreBadge: false,
            showTickBadgeWhenDone: true,
            onTap: onVocabularyTap,
          ),
          const SizedBox(height: 10),

          // Verb Practice
          DailyTaskCard(
            title: "Verb Practice",
            subtitle: "Practice regular and irregular verbs",
            icon: Icons.change_circle_rounded,
            color: const Color(0xFFC779D0),
            animationType: 'spin',
            isDone: isVerbsDone,
            scorePercentage: verbsScore,
            showCompletedLabel: false,
            showScoreBadge: false,
            showTickBadgeWhenDone: true,
            onTap: onVerbsTap,
          ),
          const SizedBox(height: 10),

          // Speaking Practice
          DailyTaskCard(
            title: "Speaking Practice",
            subtitle: "Speak 5 prompts clearly",
            icon: Icons.mic_external_on_rounded,
            color: const Color(0xFF00E5FF),
            animationType: 'speaking',
            isDone: isSpeakingDone,
            scorePercentage: speakingScore,
            showCompletedLabel: false,
            showScoreBadge: false,
            showTickBadgeWhenDone: true,
            onTap: onPronunciationTap,
          ),

          // Bonus: Daily Sentences
          DailySentenceCard(
            preferredLanguage: preferredLanguage,
            onCompleted: onSentenceCompleted,
          ),
        ],
      ),
    );
  }
}
