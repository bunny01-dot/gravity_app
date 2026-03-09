import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonLinkingWordsScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonLinkingWordsScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_linking_words',
      title: 'Linking Words',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_28_Linking_Words/',
      progressBaseKey: 'lesson_linking_words',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // 1. Hook
  LessonSlide(
    title: "Sentence Bridges",
    content:
        "Ravi studied. Ravi failed. Error: (Choppy)\n\nRavi studied, BUT he failed. OK: (Smooth)\n\nLinking words act as bridges between ideas.",
    imagePath: 'linking_hook_square.webp',
    hindiContent: "       Linking Words  ",
    tamilContent: "   Linking Words .",
  ),
  // 2. The 4 Groups
  LessonSlide(
    title: "The 4 Main Groups",
    content:
        "1. ADDITION: Adding more info (And, Also)\n2. CONTRAST: Showing difference (But, However)\n3. RESULT: Showing effects (So, Therefore)\n4. SEQUENCE: Ordering (First, Next)",
    imagePath: '4_linking_families_square.webp',
    hindiContent:
        "1.  (Addition), 2.  (Contrast), 3.  (Result), 4.  (Sequence)",
    tamilContent:
        "1.  (Addition), 2.  (Contrast), 3.  (Result), 4.  (Sequence).",
  ),
  // 3. Addition
  LessonHighlightInteraction(
    title: "Addition Links",
    introText: "Use these to add information:",
    highlightItems: [
      "AND: Simple connector",
      "ALSO: Adds another point",
      "MOREOVER: Formal addition",
      "IN ADDITION: Formal start",
    ],
    exampleText: "Ravi likes tea AND coffee. He ALSO likes juice.",
    imagePath: 'addition_links_square.webp',
    hindiContent: "    : And, Also, Moreover.",
    tamilContent: "  : And, Also, Moreover.",
  ),
  // 4. Contrast
  LessonHighlightInteraction(
    title: "Contrast Links",
    introText: "Use these to show opposites:",
    highlightItems: [
      "BUT: Simple contrast",
      "HOWEVER: Formal, starts sentence",
      "ALTHOUGH: Starts a clause",
      "NEVERTHELESS: Very formal",
    ],
    exampleText: "He studied, BUT he failed. HOWEVER, he is happy.",
    imagePath: 'contrast_links_square.webp',
    hindiContent: "   : But, However, Although.",
    tamilContent: "  : But, However, Although.",
  ),
  // 5. Quiz: Contrast
  LessonQuizInteraction(
    title: "Which Linker?",
    question: "Ravi is fast, ___ he lost the race.",
    options: ["and", "so", "but"],
    correctIndex: 2,
    explanation: "Correct! Being fast but losing is a CONTRAST.",
    imagePath: 'contrast_links_square.webp',
  ),
  // 6. Result
  LessonHighlightInteraction(
    title: "Result Links",
    introText: "Use these to show consequences:",
    highlightItems: [
      "SO: Simple result",
      "THEREFORE: Formal result",
      "AS A RESULT: Clear outcome",
      "CONSEQUENTLY: Formal outcome",
    ],
    exampleText: "He didn't study, SO he failed.",
    imagePath: 'result_links_square.webp',
    hindiContent: "   : So, Therefore, As a result.",
    tamilContent: " : So, Therefore, As a result.",
  ),
  // 7. Sequence
  LessonHighlightInteraction(
    title: "Sequence Links",
    introText: "Use these for ordering events:",
    highlightItems: [
      "FIRST / FIRSTLY",
      "NEXT / THEN",
      "AFTER THAT",
      "FINALLY / LASTLY",
    ],
    exampleText: "FIRST, wake up. THEN, brush teeth.",
    imagePath: 'sequence_links_square.webp',
    hindiContent: "   : First, Next, Then, Finally.",
    tamilContent: " : First, Next, Then, Finally.",
  ),
  // 8. Quiz: Flow
  LessonQuizInteraction(
    title: "Flow Check",
    question: "___, I went home. (Finish story)",
    options: ["First", "Finally", "But"],
    correctIndex: 1,
    explanation: "Correct! 'Finally' signals the end of a sequence.",
    imagePath: 'sequence_links_square.webp',
  ),
  // 9. Essay Flow
  LessonSlide(
    title: "Perfect Essay Flow",
    content:
        "From Choppy to Smooth:\n\nChoppy: Ravi studied. He failed. He tried again. He passed.\n\nSmooth: Ravi studied; HOWEVER, he failed. THEREFORE, he tried again. FINALLY, he passed!",
    imagePath: 'essay_flow_square.webp',
    hindiContent: "        ",
    tamilContent: "       .",
  ),
  // 10. Speaking
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'linking_chart_square.webp',
    prompts: [
      "I like tea and coffee.",
      "I ran fast, but I was late.",
      "First cook, then eat.",
    ],
    summaryPoints: [
      "Add (And/Also)",
      "Contrast (But/However)",
      "Result (So/Therefore)",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Ravi is smart ___ lazy.',
    'question_tamil': 'Ravi is smart ___ lazy.',
    'question_hindi': 'Ravi is smart ___ lazy.',
    'options': ['and', 'but', 'so', 'because'],
    'correct': 1,
  },
  {
    'question': 'It rained, ___ I stayed usage.',
    'question_tamil': 'It rained, ___ I stayed usage.',
    'question_hindi': 'It rained, ___ I stayed usage.',
    'options': ['so', 'because', 'but', 'however'],
    'correct': 0,
  },
  {
    'question': '___, I want to thank you.',
    'question_tamil': '___, I want to thank you.',
    'question_hindi': '___, I want to thank you.',
    'options': ['But', 'First', 'So', 'And'],
    'correct': 1,
  },
  {
    'question': 'I like tea; ___, I prefer coffee.',
    'question_tamil': 'I like tea; ___, I prefer coffee.',
    'question_hindi': 'I like tea; ___, I prefer coffee.',
    'options': ['and', 'however', 'so', 'first'],
    'correct': 1,
  },
  {
    'question': 'He studied hard. ___, he passed.',
    'question_tamil': 'He studied hard. ___, he passed.',
    'question_hindi': 'He studied hard. ___, he passed.',
    'options': ['Therefore', 'But', 'However', 'First'],
    'correct': 0,
  },
];
