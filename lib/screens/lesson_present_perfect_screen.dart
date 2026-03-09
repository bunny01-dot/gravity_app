import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonPresentPerfectScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonPresentPerfectScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_3_present_perfect',
      title: 'Present Perfect',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_03_Tense_Present/03_Perfect_Present/',
      progressBaseKey: 'lesson_3_present_perfect',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  LessonSlide(
    title: "What Has Ravi Done?",
    content:
        "Ravi is back! Today we learn Present Perfect.\nWhat has he done today? Has he eaten? Has he studied? Let's find out!",
    tamilContent: "  !   'Present Perfect'  .\n   ? ? ?  !",
    hindiContent: "    !   'Present Perfect' \n    ?    ?     ?    !",
    imagePath: 'ravi_achieved.webp',
  ),
  LessonSlide(
    title: "Past  Now",
    content:
        "Present Perfect connects past actions to NOW.\n\n| Experience: 'I have visited Chennai'\n| Result now: 'I have finished homework'\n| Recent: 'I have just eaten'",
    tamilContent: "Present Perfect     .\n\n| : '   '\n|  : '   '\n| : '  '",
    hindiContent:
        "Present Perfect      ()   \n\n| : '   '\n|  : '      '\n|   : '   '",
    imagePath: 'past_to_present.webp',
  ),
  LessonSlide(
    title: "The Formula",
    content:
        "Subject + have/has + Verb (past participle)\n\n| I/You/We/They HAVE eaten\n| He/She/It HAS studied",
    tamilContent:
        "Subject + have/has + Verb (past participle)\n\n| ///  \n| //  ",
    hindiContent:
        "Subject + have/has + Verb (past participle)\n\n| ///    (HAVE eaten)\n|     (HAS studied)",
    imagePath: 'past_to_present.webp',
    formula: "have/has + Past Participle (V3)",
  ),
  LessonSlide(
    title: "Past Participle",
    content:
        "It is the '3rd form' of the verb!\n\n| Regular: walk  walked\n| Irregular: eat  eaten, go  gone, see  seen",
    tamilContent:
        "  '3 '!\n\n| Regular: walk  walked\n| Irregular: eat  eaten, go  gone, see  seen",
    hindiContent:
        "   ' ' !\n\n| Regular: walk  walked\n| Irregular: eat  eaten, go  gone, see  seen",
    imagePath: 'ravi_achieved.webp',
  ),
  LessonHighlightInteraction(
    title: "Ravi's Morning",
    introText: "What has Ravi done this morning?",
    highlightItems: ["He has brushed his teeth", "He has eaten idli"],
    revealText: "All completed actions connected to today!",
    highlightText: "has brushed",
    tamilContent: "    ?\n|   \n|   ",
    hindiContent: "     ?\n|    \n|   ",
    imagePath: 'morning_achievements.webp',
  ),
  LessonHighlightInteraction(
    title: "Ravi's Travels",
    introText: "Ravi says: 'I have visited Ooty. I have eaten dosa.'",
    highlightItems: ["Experience in life", "Time doesn't matter here"],
    highlightText: "have visited",
    tamilContent: " : '  .   .'",
    hindiContent: "  : '       '",
    imagePath: 'experiences_map.webp',
  ),
  LessonSlide(
    title: "Time Words",
    content:
        "| JUST: 'I have just finished' (very recent)\n| ALREADY: 'She has already done it' (earlier than expected)\n| YET: 'Have you finished yet?'",
    tamilContent: "| JUST: '  '\n| ALREADY: '  '\n| YET: '  ?'",
    hindiContent: "| JUST: '    '\n| ALREADY: '     '\n| YET: '       ?'",
    imagePath: 'just_already_yet.webp',
  ),
  LessonHighlightInteraction(
    title: "Not Done Yet (Negative)",
    introText: "Ravi hasn't watched TV today. He hasn't played video games.",
    highlightItems: ["has not  hasn't"],
    highlightText: "hasn't watched",
    tamilContent: "   .    .",
    hindiContent: "            ",
    imagePath: 'negatives_scene.webp',
  ),
  LessonQuizInteraction(
    title: "Quick Check",
    question: "Has Ravi watched TV today?",
    options: ["Yes, he has", "No, he hasn't"],
    correctIndex: 1,
    explanation: "Correct! He hasn't done it yet.",
    imagePath: 'negatives_scene.webp',
  ),
  LessonSlide(
    title: "Questions",
    content:
        "Have + Subject + Participle?\n\n| Have you ever been to Kerala?\n| What have you eaten today?",
    tamilContent: "Have + Subject + Participle?\n\n|     ?\n|   ?",
    hindiContent: "Have + Subject + Participle?\n\n|      ?\n|     ?",
    imagePath: 'questions_students.webp',
  ),
  LessonQuizInteraction(
    title: "Ask Yourself",
    question: "Have you eaten breakfast today?",
    options: ["Yes, I have", "No, I haven't", "I don't know"],
    correctIndex: 0,
    explanation: "Great! Using 'have' in the answer is correct.",
    imagePath: 'questions_students.webp',
  ),
  LessonSlide(
    title: "Perfect vs Simple",
    content:
        "Present Perfect: 'I have lost my pen' (I am looking for it NOW)\n\nPast Simple: 'I lost my pen yesterday' (Just a story about the past)",
    tamilContent: "Present Perfect: '  ' ( )\n\nPast Simple: '   ' (  )",
    hindiContent:
        "Present Perfect: '     ' (     )\n\nPast Simple: '     ' (    )",
    imagePath: 'past_to_present.webp',
  ),
  LessonSlide(
    title: "Look Around",
    content:
        "| Rain has started. (Street is wet now)\n| Someone has broken the window. (It is broken now)\n| Ravi has won! (He is happy now)",
    tamilContent: "|   . (  )\n|   . ( )\n|  ! (   )",
    hindiContent: "|      (   )\n|       (    )\n|    ! (   )",
    imagePath: 'real_life_results.webp',
  ),
  LessonSpeakingPractice(
    title: "Tell Us!",
    imagePath: 'ravi_achieved.webp',
    prompts: ["I have visited...", "I have eaten...", "I have already..."],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Formula for Present Perfect?',
    'question_tamil': 'Present Perfect- ?',
    'question_hindi': 'Present Perfect  ?',
    'options': [
      'have/has + V1',
      'have/has + V3 (Past Participle)',
      'had + V3',
      'is/are + V-ing',
    ],
    'correct': 1,
  },
  {
    'question': 'He ___ his work.',
    'question_tamil': '   ___ ().',
    'question_hindi': '   ___ ',
    'options': ['has finished', 'have finished', 'finishing', 'done'],
    'correct': 0,
  },
  {
    'question': 'Have you ___ to Ooty?',
    'question_tamil': '  ___ ()?',
    'question_hindi': '   ___ ?',
    'options': ['go', 'went', 'gone/been', 'going'],
    'correct': 2,
  },
  {
    'question': 'Which word means "a short time ago"?',
    'question_tamil': '" "    ?',
    'question_hindi': '"  "    ?',
    'options': ['Already', 'Yet', 'Just', 'Ever'],
    'correct': 2,
  },
  {
    'question': 'They ___ eaten lunch yet.',
    'question_tamil': '    .',
    'question_hindi': '        ',
    'options': ['has not', 'have not', 'did not', 'are not'],
    'correct': 1,
  },
];
