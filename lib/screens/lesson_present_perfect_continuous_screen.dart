import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonPresentPerfectContinuousScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonPresentPerfectContinuousScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_3_present_perfect_continuous',
      title: 'Present Perfect Continuous',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath:
          'assets/Lessons/Lesson_03_Tense_Present/04_Perfect_Continuous_Present/',
      progressBaseKey: 'lesson_3_present_perfect_continuous',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  LessonSlide(
    title: "Welcome Back!",
    content:
        "Ravi returns! Present Perfect Continuous asks HOW LONG something has continued until NOW. Ravi has been studying... but for how long?",
    tamilContent: "  !         'Present Perfect Continuous' .   ...   ?",
    hindiContent: "    ! 'Present Perfect Continuous'                ...   ?",
    imagePath: 'ravi_studying_long.webp',
  ),
  LessonSlide(
    title: "When We Use It",
    content:
        "1. Duration until now: 'I have been studying for 3 hours' (still tired)\n2. Recent action (Evidence): 'You are wet! You have been running'\n3. Repeated actions: 'She has been calling me all day'",
    tamilContent: "1.   : '3    '\n2. : ' !   '\n3.    : '     '",
    hindiContent: "1.    : ' 3     '\n2. : '  !    '\n3. -   : '       '",
    imagePath: 'duration_evidence.webp',
  ),
  LessonSlide(
    title: "The Formula",
    content:
        "Subject + have/has + been + Verb(+ing)\n\n| I/You/We/They HAVE BEEN studying\n| He/She/It HAS BEEN studying",
    tamilContent: "Subject + have/has + been + Verb(+ing)\n\n| ///   \n| //   ",
    hindiContent:
        "Subject + have/has + been + Verb(+ing)\n\n| ///    (HAVE BEEN studying)\n|     (HAS BEEN studying)",
    imagePath: 'formula_perfect_cont.webp',
    formula: "have/has + been + Verb(ing)",
    imageFit: BoxFit.contain,
  ),
  LessonHighlightInteraction(
    title: "Ravi's Marathon",
    introText: "Ravi has been studying English for 4 hours.",
    highlightItems: [
      "Look at his tired eyes!",
      "Messy hair!",
      "Coffee cups everywhere!",
    ],
    highlightText: "has been studying",
    tamilContent: " 4     .",
    hindiContent: " 4      ",
    imagePath: 'ravi_long_study.webp',
  ),
  LessonSlide(
    title: "Duration (For vs Since)",
    content:
        "| FOR (duration of time): for 2 hours, for 3 days\n| SINCE (starting point): since 7 AM, since Monday",
    tamilContent: "| FOR ( ): 2  , 3 \n| SINCE ( ):  7  ,  ",
    hindiContent: "| FOR (  ): 2  , 3  \n| SINCE ( ):  7  ,  ",
    imagePath: 'for_since_timeline.webp',
  ),
  LessonHighlightInteraction(
    title: "Evidence of Action",
    introText: "Look for EVIDENCE:",
    highlightItems: [
      "Wet clothes = 'You have been swimming'",
      "Sweaty forehead = 'You have been running'",
      "Dirty hands = 'You have been gardening'",
    ],
    highlightText: "have been swimming",
    tamilContent: " :\n  = '  '",
    hindiContent: "   :\n  = '   '",
    imagePath: 'recent_evidence.webp',
  ),
  LessonSlide(
    title: "Repeated Actions",
    content:
        "Something happening repeatedly over time:\n\n'She has been calling me all morning' (Multiple calls)\n'It has been raining all week' (Multiple times)",
    tamilContent: "    :\n\n'     '\n'    '",
    hindiContent: "   -    :\n\n'       '\n'     '",
    imagePath: 'repeated_actions.webp',
  ),
  LessonSlide(
    title: "Negative Examples",
    content:
        "| 'Ravi hasn't been playing video games.'\n| 'He hasn't been sleeping.'\n| 'His sister hasn't been watching TV.'",
    tamilContent: "| '    .'\n| '  .'\n| '    .'",
    hindiContent: "| '      '\n| '    '\n| '      '",
    imagePath: 'not_been_doing.webp',
    formula: "hasn't / haven't + been + Verb(ing)",
  ),
  LessonSlide(
    title: "Asking Questions",
    content:
        "| 'How long have you been studying?'\n| 'Have you been swimming?'\n\nAnswers:\n'I have been studying for 2 years.'",
    tamilContent: "| '   ?'\n| '  ?'\n\n:\n' 2   .'",
    hindiContent: "| '     ?'\n| '    ?'\n\n:\n' 2     '",
    imagePath: 'duration_questions.webp',
  ),
  LessonSlide(
    title: "Comparison",
    content:
        "Present Perfect: 'I have read 3 books' (Completed result)\n\nPresent Perfect Continuous: 'I have been reading all day' (Focus on the activity/duration)",
    tamilContent:
        "Present Perfect: ' 3  ' ( )\n\nPresent Perfect Continuous: '    ' ( )",
    hindiContent:
        "Present Perfect: ' 3   ' ( )\n\nPresent Perfect Continuous: '     ' (  )",
    imagePath: 'tense_comparison.webp',
  ),
  LessonSlide(
    title: "Real Life",
    content:
        "| Traffic jam: 'We have been waiting for 30 minutes'\n| Cooking: 'You have been baking' (Smells good!)\n| Cleaning: 'You have been mopping' (Floor is wet)",
    tamilContent: "|  : ' 30  '\n| : '   '\n|  : '   '",
    hindiContent: "|  : ' 30      '\n|  : '    '\n| : '    '",
    imagePath: 'real_life_duration.webp',
  ),
  LessonQuizInteraction(
    title: "Match Evidence",
    question: "You see flour on someone's apron. What have they been doing?",
    options: [
      "They have been swimming.",
      "They have been baking.",
      "They have been sleeping.",
    ],
    correctIndex: 1,
    explanation: "Correct! Flour is evidence of baking.",
    imagePath: 'evidence_matching.webp',
    imageFit: BoxFit.contain,
  ),
  LessonSpeakingPractice(
    title: "Describe the Evidence",
    imagePath: 'speaking_evidence_1.webp',
    prompts: [
      "He has been running.",
      "She has been cooking.",
      "I have been waiting for hours.",
    ],
    imageFit: BoxFit.contain,
  ),
  LessonSlide(
    title: "Review",
    content:
        "You mastered:\nOK: How long actions continue\nOK: Evidence of recent activity\nOK: Using FOR and SINCE",
    tamilContent: " :\nOK:    \nOK:   \nOK: FOR  SINCE ",
    hindiContent: "   :\nOK:     \nOK:     \nOK: FOR  SINCE  ",
    imagePath: 'formula_perfect_cont.webp',
    imageFit: BoxFit.contain,
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Complete: "I ___ studying for 3 hours."',
    'question_tamil': ': "I ___ studying for 3 hours."',
    'question_hindi': ' : "I ___ studying for 3 hours."',
    'options': ['have been', 'has been', 'am been', 'was'],
    'correct': 0,
  },
  {
    'question': 'Which shows DURATION?',
    'question_tamil': '   ?',
    'question_hindi': ' /  ?',
    'options': [
      'I know him.',
      'I have known him since 2010.',
      'I am knowing him.',
      'I knew him.',
    ],
    'correct': 1,
  },
  {
    'question': 'He is sweaty. What has he been doing?',
    'question_tamil': '  .    ?',
    'question_hindi': '         ?',
    'options': [
      'He is exercising.',
      'He has been exercising.',
      'He exercises.',
      'He exercised.',
    ],
    'correct': 1,
  },
  {
    'question': '"I have been waiting ___ 5 PM."',
    'question_tamil': '"I have been waiting ___ 5 PM."',
    'question_hindi': '"I have been waiting ___ 5 PM."',
    'options': ['for', 'since', 'at', 'on'],
    'correct': 1,
  },
  {
    'question': '"She has been calling ___ 2 hours."',
    'question_tamil': '"She has been calling ___ 2 hours."',
    'question_hindi': '"She has been calling ___ 2 hours."',
    'options': ['since', 'from', 'for', 'by'],
    'correct': 2,
  },
];
