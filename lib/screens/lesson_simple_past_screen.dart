import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonSimplePastScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonSimplePastScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_4_simple_past',
      title: 'Simple Past',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_04_Tense_Past/01_Simple_Past/',
      progressBaseKey: 'lesson_4_simple_past',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // Slide 1: Hook
  LessonSlide(
    title: "Ravi & Yesterday",
    content:
        "This is Ravi. Today he is happy. But what did he do yesterday? Let's talk about the past!",
    imagePath: 'ravi_yesterday_square.webp',
    hindiContent: "           ?   ()     !",
    tamilContent: " .    .      ?    !",
  ),
  // Slide 2: Info
  LessonSlide(
    title: "When to use Simple Past?",
    content:
        "We use Simple Past for actions that are FINISHED.\n\nKeywords:\n| Yesterday\n| Last week\n| In 2020\n| 2 hours ago",
    imagePath: 'past_timeline_square.webp',
    hindiContent: "               \n: ,  , 2020 ",
    tamilContent: "   Simple Past- .\n : ,  , 2  .",
  ),
  // Slide 3: Formula
  LessonSlide(
    title: "The Formula",
    content:
        "Subject + Verb (PAST form)\n\nExamples:\n| I played (Regular: -ed)\n| I went (Irregular: changes completely)",
    imagePath: 'present_past_table_square.webp',
    formula: "Subject + Verb(V2)",
    hindiContent: ":  +  ()\n: I played ( ), I went ( )",
    tamilContent: "Subject + Verb ( )\n: I played ( ), I went ( )",
  ),
  // Slide 4: Story
  LessonSlide(
    title: "Ravi's Morning Yesterday",
    content:
        "Yesterday morning:\n1. Ravi WOKE up at 7 AM.\n2. He BRUSHED his teeth.\n3. He ATE breakfast.\n4. He WENT to school.\n\nAll finished!",
    imagePath: 'morning_yesterday_square.webp',
    hindiContent: " :\n 7              !",
    tamilContent: " :\n 7  .  .   .  .  !",
  ),
  // Slide 5: Negative
  LessonSlide(
    title: "Negative Sentences",
    content:
        "To say NO in the past:\nSubject + DID NOT (didn't) + Verb (BASE form)\n\nExamples:\n| I didn't play (NOT played)\n| He didn't go (NOT went)",
    imagePath: 'negative_actions_square.webp',
    formula: "Subject + Didn't + Verb(Base)",
    hindiContent: " :\nSubject + did not +  ( )\n: I didn't play (  )",
    tamilContent: " :\nSubject + Didn't +  ( )\n.: I didn't play ( )",
  ),
  // Slide 6: Questions
  LessonSlide(
    title: "Asking Questions",
    content:
        "To ask a question:\nDID + Subject + Verb (BASE form)?\n\nExamples:\n| Did you play?\n| Did Ravi go to school?",
    imagePath: 'did_questions_square.webp',
    formula: "Did + Subject + Verb(Base)?",
    hindiContent: " :\nDid + Subject +  ( )?\n: Did you play? (  ?)",
    tamilContent: " :\nDid + Subject +  ( )?\n.: Did you play? ( ?)",
  ),
  // Slide 7: Regular vs Irregular
  LessonSlide(
    title: "Regular vs. Irregular",
    content:
        "REGULAR (+ed):\n| Walk  Walked\n| Play  Played\n\nIRREGULAR (Memorize!):\n| Go  Went\n| Eat  Ate\n| Sleep  Slept\n| See  Saw",
    imagePath: 'regular_irregular_square.webp',
    hindiContent: " (+ed): Walk -> Walked\n ( !): Go -> Went, Eat -> Ate",
    tamilContent:
        "Regular (+ed): Walk -> Walked\nIrregular ( !): Go -> Went, Eat -> Ate",
  ),
  // Slide 8: Speaking
  LessonSpeakingPractice(
    title: "Your Turn to Speak",
    micIconPath: null,
    imagePath: 'simple_past_speaking_square.webp',
    prompts: [
      "Tell me about yesterday!",
      "I woke up at...",
      "I ate...",
      "I watched...",
    ],
    summaryPoints: [
      "Use V2 for positive sentences",
      "Use didn't + V1 for negative",
      "Use Did + V1 for questions",
    ],
  ),
  // Slide 9: Summary
  LessonSlide(
    title: "Lesson Summary",
    content:
        "Great job! Remember:\n| Use Simple Past for finished actions.\n| Watch out for irregular verbs (go -> went).\n| Use 'didn't' + base verb for negatives.",
    imagePath: 'simple_past_summary_square.webp',
    hindiContent: " !  :              ",
    tamilContent: "!  :   Simple Past. Irregular verbs- .",
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Yesterday, Ravi ___ to school.',
    'question_tamil': ',   ___ ().',
    'question_hindi': ',   ___ ()',
    'options': ['go', 'went', 'goes'],
    'correct': 1,
  },
  {
    'question': 'He ___ watch TV last night.',
    'question_tamil': '    ___ ().',
    'question_hindi': '    ___ ( )',
    'options': ['didn\'t', 'don\'t', 'not'],
    'correct': 0,
  },
  {
    'question': '___ you eat breakfast?',
    'question_tamil': '   ?',
    'question_hindi': '   ?',
    'options': ['Do', 'Are', 'Did'],
    'correct': 2,
  },
  {
    'question': 'I ___ football yesterday.',
    'question_tamil': '   ___ ().',
    'question_hindi': '   ___ ()',
    'options': ['play', 'played', 'playing'],
    'correct': 1,
  },
];
