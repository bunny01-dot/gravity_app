import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonIrregularVerbsScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonIrregularVerbsScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_irregular_verbs',
      title: 'Irregular Verbs',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_04_Irregular_Verbs/',
      progressBaseKey: 'lesson_irregular_verbs',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // 1. Hook
  LessonSlide(
    title: "Irregular Verbs",
    content:
        "Walk-walked-walked (Regular - Easy )\nGo-went-gone (Irregular - Crazy! )\n\nWe must memorize these special forms!",
    imagePath: 'irregular_hook_square.webp',
    hindiContent: " : Go-Went-Gone (   !).",
    tamilContent: " : Go-Went-Gone ( !).",
  ),
  // 2. The 3 Forms
  LessonHighlightInteraction(
    title: "The 3 Forms",
    introText: "Every verb has 3 main forms:",
    highlightItems: [
      "BASE: Present (I go)",
      "PAST: Yesterday (I went)",
      "PARTICIPLE: Perfect (I have gone)",
    ],
    exampleText: "Ravi GOES -> WENT -> has GONE.",
    imagePath: 'three_forms_square.webp',
    hindiContent: "1.  (Base), 2.  (Past), 3.   (Past Participle)",
    tamilContent: "1.  (Base), 2.  (Past), 3.   (Past Participle).",
  ),
  // 3. Top 10
  LessonHighlightInteraction(
    title: "Top Common Verbs",
    introText: "These change completely:",
    highlightItems: [
      "Be  was/were  been",
      "Go  went  gone",
      "Do  did  done",
      "Have  had  had",
    ],
    exampleText: "See  Saw  Seen. Make  Made  Made.",
    imagePath: 'top10_irregular_square.webp',
    hindiContent: "Go-Went-Gone, Do-Did-Done ",
    tamilContent: "Go-Went-Gone, Do-Did-Done .",
  ),
  // 4. No Change Group
  LessonSlide(
    title: "The No-Change Group",
    content:
        "Some verbs NEVER change!\n\n| Cut - Cut - Cut\n| Put - Put - Put\n| Hit - Hit - Hit\n| Set - Set - Set\n\nEasy to remember!",
    imagePath: 'no_change_square.webp',
    hindiContent: "        Cut - Cut - Cut.",
    tamilContent: "     .",
  ),
  // 5. Vowel Change Group
  LessonHighlightInteraction(
    title: "Vowel Changers",
    introText: "Often I -> A -> U pattern:",
    highlightItems: [
      "Sing  Sang  Sung",
      "Drink  Drank  Drunk",
      "Swim  Swam  Swum",
      "Ring  Rang  Rung",
    ],
    exampleText: "Begin  Began  Begun.",
    imagePath: 'vowel_change_square.webp',
    hindiContent: "   : i -> a -> u (Sing - Sang - Sung).",
    tamilContent: "  : i -> a -> u.",
  ),
  // 6. Past = Participle Group
  LessonHighlightInteraction(
    title: "Past = Participle",
    introText: "The 2nd and 3rd forms are the same:",
    highlightItems: [
      "Buy  Bought  Bought",
      "Teach  Taught  Taught",
      "Think  Thought  Thought",
      "Make  Made  Made",
    ],
    exampleText: "I bought it. I have bought it.",
    imagePath: 'past_equals_square.webp',
    hindiContent: "       Buy - Bought - Bought.",
    tamilContent: "     .",
  ),
  // 7. Quiz: Patterns
  LessonQuizInteraction(
    title: "Pattern Match",
    question: "Teach -> Taught -> ___",
    options: ["Teached", "Taught", "Touch"],
    correctIndex: 1,
    explanation: "Correct! Teach -> Taught -> Taught.",
    imagePath: 'past_equals_square.webp',
  ),
  // 8. Perfect Tense Use
  LessonSlide(
    title: "Using Form 3 (Participle)",
    content:
        "We use the 3rd form with HAVE/HAS:\n\n| I have EATEN (not I have ate)\n| She has GONE (not she has went)\n| They have SEEN (not they have saw)",
    imagePath: 'perfect_tense_square.webp',
    hindiContent: "Have/Has   3rd form   ",
    tamilContent: "Have/Has  3   (Participle) .",
    formula: "Have/Has + Form 3",
  ),
  // 9. Strategy
  LessonSlide(
    title: "How to Memorize?",
    content:
        "1. Learn top 20 first (covers 80%)\n2. Group by sound (sing-sang-sung)\n3. Practice daily sentences\n\nDon't try to learn all 200 at once!",
    imagePath: 'learning_strategy_square.webp',
    hindiContent: " 20        ",
    tamilContent: " 20   .   .",
  ),
  // 10. Speaking
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'irregular_chart_square.webp',
    prompts: [
      "I went to the store.",
      "I have eaten lunch.",
      "She sang a song.",
    ],
    summaryPoints: [
      "Practice 3 forms",
      "Use Participle with Have",
      "Groups help memory",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Go -> ___ -> ___',
    'question_tamil': 'Go -> ___ -> ___ ()',
    'question_hindi': 'Go -> ___ -> ___ ()',
    'options': ['goed - goed', 'went - gone', 'gone - went', 'went - went'],
    'correct': 1,
  },
  {
    'question': 'Buy -> ___ -> ___',
    'question_tamil': 'Buy -> ___ -> ___ ()',
    'question_hindi': 'Buy -> ___ -> ___ ()',
    'options': [
      'bought - bought',
      'buyed - buyed',
      'bought - buy',
      'buy - bought',
    ],
    'correct': 0,
  },
  {
    'question': 'Sing -> ___ -> ___',
    'question_tamil': 'Sing -> ___ -> ___ ()',
    'question_hindi': 'Sing -> ___ -> ___ ()',
    'options': ['singed - singed', 'sang - sung', 'sung - sang', 'sang - sang'],
    'correct': 1,
  },
  {
    'question': 'Put -> ___ -> ___',
    'question_tamil': 'Put -> ___ -> ___ ()',
    'question_hindi': 'Put -> ___ -> ___ ()',
    'options': ['put - put', 'putted - putted', 'pat - put'],
    'correct': 0,
  },
  {
    'question': 'Eat -> ___ -> ___',
    'question_tamil': 'Eat -> ___ -> ___ ()',
    'question_hindi': 'Eat -> ___ -> ___ ()',
    'options': ['eated - eated', 'ate - eaten', 'eaten - ate'],
    'correct': 1,
  },
];
