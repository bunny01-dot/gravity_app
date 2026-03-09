import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonPastPerfectScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonPastPerfectScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_4_past_perfect',
      title: 'Past Perfect',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_04_Tense_Past/03_Past_Perfect/',
      progressBaseKey: 'lesson_4_past_perfect',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  LessonSlide(
    title: "What Had Ravi Done?",
    content:
        "Before Ravi went to school yesterday, he had already done many things.\nWhat had he done before 8 AM?",
    imagePath: 'ravi_before_school_square.webp',
    hindiContent: "    ,        8       ?",
    tamilContent: "    ,     .  8     ?",
  ),
  LessonHighlightInteraction(
    title: "When We Use It",
    introText: "Use Past Perfect for:",
    highlightItems: [
      "An action finished BEFORE another past action",
      "To show which happened FIRST",
      "The 'earlier' past",
    ],
    exampleText:
        "| Ravi had brushed his teeth BEFORE he went out.\n| They had eaten dinner BEFORE the movie started.",
    imagePath: 'past_perfect_timeline_square.webp',
    hindiContent: "    :            ",
    tamilContent: "Past Perfect- :        .",
  ),
  LessonSlide(
    title: "The Formula",
    content:
        "Subject + had + Verb (past participle)\n\n| I/You/He/She/We/They had finished homework.\n| Ravi had eaten idli.\n| They had gone home.",
    imagePath: 'had_pastpart_table_square.webp',
    formula: "had + Past Participle (V3)",
    hindiContent: ": Subject + had +  (V3)",
    tamilContent: ": Subject + had +  (V3)",
  ),
  LessonSlide(
    title: "Ravi's Morning",
    content:
        "Yesterday:\n7:00  Ravi had woken up.\n7:15  He had brushed his teeth.\n7:30  He had eaten breakfast.\n8:00  He went to school.\n\nSo: 'Ravi had eaten breakfast before he went to school.'",
    imagePath: 'ravi_morning_sequence_square.webp',
    hindiContent: "         ",
    tamilContent: "      .",
  ),
  LessonSlide(
    title: "Key Words",
    content:
        "| BEFORE + Past Simple\n  ('Ravi had done homework before he slept.')\n\n| AFTER + Past Perfect\n  ('After Ravi had finished, he watched TV.')\n\n| BY THE TIME\n  ('By the time teacher came, we had sat down.')",
    imagePath: 'before_after_by_square.webp',
    hindiContent: "Before ( ), After ( ), By the time ( )",
    tamilContent: " : Before, After, By the time.",
  ),
  LessonSlide(
    title: "Negative & Questions",
    content:
        "Negative:\nSubject + had not (hadn't) + V3\n| Ravi hadn't eaten lunch.\n\nQuestions:\nHad + Subject + V3?\n| Had Ravi studied before the test?",
    imagePath: 'past_perfect_neg_questions_square.webp',
    formula: "hadn't + V3 / Had + S + V3?",
    hindiContent: ": Ravi hadn't eaten. : Had Ravi studied?",
    tamilContent: ": Ravi hadn't eaten. : Had Ravi studied?",
  ),
  LessonSlide(
    title: "Past Perfect vs Simple Past",
    content:
        "First action = Past Perfect (had done)\nSecond action = Simple Past (did)\n\n'The movie had started (1st) when we arrived (2nd).'\n(We were late!)",
    imagePath: 'pp_vs_past_simple_square.webp',
    hindiContent: "  = Past Perfect.   = Simple Past.",
    tamilContent: "  = Past Perfect.   = Simple Past.",
  ),
  LessonQuizInteraction(
    title: "Quick Check!",
    question: "When Ravi reached school, the class ___ already ___.",
    options: ["had started", "started", "has started"],
    correctIndex: 0,
    explanation: "Correct! The class started BEFORE he arrived.",
    imagePath: 'past_perfect_quiz_square.webp',
  ),
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'past_perfect_speaking_square.webp',
    prompts: [
      "Before I came here, I had...",
      "By 8 AM today, I had...",
      "Before I went to sleep, I had...",
    ],
    summaryPoints: ["I had eaten...", "I had finished..."],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Formula for Past Perfect?',
    'question_tamil': 'Past Perfect-  ?',
    'question_hindi': 'Past Perfect    ?',
    'options': [
      'had + V3 (Past Participle)',
      'have + V3',
      'was + V-ing',
      'did + V1',
    ],
    'correct': 0,
  },
  {
    'question': 'Before he went to sleep, he ___ his homework.',
    'question_tamil': '   ,   ___ .',
    'question_hindi': '   ,    ___  ',
    'options': ['finishes', 'has finished', 'had finished', 'finished'],
    'correct': 2,
  },
  {
    'question': 'When I arrived, the train ___ already ___.',
    'question_tamil': ' ,   ___ .',
    'question_hindi': '  ,    ___  ',
    'options': ['had / left', 'has / left', 'was / leaving', 'did / leave'],
    'correct': 0,
  },
  {
    'question': 'She was hungry because she ___ breakfast.',
    'question_tamil': '       ___.',
    'question_hindi': '      ___ ',
    'options': ['has not eaten', 'had not eaten', 'did not ate', 'was not eat'],
    'correct': 1,
  },
  {
    'question': 'Which action happened FIRST?',
    'question_tamil': '   ?',
    'question_hindi': '    ?',
    'options': [
      'I went to school.',
      'I had eaten breakfast.',
      'Both same time.',
      'None.',
    ],
    'correct': 1,
  },
];
