import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonTypesOfSentencesScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonTypesOfSentencesScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_8_sentence_types',
      title: 'Types Of Sentences',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_08_Types_of_Sentences/',
      progressBaseKey: 'lesson_8_sentence_types',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  LessonSlide(
    title: "Same Words, Different Meaning",
    content:
        "Ravi eats dosa. (Statement)\nEats dosa? (Question)\nEat dosa! (Command)\nWhat a dosa! (Excitement)\n\nSame words, but different sentence types change the meaning completely!",
    imagePath: 'ravi_4_types_square.webp',
    hindiContent: " ,  !       ",
    tamilContent: " ,  !    .",
  ),
  LessonHighlightInteraction(
    title: "4 Types by Function",
    introText: "Sentences are defined by their PURPOSE:",
    highlightItems: [
      "Declarative (.): States fact  'Ravi eats dosa.'",
      "Interrogative (?): Asks question  'Does Ravi eat?'",
      "Imperative (.!): Gives command  'Eat dosa!'",
      "Exclamatory (!): Shows emotion  'What a dosa!'",
    ],
    exampleText: "Look at the punctuation mark to spot the type!",
    imagePath: '4_function_types_square.webp',
    hindiContent: "    !",
    tamilContent: "   !",
  ),
  LessonSlide(
    title: "Declarative (Statements)",
    content:
        "Declarative = tells information (most common)\n\nOK: Ravi eats dosa.\nOK: Mom cooks rice daily.\nOK: School starts at 9 AM.\n\nEnds with period (.). Most sentences you speak/write are this type.",
    imagePath: 'declarative_ravi_square.webp',
    formula: "Ends with .",
    hindiContent: " =    (.)     ",
    tamilContent: "  . (.)  .",
  ),
  LessonSlide(
    title: "Interrogative (Questions)",
    content:
        "Interrogative = asks questions\n\nOK: Does Ravi eat dosa?\nOK: Where is mom?\nOK: What time does school start?\n\nStarts with Wh-word OR helper verb. Ends with question mark (?).",
    imagePath: 'interrogative_ravi_square.webp',
    formula: "Ends with ?",
    hindiContent: " =    (?)     ",
    tamilContent: " . (?)  .",
  ),
  LessonSlide(
    title: "Imperative (Commands)",
    content:
        "Imperative = gives orders or requests\n\nOK: Eat dosa!\nOK: Come here.\nOK: Please sit down.\nOK: Don't run!\n\nThe subject 'You' is hidden. Ends with . or !",
    imagePath: 'imperative_ravi_square.webp',
    formula: "Ends with . or !",
    hindiContent: " =   ",
    tamilContent: "   .",
  ),
  LessonSlide(
    title: "Exclamatory (Emotions)",
    content:
        "Exclamatory = strong feelings\n\nOK: What a tasty dosa!\nOK: How delicious!\nOK: Ravi won the match!\nOK: Stop that noise!\n\nUse words like What/How + strong emotion. Ends with !",
    imagePath: 'exclamatory_ravi_square.webp',
    formula: "Ends with !",
    hindiContent: " =   (!)     ",
    tamilContent: " . (!)  .",
  ),
  LessonHighlightInteraction(
    title: "4 Types by Structure",
    introText: "Sentences can also be grouped by CLAUSES:",
    highlightItems: [
      "Simple: 1 idea  'Ravi eats.'",
      "Compound: 2 ideas + and/but  'Ravi eats, and mom cooks.'",
      "Complex: Main + because/when  'Ravi eats because he is hungry.'",
      "Compound-Complex: All 3!  'Ravi eats because he is hungry, and mom cooks.'",
    ],
    exampleText: "We will learn structure details in the next lesson!",
    imagePath: '4_structure_types_square.webp',
    hindiContent: "         ",
    tamilContent: "   .",
  ),
  LessonSlide(
    title: "Punctuation Guide",
    content:
        "Match ending mark to type:\n\nType          End       Example\nDeclarative   .         Ravi eats.\nInterrogative ?         Ravi eats?\nImperative    . or !    Eat!\nExclamatory   !         What a meal!\n\nQuick test: Read aloud  emotion shows type!",
    imagePath: 'punctuation_guide_square.webp',
    hindiContent: "       !",
    tamilContent: "     !",
  ),
  LessonHighlightInteraction(
    title: "Type Detective Quiz",
    introText: "Identify sentence type:",
    highlightItems: [
      "Ravi plays cricket.  Declarative OK:",
      "Play cricket, Ravi!  Imperative OK:",
      "What a goal!  Exclamatory OK:",
      "Where is Ravi?  Interrogative OK:",
      "Ravi plays because he loves it.  Complex OK:",
    ],
    exampleText: "Check the ending mark!",
    imagePath: 'type_detective_quiz_square.webp',
    hindiContent: "    ",
    tamilContent: "   .",
  ),
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'sentence_types_speaking_square.webp',
    prompts: [
      "Declarative: I like ice cream.",
      "Interrogative: Do you like ice cream?",
      "Imperative: Eat your ice cream!",
      "Exclamatory: What tasty ice cream!",
    ],
    summaryPoints: [
      "Declarative states facts (.)",
      "Interrogative asks questions (?)",
      "Imperative gives commands (.!)",
      "Exclamatory shows emotion (!)",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Which type asks a question?',
    'question_tamil': '   ?',
    'question_hindi': '     ?',
    'options': ['Declarative', 'Interrogative', 'Imperative', 'Exclamatory'],
    'correct': 1,
  },
  {
    'question': '"Eat your dosa!" is which type?',
    'question_tamil': '"Eat your dosa!"   ?',
    'question_hindi': '"Eat your dosa!"    ?',
    'options': ['Declarative', 'Interrogative', 'Imperative', 'Exclamatory'],
    'correct': 2,
  },
  {
    'question': 'Which punctuation ends a Declarative sentence?',
    'question_tamil': '     ?',
    'question_hindi': '          ?',
    'options': ['?', '!', '.', ','],
    'correct': 2,
  },
  {
    'question': '"What a beautiful day!" is...',
    'question_tamil': '"What a beautiful day!" ...',
    'question_hindi': '"What a beautiful day!" ...',
    'options': ['Exclamatory', 'Imperative', 'Declarative', 'Complex'],
    'correct': 0,
  },
  {
    'question': '"Ravi eats dosa." is...',
    'question_tamil': '"Ravi eats dosa." ...',
    'question_hindi': '"Ravi eats dosa." ...',
    'options': ['Imperative', 'Exclamatory', 'Declarative', 'Interrogative'],
    'correct': 2,
  },
];
