import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonPunctuationScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonPunctuationScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_punctuation',
      title: 'Punctuation',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_Punctuation/',
      progressBaseKey: 'lesson_punctuation',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // 1. Hook
  LessonSlide(
    title: "Traffic Signals",
    content:
        "Punctuation is like traffic signals for reading.\nIt tells you when to stop, pause, or get excited!\n\nRavi eats dosa mom cooks rice Error:\nRavi eats dosa. Mom cooks rice. OK:",
    imagePath: 'punctuation_hook_square.webp',
    hindiContent: "         ",
    tamilContent: "    .",
    imageFit: BoxFit.contain,
  ),
  // 2. The Big 3 Enders
  LessonSlide(
    title: "3 Sentence Enders",
    content:
        "1. Full Stop (.) -> Finished thought.\n2. Question Mark (?) -> Asking.\n3. Exclamation (!) -> Excitement.\n\nChoose wisely!",
    imagePath: '4_enders_square.webp',
    hindiContent: "(.)  \n(?) \n(!) ",
    tamilContent: "(.) \n(?) \n(!) ",
    imageFit: BoxFit.contain,
  ),
  // 3. Comma
  LessonSlide(
    title: "Comma (,) - The Pause",
    content:
        "Use a comma for a short pause.\n\n| Lists: Dosa, Idli, and Sambar.\n| Intro: Hi, Ravi.\n| Separation: When I run, I sweat.",
    imagePath: 'comma_rules_square.webp',
    hindiContent: " (,)       ",
    tamilContent: "   (,) .",
    imageFit: BoxFit.contain,
  ),
  // 4. Quotation Marks
  LessonSlide(
    title: "Quotation Marks \" \"",
    content:
        "Use when someone is speaking.\n\nMom said, \"Eat your food.\"\nRavi asked, \"Is it ready?\"\n\nNote the comma before the quote!",
    imagePath: 'quotes_square.webp',
    hindiContent: "       ",
    tamilContent: "  .",
    imageFit: BoxFit.contain,
  ),
  // 5. Apostrophe
  LessonSlide(
    title: "Apostrophe '",
    content:
        "Two main jobs:\n1. Possession: Ravi's book (Belongs to Ravi)\n2. Contraction: It's (It is), Don't (Do not)",
    imagePath: 'apostrophe_square.webp',
    hindiContent: "1.  (Ravi's)\n2.  (It's)",
    tamilContent: "1.  (Ravi's)\n2.  (It's)",
    imageFit: BoxFit.contain,
  ),
  // 6. Colon & Semicolon
  LessonSlide(
    title: "Colon : & Semicolon ;",
    content:
        "Colon (:) -> Introduces a list.\nSemicolon (;) -> Connects related sentences.\n\nRavi needs: pen, paper, ink.\nRavi is sad; he lost the match.",
    imagePath: 'colon_semicolon_square.webp',
    hindiContent: "(:)   \n(;)   ",
    tamilContent: "(:)  \n(;)  ",
    imageFit: BoxFit.contain,
  ),
  // 7. Highlight Interaction
  LessonHighlightInteraction(
    title: "Punctuation Detective",
    introText: "Find the marks:",
    highlightItems: ["Ravi eats.", "What?", "Wow!", "Ravi's bat"],
    exampleText: "Every mark changes the meaning.",
    imagePath: '4_enders_square.webp',
    hindiContent: "  ",
    tamilContent: " .",
    imageFit: BoxFit.contain,
  ),
  // 8. Speaking
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'punctuation_chart_square.webp',
    prompts: [
      "Stop! Wait for me.",
      "Do you like tea?",
      "I like tea, coffee, and milk.",
    ],
    summaryPoints: [
      "Pause at particles",
      "Raise tone for questions",
      "Show emotion for exclamation",
    ],
    imageFit: BoxFit.contain,
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Which mark ends a normal sentence?',
    'question_tamil': 'Which mark ends a normal sentence?',
    'question_hindi': 'Which mark ends a normal sentence?',
    'options': ['.', '?', '!'],
    'correct': 0,
  },
  {
    'question': 'Mom said ___ "Eat food."',
    'question_tamil': 'Mom said ___ "Eat food."',
    'question_hindi': 'Mom said ___ "Eat food."',
    'options': ['.', ',', ';', ':'],
    'correct': 1,
  },
  {
    'question': 'It ___ s raining.',
    'question_tamil': 'It ___ s raining.',
    'question_hindi': 'It ___ s raining.',
    'options': [',', '\'', ';'],
    'correct': 1,
  },
  {
    'question': 'I love dosa ___ mom loves idli.',
    'question_tamil': 'I love dosa ___ mom loves idli.',
    'question_hindi': 'I love dosa ___ mom loves idli.',
    'options': [':', ';', ','],
    'correct': 1,
  },
  {
    'question': 'What a great day ___',
    'question_tamil': 'What a great day ___',
    'question_hindi': 'What a great day ___',
    'options': ['?', '!', '.'],
    'correct': 1,
  },
];
