import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonArticlesScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonArticlesScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_2_articles',
      title: 'Articles',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_03_Articles/',
      progressBaseKey: 'lesson_2_articles',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  // Slide 1: Hook
  LessonSlide(
    title: "Ravi wants to eat",
    content:
        "A dosa? An apple? The specific mango his mom made?\n\nWhich article goes where?",
    imagePath: 'ravi_articles_confused_square.webp',
    hindiContent: "   ...  ?  ?       ?      ?",
    tamilContent: "  ...  ?  ?     ?  'article'  ?",
  ),
  // Slide 2: What Are Articles?
  LessonSlide(
    title: "What Are Articles?",
    content:
        "Small words before nouns.\n\nA/An = Any one (first mention)\n'I saw a dog.'\n\nThe = Specific one (known)\n'The dog was black.'",
    imagePath: 'a_vs_the_dog_square.webp',
    hindiContent: "    \n\nA/An =    ( )\n'   '\n\nThe =  ()\n'   '",
    tamilContent: "    .\n\nA/An =   ( )\n'   .'\n\nThe =   ()\n'   .'",
  ),
  // Slide 3: A vs An Rule
  LessonHighlightInteraction(
    title: "A vs An Rule",
    introText: "It depends on SOUND:",
    highlightItems: [
      "A + Consonant Sound (a dog, a cat, a university)",
      "An + Vowel Sound (an apple, an hour)",
    ],
    exampleText:
        "Sound matters, not spelling!\n'An hour' (h is silent) OK:\n'A university' (yoo sound) OK:",
    imagePath: 'a_an_sound_rule_square.webp',
    hindiContent: "     :\n\nA +   (a dog, a cat)\nAn +   (an apple, an hour)",
    tamilContent: "  :\n\nA +   (a dog)\nAn +   (an apple)",
  ),
  // Slide 4: Practice A/An
  LessonQuizInteraction(
    title: "Practice: A or An?",
    question: "He is ___ honest boy.",
    options: ["a", "an"],
    correctIndex: 1,
    explanation: "Correct! 'Honest' starts with an 'O' sound.",
    imagePath: 'a_an_quiz_square.webp',
  ),
  // Slide 5: When Use "The"
  LessonHighlightInteraction(
    title: "When Use 'The'?",
    introText: "Use 'The' for specific things:",
    highlightItems: [
      "Already mentioned (The book is red)",
      "Unique things (The sun, The moon)",
      "Superlatives (The best)",
    ],
    exampleText: "I bought a book. THE book is funny.\nLook at THE sky.",
    imagePath: 'the_specific_square.webp',
    hindiContent: "'The'       :\n   (The book)\n  (The sun)\n  (The best)",
    tamilContent: "'The'    :\n  (The book)\n (The sun)\n (The best)",
  ),
  // Slide 6: No Article Rules
  LessonSlide(
    title: "No Article (Zero)",
    content:
        "No article for:\nError: General plurals (I love books)\nError: Uncountable general (I drink water)\nError: Meals/Places (Go to school)\n\nBut specific: 'The water in this glass'.",
    imagePath: 'no_article_rules_square.webp',
    hindiContent: "  :\nError:  \nError:  \nError: /",
    tamilContent: "article :\nError:  \nError:  \nError: /",
  ),
  // Slide 7: Common Exceptions
  LessonHighlightInteraction(
    title: "Special Cases",
    introText: "Memorize these patterns:",
    highlightItems: [
      "Use THE with instruments (play the guitar)",
      "Use THE with directions (the right)",
      "Use THE with oceans (the Pacific)",
    ],
    exampleText: "Play cricket? No article.\nPlay THE guitar? Use 'The'.",
    imagePath: 'article_exceptions_square.webp',
    hindiContent: "    :\n   THE\n   THE\n   THE",
    tamilContent: "   :\n THE\n THE\n THE",
  ),
  // Slide 8: Story
  LessonSlide(
    title: "Ravi's Day",
    content:
        "He ate an idli. (First mention)\nThe idli was spicy. (Specific now)\n\nHe drank water. (Uncountable)\nThe water was cold. (Specific glass)\n\nHe went to school. (General place)\nThe teacher was kind. (Specific)",
    imagePath: 'ravi_articles_story_square.webp',
    hindiContent: "    ( )\n    ( )\n\n  \n   ",
    tamilContent: "   . ( )\n   . ()\n\n  .\n   .",
  ),
  // Slide 9: Practice Mixed
  LessonQuizInteraction(
    title: "Practice: Mixed",
    question: "___ Mount Everest is tall.",
    options: ["The", "A", "- (No article)"],
    correctIndex: 2,
    explanation: "Correct! Mountains usually don't take 'The' (unless ranges).",
    imagePath: 'mixed_articles_quiz_square.webp',
  ),
  // Slide 10: Reference
  LessonSpeakingPractice(
    title: "Speaking Practice",
    micIconPath: null,
    imagePath: 'articles_cheatsheet_square.webp',
    prompts: [
      "Describe breakfast: 'I ate an egg...'",
      "The egg was tasty.",
      "I drank water.",
    ],
    summaryPoints: [
      "A/An for new things",
      "The for known things",
      "No article for general things",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'I saw ___ elephant.',
    'question_tamil': ' ___  .',
    'question_hindi': ' ___  ',
    'options': ['a', 'an', 'the'],
    'correct': 1,
  },
  {
    'question': '___ sun is hot.',
    'question_tamil': '___   .',
    'question_hindi': '___   ',
    'options': ['A', 'An', 'The'],
    'correct': 2,
  },
  {
    'question': 'He is ___ honest man.',
    'question_tamil': ' ___  .',
    'question_hindi': ' ___   ',
    'options': ['a', 'an', 'the'],
    'correct': 1,
  },
  {
    'question': 'She plays ___ guitar.',
    'question_tamil': ' ___  .',
    'question_hindi': ' ___   ',
    'options': ['a', 'an', 'the'],
    'correct': 2,
  },
  {
    'question': 'I go to ___ school.',
    'question_tamil': ' ___  .',
    'question_hindi': ' ___   ',
    'options': ['the', 'a', '-', 'an'],
    'correct': 2,
  },
];
