import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonCorrelativeConjunctionsScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonCorrelativeConjunctionsScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_correlative',
      title: 'Correlative Conjunctions',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_Correlative_Conjunctions/',
      progressBaseKey: 'lesson_correlative',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // 1. Hook
  LessonSlide(
    title: "Pairs that Work Together",
    content:
        "Correlative conjunctions are paired words that connect equal parts of sentences.\n\nLike best friends, they always stay together!",
    imagePath: 'ravi_correlative_pairs_square.webp',
    hindiContent: "  (Correlative conjunctions)            ",
    tamilContent: "        .",
  ),
  // 2. Overview
  LessonSlide(
    title: "8 Core Pairs",
    content:
        "Common pairs:\n| Both...and (Two true)\n| Either...or (Choice)\n| Neither...nor (None)\n| Not only...but also (Bonus)",
    imagePath: '8_correlative_pairs_square.webp',
    hindiContent:
        "Both...and ()\nEither...or ( )\nNeither...nor ( )\nNot only...but also ( ...   )",
    tamilContent:
        "Both...and ()\nEither...or ( )\nNeither...nor ()\nNot only...but also ( ...  )",
  ),
  // 3. Both...And
  LessonSlide(
    title: "Both...And (Both True)",
    content:
        "Use when two things are true.\n\nBoth Ravi AND Mom eat dosa.\nRavi likes both cricket AND football.\n\nVerb is always PLURAL.",
    imagePath: 'both_and_square.webp',
    hindiContent: "A  B       (subjects)      ()",
    tamilContent: "A  B  .   (Plural)  .",
    formula: "Both [A] and [B] + Plural Verb",
  ),
  // 4. Either...Or
  LessonSlide(
    title: "Either...Or (Choice)",
    content:
        "Use when you have a choice.\n\nEither Ravi OR Mom will cook.\nYou can have either dosa OR idli.\n\nVerb agrees with the CLOSEST subject.",
    imagePath: 'either_or_square.webp',
    hindiContent: "  A  B ( )    (subject)    ",
    tamilContent: "A  B  .     (subject)  .",
    formula: "Either [A] or [B]",
  ),
  // 5. Quiz: Either...Or
  LessonQuizInteraction(
    title: "Quick Check",
    question: "Either Ravi or the girls ___ coming.",
    options: ["is", "are"],
    correctIndex: 1,
    explanation: "Correct! 'Girls' is closer to the verb, so use plural 'are'.",
    imagePath: 'either_or_square.webp',
  ),
  // 6. Neither...Nor
  LessonSlide(
    title: "Neither...Nor (None)",
    content:
        "Use when both are false.\n\nNeither Ravi NOR Mom likes bitter gourd.\nNeither dosa nor idli is ready.\n\nDo not use 'not' again!",
    imagePath: 'neither_nor_square.webp',
    hindiContent: "  A    B   (double negative)  ",
    tamilContent: "A- , B- .    (not)  .",
    formula: "Neither [A] nor [B]",
  ),
  // 7. Not Only...But Also
  LessonSlide(
    title: "Not Only...But Also",
    content:
        "When there is something extra!\n\nRavi is not only smart BUT ALSO kind.\nNot only dosa but also idli is popular.",
    imagePath: 'not_only_but_also_square.webp',
    hindiContent: "  !   A  B ",
    tamilContent: "  ! A   B- .",
  ),
  // 8. Comparison Pairs
  LessonSlide(
    title: "Comparison & Result",
    content:
        "| As...as (Equality)\nRavi is AS tall AS mom.\n\n| Rather...than (Preference)\nI'd RATHER study THAN play.\n\n| Such...that (Result)\nIt was SUCH a hot day THAT we stayed home.",
    imagePath: 'comparison_pairs_square.webp',
    hindiContent: "As...as =  \nRather...than = \nSuch...that = ",
    tamilContent: "As...as =  .\nRather...than =  .\nSuch...that = .",
  ),
  // 9. Parallel Structure
  LessonSlide(
    title: "Parallel Structure Rule",
    content:
        "Both parts must be the SAME type of word.\n\nOK: Both Ravi AND mom (Noun + Noun)\nError: Both Ravi eats AND mom (Verb + Noun)\n\nKeep it balanced!",
    imagePath: 'parallel_structure_square.webp',
    hindiContent: "        (+, +)",
    tamilContent: "      (+).",
  ),
  // 10. Speaking Practice
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'ravi_correlative_pairs_square.webp',
    prompts: [
      "Both Ravi and Mom are happy.",
      "Either you or I can go.",
      "Neither hot nor cold.",
    ],
    summaryPoints: [
      "Pairs connect equal parts",
      "Watch subject-verb agreement",
      "Keep structure parallel",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Both Ravi ___ Mom eat dosa.',
    'question_tamil': 'Both Ravi ___ Mom eat dosa.',
    'question_hindi': 'Both Ravi ___ Mom eat dosa.',
    'options': ['or', 'nor', 'and', 'but'],
    'correct': 2,
  },
  {
    'question': 'You can have either dosa ___ idli.',
    'question_tamil': 'You can have either dosa ___ idli.',
    'question_hindi': 'You can have either dosa ___ idli.',
    'options': ['and', 'nor', 'or', 'so'],
    'correct': 2,
  },
  {
    'question': 'Neither Ravi ___ Mom likes bitter gourd.',
    'question_tamil': 'Neither Ravi ___ Mom likes bitter gourd.',
    'question_hindi': 'Neither Ravi ___ Mom likes bitter gourd.',
    'options': ['nor', 'or', 'and', 'but'],
    'correct': 0,
  },
  {
    'question': 'Ravi is not only smart ___ kind.',
    'question_tamil': 'Ravi is not only smart ___ kind.',
    'question_hindi': 'Ravi is not only smart ___ kind.',
    'options': ['and', 'but also', 'so', 'or'],
    'correct': 1,
  },
  {
    'question': 'It was ___ a hot day that we stayed home.',
    'question_tamil': 'It was ___ a hot day that we stayed home.',
    'question_hindi': 'It was ___ a hot day that we stayed home.',
    'options': ['such', 'so', 'as', 'like'],
    'correct': 0,
  },
];
