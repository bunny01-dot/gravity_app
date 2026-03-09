import 'package:flutter/material.dart';
import 'package:gravity_app/features/dashboard/widgets/daily_task_card.dart';
import 'package:gravity_app/services/daily_task_completion_service.dart';

class DashboardDailyTasksSection extends StatelessWidget {
  final Widget sectionHeader;
  final double savedDailyWordCount;
  final bool isQuizDone;
  final bool isVocabDone;
  final bool isVerbsDone;
  final bool isSpeakingDone;
  final int quizScore;
  final int vocabScore;
  final int verbsScore;
  final int speakingScore;
  final VoidCallback onAssessmentTap;
  final VoidCallback onVocabularyTap;
  final VoidCallback onVerbsTap;
  final VoidCallback onSpeakingTap;

  const DashboardDailyTasksSection({
    super.key,
    required this.sectionHeader,
    required this.savedDailyWordCount,
    required this.isQuizDone,
    required this.isVocabDone,
    required this.isVerbsDone,
    required this.isSpeakingDone,
    required this.quizScore,
    required this.vocabScore,
    required this.verbsScore,
    required this.speakingScore,
    required this.onAssessmentTap,
    required this.onVocabularyTap,
    required this.onVerbsTap,
    required this.onSpeakingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sectionHeader,

        // Previous Level Quiz Task (Priority)
        DailyTaskCard(
          title: "Assessment",
          subtitle: "Complete this checkpoint to unlock the next learning step",
          icon: Icons.assignment_turned_in_rounded,
          color: const Color(0xFF6C63FF),
          animationType: 'pulse',
          isDone: isQuizDone,
          scorePercentage: quizScore,
          onTap: onAssessmentTap,
        ),
        // Vocabulary Practice
        DailyTaskCard(
          title: "Vocabulary Practice",
          subtitle:
              "Learn ${savedDailyWordCount.round()} words for this step (+${TaskCompletionXpConfig.vocabulary} XP)",
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
        // Verb Practice
        DailyTaskCard(
          title: "Verb Practice",
          subtitle:
              "Practice regular and irregular verbs (+${TaskCompletionXpConfig.verbs} XP)",
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
        // Speaking Practice (5 prompts)
        DailyTaskCard(
          title: "Speaking Practice",
          subtitle:
              "Speak 5 prompts clearly (+${TaskCompletionXpConfig.pronunciation} XP)",
          icon: Icons.mic_external_on_rounded,
          color: const Color(0xFF00E5FF),
          animationType: 'speaking',
          isDone: isSpeakingDone,
          scorePercentage: speakingScore,
          showCompletedLabel: false,
          showScoreBadge: false,
          showTickBadgeWhenDone: true,
          onTap: onSpeakingTap,
        ),
      ],
    );
  }
}
