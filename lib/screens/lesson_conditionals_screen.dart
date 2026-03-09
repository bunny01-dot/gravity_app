import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonConditionalsScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonConditionalsScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_conditionals',
      title: 'Conditionals',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_Conditionals/',
      progressBaseKey: 'lesson_conditionals',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // 1. Hook
  LessonSlide(
    title: "4 Conditionals",
    content:
        "If Ravi studies  he passes OK: (Fact)\nIf Ravi studied  he would pass  (Dream)\nIf Ravi had studied  he would have passed Error: (Regret)\n\n4 ways to talk about 'IF'!",
    imagePath: 'conditionals_timeline_square.webp',
    hindiContent: "4       : ,   , ,  ",
    tamilContent: "4    : ,  , , .",
  ),
  // 2. Overview
  LessonSlide(
    title: "Overview",
    content:
        "ZERO: Facts (Water boils...)\nFIRST: Real Future (If he studies...)\nSECOND: Dream Now (If he studied...)\nTHIRD: Past Regret (If he had studied...)",
    imagePath: '4_conditionals_square.webp',
    hindiContent: "ZERO:  FIRST:   SECOND: / THIRD:   ",
    tamilContent: "ZERO: . FIRST: . SECOND: /. THIRD:  .",
  ),
  // 3. Zero Conditional
  LessonSlide(
    title: "Zero Conditional",
    content:
        "Always true (Facts)\n\nIf water boils, it evaporates.\nIf Ravi eats dosa, he is happy.\n\nUse PRESENT tense for both parts.",
    imagePath: 'zero_conditional_square.webp',
    hindiContent: "  () ( + ) :        ",
    tamilContent: " . ( + ). .:   .",
    formula: "IF + Present Simple, Present Simple",
  ),
  // 4. First Conditional
  LessonSlide(
    title: "First Conditional",
    content:
        "Real Future Possibility\n\nIf it rains, we WILL stay home.\nIf Ravi studies, he WILL pass.\n\nLikely to happen!",
    imagePath: 'first_conditional_square.webp',
    hindiContent: "    ( + WILL)   ,     ",
    tamilContent: " . ( + WILL).  ,  .",
    formula: "IF + Present Simple, WILL + Verb",
  ),
  // 5. Second Conditional
  LessonSlide(
    title: "Second Conditional",
    content:
        "Dreams / Unreal Now\n\nIf I WERE rich, I WOULD travel.\nIf Ravi WERE king, he WOULD give free dosa.\n\nNot true right now.",
    imagePath: 'second_conditional_square.webp',
    hindiContent: "    ( + WOULD)       ",
    tamilContent: "  . ( + WOULD).     .",
    formula: "IF + Past Simple, WOULD + Verb",
  ),
  // 6. Third Conditional
  LessonSlide(
    title: "Third Conditional",
    content:
        "Regrets (Too Late)\n\nIf I HAD studied, I WOULD HAVE passed.\nIf Ravi HAD come, we WOULD HAVE won.\n\nCannot change the past.",
    imagePath: 'third_conditional_square.webp',
    hindiContent: "    (Past Perfect + WOULD HAVE)       ",
    tamilContent: "   . (Past Perfect + WOULD HAVE).  .",
    formula: "IF + Past Perfect, WOULD HAVE + V3",
  ),
  // 7. Detective Quiz 1
  LessonQuizInteraction(
    title: "Identify",
    question: "If water boils...",
    options: ["it evaporates", "it will evaporate", "it would evaporate"],
    correctIndex: 0,
    explanation: "Correct! Zero conditional (Fact) uses Present Tense.",
    imagePath: 'zero_conditional_square.webp',
  ),
  // 8. Detective Quiz 2
  LessonQuizInteraction(
    title: "Identify",
    question: "If I won the lottery...",
    options: ["I will travel", "I would travel", "I travel"],
    correctIndex: 1,
    explanation: "Correct! Second conditional (Dream) uses 'Would'.",
    imagePath: 'second_conditional_square.webp',
  ),
  // 9. Detective Quiz 3
  LessonQuizInteraction(
    title: "Identify",
    question: "If I had studied...",
    options: ["I passed", "I would pass", "I would have passed"],
    correctIndex: 2,
    explanation: "Correct! Third conditional (Regret) uses 'Would Have'.",
    imagePath: 'third_conditional_square.webp',
  ),
  // 10. Mixed Conditionals
  LessonSlide(
    title: "Mixed Conditionals",
    content:
        "Past affects Present:\nIf I HAD studied (past), I WOULD be rich now (present).\n\nPresent affects Past:\nIf I WERE smart (general), I WOULD HAVE passed (past).",
    imagePath: 'mixed_conditionals_square.webp',
    hindiContent: "         ,  Mixed Conditional    ",
    tamilContent: "      Mixed Conditional .",
  ),
  // 11. Mistakes
  LessonSlide(
    title: "Common Mistakes",
    content:
        "Error: If I will study -> If I study (First)\nError: If I was rich -> If I were rich (Second)\nError: If I would pass -> If I pass\n\nNEVER use 'will' or 'would' inside the IF part!",
    imagePath: 'conditional_mistakes_square.webp',
    hindiContent: "IF    Will/Would    If I were rich  , If I was rich  ",
    tamilContent: "IF  Will/Would . If I were rich  , If I was rich .",
  ),
  // 12. Speaking
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'conditional_chart_square.webp',
    prompts: [
      "If I study, I will pass.",
      "If I were rich, I would travel.",
      "If I had known, I would have come.",
    ],
    summaryPoints: [
      "Zero: Facts",
      "First: Future",
      "Second: Dreams",
      "Third: Regrets",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Zero Conditional: If ice melts, it becomes ___.',
    'question_tamil': 'Zero Conditional:  ,  ___ .',
    'question_hindi': 'Zero Conditional:    ,   ___   ',
    'options': ['water', 'steam', 'ice', 'gas'],
    'correct': 0,
  },
  {
    'question': 'First Conditional: If it rains, I ___ stay home.',
    'question_tamil': 'First Conditional:  ,   ___.',
    'question_hindi': 'First Conditional:    ,     ___',
    'options': ['would', 'will', 'had', 'am'],
    'correct': 1,
  },
  {
    'question': 'Second Conditional: If I ___ rich, I would travel.',
    'question_tamil': 'Second Conditional:   ___,   .',
    'question_hindi': 'Second Conditional:    ___,    ',
    'options': ['am', 'was', 'were', 'will be'],
    'correct': 2,
  },
  {
    'question': 'Third Conditional: If I had studied, I would have ___.',
    'question_tamil': 'Third Conditional:  ,  ___.',
    'question_hindi': 'Third Conditional:     ,   ___',
    'options': ['pass', 'passing', 'passes', 'passed'],
    'correct': 3,
  },
  {
    'question': 'Mixed: If I were smart now, I would ___ passed then.',
    'question_tamil': 'Mixed:   ,    ___.',
    'question_hindi': 'Mixed:     ,     ___',
    'options': ['have', 'has', 'had', 'will'],
    'correct': 0,
  },
];
