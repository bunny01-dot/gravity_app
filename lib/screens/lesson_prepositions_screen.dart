import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonPrepositionsScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonPrepositionsScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LessonScaffold(
      lessonId: 'lesson_prepositions',
      title: isDark ? 'Prepositions' : 'Prepositions',
      assetPath: 'assets/Lessons/Lesson_Prepositions/',
      progressBaseKey: 'lesson_prepositions',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
      slides: [
        // 1. Hook
        LessonSlide(
          title: "Where? When? How?",
          content:
              "Ravi table Error:\nRavi ON table OK:\n\nPrepositions act as locators. They tell us WHERE, WHEN, or HOW something is happening.",
          imagePath: 'preposition_hook_square.webp',
          hindiContent: "Prepositions ,      (:   - ON table)",
          tamilContent: "Prepositions ,    . (.:   - ON table).",
        ),
        // 2. Time Rules
        LessonSlide(
          title: "Time Rules (At/On/In)",
          content:
              "AT = exact time (at 5 PM)\nON = days/dates (on Monday)\nIN = months/years (in 2026)\n\nRavi studies AT 5 PM ON Monday IN January.",
          imagePath: 'time_prepositions_square.webp',
          formula: "Time: At < On < In",
          hindiContent: "AT:  (at 5 PM) ON:  (on Monday) IN: / (in 2026)",
          tamilContent: "AT:  (at 5 PM). ON:  (on Monday). IN: / (in 2026).",
        ),
        // 3. Place Rules
        LessonSlide(
          title: "Place Rules",
          content:
              "IN = enclosed spaces (in room)\nON = surfaces (on table)\nAT = specific points (at door)\n\nRavi is IN class ON a chair AT his desk.",
          imagePath: 'place_prepositions_square.webp',
          formula: "Place: In (inside) / On (top) / At (point)",
          hindiContent: "IN:  (in room) ON:  (on table) AT:    (at door)",
          tamilContent: "IN:  (in room). ON:  (on table). AT:   (at door).",
        ),
        // 4. Movement
        LessonSlide(
          title: "Movement (To/Through)",
          content:
              "TO = destination (Go to school)\nTHROUGH = path inside (Walk through park)\nACROSS = side to side (Run across road)",
          imagePath: 'movement_prepositions_square.webp',
          hindiContent: "TO:  THROUGH:    ACROSS: -",
          tamilContent: "TO: . THROUGH: . ACROSS: .",
        ),
        // 5. Fixed Phrases
        LessonSlide(
          title: "Fixed Phrases",
          content:
              "Some words are picky!\n\nOK: good AT math\nOK: angry WITH Ravi\nOK: interested IN cricket\nOK: wait FOR mom\n\nMemorize these pairs.",
          imagePath: 'common_phrases_square.webp',
          hindiContent: "     Prepositions    (good AT, wait FOR)",
          tamilContent: "   Prepositions  . (good AT, wait FOR).",
        ),
        // 6. Preposition Detective
        LessonHighlightInteraction(
          title: "Preposition Detective",
          introText: "Find the missing linkers:",
          highlightItems: [
            "Ravi studies ___ 5 PM.  AT",
            "Dosa is ___ the table.  ON",
            "Class is ___ Monday.  ON",
            "Good ___ swimming.  AT",
            "Walk ___ the park.  THROUGH",
          ],
          exampleText: "Observe how context changes the word.",
          imagePath: 'preposition_mistakes_square.webp',
          hindiContent: "      , ",
          tamilContent: "      .",
        ),
        // 7. Tricky Pairs
        LessonSlide(
          title: "Tricky Pairs",
          content:
              "AT vs IN Time:\n| AT 5 PM (Clock time)\n| IN the morning (Period of time)\n\nON vs IN Place:\n| ON page 5 (Surface)\n| IN the book (Inside)",
          imagePath: 'tricky_prepositions_square.webp',
          hindiContent: "AT   , IN    ON   , IN   ",
          tamilContent: " AT,   IN.  ON,  IN.",
        ),
        // 8. Verbs + Prep
        LessonSlide(
          title: "Verbs + Prepositions",
          content:
              "Verbs choose their partners:\n\n| Listen TO music (Not listen music)\n| Look AT board\n| Depend ON mom\n| Believe IN God",
          imagePath: 'verb_prepositions_square.webp',
          hindiContent: "  Preposition   Listen TO, Look AT",
          tamilContent: "  Preposition- . Listen TO, Look AT.",
        ),
        // 9. Common Mistakes
        LessonHighlightInteraction(
          title: "Mistake Buster",
          introText: "Don't say these!",
          highlightItems: [
            "Good IN math Error:  Good AT math OK:",
            "Meet IN 5 PM Error:  Meet AT 5 PM OK:",
            "Dosa IN table Error:  Dosa ON table OK:",
            "Class IN Monday Error:  Class ON Monday OK:",
          ],
          exampleText: "Small words make a big difference!",
          imagePath: 'preposition_mistakes_square.webp',
          hindiContent: "Good AT Math      AT ",
          tamilContent: "Good AT Math .  AT  .",
        ),
        // 10. Speaking
        LessonSpeakingPractice(
          title: "Speaking Practice",
          imagePath: 'preposition_chart_square.webp',
          prompts: [
            "I wake up at 6 AM.",
            "My birthday is in June.",
            "The book is on the table.",
            "I go to school.",
          ],
          summaryPoints: [
            "AT = Specific Time/Point",
            "ON = Days/Surfaces",
            "IN = Periods/Enclosed",
            "TO = Movement",
          ],
        ),
      ],
      quizQuestions: [
        {
          'question': 'Ravi is good ___ math.',
          'question_tamil': 'Ravi is good ___ math.',
          'question_hindi': 'Ravi is good ___ math.',
          'options': ['in', 'at', 'on', 'with'],
          'correct': 1,
        },
        {
          'question': 'I will meet you ___ 5 PM.',
          'question_tamil': 'I will meet you ___ 5 PM.',
          'question_hindi': 'I will meet you ___ 5 PM.',
          'options': ['on', 'in', 'at', 'to'],
          'correct': 2,
        },
        {
          'question': 'Put the book ___ the table.',
          'question_tamil': 'Put the book ___ the table.',
          'question_hindi': 'Put the book ___ the table.',
          'options': ['at', 'on', 'in', 'for'],
          'correct': 1,
        },
        {
          'question': 'We walk ___ the park.',
          'question_tamil': 'We walk ___ the park.',
          'question_hindi': 'We walk ___ the park.',
          'options': ['through', 'on', 'at', 'with'],
          'correct': 0,
        },
        {
          'question': 'My birthday is ___ January.',
          'question_tamil': 'My birthday is ___ January.',
          'question_hindi': 'My birthday is ___ January.',
          'options': ['at', 'on', 'in', 'to'],
          'correct': 2,
        },
      ],
    );
  }
}
