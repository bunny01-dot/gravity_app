import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class LessonDirectIndirectSpeechScreen extends StatelessWidget {
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonDirectIndirectSpeechScreen({
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LessonScaffold(
      lessonId: 'lesson_direct_indirect',
      title: isDark ? 'Direct/Indirect Speech' : 'Direct/Indirect Speech',
      assetPath: 'assets/Lessons/Lesson_Direct_Indirect_Speech/',
      progressBaseKey: 'lesson_direct_indirect',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
      slides: [
        // 1. Hook
        LessonSlide(
          title: "Two Ways to Tell",
          content:
              "Direct Speech: The exact words spoken.\n\"I eat dosa.\"\n\nIndirect Speech: Reporting what was said.\nHe said he ate dosa.",
          imagePath: 'direct_indirect_hook_square.webp',
          hindiContent: "Direct:   (\"   \")\nIndirect:   (     )",
          tamilContent: "Direct:   (\"  \").\nIndirect:   (   ).",
        ),
        // 2. Core Difference / Formula
        LessonSlide(
          title: "The Formula",
          content:
              "Direct: Use quotes \" \"\nRavi said, \"I am happy.\"\n\nIndirect: Remove quotes, use THAT/IF\nRavi said THAT he was happy.",
          imagePath: 'speech_types_square.webp',
          hindiContent: "DIRECT:     INDIRECT:    , reported ",
          tamilContent: "DIRECT:   . INDIRECT:   , reported .",
        ),
        // 3. Tense Change (Backshift)
        LessonSlide(
          title: "1. Backshift Tense",
          content:
              "We usually go BACK one step in the past.\n\nPresent  Past\n\"I eat\"  He ATE\n\"I am eating\"  He WAS eating\n\"I will eat\"  He WOULD eat",
          imagePath: 'tense_backshift_square.webp',
          hindiContent: "       \"will\"  \"would\".",
          tamilContent: "   . \"will\"  \"would\".",
          formula: "Present  Past | Will  Would",
        ),
        // 4. Quiz: Tense
        LessonQuizInteraction(
          title: "Quick Check",
          question: "Ravi said, \"I play cricket.\"",
          options: [
            "He playing cricket",
            "He plays cricket",
            "He played cricket",
          ],
          correctIndex: 2,
          explanation:
              "Correct! Simple Present 'play' becomes Simple Past 'played'.",
          imagePath: 'tense_backshift_square.webp',
        ),
        // 5. Pronoun Changes
        LessonSlide(
          title: "2. Change the Person",
          content:
              "Pronouns change to match who is speaking.\n\n\"I love MY dosa\"\n\nHE loved HIS dosa\n\nI  He/She, My  His/Her",
          imagePath: 'pronoun_changes_square.webp',
          hindiContent: "       I  He/She, My  His/Her.",
          tamilContent: "   . I  He/She, My  His/Her.",
        ),
        // 6. Time and Place
        LessonSlide(
          title: "3. Time & Place",
          content:
              "Words for time and place also shift away.\n\nNow  Then\nToday  That day\nTomorrow  The next day\nHere  There",
          imagePath: 'time_place_changes_square.webp',
          hindiContent: "Now  Then, Today  That day, Tomorrow  The next day.",
          tamilContent: "Now  Then, Today  That day, Tomorrow  The next day.",
        ),
        // 7. Quiz: Time
        LessonQuizInteraction(
          title: "Quick Check",
          question: "Change 'Tomorrow' to indirect speech:",
          options: ["Yesterday", "The next day", "That day"],
          correctIndex: 1,
          explanation:
              "Correct! Tomorrow becomes 'The next day' or 'The following day'.",
          imagePath: 'time_place_changes_square.webp',
        ),
        // 8. Questions
        LessonSlide(
          title: "Reporting Questions",
          content:
              "Yes/No Question? Use IF or WHETHER.\n\"Are you hungry?\"  ...if I was hungry.\n\nWH Question? keep the word.\n\"Where is it?\"  ...where it was.",
          imagePath: 'question_indirect_square.webp',
          hindiContent: "Yes/No   if    WH      (where)",
          tamilContent: "Yes/No   if . WH      .",
        ),
        // 9. Commands
        LessonSlide(
          title: "Commands & Requests",
          content:
              "Use TO + Verb.\n\n\"Eat your dosa!\"\n\nMom told me TO eat my dosa.\n\n(Don't say 'that' for commands!)",
          imagePath: 'commands_indirect_square.webp',
          hindiContent: "\"to\" +     \"Eat!\"  Told me TO eat.",
          tamilContent: "\"to\" +  . \"Eat!\"  Told me TO eat.",
        ),
        // 10. Speaking Practice
        LessonSpeakingPractice(
          title: "Speaking Practice",
          imagePath: 'speech_reference_square.webp',
          prompts: [
            "I am happy  He said he was happy.",
            "I will come  He said he would come.",
            "Eat!  Told me to eat.",
          ],
          summaryPoints: [
            "Quotes gone",
            "Backshift tense",
            "Change pronouns",
            "Change time words",
          ],
        ),
      ],
      quizQuestions: [
        {
          'question': 'Ravi said, "I eat dosa."  Ravi said he ___ dosa.',
          'question_tamil': 'Ravi said, "I eat dosa."  Ravi said he ___ dosa.',
          'question_hindi': 'Ravi said, "I eat dosa."  Ravi said he ___ dosa.',
          'options': ['eat', 'eats', 'ate', 'eating'],
          'correct': 2,
        },
        {
          'question': '"I will come tomorrow."  He said he ____ come.',
          'question_tamil': '"I will come tomorrow."  He said he ____ come.',
          'question_hindi': '"I will come tomorrow."  He said he ____ come.',
          'options': ['will', 'would', 'is', 'was'],
          'correct': 1,
        },
        {
          'question':
              'Mom asked, "Are you hungry?"  Mom asked ___ I was hungry.',
          'question_tamil':
              'Mom asked, "Are you hungry?"  Mom asked ___ I was hungry.',
          'question_hindi':
              'Mom asked, "Are you hungry?"  Mom asked ___ I was hungry.',
          'options': ['that', 'did', 'if', 'why'],
          'correct': 2,
        },
        {
          'question': '"Eat dosa!"  Mom told me ___ eat dosa.',
          'question_tamil': '"Eat dosa!"  Mom told me ___ eat dosa.',
          'question_hindi': '"Eat dosa!"  Mom told me ___ eat dosa.',
          'options': ['to', 'that', 'if', 'for'],
          'correct': 0,
        },
        {
          'question': '"I love my book."  He said he loved ___ book.',
          'question_tamil': '"I love my book."  He said he loved ___ book.',
          'question_hindi': '"I love my book."  He said he loved ___ book.',
          'options': ['my', 'his', 'her', 'their'],
          'correct': 1,
        },
      ],
    );
  }
}
