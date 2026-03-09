import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonInfinitivesParticiplesScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonInfinitivesParticiplesScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_infinitives',
      title: 'Infinitives Participles',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_Infinitives_Participles/',
      progressBaseKey: 'lesson_infinitives',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // 1. Hook
  LessonSlide(
    title: "1 Verb = 4 Jobs",
    content:
        "A single verb can change form to do different jobs.\n\n| To eat (Purpose)\n| Eating (Action/Description)\n| Eaten (Completed)\n\nLet's see how they work!",
    imagePath: 'verb_forms_hook_square.webp',
    hindiContent: "  4   :  , , , ",
    tamilContent: "  4  :  , , , .",
  ),
  // 2. The Spectrum
  LessonSlide(
    title: "The Verb Spectrum",
    content:
        "1. Base: eat (I eat)\n2. Infinitive: to eat (I want to eat)\n3. Gerund/Participle: eating (Eating is fun)\n4. Past Participle: eaten (I have eaten)",
    imagePath: 'verb_spectrum_square.webp',
    hindiContent:
        "  : , Infinitive (to eat), Gerund (eating), Participle (eaten)",
    tamilContent:
        " : , Infinitive (to eat), Gerund (eating), Participle (eaten).",
  ),
  // 3. Infinitives
  LessonHighlightInteraction(
    title: "Infinitives (To + Verb)",
    introText: "Use TO + VERB for purpose or future intent:",
    highlightItems: [
      "After WANT (want to go)",
      "After NEED (need to sleep)",
      "After LIKE (like to play)",
      "To show PURPOSE (came to study)",
    ],
    exampleText: "I want TO eat dosa. She came TO learn.",
    imagePath: 'infinitive_purpose_square.webp',
    hindiContent: "TO +  = / want, need, like    ",
    tamilContent: "TO +  = /. want, need, like   .",
  ),
  // 4. Quiz: Infinitives
  LessonQuizInteraction(
    title: "Quick Check",
    question: "I decided ___ home.",
    options: ["go", "to go", "going"],
    correctIndex: 1,
    explanation:
        "Correct! After 'decide', we usually use the infinitive (to go).",
    imagePath: 'infinitive_purpose_square.webp',
  ),
  // 5. Bare Infinitives
  LessonHighlightInteraction(
    title: "Bare Infinitives",
    introText: "Wait! Sometimes we drop the 'TO':",
    highlightItems: [
      "After LET (Let him go)",
      "After MAKE (Make her study)",
      "After MODALS (Can swim, Must eat)",
    ],
    exampleText: "Let Ravi go. (NOT 'to go')",
    imagePath: 'bare_infinitive_square.webp',
    hindiContent: "    TO  : let, make, help, can, must",
    tamilContent: "   TO : let, make, help, can, must.",
  ),
  // 6. Present Participles
  LessonHighlightInteraction(
    title: "Present Participle (-ing)",
    introText: "Add -ING to show action or describe:",
    highlightItems: [
      "Happening NOW (is eating)",
      "As a NOUN (Eating is fun) -> Gerund",
      "Describing (Singing bird)",
    ],
    exampleText: "The sleeping cat looks cute.",
    imagePath: 'present_participle_square.webp',
    hindiContent: "-ING =       Eating is fun, Running boy ",
    tamilContent: "-ING =  . Eating is fun, Running boy .",
  ),
  // 7. Past Participles
  LessonHighlightInteraction(
    title: "Past Participle (-ed/en)",
    introText: "Use for completed actions or adjectives:",
    highlightItems: [
      "Completed (Has eaten)",
      "Passive (Was eaten)",
      "Describing (Broken chair)",
    ],
    exampleText: "The written book is on the table.",
    imagePath: 'past_participle_square.webp',
    hindiContent: "-ED/EN =   Eaten dosa, Broken chair ",
    tamilContent: "-ED/EN =  . Eaten dosa, Broken chair .",
  ),
  // 8. Quiz: Participle
  LessonQuizInteraction(
    title: "Quick Check",
    question: "The ___ glass (break)",
    options: ["breaking", "broken", "broke"],
    correctIndex: 1,
    explanation:
        "Correct! 'Broken' is the past participle used to describe the glass.",
    imagePath: 'past_participle_square.webp',
  ),
  // 9. Patterns Summary
  LessonSlide(
    title: "Verb Patterns",
    content:
        "Remember These Pairs:\n\n| Want TO go\n| Enjoy GOING\n| Let GO\n| Can GO\n\nVerbs form patterns. Memorize the first word to know what comes next!",
    imagePath: 'verb_patterns_square.webp',
    hindiContent: " : want to, enjoy -ing, let (bare)",
    tamilContent: " : want to, enjoy -ing, let (bare).",
  ),
  // 10. Speaking
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'verb_forms_chart_square.webp',
    prompts: ["I want to eat pizza.", "Swimming is fun.", "Let me go home."],
    summaryPoints: [
      "To + Verb (Infinitive)",
      "Verb + ing (Gerund/Participle)",
      "Bare Verb (Base form)",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'I want ___ dosa.',
    'question_tamil': 'I want ___ dosa.',
    'question_hindi': 'I want ___ dosa.',
    'options': ['eat', 'to eat', 'eating', 'eaten'],
    'correct': 1,
  },
  {
    'question': '___ dosa is fun.',
    'question_tamil': '___ dosa is fun.',
    'question_hindi': '___ dosa is fun.',
    'options': ['To eat', 'Eat', 'Eating', 'Eaten'],
    'correct': 2,
  },
  {
    'question': 'Let Ravi ___.',
    'question_tamil': 'Let Ravi ___.',
    'question_hindi': 'Let Ravi ___.',
    'options': ['to go', 'go', 'going', 'gone'],
    'correct': 1,
  },
  {
    'question': 'The ___ plate is empty.',
    'question_tamil': 'The ___ plate is empty.',
    'question_hindi': 'The ___ plate is empty.',
    'options': ['eating', 'to eat', 'eat', 'eaten'],
    'correct': 3,
  },
  {
    'question': 'Ravi enjoys ___ cricket.',
    'question_tamil': 'Ravi enjoys ___ cricket.',
    'question_hindi': 'Ravi enjoys ___ cricket.',
    'options': ['to play', 'play', 'playing', 'played'],
    'correct': 2,
  },
];
