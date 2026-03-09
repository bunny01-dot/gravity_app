import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonIdiomsScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonIdiomsScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_idioms',
      title: 'Idioms',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_Idioms/',
      progressBaseKey: 'lesson_idioms',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // 1. Hook
  LessonSlide(
    title: "Hidden Meanings!",
    content:
        "Piece of cake = Easy!\nBreak a leg = Good luck!\nRaining cats and dogs = Heavy rain!\n\nWords trick you - the real meaning is hidden.",
    imagePath: 'idioms_confusion_square.webp',
    hindiContent: "      ,     ",
    tamilContent: "       .",
  ),
  // 2. Literal vs Idiom
  LessonSlide(
    title: "Literal vs Idiom",
    content:
        "Literal: Taking words exactly as said (Eating a cake).\n\nIdiom: A phrase with a special meaning.\n'Piece of cake' = A very easy task.",
    imagePath: 'literal_vs_idiom_square.webp',
    hindiContent: "Literal:   Idiom: 'Piece of cake'      ",
    tamilContent: "Literal:  . Idiom: 'Piece of cake'    .",
  ),
  // 3. Food Idioms
  LessonHighlightInteraction(
    title: "Food Idioms",
    introText: "Common idioms about food:",
    highlightItems: [
      "Piece of cake (Very easy)",
      "Spill the beans (Tell a secret)",
      "Bring home the bacon (Earn money)",
      "In the same boat (Same problem)",
    ],
    exampleText: "Don't spill the beans about the party!",
    imagePath: 'food_idioms_square.webp',
    hindiContent: "    Spill the beans =  ",
    tamilContent: "  . Spill the beans =  .",
  ),
  // 4. Quiz: Food
  LessonQuizInteraction(
    title: "Quick Check",
    question: "Don't spill the beans!",
    options: ["Don't make a mess", "Don't tell the secret", "Don't cook beans"],
    correctIndex: 1,
    explanation: "Correct! 'Spill the beans' means to reveal a secret.",
    imagePath: 'food_idioms_square.webp',
  ),
  // 5. Body Idioms
  LessonHighlightInteraction(
    title: "Body Idioms",
    introText: "Idioms using body parts:",
    highlightItems: [
      "Break a leg (Good Luck!)",
      "Cost an arm and a leg (Very Expensive)",
      "Lend a hand (Help someone)",
      "Cold shoulder (Ignore someone)",
    ],
    exampleText: "Can you lend me a hand with this?",
    imagePath: 'body_idioms_square.webp',
    hindiContent: "     Break a leg = ",
    tamilContent: "   . Break a leg = .",
  ),
  // 6. Animal Idioms
  LessonHighlightInteraction(
    title: "Animal Idioms",
    introText: "Animal-themed idioms:",
    highlightItems: [
      "Raining cats and dogs (Heavy rain)",
      "Let sleeping dogs lie (Avoid trouble)",
      "Hold your horses (Wait!)",
      "When pigs fly (Never happening)",
    ],
    exampleText: "It's raining cats and dogs outside!",
    imagePath: 'animal_idioms_square.webp',
    hindiContent: "   Raining cats and dogs =  ",
    tamilContent: "  . Raining cats and dogs = .",
  ),
  // 7. Quiz: Animal
  LessonQuizInteraction(
    title: "Quick Check",
    question: "I will do it when pigs fly.",
    options: ["I will do it soon", "I will do it never", "I love pigs"],
    correctIndex: 1,
    explanation: "Correct! Pigs cannot fly, so this means NEVER.",
    imagePath: 'animal_idioms_square.webp',
  ),
  // 8. School/Emotion Idioms
  LessonHighlightInteraction(
    title: "School & Emotion",
    introText: "For studying and feelings:",
    highlightItems: [
      "Hit the books (Study hard)",
      "Pass with flying colors (Great grade)",
      "On cloud nine (Very happy)",
      "Down in the dumps (Sad)",
    ],
    exampleText: "She was on cloud nine after passing.",
    imagePath: 'school_idioms_square.webp',
    hindiContent: "Hit the books =    On cloud nine =  ",
    tamilContent: "Hit the books =  . On cloud nine =  .",
  ),
  // 9. Completion Quiz
  LessonQuizInteraction(
    title: "Complete the Idiom",
    question: "I have butterflies in my ___ (Nervous)",
    options: ["head", "stomach", "hands"],
    correctIndex: 1,
    explanation: "Correct! 'Butterflies in my stomach' means feeling nervous.",
    imagePath: 'emotion_idioms_square.webp',
  ),
  // 10. Speaking Practice
  LessonSpeakingPractice(
    title: "Speaking Practice",
    imagePath: 'idioms_speaking_square.webp',
    prompts: [
      "The test was a piece of cake.",
      "Good luck, break a leg!",
      "I'm on cloud nine!",
    ],
    summaryPoints: [
      "Learning idioms sounds natural",
      "Don't translate literally",
      "Use them in context",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Piece of cake means?',
    'question_tamil': 'Piece of cake means?',
    'question_hindi': 'Piece of cake means?',
    'options': ['Tasty', 'Easy', 'Hard', 'Sweet'],
    'correct': 1,
  },
  {
    'question': 'Break a leg means?',
    'question_tamil': 'Break a leg means?',
    'question_hindi': 'Break a leg means?',
    'options': ['Get hurt', 'Good luck', 'Dance', 'Run'],
    'correct': 1,
  },
  {
    'question': 'Spill the beans means?',
    'question_tamil': 'Spill the beans means?',
    'question_hindi': 'Spill the beans means?',
    'options': ['Cook', 'Eat', 'Tell secret', 'Plant'],
    'correct': 2,
  },
  {
    'question': 'Hit the books means?',
    'question_tamil': 'Hit the books means?',
    'question_hindi': 'Hit the books means?',
    'options': ['Study', 'Punch', 'Read', 'Write'],
    'correct': 0,
  },
  {
    'question': 'Raining cats and dogs means?',
    'question_tamil': 'Raining cats and dogs means?',
    'question_hindi': 'Raining cats and dogs means?',
    'options': ['Animals', 'Light rain', 'Heavy rain', 'Sunny'],
    'correct': 2,
  },
];
