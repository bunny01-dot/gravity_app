import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonSimpleFutureScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonSimpleFutureScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_5_simple_future',
      title: 'Simple Future',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_05_Tense_Future/01_Simple_Future/',
      progressBaseKey: 'lesson_5_simple_future',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  LessonSlide(
    title: "Tomorrow",
    content:
        "The Simple Future talks about things that have NOT happened yet.\n\nExamples: Tomorrow, Next Week, Soon",
    imagePath: 'ravi_tomorrow_square.webp',
    hindiContent: "             ",
    tamilContent: "    .",
  ),
  LessonSlide(
    title: "The Formula",
    content:
        "We use the helper word 'Will' before the verb.\n\n| I will play.\n| She will sing.",
    imagePath: 'will_formula_square.webp',
    formula: "Subject + will + Verb(base)",
    hindiContent: "    'Will'    ",
    tamilContent: "  'Will' .",
  ),
  // Converted DragDrop 1 to QuizInteraction
  LessonQuizInteraction(
    title: "Quick Check",
    question: "Which word creates the Future Tense?",
    options: ["Did", "Will", "Is"],
    correctIndex: 1,
    explanation: "'Will' is the helper verb for Simple Future.",
    imagePath:
        'future_quiz_square.webp', // Text-based quiz or reuse image if available
  ),
  LessonSlide(
    title: "Plans",
    content:
        "Use it for decisions you make right now or plans.\n\nExample: 'I will call you later.'",
    imagePath: 'future_calendar_square.webp',
    hindiContent: "       ",
    tamilContent: "    .",
  ),
  LessonSlide(
    title: "Negative",
    content:
        "To say NO, use 'Will Not' or 'Won't'.\n\n| I won't go.\n| It won't rain.",
    imagePath: 'future_negative_square.webp',
    formula: "won't + Verb",
    hindiContent: "    'Won't'   ",
    tamilContent: "   'Won't' .",
  ),
  // Converted DragDrop 2 to QuizInteraction
  LessonQuizInteraction(
    title: "Quick Check",
    question: "Which is Negative?",
    options: ["Will", "Won't", "Do"],
    correctIndex: 1,
    explanation: "'Won't' is the short form of 'Will Not'.",
    imagePath: 'future_quiz_square.webp',
  ),
  LessonSlide(
    title: "Questions",
    content:
        "Put 'Will' at the start to ask a question.\n\n| Will you come?\n| Will it fly?",
    imagePath: 'future_questions_square.webp',
    formula: "Will + Subject + Verb?",
    hindiContent: "    'Will'    ",
    tamilContent: "  'Will'   .",
  ),
  LessonSlide(
    title: "Predictions",
    content:
        "Use it to guess what might happen.\n\nExample: 'It will run fast!'",
    imagePath: 'ravi_tomorrow_plan_square.webp',
    hindiContent: "        ",
    tamilContent: "   .",
  ),
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'future_speaking_square.webp',
    prompts: ["I will go tomorrow", "She will help us", "Will you come?"],
    summaryPoints: ["Use 'Will' for plans", "Use 'Won't' for negative"],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Which word indicates future?',
    'question_tamil': '   ?',
    'question_hindi': '       ?',
    'options': ['Did', 'Will', 'Does', 'Has'],
    'correct': 1,
  },
  {
    'question': 'I ___ go to the market tomorrow.',
    'question_tamil': '   ___ .',
    'question_hindi': '   ___ ',
    'options': ['will', 'willed', 'will to', 'am'],
    'correct': 0,
  },
  {
    'question': 'Short form of "will not"?',
    'question_tamil': '"will not"  ?',
    'question_hindi': '"will not"   ?',
    'options': ['Willn\'t', 'Don\'t', 'Won\'t', 'Not'],
    'correct': 2,
  },
  {
    'question': 'She ___ help us.',
    'question_tamil': '  ___ .',
    'question_hindi': '   ___ ',
    'options': ['will', 'wills', 'willing', 'to will'],
    'correct': 0,
  },
  {
    'question': 'We use Simple Future for...',
    'question_tamil': '   ...',
    'question_hindi': '        ...',
    'options': ['Past Habits', 'Predictions', 'Facts', 'Now'],
    'correct': 1,
  },
];
