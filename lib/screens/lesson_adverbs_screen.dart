import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonAdverbsScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonAdverbsScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_27_adverbs',
      title: 'Adverbs',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_27_Adverbs/',
      progressBaseKey: 'lesson_27_adverbs',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // 1. Hook
  LessonSlide(
    title: "Adverbs",
    content:
        "Ravi runs. (basic)\nRavi runs quickly. (HOW?)\nRavi always runs here. (WHEN? WHERE?)\n\nAdverbs make actions ALIVE!",
    imagePath: 'adverb_hook_square.webp',
    hindiContent: "  (Adverbs)     ,    \nQuickly, always, here ->      !",
    tamilContent: " (Adverbs)   , ,    .\nQuickly, always, here ->    !",
  ),
  // 2. 5 Families
  LessonSlide(
    title: "5 Adverb Families",
    content:
        "OK: Manner (HOW): quickly, carefully\nOK: Time (WHEN): now, yesterday\nOK: Place (WHERE): here, there\nOK: Frequency (HOW OFTEN): always\nOK: Degree (HOW MUCH): very, too",
    imagePath: '5_adverb_types_square.webp',
    hindiContent:
        "    :\n1.  (Manner)\n2.  (Time)\n3.  (Place)\n4.  (Frequency)\n5.  (Degree)",
    tamilContent:
        "  :\n1.  (Manner)\n2.  (Time)\n3.  (Place)\n4.  (Frequency)\n5.  (Degree)",
  ),
  // 3. Manner
  LessonSlide(
    title: "Manner: How?",
    content:
        "HOW?  -ly ending:\nOK: quick  quickly\nOK: careful  carefully\nOK: happy  happily\n\nRavi sings beautifully. Mom cooks carefully.",
    imagePath: 'manner_adverbs_square.webp',
    formula: "Verb + Manner Adverb",
    hindiContent: "? (How)    \n -ly    \nQuick -> Quickly ( )",
    tamilContent: "? (How)    .\n -ly  .\nQuick -> Quickly ().",
  ),
  // 4. Frequency
  LessonSlide(
    title: "Frequency: How Often?",
    content:
        "Always (100%)  usually  often\nSometimes  rarely  never (0%)\n\nOK: Ravi ALWAYS eats dosa.\nOK: Mom NEVER forgets milk.",
    imagePath: 'frequency_adverbs_square.webp',
    formula: "Before Main Verb OR End",
    hindiContent: " ?\nAlways () -> Sometimes (-) -> Never ( )",
    tamilContent: " ?\nAlways () -> Sometimes ( ) -> Never ( ).",
  ),
  // 5. Place & Time
  LessonSlide(
    title: "Place & Time",
    content:
        "WHERE: here, there, everywhere\nOK: Books are HERE.\n\nWHEN: now, yesterday, tomorrow\nOK: Ravi ate YESTERDAY.",
    imagePath: 'place_time_adverbs_square.webp',
    hindiContent: " (Place): Here (), There ()\n (Time): Now (), Yesterday ()",
    tamilContent:
        " (Place): Here (), There ().\n (Time): Now (), Yesterday ().",
  ),
  // 6. Degree
  LessonSlide(
    title: "Degree: How Much?",
    content:
        "Intensifiers: very, too, quite, almost\n\nOK: VERY tasty dosa\nOK: TOO spicy chili\nOK: QUITE good score\n\nRavi runs VERY quickly!",
    imagePath: 'degree_adverbs_square.webp',
    hindiContent: "? (How much)\nVery (), Too (), Quite ()",
    tamilContent: "? (How much)\nVery (), Too (), Quite ().",
  ),
  // 7. Detective Quiz
  LessonQuizInteraction(
    title: "Adverb Detective",
    question: "Identify the type: 'Ravi runs QUICKLY'",
    options: ["Time", "Manner", "Place", "Degree"],
    correctIndex: 1,
    explanation: "Quickly tells HOW he runs, so it is a Manner adverb.",
    imagePath: 'adverb_quiz_square.webp',
  ),
  // 8. Positions
  LessonSlide(
    title: "Positions",
    content:
        "1. Front: YESTERDAY, Ravi studied.\n2. Middle: Ravi ALWAYS studies.\n3. End: Ravi studies QUICKLY.\n\nManner = End\nFrequency = Middle",
    imagePath: 'adverb_positions_square.webp',
    hindiContent: "     :\nYesterday (), Always ( ), Quickly ( )",
    tamilContent: "  :\nYesterday (), Always (), Quickly ().",
  ),
  // 9. Common Mistakes (Highlight Interaction)
  LessonHighlightInteraction(
    title: "Mistake Buster",
    introText: "Fix these common errors:",
    highlightItems: [
      "Ravi happy sings Error:  HAPPILY sings OK:",
      "He run quick Error:  Runs QUICKLY OK:",
      "Very unique Error:  Unique (No very!) OK:",
    ],
    exampleText: "Adjectives describe Nouns. Adverbs describe Verbs!",
    imagePath: 'adverb_mistakes_square.webp',
    hindiContent: "Happy sings  -> Happily sings  Quick  -> Quickly ",
    tamilContent: "Happy sings  -> Happily sings . Quick  -> Quickly .",
  ),
  // 10. Speaking
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'adverb_chart_square.webp',
    prompts: ["Ravi always studies here.", "He runs very quickly."],
    summaryPoints: [
      "Manner: -ly (quickly)",
      "Frequency: always/never",
      "Place: here/there",
      "Time: now/soon",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Which word is an adverb?',
    'question_tamil': '  (Adverb) ?',
    'question_hindi': '     ?',
    'options': ['Quick', 'Table', 'Quickly', 'Run'],
    'correct': 2,
  },
  {
    'question': '"She sings happi___."',
    'question_tamil': '"She sings happi___."',
    'question_hindi': '"She sings happi___."',
    'options': ['-ly', '-ness', '-er', '-est'],
    'correct': 0,
  },
  {
    'question': 'Manner adverbs answer: ___?',
    'question_tamil': 'Manner adverbs  : ___?',
    'question_hindi': 'Manner adverbs    : ___?',
    'options': ['When', 'How', 'Where', 'Why'],
    'correct': 1,
  },
  {
    'question': 'Identify the adverb: "He runs very fast."',
    'question_tamil': ' : "He runs very fast."',
    'question_hindi': '  : "He runs very fast."',
    'options': ['He', 'Runs', 'Fast', 'Very'],
    'correct': 3,
  },
  {
    'question': 'Frequency: "I ___ eat breakfast."',
    'question_tamil': 'Frequency: "I ___ eat breakfast."',
    'question_hindi': 'Frequency: "I ___ eat breakfast."',
    'options': ['quickly', 'always', 'here', 'happy'],
    'correct': 1,
  },
];
