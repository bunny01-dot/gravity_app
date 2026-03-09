import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonFutureContinuousScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonFutureContinuousScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LessonScaffold(
      lessonId: 'lesson_5_future_continuous',
      title: isDark ? 'Future Continuous' : 'Future Continuous',
      assetPath: 'assets/Lessons/Lesson_05_Tense_Future/02_Future_Continuous/',
      progressBaseKey: 'lesson_5_future_continuous',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
      slides: [
        LessonSlide(
          title: "What Will Ravi Be Doing?",
          content:
              "Tomorrow at 10 AM, what will Ravi be doing?\n\nWill he be studying? Be playing? Be eating?\n\nIt's an action in progress at that exact time.",
          imagePath: 'future_continuous_hook.webp',
          hindiContent: "  10 ,     ?",
          tamilContent: "  10 ,    ?",
        ),
        LessonHighlightInteraction(
          title: "When to Use It",
          introText: "We use it for:",
          highlightItems: [
            "Action in progress at a specific future time",
            "What someone will be doing at that moment",
            "Interrupted action in future",
          ],
          exampleText:
              "| At 2 PM tomorrow, he will be playing cricket.\n| This time next week, they will be studying.",
          imagePath: 'future_continuous_uses.webp',
          hindiContent: "       ",
          tamilContent: "     .",
        ),
        LessonSlide(
          title: "The Formula",
          content:
              "Subject + will + be + Verb(+ing)\n\n| I/You/He/She/We/They will be reading.\n| Ravi will be studying at 10 AM.",
          imagePath: 'future_continuous_formation.webp',
          formula: "will + be + Verb(ing)",
          hindiContent: ": Subject + will + be + Verb(ing)",
          tamilContent: ": Subject + will + be + Verb(ing)",
        ),
        LessonSlide(
          title: "Ravi's Tomorrow Timeline",
          content:
              "8 AM  He will be eating.\n9:30 AM  He will be going to school.\n11 AM  He will be studying.\n2 PM  He will be playing.",
          imagePath: 'future_continuous_time.webp',
          hindiContent: " 11    ",
          tamilContent: " 11   .",
        ),
        LessonHighlightInteraction(
          title: "Time Markers Are Key",
          introText: "Future Continuous needs a specific TIME:",
          highlightItems: [
            "AT + time (at 10 AM)",
            "TOMORROW + time (tomorrow evening)",
            "WHEN + future event (when you call)",
          ],
          exampleText:
              "OK: 'He will be studying at 10 AM.'\n Without time, it might just be a plan.",
          imagePath: 'future_continuous_time.webp',
          hindiContent: "    ",
          tamilContent: "  .",
        ),
        LessonSlide(
          title: "Negative Sentences",
          content:
              "Subject + will not (won't) + be + Verb(+ing)\n\n| Ravi won't be studying at 2 PM.\n| She won't be sleeping when we arrive.",
          imagePath: 'future_continuous_negative.webp',
          formula: "won't + be + V-ing",
          hindiContent: " 2     ",
          tamilContent: " 2    .",
        ),
        LessonSlide(
          title: "Questions",
          content:
              "Yes/No Questions:\nWill + Subject + be + Verb(+ing)?\n| Will Ravi be studying ar 10 AM?\n\nWh- Questions:\n| What will you be doing at 5 PM?",
          imagePath: 'future_continuous_questions.webp',
          formula: "Will + Sub + be + V-ing?",
          hindiContent: "   10    ?",
          tamilContent: "  10   ?",
        ),
        LessonQuizInteraction(
          title: "Practice: Fill & Choose",
          question: "Select the correct Future Continuous form:",
          options: [
            "At 9 AM, Ravi will study.",
            "At 9 AM, Ravi will be studying.",
            "At 9 AM, Ravi is studying.",
          ],
          correctIndex: 1,
          explanation:
              "Correct! We use 'will be studying' for a specific time in the future.",
          imagePath: 'future_continuous_vs_simple.webp',
        ),
        LessonSpeakingPractice(
          title: "Speaking Practice",
          imagePath: 'future_continuous_reference.webp',
          prompts: [
            "What will you be doing at 7 AM?",
            "I will be sleeping at 10 PM.",
            "Will you be working?",
          ],
          summaryPoints: [
            "Subject + will + be + Verb(+ing)",
            "Action in progress",
          ],
        ),
      ],
      quizQuestions: [
        {
          'question': 'Formula for Future Continuous?',
          'question_tamil': '  ?',
          'question_hindi': 'Future Continuous  ?',
          'options': [
            'will + V1',
            'will be + V-ing',
            'will have + V3',
            'was + V-ing',
          ],
          'correct': 1,
        },
        {
          'question': 'At 8 PM, I ___ dinner.',
          'question_tamil': ' 8 ,    ___.',
          'question_hindi': ' 8 ,     ___ ',
          'options': ['will be eating', 'will eating', 'eating', 'ate'],
          'correct': 0,
        },
        {
          'question': 'Negative form of "She will be sleeping":',
          'question_tamil': '"She will be sleeping"   :',
          'question_hindi': '"She will be sleeping"   :',
          'options': [
            'She will not be sleeping',
            'She won\'t sleeping',
            'She not sleeping',
            'She be not sleeping',
          ],
          'correct': 0,
        },
        {
          'question': 'Future Continuous is used for...',
          'question_tamil': 'Future Continuous  ...',
          'question_hindi': 'Future Continuous       ...',
          'options': [
            'Completed action',
            'Action in progress at future time',
            'Habit',
            'Past action',
          ],
          'correct': 1,
        },
        {
          'question': 'This time tomorrow, we ___ to London.',
          'question_tamil': '  ,   ___.',
          'question_hindi': '  ,     ___ ',
          'options': [
            'will be flying',
            'are fly',
            'will flying',
            'will have fly',
          ],
          'correct': 0,
        },
      ],
    );
  }
}
