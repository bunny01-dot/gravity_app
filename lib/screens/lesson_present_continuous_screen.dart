import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonPresentContinuousScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonPresentContinuousScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_3_present_continuous',
      title: 'Present Continuous',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath:
          'assets/Lessons/Lesson_03_Tense_Present/02_Continuous_Present/',
      progressBaseKey: 'lesson_3_present_continuous',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  LessonSlide(
    title: "Meet Ravi Again",
    content:
        "This time, we are watching him RIGHT NOW.\nWhat is he doing at this very moment?",
    tamilContent: " ,    .\n     ?",
    hindiContent: " ,      \n      ?",
    imagePath: 'ravi_action.webp',
  ),
  LessonHighlightInteraction(
    title: "Right Now!",
    introText: "We use Present Continuous for:",
    highlightItems: [
      "Actions happening NOW",
      "At this exact moment",
      "Temporary situations",
    ],
    exampleText: "| I am studying right now.\n| Ravi is playing football NOW.",
    tamilContent: " Present Continuous-  :\n|   \n|   \n|  ",
    hindiContent: " Present Continuous      :\n|    \n|    \n|  ",
    imagePath: 'ravi_studying.webp',
  ),
  LessonSlide(
    title: "The Formula",
    content:
        "Subject + is/are/am + Verb(+ing)\n\n| I am reading.\n| He is running.\n| We are playing.",
    tamilContent: "Subject + is/are/am + Verb(+ing)\n\n|   .\n|   .\n|   .",
    hindiContent: "Subject + is/are/am + Verb(+ing)\n\n|    \n|    \n|    ",
    imagePath: 'ravi_studying.webp',
    formula: "is/am/are + Verb(ing)",
  ),
  LessonSlide(
    title: "Spelling Rules",
    content:
        "Add -ing to verbs!\n\n| run  running (double n)\n| write  writing (drop e)\n| play  playing",
    tamilContent:
        " -ing !\n\n| run  running\n| write  writing\n| play  playing",
    hindiContent:
        "  -ing !\n\n| run  running\n| write  writing\n| play  playing",
    imagePath: 'ravi_action.webp',
  ),
  LessonSlide(
    title: "It is 7:30 AM",
    content: "What is Ravi doing RIGHT NOW?\n\nRavi is brushing his teeth.",
    tamilContent: "   ?\n\n   .",
    hindiContent: "     ?\n\n    ",
    imagePath: 'ravi_brushing.webp',
    formula: "is + brushing",
  ),
  LessonSlide(
    title: "It is 10 AM",
    content:
        "Boys are playing cricket.\nThe teacher is writing.\nRavi is watching.",
    tamilContent: "   .\n  .\n  .",
    hindiContent: "    \n   \n   ",
    imagePath: 'ravi_cricket.webp',
    formula: "are + playing",
  ),
  LessonSlide(
    title: "It is 2 PM (Negative)",
    content:
        "Ravi is NOT sleeping.\nHe is studying.\nHe is NOT playing video games.",
    tamilContent: "  .\n  .\n   .",
    hindiContent: "    \n   \n      ",
    imagePath: 'ravi_studying.webp',
    formula: "is + NOT + studying",
  ),
  LessonSlide(
    title: "Questions?",
    content:
        "Is Ravi playing? -> No, he is studying.\nWho is singing? -> The girl is singing!",
    tamilContent: "  ? -> ,   .\n ? ->   !",
    hindiContent: "    ? -> ,    \n   ? ->    !",
    imagePath: 'girl_singing.webp',
  ),
  LessonSlide(
    title: "Habit vs Now",
    content:
        "Simple Present: He plays on Saturdays (Habit).\n\nPresent Continuous: He is playing right now (Action happening now).",
    tamilContent: "Simple Present:    ().\n\nPresent Continuous:     ( ).",
    hindiContent: "Simple Present:      ()\n\nPresent Continuous:      ( )",
    imagePath: 'ravi_cricket.webp',
  ),
  LessonQuizInteraction(
    title: "Quick Check",
    question: "Select the correct sentence:",
    options: [
      "Ravi play cricket now.",
      "Ravi is playing cricket now.",
      "Ravi playing cricket now.",
    ],
    correctIndex: 1,
    explanation: "Correct! Subject + is + Verb(ing).",
    imagePath: 'ravi_cricket.webp',
  ),
  LessonSpeakingPractice(
    title: "Describe the Action",
    imagePath: 'ravi_brushing.webp',
    prompts: [
      "He is brushing his teeth.",
      "She is singing a song.",
      "They are playing cricket.",
    ],
  ),
  LessonSlide(
    title: "Common Mistakes",
    content:
        "Error: She is study.\nOK: She is studyING.\n\nError: I playing.\nOK: I AM playing.",
    tamilContent:
        "Error: She is study.\nOK: She is studyING.\n\nError: I playing.\nOK: I AM playing. (is/am/are  )",
    hindiContent:
        "Error: She is study.\nOK: She is studyING.\n\nError: I playing.\nOK: I AM playing. (is/am/are  )",
    imagePath: 'ravi_studying.webp',
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Which is Present Continuous?',
    'question_tamil': '  ?',
    'question_hindi': '    ?',
    'options': [
      'I play cricket.',
      'I am playing cricket.',
      'I played cricket.',
      'I will play cricket.',
    ],
    'correct': 1,
  },
  {
    'question': 'What is Ravi doing right now?',
    'question_tamil': '   ?',
    'question_hindi': '     ?',
    'options': ['He sleeps.', 'He is sleeping.', 'He slept.', 'He has slept.'],
    'correct': 1,
  },
  {
    'question': 'Spelling: Run + ing = ?',
    'question_tamil': ': Run + ing = ?',
    'question_hindi': ': Run + ing = ?',
    'options': ['Runing', 'Runneing', 'Running', 'Runng'],
    'correct': 2,
  },
  {
    'question': 'We use Present Continuous for...',
    'question_tamil': '    ...',
    'question_hindi': '        ...',
    'options': [
      'Habits (Every day)',
      'Actions happening NOW',
      'Past actions',
      'Future plans only',
    ],
    'correct': 1,
  },
  {
    'question': '___ they playing football?',
    'question_tamil': '___   ?',
    'question_hindi': '___     ?',
    'options': ['Am', 'Is', 'Are', 'Do'],
    'correct': 2,
  },
];
