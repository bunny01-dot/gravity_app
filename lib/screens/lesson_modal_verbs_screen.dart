import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonModalVerbsScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonModalVerbsScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_9_modals',
      title: 'Modal Verbs',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_09_Modal_Verbs/',
      progressBaseKey: 'lesson_9_modals',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // 1. Hook
  LessonSlide(
    title: "Same Ravi, Different Meaning",
    content:
        "Ravi can play cricket.\nRavi must study now.\nRavi should eat dosa.\n\nSame Ravi, but different 'helper words' (modals) change the whole meaning!",
    imagePath: 'ravi_modals_hook_square.webp',
    hindiContent: " ,  -   (modals)     !",
    tamilContent: " ,   ' ' (modals)   !",
  ),
  // 2. What are Modals?
  LessonHighlightInteraction(
    title: "What Are Modal Verbs?",
    introText:
        "9 Core Modals: can, could, will, would, shall, should, may, might, must",
    highlightItems: [
      "Followed by BASE verb (no -s, -ing, -ed)",
      "Same form for all subjects (I can, He can)",
      "Questions: Modal first (Can Ravi play?)",
    ],
    exampleText: "Ravi can eat. (NOT 'Ravi cans eat' Error:)",
    imagePath: '9_modals_overview_square.webp',
    hindiContent: ":    (Base Verb)   ",
    tamilContent: ":    (Base Verb) .",
  ),
  // 3. Ability
  LessonSlide(
    title: "Ability: Can / Could",
    content:
        "CAN = present ability or skill\nOK: Ravi can play cricket.\nOK: I can speak Tamil.\n\nCOULD = past ability OR polite request\nOK: Ravi could run fast (when young).\nOK: Could you help me? (polite)",
    imagePath: 'can_could_ability_square.webp',
    formula: "Can/Could + Verb",
    hindiContent: "CAN =  COULD =      ",
    tamilContent: "CAN = . COULD =      .",
  ),
  // 4. Obligation
  LessonSlide(
    title: "Obligation: Must / Have to",
    content:
        "MUST = strong obligation (internal)\nOK: Ravi must study for exams.\nOK: We must finish homework.\n\nHAVE TO = external rule\nOK: Ravi has to wear uniform.\nOK: I have to go to work.",
    imagePath: 'must_have_to_square.webp',
    formula: "Must/Have to + Verb",
    hindiContent: "MUST =   HAVE TO =   ",
    tamilContent: "MUST =  . HAVE TO =   .",
  ),
  // 5. Advice
  LessonSlide(
    title: "Advice: Should / Ought to",
    content:
        "SHOULD = advice or recommendation\nOK: You should study daily.\nOK: Ravi should eat breakfast.\n\nOUGHT TO = moral duty (stronger)\nOK: We ought to help the poor.\nOK: Students ought to respect teachers.",
    imagePath: 'should_advice_square.webp',
    formula: "Should/Ought to + Verb",
    hindiContent: "SHOULD =  OUGHT TO =  ",
    tamilContent: "SHOULD = . OUGHT TO =  .",
  ),
  // 6. Possibility
  LessonSlide(
    title: "Possibility: May / Might",
    content:
        "MAY = formal possibility or permission\nOK: It may rain tomorrow.\nOK: May I come in?\n\nMIGHT = less certain possibility\nOK: Ravi might win the match.\nOK: It might be spicy!",
    imagePath: 'may_might_possibility_square.webp',
    formula: "May/Might + Verb",
    hindiContent: "MAY = / MIGHT =  ",
    tamilContent: "MAY = /. MIGHT =  .",
  ),
  // 7. Future
  LessonSlide(
    title: "Future: Will / Shall",
    content:
        "WILL = future or promise\nOK: Ravi will study tomorrow.\nOK: I will help you.\n\nSHALL = formal suggestion (I/We)\nOK: Shall I make tea?\nOK: Shall we go now?",
    imagePath: 'will_shall_future_square.webp',
    formula: "Will/Shall + Verb",
    hindiContent: "WILL = / SHALL =  ()",
    tamilContent: "WILL = /. SHALL =  ().",
  ),
  // 8. Questions
  LessonSlide(
    title: "Questions & Negatives",
    content:
        "Questions: Put Modal FIRST\nOK: Can Ravi play?\nOK: Will you help?\n\nNegatives: Add NOT\nOK: Ravi cannot play. (can't)\nOK: You must not be late.\nOK: He should not worry.",
    imagePath: 'modal_questions_neg_square.webp',
    formula: "Modal + Subject... / Modal + not...",
    hindiContent: ": Modal  : Not ",
    tamilContent: ": Modal . : Not .",
  ),
  // 9. Quiz
  LessonQuizInteraction(
    title: "Quick Check",
    question: "Ravi ___ play guitar. (ability)",
    options: ["can", "should", "must"],
    correctIndex: 0,
    explanation: "Correct! 'Can' expresses ability.",
    imagePath: 'modal_quiz_square.webp',
  ),
  // 10. Speaking
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'modals_speaking_square.webp',
    prompts: [
      "I can run fast.",
      "I must learn English.",
      "You should drink water.",
      "It might rain today.",
    ],
    summaryPoints: [
      "Can = Ability",
      "Must = Obligation",
      "Should = Advice",
      "May/Might = Possibility",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Which modal shows "Ability"?',
    'question_tamil': 'Which modal shows "Ability"?',
    'question_hindi': 'Which modal shows "Ability"?',
    'options': ['Must', 'Can', 'Should', 'May'],
    'correct': 1,
  },
  {
    'question': 'Which sentence is correct?',
    'question_tamil': 'Which sentence is correct?',
    'question_hindi': 'Which sentence is correct?',
    'options': [
      'Ravi can plays.',
      'Ravi can to play.',
      'Ravi can play.',
      'Ravi cans play.',
    ],
    'correct': 2,
  },
  {
    'question': '"You ___ study for exams." (Strong Obligation)',
    'question_tamil': '"You ___ study for exams." (Strong Obligation)',
    'question_hindi': '"You ___ study for exams." (Strong Obligation)',
    'options': ['might', 'can', 'must', 'may'],
    'correct': 2,
  },
  {
    'question': 'Which modal is for "Advice"?',
    'question_tamil': 'Which modal is for "Advice"?',
    'question_hindi': 'Which modal is for "Advice"?',
    'options': ['Will', 'Should', 'Can', 'Might'],
    'correct': 1,
  },
  {
    'question': '"It ___ rain today." (Possibility)',
    'question_tamil': '"It ___ rain today." (Possibility)',
    'question_hindi': '"It ___ rain today." (Possibility)',
    'options': ['must', 'should', 'might', 'have to'],
    'correct': 2,
  },
];
