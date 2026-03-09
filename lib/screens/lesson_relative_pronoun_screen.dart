import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonRelativePronounScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonRelativePronounScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_relative_pronoun',
      title: 'Relative Pronoun',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_16_Relative_Pronoun/',
      progressBaseKey: 'lesson_relative_pronoun',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // 1. Hook
  LessonSlide(
    title: "Sentence Glue",
    content:
        "Relative Pronouns join sentences like glue!\n\nRavi eats dosa + Ravi is my friend\n= Ravi, WHO eats dosa, is my friend.",
    imagePath: 'relative_pronoun_hook_square.webp',
    hindiContent: "        !",
    tamilContent: "   .",
    imageFit: BoxFit.contain,
  ),
  // 2. The Big 5
  LessonSlide(
    title: "The 5 Core Pronouns",
    content:
        "1. Who (Person Subject)\n2. Whom (Person Object)\n3. Whose (Possession)\n4. Which (Thing)\n5. That (Thing/Person)",
    imagePath: '5_relative_pronouns_square.webp',
    hindiContent: "Who, Whom, Whose, Which, That",
    tamilContent: "Who, Whom, Whose, Which, That",
    imageFit: BoxFit.contain,
  ),
  // 3. Who vs Whom
  LessonSlide(
    title: "Who vs Whom",
    content:
        "WHO does the action.\nWHOM receives the action.\n\nTip: If you can say 'Him', use 'Whom'.",
    imagePath: 'who_whom_square.webp',
    hindiContent: "WHO    WHOM    ",
    tamilContent: "WHO  . WHOM  .",
    imageFit: BoxFit.contain,
  ),
  // 4. Whose
  LessonSlide(
    title: "Whose (Ownership)",
    content:
        "Shows belonging.\n\nThe boy WHOSE bag fell.\nThe dog WHOSE tail wagged.",
    imagePath: 'whose_possession_square.webp',
    hindiContent: "  ",
    tamilContent: " .",
    imageFit: BoxFit.contain,
  ),
  // 5. Which vs That
  LessonSlide(
    title: "Which vs That",
    content:
        "WHICH adds extra info (comma needed).\nTHAT adds essential info (no comma).\n\nMy car, WHICH is red, is fast.\nThe car THAT hit me ran away.",
    imagePath: 'which_that_square.webp',
    hindiContent: "WHICH   THAT  ",
    tamilContent: "WHICH  . THAT  .",
    imageFit: BoxFit.contain,
  ),
  // 6. Sentence Combiner
  LessonHighlightInteraction(
    title: "Sentence Combiner",
    introText: "See how they join:",
    highlightItems: [
      "Ravi runs + Ravi is nice -> Ravi, WHO runs, is nice.",
      "This is the cake + I baked it -> This is the cake THAT I baked.",
    ],
    exampleText: "They make speech smoother.",
    imagePath: 'relative_pronoun_hook_square.webp',
    hindiContent: "     ",
    tamilContent: "    .",
    imageFit: BoxFit.contain,
  ),
  // 7. Detective
  LessonQuizInteraction(
    title: "Pronoun Detective",
    question: "The girl ___ sang well is here.",
    options: ["which", "who", "whom"],
    correctIndex: 1,
    explanation: "Girl is a person doing action (sang), so use WHO.",
    imagePath: 'who_whom_square.webp',
    imageFit: BoxFit.contain,
  ),
  // 8. Omit Pronoun
  LessonSlide(
    title: "Skipping the Pronoun",
    content:
        "You can skip the pronoun if it's the OBJECT.\n\nThe book (that) I read.\nThe man (whom) I met.\n\nBut NOT subject: The man WHO came.",
    imagePath: 'omit_pronoun_square.webp',
    hindiContent: "   (Object)       ",
    tamilContent: "   .",
    imageFit: BoxFit.contain,
  ),
  // 9. Speaking
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'relative_speaking_square.webp',
    prompts: [
      "The boy who runs is Ravi.",
      "This is the pen that I like.",
      "The girl whose bag fell.",
    ],
    summaryPoints: [
      "Who/Whom/Whose -> People",
      "Which/That -> Things",
      "That -> Essential Info",
    ],
    imageFit: BoxFit.contain,
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'The man ___ called yesterday.',
    'question_tamil': 'The man ___ called yesterday.',
    'question_hindi': 'The man ___ called yesterday.',
    'options': ['who', 'which', 'whose'],
    'correct': 0,
  },
  {
    'question': 'The book ___ I read.',
    'question_tamil': 'The book ___ I read.',
    'question_hindi': 'The book ___ I read.',
    'options': ['who', 'that', 'whom'],
    'correct': 1,
  },
  {
    'question': 'The girl ___ bag was lost.',
    'question_tamil': 'The girl ___ bag was lost.',
    'question_hindi': 'The girl ___ bag was lost.',
    'options': ['who', 'whose', 'which'],
    'correct': 1,
  },
  {
    'question': 'The car ___ hit the tree.',
    'question_tamil': 'The car ___ hit the tree.',
    'question_hindi': 'The car ___ hit the tree.',
    'options': ['who', 'which', 'whom'],
    'correct': 1,
  },
  {
    'question': 'The person ___ I met.',
    'question_tamil': 'The person ___ I met.',
    'question_hindi': 'The person ___ I met.',
    'options': ['which', 'whose', 'whom'],
    'correct': 2,
  },
];
