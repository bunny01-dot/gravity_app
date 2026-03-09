import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonSentencePatternsScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonSentencePatternsScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    return LessonScaffold(
      lessonId: 'lesson_7_sentence_patterns',
      title: 'Sentence Patterns',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: 'assets/Lessons/Lesson_07_Sentence_Patterns/',
      progressBaseKey: 'lesson_7_sentence_patterns',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }
}

final List<LessonUnit> _slides = [
  LessonSlide(
    title: "Same Ravi, Different Sentences",
    content:
        "Ravi eats dosa. Ravi runs fast. Ravi is happy.\n\nAll different sentences, but they follow the same 5 patterns!\n\nWhich pattern is your favorite?",
    imagePath: '5_patterns_overview_square.webp',
    hindiContent: "          ",
    tamilContent: "  .   .   .",
  ),
  LessonHighlightInteraction(
    title: "The 5 Patterns Overview",
    introText: "Every English sentence = 1 of these 5:",
    highlightItems: [
      "S-V-O: Ravi eats dosa",
      "S-V: Ravi runs",
      "S-V-A: Ravi is happy",
      "S-V-Adv: Ravi runs fast",
      "S-V-N: Ravi is a student",
    ],
    exampleText: "Subject (S) + Verb (V) is the core of every pattern!",
    imagePath: '5_patterns_overview_square.webp',
    hindiContent: "    5      ",
    tamilContent: "    5  .",
  ),
  LessonSlide(
    title: "Pattern 1: S-V-O (Most Common)",
    content:
        "Subject + Verb + Object (80% of sentences!)\n\nOK: Ravi eats dosa\nOK: Mom cooks rice\nOK: Teacher teaches English\n\nAsk: What?  Object answers.",
    imagePath: 'svo_ravi_eats_square.webp',
    formula: "S - V - O",
    hindiContent: " +  + ",
    tamilContent: " +  + ",
  ),
  LessonSlide(
    title: "Pattern 2: S-V (Simple Action)",
    content:
        "Subject + Verb (complete by itself)\n\nOK: Ravi runs\nOK: Birds fly\nOK: Baby sleeps\n\nNo object needed! Action is complete.",
    imagePath: 'sv_ravi_runs_square.webp',
    formula: "S - V",
    hindiContent: " + ",
    tamilContent: " + ",
  ),
  LessonSlide(
    title: "Pattern 3: S-V-A (Feelings)",
    content:
        "Subject + Verb + Adjective (describes subject)\n\nOK: Ravi is happy\nOK: Mom feels tired\nOK: Food tastes spicy\n\nLink verb (is, feels) + describing word.",
    imagePath: 'sva_ravi_happy_square.webp',
    formula: "S - V - Adj",
    hindiContent: " +  + ",
    tamilContent: " +  + ",
  ),
  LessonSlide(
    title: "Pattern 4: S-V-Adv (How?)",
    content:
        "Subject + Verb + Adverb (tells HOW)\n\nOK: Ravi runs fast\nOK: She speaks loudly\nOK: He works hard\n\nAdverbs usually end in -ly.",
    imagePath: 'svadv_ravi_fast_square.webp',
    formula: "S - V - Adv",
    hindiContent: " +  + ",
    tamilContent: " +  + ",
  ),
  LessonSlide(
    title: "Pattern 5: S-V-N (Identity)",
    content:
        "Subject + Verb + Noun (names subject)\n\nOK: Ravi is a student\nOK: She became a doctor\nOK: They are friends\n\nLink verb + new name/role for subject.",
    imagePath: 'svn_ravi_student_square.webp',
    formula: "S - V - Noun",
    hindiContent: " +  + ",
    tamilContent: " +  + ",
  ),
  LessonHighlightInteraction(
    title: "Pattern Detective Game",
    introText: "Identify the pattern:",
    highlightItems: [
      "Ravi plays cricket  S-V-O OK:",
      "Mom cooks  S-V OK:",
      "Baby is cute  S-V-A OK:",
      "Dog barks loudly  S-V-Adv OK:",
      "Ravi is captain  S-V-N OK:",
    ],
    exampleText: "Look at the end of the sentence to find the pattern type!",
    imagePath: 'mix_match_sentence_square.webp',
    hindiContent: "      !",
    tamilContent: "    !",
  ),
  LessonQuizInteraction(
    title: "Mix & Match Practice",
    question: "Which of these is an S-V-O sentence?",
    options: [
      "Ravi runs fast",
      "Ravi eats dosa",
      "Ravi is happy",
      "Ravi is a student",
    ],
    correctIndex: 1,
    explanation: "Correct! 'Ravi (S) eats (V) dosa (O)'.",
    imagePath: 'mix_match_sentence_square.webp',
  ),
  LessonSpeakingPractice(
    title: "Your Sentences + Cheat Sheet",
    imagePath: 'sentence_patterns_cheatsheet_square.webp',
    prompts: ["S-V-O: I eat pizza.", "S-V: Birds fly.", "S-V-A: I am happy."],
    summaryPoints: [
      " S-V-O = most common",
      " S-V = simplest",
      " S-V-A = feelings",
      " S-V-Adv = how",
      " S-V-N = identity",
    ],
  ),
];

final List<Map<String, dynamic>> _quizQuestions = [
  {
    'question': 'Which pattern is: "Ravi eats dosa"?',
    'question_tamil': '   : "Ravi eats dosa"?',
    'question_hindi': '     : "Ravi eats dosa"?',
    'options': ['S-V', 'S-V-O', 'S-V-A', 'S-V-N'],
    'correct': 1,
  },
  {
    'question': 'Which pattern represents: "Ravi runs"?',
    'question_tamil': '    : "Ravi runs"?',
    'question_hindi': '"Ravi runs"      ?',
    'options': ['S-V', 'S-V-O', 'S-V-Adv', 'S-V-N'],
    'correct': 0,
  },
  {
    'question': 'Identify the pattern: "Ravi is happy".',
    'question_tamil': ' : "Ravi is happy".',
    'question_hindi': ' : "Ravi is happy".',
    'options': ['S-V-O', 'S-V', 'S-V-A', 'S-V-Adv'],
    'correct': 2,
  },
  {
    'question': 'Identify the pattern: "Ravi runs fast".',
    'question_tamil': ' : "Ravi runs fast".',
    'question_hindi': ' : "Ravi runs fast".',
    'options': ['S-V-Adv', 'S-V-O', 'S-V-N', 'S-V'],
    'correct': 0,
  },
  {
    'question': 'Identify the pattern: "Ravi is a student".',
    'question_tamil': ' : "Ravi is a student".',
    'question_hindi': ' : "Ravi is a student".',
    'options': ['S-V-A', 'S-V-O', 'S-V-N', 'S-V'],
    'correct': 2,
  },
];
