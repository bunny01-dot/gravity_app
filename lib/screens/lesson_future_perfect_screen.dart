import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonFuturePerfectScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonFuturePerfectScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_5_future_perfect',
      title: 'Future Perfect',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_05_Tense_Future/03_Future_Perfect/',
      progressBaseKey: 'lesson_5_future_perfect',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  LessonSlide(
    title: "What Will Ravi Have Done?",
    content:
        "By 5 PM tomorrow, what will Ravi have done?\n\nWill he have finished homework? Have eaten lunch?\n\nFuture Perfect shows actions COMPLETED before a future time.",
    imagePath: 'ravi_future_perfect_square.webp',
    hindiContent: "  5  ,     ?",
    tamilContent: "  5 ,   ?",
  ),
  LessonHighlightInteraction(
    title: "When We Use It",
    introText: "Use Future Perfect for:",
    highlightItems: [
      "Actions completed before a specific future time",
      "Focus on 'completion' (done/finished)",
    ],
    exampleText:
        "| By 6 PM, I will have finished my homework.\n| By next year, he will have learned English.",
    imagePath: 'future_perfect_timeline_square.webp',
    hindiContent: "       ",
    tamilContent: "      .",
  ),
  LessonSlide(
    title: "Formula Breakdown",
    content:
        "Subject + will + have + Verb(past participle)\n\n| Ravi WILL HAVE studied by 5 PM.\n\nKey parts:\nOK: 'will have' (same for everyone)\nOK: Past Participle (finished, eaten, gone)",
    imagePath: 'will_have_verb_table_square.webp',
    formula: "will + have + V3",
    hindiContent: ": Subject + will + have + V3",
    tamilContent: ": Subject + will + have + V3",
  ),
  LessonSlide(
    title: "Ravi's Schedule",
    content:
        "By tomorrow evening:\n\n| By 9 AM: He will have woken up.\n| By 12 PM: He will have eaten lunch.\n| By 7 PM: He will have done homework.",
    imagePath: 'ravi_completion_timeline_square.webp',
    hindiContent: " 7  ,      ",
    tamilContent: " 7 ,   .",
  ),
  LessonHighlightInteraction(
    title: "'BY' Time Markers",
    introText: "Future Perfect needs 'BY':",
    highlightItems: [
      "BY + future time (By 5 PM, By tomorrow)",
      "BY THE TIME + future event",
    ],
    exampleText:
        "OK: 'By 5 PM, I will have finished.'\nOK: 'By the time you arrive, I will have cooked.'",
    imagePath: 'by_time_markers_square.webp',
    hindiContent: "'By'    ",
    tamilContent: "'By'  .",
  ),
  LessonSlide(
    title: "Negative (Won't Have)",
    content:
        "Subject + will not (won't) + have + Verb(3rd form)\n\n| By 6 PM, Ravi won't have finished his homework.\n| She won't have eaten yet.",
    imagePath: 'future_perfect_negative_square.webp',
    formula: "won't + have + V3",
    hindiContent: "       ",
    tamilContent: "   .",
  ),
  LessonSlide(
    title: "Questions",
    content:
        "Yes/No Questions:\nWill + Subject + have + Verb(3rd form)?\n| Will Ravi have finished by 5 PM?\n\nWh-Questions:\n| What will you have done by tonight?",
    imagePath: 'future_perfect_qa_square.webp',
    formula: "Will + Sub + have + V3?",
    hindiContent: "   5       ?",
    tamilContent: " 5  ?",
  ),
  LessonQuizInteraction(
    title: "Practice: Choose Correct",
    question: "By 6 PM, I ___ my homework.",
    options: ["will finish", "will have finished"],
    correctIndex: 1,
    explanation:
        "Correct! 'By 6 PM' requires Future Perfect (will have finished).",
    imagePath: 'future_perfect_quiz_square.webp',
  ),
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'future_perfect_speaking_square.webp',
    prompts: [
      "By 8 PM, what will you have done?",
      "I will have finished my work.",
      "Will you have eaten?",
    ],
    summaryPoints: [
      "Subject + will have + verb(3rd form)",
      "Use 'By' or 'By the time'",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Formula for Future Perfect?',
    'question_tamil': 'Future Perfect-  ?',
    'question_hindi': 'Future Perfect    ?',
    'options': ['will have + V3', 'will + V1', 'will be + V-ing', 'had + V3'],
    'correct': 0,
  },
  {
    'question': 'By 5 PM, Ravi ___ his homework.',
    'question_tamil': ' 5 ,   ___.',
    'question_hindi': ' 5  ,    ___',
    'options': ['will have finished', 'will finish', 'has finished', 'having'],
    'correct': 0,
  },
  {
    'question': 'Future Perfect shows...',
    'question_tamil': 'Future Perfect  ...',
    'question_hindi': 'Future Perfect   ...',
    'options': [
      'Duration',
      'Action completed before future time',
      'Ongoing action',
      'Past habit',
    ],
    'correct': 1,
  },
  {
    'question': 'Which word is a key time marker?',
    'question_tamil': '   ?',
    'question_hindi': '       ?',
    'options': ['By', 'Now', 'Yesterday', 'Usually'],
    'correct': 0,
  },
  {
    'question': 'By next year, she ___ graduated.',
    'question_tamil': '    ___.',
    'question_hindi': '  ,   ___',
    'options': ['will have', 'will be', 'has', 'is'],
    'correct': 0,
  },
];
