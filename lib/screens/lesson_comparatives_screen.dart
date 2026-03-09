import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonComparativesScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonComparativesScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_comparatives',
      title: 'Comparatives',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_Comparatives/',
      progressBaseKey: 'lesson_comparatives',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // 1. Hook
  LessonSlide(
    title: "Taller, Bigger, Faster!",
    content:
        "Ravi is tall.\nMom is TALLER.\nDad is TALLEST!\n\nDosa is tasty.\nIdli is TASTIER.\nVada is TASTIEST!\n\nSame pattern for ALL adjectives!",
    imagePath: 'comparison_ladder_square.webp',
    hindiContent:
        "       (Taller)     (Tallest) !        (Tastier)     (Tastiest) !",
    tamilContent: " .     (Taller).     (Tallest)!     .",
    formula: "Positive -> Comparative -> Superlative",
  ),
  // 2. The 3 Degrees
  LessonSlide(
    title: "3 Degrees of Adjectives",
    content:
        "1. Positive: tall (Just one thing)\n2. Comparative: taller (Comparing 2 things)\n3. Superlative: tallest (The best of 3+ things)",
    imagePath: 'three_degrees_square.webp',
    hindiContent:
        "1. Positive ():  \n2. Comparative ():    \n3. Superlative ():      ",
    tamilContent: "1. Positive:  ()\n2. Comparative:  \n3. Superlative:  /",
    formula: "Tall -> Taller -> Tallest",
  ),
  // 3. Short Adjectives
  LessonSlide(
    title: "Rule 1: Short Words",
    content:
        "For short words (1 syllable), just add -er or -est.\n\n| fast  faster  fastest\n| big  bigger  biggest (double the consonant!)",
    imagePath: 'short_adjectives_square.webp',
    hindiContent: "   ,  -er  -est \n: fast  faster  fastest",
    tamilContent: "  -er  -est .\n: fast  faster  fastest",
    formula: "Short Word + er/est",
  ),
  // 4. Y Adjectives
  LessonSlide(
    title: "Rule 2: Ends in -y",
    content:
        "If it ends in 'y', remove 'y' and add -ier or -iest.\n\n| happy  happier  happiest\n| easy  easier  easiest\n| busy  busier  busiest",
    imagePath: 'y_adjectives_square.webp',
    hindiContent: "  'y'    ,  'y'    -ier  -iest \n: happy  happier  happiest",
    tamilContent: " 'y'  , 'y'   -ier  -iest .",
    formula: "Drop 'y' -> Add ier/iest",
  ),
  // 5. Long Adjectives
  LessonSlide(
    title: "Rule 3: Long Words",
    content:
        "For long words (2+ syllables), use MORE and MOST.\n\n| beautiful  MORE beautiful  MOST beautiful\n| expensive  MORE expensive  MOST expensive",
    imagePath: 'long_adjectives_square.webp',
    hindiContent: "   , MORE  MOST   \n: beautiful  MORE beautiful",
    tamilContent: "   MORE  MOST .\n: beautiful  MORE beautiful",
    formula: "More/Most + Long Word",
  ),
  // 6. Irregular Adjectives
  LessonSlide(
    title: "Irregular Words",
    content:
        "These break the rules! Memorize them:\n\n| good  BETTER  BEST\n| bad  WORSE  WORST\n| little  LESS  LEAST",
    imagePath: 'irregular_adjectives_square.webp',
    hindiContent: "    !   :\nGood  Better  Best\nBad  Worse  Worst",
    tamilContent: "  :\nGood  Better  Best ( -> )",
  ),
  // 7. Quiz Interaction 1
  LessonQuizInteraction(
    title: "Quick Check",
    question: "Dosa is ___ than Idli.",
    options: ["tasty", "tastier", "tastiest"],
    correctIndex: 1,
    explanation: "Correct! Comparing 2 things (Dosa vs Idli) = Tastier.",
    imagePath: 'comp_vs_super_square.webp',
  ),
  // 8. Quiz Interaction 2
  LessonQuizInteraction(
    title: "Quick Check",
    question: "Ravi is the ___ student.",
    options: ["good", "better", "best"],
    correctIndex: 2,
    explanation: "Correct! 'The' indicates Superlative = Best.",
    imagePath: 'irregular_adjectives_square.webp',
  ),
  // 9. When to use which?
  LessonSlide(
    title: "When to use which?",
    content:
        "2 Things = COMPARATIVE (+ than)\n\"Ravi is taller THAN mom.\"\n\n3+ Things = SUPERLATIVE (+ the)\n\"Ravi is THE tallest in the class.\"",
    imagePath: 'comp_vs_super_square.webp',
    hindiContent: "2  = Comparative (+ than)\n3+  = Superlative (+ the)",
    tamilContent: "    Comparative (+ than).     Superlative (+ the).",
    formula: "Comparative + THAN | THE + Superlative",
  ),
  // 10. Mistakes
  LessonSlide(
    title: "Common Mistakes",
    content:
        "Error: More bigger -> Bigger\nError: Most tallest -> Tallest\nError: Gooder -> Better\n\nNever use 'more' with -er words!",
    imagePath: 'comparison_mistakes_square.webp',
    hindiContent: "Error: More bigger   Bigger  \nError: Gooder   Better  ",
    tamilContent: "More bigger . Bigger  . Gooder  , Better   .",
  ),
  // 11. Speaking
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'comparison_chart_square.webp',
    prompts: [
      "Ravi is taller than Mom.",
      "This book is better.",
      "She is the happiest.",
    ],
    summaryPoints: [
      "Short: -er / -est",
      "Long: more / most",
      "Irregular: better / best",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Form of "Good"?',
    'question_tamil': '"Good"  ?',
    'question_hindi': '"Good"    ?',
    'options': ['Gooder', 'More good', 'Better', 'Bestest'],
    'correct': 2,
  },
  {
    'question': 'Ravi is ___ than Mom.',
    'question_tamil': '   ___.',
    'question_hindi': '     ___ ',
    'options': ['tall', 'tallest', 'taller', 'more tall'],
    'correct': 2,
  },
  {
    'question': 'This dosa is the ___!',
    'question_tamil': '  ___!',
    'question_hindi': '  ___ !',
    'options': ['tasty', 'tastier', 'tastiest', 'more tasty'],
    'correct': 2,
  },
  {
    'question': 'A cheetah is ___ than a cat.',
    'question_tamil': '   ___.',
    'question_hindi': '   ___ ',
    'options': ['fast', 'faster', 'fastest', 'more fast'],
    'correct': 1,
  },
  {
    'question': 'This test is ___ difficult than the last one.',
    'question_tamil': '     ___ .',
    'question_hindi': '     ___  ',
    'options': ['most', 'more', 'much', 'many'],
    'correct': 1,
  },
];
