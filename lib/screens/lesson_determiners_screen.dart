import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonDeterminersScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonDeterminersScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_determiners',
      title: 'Determiners',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_Determiners/',
      progressBaseKey: 'lesson_determiners',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // 1. Hook
  LessonSlide(
    title: "Which One? How Many?",
    content:
        "Dosa or THE dosa?\nFriend or MY friend?\nThree books or SOME books?\n\nDeterminers introduce nouns and make them specific.",
    imagePath: 'determiners_hook_square.webp',
    hindiContent: "Determiners       ' ?'  '?'  ",
    tamilContent: "Determiners    '?'  '?'  .",
  ),
  // 2. Types
  LessonSlide(
    title: "Types of Determiners",
    content:
        "1. Articles (the, a)\n2. Possessives (my, your)\n3. Demonstratives (this, that)\n4. Quantifiers (some, many)\n5. Numbers (one, first)",
    imagePath: 'determiner_types_square.webp',
    hindiContent:
        ": 1. Articles 2. Possessives 3. Demonstratives 4. Quantifiers 5. Numbers",
    tamilContent:
        ": 1. Articles 2. Possessives 3. Demonstratives 4. Quantifiers 5. Numbers.",
  ),
  // 3. Articles
  LessonSlide(
    title: "Articles",
    content:
        "THE = Specific / Known (The dosa Ravi loves)\nA / AN = General (A dosa)\n\nUse AN before vowel sounds.",
    imagePath: 'articles_determiners_square.webp',
    hindiContent: "THE =  A/AN =       AN   ",
    tamilContent: "THE =  . A/AN =  .    AN .",
    formula: "The [Specific] vs A/An [General]",
  ),
  // 4. Possessives
  LessonSlide(
    title: "Possessives",
    content:
        "Shows Ownership.\n\nMy book\nYour pen\nHis/Her dosa\nOur house\n\nReplaces 'The' + Owner.",
    imagePath: 'possessive_determiners_square.webp',
    hindiContent: "? My (), Your (), His ( - ), Her ( - )",
    tamilContent: "? My (), Your (), His (), Her ().",
    formula: "Possessive + Noun",
  ),
  // 5. Quiz: Possessive
  LessonQuizInteraction(
    title: "Quick Check",
    question: "Ravi lost ___ book.",
    options: ["he", "his", "him"],
    correctIndex: 1,
    explanation: "Correct! 'His' shows ownership (Possessive).",
    imagePath: 'possessive_determiners_square.webp',
  ),
  // 6. Demonstratives
  LessonSlide(
    title: "Demonstratives",
    content:
        "Points to things.\n\nTHIS / THESE = Near (Here)\nTHAT / THOSE = Far (There)\n\nSingular: This/That\nPlural: These/Those",
    imagePath: 'demonstratives_square.webp',
    hindiContent: " = This/These  = That/Those",
    tamilContent: " = This/These.  = That/Those.",
    formula: "This/These vs That/Those",
  ),
  // 7. Quiz: Demonstrative
  LessonQuizInteraction(
    title: "Quick Check",
    question: "Look at ___ bird in the sky.",
    options: ["this", "that", "these"],
    correctIndex: 1,
    explanation: "Correct! The bird is far away, so use 'That'.",
    imagePath: 'demonstratives_square.webp',
  ),
  // 8. Quantifiers
  LessonSlide(
    title: "Quantifiers",
    content:
        "How much?\n\nCountable: Many, few, several (books)\nUncountable: Much, little, some (water)\n\n'Some' works for both!",
    imagePath: 'quantifiers_square.webp',
    hindiContent: "? Countable: Many, few. Uncountable: Much, little.",
    tamilContent: "? Countable: Many, few. Uncountable: Much, little.",
    formula: "Countable vs Uncountable",
  ),
  // 9. Numbers
  LessonSlide(
    title: "Numbers",
    content:
        "Cardinal (How many): One, two, three\nOrdinal (Order): First, second, third\n\nThese are precise determiners!",
    imagePath: 'numbers_determiners_square.webp',
    hindiContent: "Cardinal:  (One, two). Ordinal:  (First, second).",
    tamilContent: "Cardinal:  (One, two). Ordinal:  (First, second).",
  ),
  // 10. Rules
  LessonSlide(
    title: "Golden Rules",
    content:
        "1. Only ONE main determiner per noun.\nError: My this book\nOK: My book OR This book\n\n2. Order: Quantity -> Adjective -> Noun\nOK: Three big dosas",
    imagePath: 'determiner_rules_square.webp',
    hindiContent: "      Determiner",
    tamilContent: "   Determiner  .",
  ),
  // 11. Speaking
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'determiner_chart_square.webp',
    prompts: [
      "I have three books.",
      "That is my house.",
      "Give me some water.",
    ],
    summaryPoints: [
      "Articles specify",
      "Possessives show owner",
      "Demonstratives point",
      "Quantifiers count",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Which is a determiner?',
    'question_tamil': 'Which is a determiner?',
    'question_hindi': 'Which is a determiner?',
    'options': ['Happy', 'Run', 'The', 'Yesterday'],
    'correct': 2,
  },
  {
    'question': 'I am eating ___ apple.',
    'question_tamil': 'I am eating ___ apple.',
    'question_hindi': 'I am eating ___ apple.',
    'options': ['a', 'an', 'some', 'many'],
    'correct': 1,
  },
  {
    'question': '___ is my book. (Near)',
    'question_tamil': '___ is my book. (Near)',
    'question_hindi': '___ is my book. (Near)',
    'options': ['That', 'Those', 'This', 'These'],
    'correct': 2,
  },
  {
    'question': 'Ravi lost ___ pen. (Possessive)',
    'question_tamil': 'Ravi lost ___ pen. (Possessive)',
    'question_hindi': 'Ravi lost ___ pen. (Possessive)',
    'options': ['his', 'her', 'my', 'their'],
    'correct': 0,
  },
  {
    'question': 'Can I have ___ water? (Uncountable)',
    'question_tamil': 'Can I have ___ water? (Uncountable)',
    'question_hindi': 'Can I have ___ water? (Uncountable)',
    'options': ['many', 'few', 'some', 'these'],
    'correct': 2,
  },
];
