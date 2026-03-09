import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonFuturePerfectContinuousScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonFuturePerfectContinuousScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_5_future_perfect_continuous',
      title: 'Future Perfect Continuous',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath:
          'assets/Lessons/Lesson_05_Tense_Future/04_Future_Perfect_Continuous/',
      progressBaseKey: 'lesson_5_future_perfect_continuous',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  LessonSlide(
    title: "How Long Will He Study?",
    content:
        "By 5 PM tomorrow, how long will Ravi have been studying?\n\n3 hours? 4 hours?\n\nThis tense shows the DURATION of an action still in progress at that future moment.",
    imagePath: 'ravi_fut_perf_cont_square.webp',
    hindiContent: "  5  ,      ?",
    tamilContent: "  5 ,     ?",
  ),
  LessonHighlightInteraction(
    title: "When We Use It",
    introText: "Use Future Perfect Continuous for:",
    highlightItems: [
      "Duration of an action up to a future time",
      "Action still continuing at that point",
    ],
    exampleText:
        "| By 6 PM, I will have been working for 8 hours.\n| By next month, Ravi will have been studying for 6 months.",
    imagePath: 'duration_to_future_square.webp',
    hindiContent: "       ",
    tamilContent: "     .",
  ),
  LessonSlide(
    title: "The Formula",
    content:
        "Subject + will + have + been + Verb(+ing)\n\n| I will have been reading.\n| Ravi will have been studying for 4 hours by 5 PM.",
    imagePath: 'will_have_been_table_square.webp',
    formula: "will + have + been + V-ing",
    hindiContent: ": will + have + been + Verb(ing)",
    tamilContent: ": will + have + been + Verb(ing)",
  ),
  LessonSlide(
    title: "Ravi's Study Marathon",
    content:
        "Ravi starts at 1 PM.\n\n| By 3 PM  will have been studying 2 hours.\n| By 5 PM  will have been studying 4 hours.\n\nShows duration accumulating.",
    imagePath: 'ravi_study_marathon_square.webp',
    hindiContent: " 5  ,  4     ",
    tamilContent: " 5 ,  4   .",
  ),
  LessonHighlightInteraction(
    title: "Duration Markers",
    introText: "Always shows duration:",
    highlightItems: [
      "FOR (total time): for 8 hours",
      "SINCE (start point): since morning",
    ],
    exampleText:
        "OK: 'By noon, they will have been waiting since 9 AM.'\nOK: 'By 6 PM, I will have been working for 8 hours.'",
    imagePath: 'for_since_future_square.webp',
    hindiContent: "      'for'  'since'   ",
    tamilContent: "   'for'  'since' .",
  ),
  LessonSlide(
    title: "Evidence of Duration",
    content:
        "Physical evidence often shows the long effort:\n\n| Exhausted eyes  will have been studying for hours.\n| Sweaty clothes  will have been exercising.",
    imagePath: 'duration_evidence_square.webp',
    hindiContent: "         ",
    tamilContent: "      .",
  ),
  LessonSlide(
    title: "Negative & Questions",
    content:
        "Negative:\nSubject + won't + have + been + Verb-ing\n| Ravi won't have been studying for long.\n\nQuestions:\nWill + Subject + have + been + Verb-ing?",
    imagePath: 'fut_perf_cont_qa_square.webp',
    formula: "won't + have + been + V-ing",
    hindiContent: "       ",
    tamilContent: "     .",
  ),
  LessonSlide(
    title: "Perfect vs Perfect Continuous",
    content:
        "Future Perfect (Done):\n| 'Ravi will have finished by 5 PM.'\n\nFuture Perf. Continuous (Duration):\n| 'Ravi will have been studying for 4 hours by 5 PM.'",
    imagePath: 'future_perfects_compare_square.webp',
    hindiContent: "Future Perfect         ,  Perfect Continuous   ",
    tamilContent: "Future Perfect   , Perfect Continuous   .",
  ),
  LessonQuizInteraction(
    title: "Practice: Choose Correct",
    question: "By 6 PM, I ___ for 8 hours.",
    options: ["will work", "will have been working"],
    correctIndex: 1,
    explanation:
        "Correct! 'For 8 hours' indicates duration up to a future point.",
    imagePath: 'fut_perf_cont_quiz_square.webp',
  ),
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'fut_perf_cont_celebration_square.webp',
    prompts: [
      "By 8 PM, I will have been studying.",
      "How long will you have been working?",
      "He will have been waiting since noon.",
    ],
    summaryPoints: [
      "Subject + will have been + Verb(ing)",
      "Duration (for/since)",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Formula for Future Perfect Continuous?',
    'question_tamil': 'Future Perfect Continuous-  ?',
    'question_hindi': 'Future Perfect Continuous    ?',
    'options': [
      'will have been + V-ing',
      'will be + V-ing',
      'will have + V3',
      'had been + V-ing',
    ],
    'correct': 0,
  },
  {
    'question': 'This tense emphasizes...',
    'question_tamil': '   ...',
    'question_hindi': '    ...',
    'options': [
      'Completion',
      'Duration up to a future time',
      'Past habits',
      'Immediate future',
    ],
    'correct': 1,
  },
  {
    'question': 'By 6 PM, I ___ working for 8 hours.',
    'question_tamil': ' 6 ,  8    ___.',
    'question_hindi': ' 6  ,  8    ___',
    'options': ['will have been', 'will be', 'am', 'was'],
    'correct': 0,
  },
  {
    'question': 'Which keywords are common?',
    'question_tamil': '  ?',
    'question_hindi': '    ?',
    'options': ['For/Since + By', 'Yesterday', 'Now', 'Usually'],
    'correct': 0,
  },
  {
    'question': 'By next month, he ___ living here for 2 years.',
    'question_tamil': '  ,   2   ___.',
    'question_hindi': '  ,   2    ___',
    'options': ['will have been', 'is', 'will', 'has'],
    'correct': 0,
  },
];
