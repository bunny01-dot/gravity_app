import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonQuestionTypesScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonQuestionTypesScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_14_question_types',
      title: 'Question Types',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_14_Question_Types/',
      progressBaseKey: 'lesson_14_question_types',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // 1. Hook
  LessonSlide(
    title: "Question Power",
    content:
        "Questions are the key to conversation!\n\nDo you like dosa? \nWhere is the dosa? \nDosa or idli? ",
    imagePath: 'question_types_hook_square.webp',
    hindiContent: "       ",
    tamilContent: "   .",
    imageFit: BoxFit.contain,
  ),
  // 2. Overview
  LessonSlide(
    title: "5 Question Families",
    content:
        "1. Yes/No (Simple)\n2. WH (Information)\n3. Choice (Options)\n4. Tag (Confirmation)\n5. Indirect (Polite)",
    imagePath: '5_question_types_square.webp',
    hindiContent: "1. Yes/No\n2. WH\n3. Choice\n4. Tag\n5. Indirect",
    tamilContent: "1. Yes/No\n2. WH\n3. Choice\n4. Tag\n5. Indirect",
    imageFit: BoxFit.contain,
  ),
  // 3. Yes/No
  LessonSlide(
    title: "Yes/No Questions",
    content:
        "Start with Auxiliary (Do, Is, Can).\n\nOK: DO you like dosa?\nOK: CAN mom cook?\n\nAnswer is simple: Yes or No.",
    imagePath: 'yes_no_questions_square.webp',
    hindiContent: "  (Auxuliary)   ",
    tamilContent: "  (Auxiliary) .",
    formula: "Aux + Subject + Verb?",
    imageFit: BoxFit.contain,
  ),
  // 4. WH Questions
  LessonSlide(
    title: "WH Questions",
    content:
        "Start with Question Word.\n\nOK: WHAT do you eat?\nOK: WHERE is Ravi?\nOK: WHY are you late?",
    imagePath: 'wh_questions_square.webp',
    hindiContent: "  (Question Word)   ",
    tamilContent: "  (Question Word) .",
    formula: "WH + Aux + Subject?",
    imageFit: BoxFit.contain,
  ),
  // 5. Choice
  LessonSlide(
    title: "Choice Questions",
    content:
        "Giving options with OR.\n\nOK: Dosa OR Idli?\nOK: Monday OR Friday?\n\nChoose ONE option.",
    imagePath: 'choice_questions_square.webp',
    hindiContent: "OR    ",
    tamilContent: "OR   .",
    imageFit: BoxFit.contain,
  ),
  // 6. Tag
  LessonSlide(
    title: "Tag Questions",
    content:
        "Statement + Mini Question.\n\nOK: You like dosa, DON'T YOU?\nOK: Ravi is smart, ISN'T HE?\n\nConfirming facts.",
    imagePath: 'tag_questions_square.webp',
    hindiContent: "     ",
    tamilContent: " .",
    imageFit: BoxFit.contain,
  ),
  // 7. Indirect
  LessonSlide(
    title: "Indirect Questions",
    content:
        "Polite and embedded.\n\nError: Where is bank?\nOK: Could you TELL ME where the bank IS?\n\nWord order changes!",
    imagePath: 'indirect_questions_square.webp',
    hindiContent: "      !",
    tamilContent: ".   !",
    imageFit: BoxFit.contain,
  ),
  // 8. Quiz Detective
  LessonQuizInteraction(
    title: "Question Detective",
    question: "Identify: 'Tea or Coffee?'",
    options: ["Yes/No", "Choice", "Tag"],
    correctIndex: 1,
    explanation: "Using 'OR' makes it a Choice question.",
    imagePath: 'choice_questions_square.webp',
    imageFit: BoxFit.contain,
  ),
  // 9. Speaking
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'question_chart_square.webp',
    prompts: ["Do you like music?", "Where are you from?", "Coffee or tea?"],
    summaryPoints: [
      "Use Do/Is for Yes/No",
      "Use WH for info",
      "Use OR for choice",
    ],
    imageFit: BoxFit.contain,
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': '___ you like pizza?',
    'question_tamil': '___ you like pizza?',
    'question_hindi': '___ you like pizza?',
    'options': ['Do', 'Are', 'Is'],
    'correct': 0,
  },
  {
    'question': '___ is your name?',
    'question_tamil': '___ is your name?',
    'question_hindi': '___ is your name?',
    'options': ['What', 'Where', 'When'],
    'correct': 0,
  },
  {
    'question': 'Coffee ___ Tea?',
    'question_tamil': 'Coffee ___ Tea?',
    'question_hindi': 'Coffee ___ Tea?',
    'options': ['and', 'or', 'but'],
    'correct': 1,
  },
  {
    'question': 'You are happy, ___?',
    'question_tamil': 'You are happy, ___?',
    'question_hindi': 'You are happy, ___?',
    'options': ['are you', 'aren\'t you', 'do you'],
    'correct': 1,
  },
  {
    'question': 'Could you tell me where ___?',
    'question_tamil': 'Could you tell me where ___?',
    'question_hindi': 'Could you tell me where ___?',
    'options': ['is the bank', 'the bank is', 'bank is'],
    'correct': 1,
  },
];
