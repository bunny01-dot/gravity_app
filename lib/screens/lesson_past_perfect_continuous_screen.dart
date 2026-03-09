import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonPastPerfectContinuousScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonPastPerfectContinuousScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_4_past_perfect_continuous',
      title: 'Past Perfect Continuous',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath:
          'assets/Lessons/Lesson_04_Tense_Past/04_Past_Perfect_Continuous/',
      progressBaseKey: 'lesson_4_past_perfect_continuous',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  LessonSlide(
    title: "How Long Had Ravi Been Doing It?",
    content:
        "Ravi had been studying for 3 hours when his mother called him for dinner.\nHow long had he been studying?",
    imagePath: 'ravi_been_studying_square.webp',
    hindiContent: " 3                     ?",
    tamilContent: " 3    ,      .     ?",
  ),
  LessonHighlightInteraction(
    title: "When We Use It",
    introText: "Use Past Perfect Continuous for:",
    highlightItems: [
      "Action in progress UNTIL another past time",
      "Imagine a duration leading up to a past event",
      "Reason/Cause for a past result",
    ],
    exampleText:
        "| Ravi had been studying for 3 hours when dinner was ready.\n| They had been playing for an hour when it began to rain.",
    imagePath: 'past_perfect_cont_timeline_square.webp',
    hindiContent: "      ",
    tamilContent: "       .",
  ),
  LessonSlide(
    title: "The Formula",
    content:
        "Subject + had + been + Verb(+ing)\n\n| I/You/He/She/We/They had been reading.\n| Ravi had been studying for 3 hours.\n| They had been waiting since morning.",
    imagePath: 'had_been_verb_table_square.webp',
    formula: "had + been + Verb(ing)",
    hindiContent: ": Subject + had + been + Verb(ing)",
    tamilContent: ": Subject + had + been + Verb(ing)",
  ),
  LessonSlide(
    title: "Ravi's Study Session",
    content:
        "Yesterday:\n2:00 PM  STARTED.\n...Studying...\n5:00 PM  Mom called.\n\nAt 5 PM, he HAD BEEN STUDYING for 3 hours.",
    imagePath: 'ravi_study_duration_square.webp',
    hindiContent: " 5 ,  3     ",
    tamilContent: " 5 ,  3    .",
  ),
  LessonSlide(
    title: "For vs. Since",
    content:
        "FOR (Duration):\n| 'He had been working for 4 hours.'\n\nSINCE (Start Point):\n| 'He had been working since 10 AM.'\n\nBoth tell us how long the action continued up to that past moment.",
    imagePath: 'for_since_past_perfect_square.webp',
    hindiContent: "For ()  Since ( )",
    tamilContent: "For ( ) vs Since ( ).",
  ),
  LessonSlide(
    title: "Evidence of Effort",
    content:
        "Often used to explain WHY someone was tired/wet/messy in the past:\n\n| 'He was sweating because he had been running.'\n| 'The road was wet because it had been raining.'",
    imagePath: 'evidence_duration_square.webp',
    hindiContent: "         ",
    tamilContent: "    .",
  ),
  LessonSlide(
    title: "Negative & Questions",
    content:
        "Negative:\nSubject + had not (hadn't) + been + V-ing\n| He hadn't been working long.\n\nQuestions:\nHad + Subject + been + V-ing?\n| Had you been waiting long?",
    imagePath: 'past_perfect_cont_qa_square.webp',
    formula: "hadn't been V-ing / Had you been V-ing?",
    hindiContent: "Negative: hadn't been. Question: Had you been...?",
    tamilContent: ": hadn't been. : Had you been...?",
  ),
  LessonQuizInteraction(
    title: "Quick Check!",
    question: "When the rain started, they ___ for 2 hours.",
    options: ["had been playing", "had played", "were playing"],
    correctIndex: 0,
    explanation:
        "Correct! 'Had been playing' emphasizes the duration up to that moment.",
    imagePath: 'past_perfect_cont_quiz_square.webp',
  ),
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'past_perfect_cont_speaking_square.webp',
    prompts: [
      "I had been studying for... before...",
      "How long had you been waiting?",
      "She had been working since...",
    ],
    summaryPoints: [
      "I had been waiting for...",
      "She had been working since...",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Formula for Past Perfect Continuous?',
    'question_tamil': 'Past Perfect Continuous-  ?',
    'question_hindi': 'Past Perfect Continuous    ?',
    'options': [
      'had + been + V-ing',
      'has + been + V-ing',
      'was + V-ing',
      'had + V3',
    ],
    'correct': 0,
  },
  {
    'question': 'He ___ waiting for 2 hours when she arrived.',
    'question_tamil': ' ,  2    ___ .',
    'question_hindi': '  ,   2    ___ ',
    'options': ['is waiting', 'had waited', 'had been waiting', 'waited'],
    'correct': 2,
  },
  {
    'question': 'We use "FOR" with...',
    'question_tamil': '"FOR"-  ...',
    'question_hindi': ' "FOR"      ...',
    'options': [
      'A starting point (9 PM)',
      'A duration (2 hours)',
      'Future time',
      'Single actions',
    ],
    'correct': 1,
  },
  {
    'question': 'She was tired because she ___ running.',
    'question_tamil': '      ___.',
    'question_hindi': '       ___ ',
    'options': ['had been', 'has been', 'was', 'is'],
    'correct': 0,
  },
  {
    'question': 'How long ___ waiting before the bus came?',
    'question_tamil': '      ___?',
    'question_hindi': '        ___?',
    'options': ['had you been', 'have you been', 'did you', 'were you'],
    'correct': 0,
  },
];
