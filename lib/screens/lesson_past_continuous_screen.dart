import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonPastContinuousScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonPastContinuousScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_4_past_continuous',
      title: 'Past Continuous',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_04_Tense_Past/02_Past_Continuous/',
      progressBaseKey: 'lesson_4_past_continuous',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  LessonSlide(
    title: "The Mystery of 7 PM",
    content:
        "Yesterday at 7 PM, Ravi was doing something.\nWhat was he doing at that time? Let's find out!",
    imagePath: 'ravi_7pm_square.webp',
    hindiContent: "  7 ,            ?    !",
    tamilContent: "  7 ,    .      ? !",
  ),
  LessonHighlightInteraction(
    title: "When We Use It",
    introText: "Use Past Continuous for:",
    highlightItems: [
      "Action IN PROGRESS at a past time",
      "What was happening THEN",
      "Duration in the past",
    ],
    exampleText:
        "| At 7 PM, Ravi WAS STUDYING.\n| Not 'studied' (finished), but 'was studying' (ongoing).",
    imagePath: 'past_cont_timeline_square.webp',
    hindiContent: "    :       :  7 ,    ",
    tamilContent: "Past Continuous- :     . .:  7 ,  .",
  ),
  LessonSlide(
    title: "The Formula",
    content:
        "Subject + WAS / WERE + Verb(+ing)\n\n| I / He / She / It -> WAS playing\n| You / We / They -> WERE playing",
    imagePath: 'was_were_table_square.webp',
    formula: "was/were + Verb(ing)",
    hindiContent: ": Subject + was/were + Verb(ing)",
    tamilContent: ": Subject + was/were + Verb(ing)",
  ),
  LessonSlide(
    title: "Ravi's Evening",
    content:
        "Yesterday evening:\n\n| At 6 PM, he was walking home.\n| At 7 PM, he was doing homework.\n| At 8 PM, he was watching TV.\n| At 9 PM, he was sleeping.",
    imagePath: 'ravi_evening_story_square.webp',
    hindiContent: " :\n6      \n7      ",
    tamilContent: " :\n6     .\n7    .",
  ),
  LessonSlide(
    title: "Negative Sentences",
    content:
        "Subject + WAS/WERE + NOT + Verb(+ing)\n\n| Ravi was not (wasn't) playing.\n| They were not (weren't) studying.\n\nRemember: wasn't / weren't!",
    imagePath: 'past_cont_negative_square.webp',
    formula: "was/were + not + V(ing)",
    hindiContent: "         ",
    tamilContent: "  .   .",
  ),
  LessonSlide(
    title: "Asking Questions",
    content:
        "WAS / WERE + Subject + Verb(+ing)?\n\n| Was Ravi studying at 7 PM?\n  -> Yes, he was.\n| Were they playing football?\n  -> No, they weren't.",
    imagePath: 'past_cont_questions_square.webp',
    formula: "Was/Were + S + V(ing)?",
    hindiContent: "    ?      ? ",
    tamilContent: "  ? .   ? .",
  ),
  LessonSlide(
    title: "Two Actions at Once",
    content:
        "Use 'WHILE' for two actions happening together:\n\n| Ravi was studying WHILE his sister was listening to music.\n| They were playing WHILE it was raining.",
    imagePath: 'two_actions_square.webp',
    hindiContent: "   :           ",
    tamilContent: "   :        .",
  ),
  // Embedded Quiz from original content
  LessonQuizInteraction(
    title: "Quick Quiz!",
    question: "They ___ playing football when it started to rain.",
    options: ["was", "were", "did"],
    correctIndex: 1,
    explanation: "Correct! 'They' takes 'were'.",
    imagePath: 'past_cont_quiz_square.webp',
  ),
  LessonSpeakingPractice(
    title: "Your Turn to Speak",
    imagePath: 'past_cont_speaking_square.webp',
    prompts: [
      "What were you doing at 7 AM yesterday?",
      "What were you doing at 5 PM yesterday?",
    ],
    summaryPoints: ["I was sleeping...", "I was playing..."],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Formula for Past Continuous?',
    'question_tamil': '   ?',
    'question_hindi': 'Past Continuous  ?',
    'options': ['was/were + V-ing', 'had + V3', 'did + V1', 'will be + V-ing'],
    'correct': 0,
  },
  {
    'question': 'Yesterday at 7 PM, Ravi ___ TV.',
    'question_tamil': '  7 ,   ___.',
    'question_hindi': '  7 ,   ___ ',
    'options': ['watched', 'was watching', 'is watching', 'watches'],
    'correct': 1,
  },
  {
    'question': 'We use "WHILE" for...',
    'question_tamil': '"WHILE"  ?',
    'question_hindi': ' "WHILE"     ?',
    'options': [
      'Completed actions',
      'Future plans',
      'Two actions at the same time',
      'Facts',
    ],
    'correct': 2,
  },
  {
    'question': 'They ___ playing football when it rained.',
    'question_tamil': '     ___.',
    'question_hindi': '       ___ ',
    'options': ['was', 'were', 'are', 'did'],
    'correct': 1,
  },
  {
    'question': 'Negative: She ___ sleeping.',
    'question_tamil': ':    ___.',
    'question_hindi': ':    ___ ',
    'options': ['was not', 'were not', 'did not', 'will not'],
    'correct': 0,
  },
];
