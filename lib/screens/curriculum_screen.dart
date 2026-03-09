import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/data_service.dart';
import '../services/lesson_registry.dart';
import 'package:gravity_app/widgets/modern_glass_dialog.dart';
import 'package:gravity_app/widgets/tense_sub_menu.dart';
import '../services/sound_service.dart';
import 'package:gravity_app/services/placement_state_service.dart';
import 'package:gravity_app/data/repositories/csv_repository.dart';
import 'lesson_subjects_screen.dart';
import 'lesson_parts_of_speech_screen.dart'; // Restored
import 'package:gravity_app/screens/lesson_articles_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_simple_future_screen.dart';
// import 'package:gravity_app/screens/lesson_present_perfect_screen.dart'; // Provides LessonUnit classes
import 'package:gravity_app/screens/lesson_future_continuous_screen.dart';
import 'package:gravity_app/screens/placeholder_lesson_screen.dart';
import 'package:gravity_app/screens/lesson_sentence_patterns_screen.dart';
import 'package:gravity_app/screens/lesson_types_of_sentences_screen.dart';
import 'package:gravity_app/screens/lesson_modal_verbs_screen.dart';
import 'package:gravity_app/screens/lesson_subject_verb_agreement_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_phrasal_verbs_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_active_passive_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_correlative_conjunctions_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_prefixes_suffixes_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_relative_pronoun_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_verbal_nouns_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_adverbs_screen.dart'; // Checked
import 'package:gravity_app/screens/lesson_question_types_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_linking_words_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_irregular_verbs_screen.dart'; // Checked
import 'package:gravity_app/screens/lesson_comparatives_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_punctuation_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_direct_indirect_speech_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_idioms_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_determiners_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_prepositions_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_conditionals_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_infinitives_participles_screen.dart'; // Added
import 'package:gravity_app/screens/lesson_reported_questions_screen.dart'; // Added
import 'package:gravity_app/models/lesson_config.dart';
import 'package:gravity_app/widgets/refresh_lottie_loader.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Lesson Data fetched from DataService for consistency
  final List<Map<String, String>> _lessons = DataService()
      .getCurriculumLessons();
  List<List<dynamic>>? _circulationQuizCache;

  static const String _circulationQuizCsvUrl =
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vQ6hRMDTnZ8-ZQ9AbTappG9mOBnR7RgfZypI-ksDGr0r_nRkIyzFYBGDjB_A_xCWBge0z3VUIPSLtRa/pub?output=csv';

  static const Map<String, List<String>> _lessonQuizKeysByTitle = {
    'Lesson 1 - Subjects': [
      'lesson_1_subjects_quiz_completed',
      'lesson1_quiz_completed',
    ],
    'Lesson 2 - Parts of Speech': ['lesson_2_parts_of_speech_quiz_completed'],
    'Lesson 3 - Articles': ['lesson_2_articles_quiz_completed'],
    'Lesson 4 - Irregular Verbs': ['lesson_irregular_verbs_quiz_completed'],
    'Lesson 5 - Tense - Present': [
      'lesson_3_simple_present_quiz_completed',
      'lesson_3_present_continuous_quiz_completed',
      'lesson_3_present_perfect_quiz_completed',
      'lesson_3_present_perfect_continuous_quiz_completed',
    ],
    'Lesson 6 - Tense - Past': [
      'lesson_4_simple_past_completed',
      'lesson_4_past_continuous_quiz_completed',
      'lesson_4_past_perfect_quiz_completed',
      'lesson_4_past_perfect_continuous_quiz_completed',
    ],
    'Lesson 7 - Tense - Future': [
      'lesson_5_simple_future_quiz_completed',
      'lesson_5_future_continuous_quiz_completed',
      'lesson_5_future_perfect_quiz_completed',
      'lesson_5_future_perfect_continuous_quiz_completed',
    ],
    'Lesson 8 - Sentence Pattern': [
      'lesson_7_sentence_patterns_quiz_completed',
    ],
    'Lesson 9 - Subject-verb Agreement': ['lesson_subject_verb_quiz_completed'],
    'Lesson 10 - Modal Verbs': ['lesson_9_modals_quiz_completed'],
    'Lesson 11 - Types of Sentences': [
      'lesson_8_sentence_types_quiz_completed',
    ],
    'Lesson 12 - Question Types': ['lesson_14_question_types_quiz_completed'],
    'Lesson 13 - Phrasal Verbs': ['lesson_phrasal_verbs_quiz_completed'],
    'Lesson 14 - Prepositions': ['lesson_prepositions_quiz_completed'],
    'Lesson 15 - Prefixes & Suffixes': [
      'lesson_prefixes_suffixes_quiz_completed',
    ],
    'Lesson 16 - Determiners': ['lesson_determiners_quiz_completed'],
    'Lesson 17 - Punctuation': ['lesson_punctuation_quiz_completed'],
    'Lesson 18 - Adverbs': ['lesson_27_adverbs_quiz_completed'],
    'Lesson 19 - Correlative Conjunctions': [
      'lesson_correlative_quiz_completed',
    ],
    'Lesson 20 - Relative Pronoun': ['lesson_relative_pronoun_quiz_completed'],
    'Lesson 21 - Verbal Nouns': ['lesson_verbal_nouns_quiz_completed'],
    'Lesson 22 - Comparatives & Superlatives': [
      'lesson_comparatives_quiz_completed',
    ],
    'Lesson 23 - Active and Passive Voice': [
      'lesson_12_active_passive_completed',
    ],
    'Lesson 24 - Direct and Indirect Speech': [
      'lesson_direct_indirect_quiz_completed',
    ],
    'Lesson 25 - Reported Questions': [
      'lesson_reported_questions_quiz_completed',
    ],
    'Lesson 26 - Conditionals': ['lesson_conditionals_quiz_completed'],
    'Lesson 27 - Infinitives & Participles': [
      'lesson_infinitives_quiz_completed',
    ],
    'Lesson 28 - Linking Words': ['lesson_linking_words_quiz_completed'],
  };

  final Map<String, bool> _completedLessons = {};
  Map<String, bool> _quizCompleted = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlacementState();
    _loadProgress();
    _loadLessonQuizCompletion();
  }

  String _curriculumQuizKey(String lessonTitle) {
    final normalized = lessonTitle
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return 'curriculum_quiz_completed_$normalized';
  }

  Future<void> _loadLessonQuizCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = <String, bool>{};

    for (final lesson in _lessons) {
      final title = lesson['title'];
      if (title == null) continue;
      bool isCompleted = prefs.getBool(_curriculumQuizKey(title)) ?? false;
      final keys = _lessonQuizKeysByTitle[title] ?? const <String>[];
      for (final key in keys) {
        if (prefs.getBool(key) == true) {
          isCompleted = true;
          break;
        }
      }
      completed[title] = isCompleted;
    }

    if (mounted) {
      setState(() {
        _quizCompleted = completed;
      });
    }

    if (_currentUser == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .collection('curriculum_progress')
          .get();
      if (snapshot.docs.isEmpty) return;

      final merged = Map<String, bool>.from(completed);
      for (final doc in snapshot.docs) {
        if (doc.data()['completed'] == true) {
          merged[doc.id] = true;
          await prefs.setBool(_curriculumQuizKey(doc.id), true);
        }
      }

      if (mounted) {
        setState(() {
          _quizCompleted = merged;
        });
      }
    } catch (e) {
      debugPrint("Error loading curriculum quiz progress: $e");
    }
  }

  Future<void> _loadProgress() async {
    try {
      await SharedPreferences.getInstance();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading progress: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleViewSlides(String fileName) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const RefreshLottieLoader(
          message: "Opening slides...",
          subtitle: "Preparing presentation file",
        ),
      );

      // Load asset
      final byteData = await rootBundle.load('assets/PPTs/$fileName');

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');

      // Write file
      await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      if (mounted) {
        Navigator.pop(context); // Close loading

        // Open file
        final result = await OpenFilex.open(tempFile.path);
        if (result.type != ResultType.done) {
          _showError(
            "Could not open presentation: ${result.message}\nPlease ensure you have a PPT viewer installed.",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError("Error loading slides: $e");
      }
    }
  }

  Future<void> _handleTakeQuiz(String lessonTitle, String topic) async {
    // 1. Ask for question count (10 or 20)
    final int? questionCount = await _showQuestionCountDialog();
    if (questionCount == null) return; // User cancelled

    // 2. Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => PopScope(
        canPop: false,
        child: const RefreshLottieLoader(
          message: "Preparing quiz...",
          subtitle: "Loading questions for this lesson",
        ),
      ),
    );

    try {
      // 3. Load Questions
      final questions = await _loadQuestionsFromCsv(questionCount, lessonTitle);

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (questions.isNotEmpty) {
          _showQuizDialog(lessonTitle, questions);
        } else {
          _showError("Questions coming soon for this lesson.");
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showError("Failed to load quiz: $e");
      }
    }
  }

  Future<int?> _showQuestionCountDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    return await showModernDialog<int>(
      context,
      title: "Select Quiz Length",
      message: "How many questions would you like to attempt?",
      primaryButtonText: "20 Questions",
      onPrimaryPressed: () => Navigator.pop(context, 20),
      secondaryButtonText: "10 Questions",
      onSecondaryPressed: () => Navigator.pop(context, 10),
      icon: Icons.filter_list_alt,
      accentColor: colorScheme.primary,
    );
  }

  Future<List<Map<String, dynamic>>> _loadQuestionsFromCsv(
    int count,
    String lessonTitle,
  ) async {
    try {
      List<Map<String, dynamic>> buildQuestions(
        List<List<dynamic>> rows,
        String sourceLabel,
      ) {
        if (rows.isEmpty) {
          debugPrint(
            "Error: Quiz CSV ($sourceLabel): no rows found. Check quiz CSV registration or cloud sync.",
          );
          return [];
        }

        final lessonQuestions = <Map<String, dynamic>>[];
        String? currentSection;
        int? questionIndex;
        int? answerIndex;
        List<int> optionIndices = [];
        int scannedRows = 0;
        int invalidRows = 0;

        String normalizeCell(String value) {
          return value.replaceAll('\uFEFF', '').trim();
        }

        bool looksLikeHeaderRow(List<String> cells) {
          final lower = cells.map((c) => c.toLowerCase()).toList();
          final hasQuestion = lower.any((c) => c.contains('question'));
          final hasAnswer = lower.any((c) => c.contains('answer'));
          final hasOption = lower.any(
            (c) =>
                c.contains('option') ||
                c == 'a' ||
                c == 'b' ||
                c == 'c' ||
                c == 'd',
          );
          return hasQuestion && (hasAnswer || hasOption);
        }

        void updateHeaderIndices(List<String> cells) {
          questionIndex = null;
          answerIndex = null;
          optionIndices = [];
          for (int i = 0; i < cells.length; i++) {
            final value = cells[i].toLowerCase();
            if (value.contains('question')) {
              questionIndex = i;
            }
            if (value.contains('answer')) {
              answerIndex = i;
            }
            if (value.contains('option') ||
                value == 'a' ||
                value == 'b' ||
                value == 'c' ||
                value == 'd') {
              optionIndices.add(i);
            }
          }
          if (optionIndices.length > 4) {
            optionIndices = optionIndices.take(4).toList();
          }
        }

        int? resolveAnswerIndex(String raw, List<String> options) {
          final trimmed = raw.trim();
          if (trimmed.isEmpty) return null;

          final upper = trimmed.toUpperCase();
          if (upper == 'A' || upper == 'B' || upper == 'C' || upper == 'D') {
            return upper.codeUnitAt(0) - 'A'.codeUnitAt(0);
          }

          final numeric = int.tryParse(upper);
          if (numeric != null && numeric > 0) {
            return numeric - 1;
          }

          final matchIndex = options.indexWhere(
            (o) => o.toLowerCase() == trimmed.toLowerCase(),
          );
          if (matchIndex != -1) return matchIndex;

          return null;
        }

        for (final row in rows) {
          scannedRows++;
          if (row.isEmpty) continue;

          final cells = row
              .map((e) => normalizeCell(e?.toString() ?? ''))
              .toList();
          if (cells.every((c) => c.isEmpty)) continue;

          final firstNonEmpty = cells.firstWhere(
            (c) => c.isNotEmpty,
            orElse: () => '',
          );

          if (firstNonEmpty.toLowerCase().startsWith('lesson')) {
            currentSection = firstNonEmpty;
            continue;
          }

          if (looksLikeHeaderRow(cells)) {
            updateHeaderIndices(cells);
            continue;
          }

          currentSection ??= lessonTitle;
          if (!_isSameLesson(currentSection, lessonTitle)) {
            continue;
          }

          final resolvedQuestionIndex =
              questionIndex ?? (cells.length > 1 ? 1 : 0);
          if (resolvedQuestionIndex >= cells.length) {
            invalidRows++;
            continue;
          }

          final questionText = cells[resolvedQuestionIndex];
          if (questionText.isEmpty) {
            invalidRows++;
            continue;
          }

          final resolvedOptionIndices = optionIndices.isNotEmpty
              ? optionIndices.where((i) => i < cells.length).toList()
              : List.generate(
                  4,
                  (i) => resolvedQuestionIndex + 1 + i,
                ).where((i) => i < cells.length).toList();

          if (resolvedOptionIndices.isEmpty) {
            invalidRows++;
            continue;
          }

          final rawOptions = resolvedOptionIndices
              .map((i) => cells[i])
              .toList();
          final compactOptions = <String>[];
          final indexMap = <int, int>{};
          for (int i = 0; i < rawOptions.length; i++) {
            final optionText = rawOptions[i].trim();
            if (optionText.isEmpty) continue;
            indexMap[i] = compactOptions.length;
            compactOptions.add(optionText);
          }

          if (compactOptions.length < 2) {
            invalidRows++;
            continue;
          }

          final answerCell =
              (answerIndex != null && answerIndex! < cells.length)
              ? cells[answerIndex!]
              : cells.last;

          final answerIndexRaw = resolveAnswerIndex(answerCell, rawOptions);
          int? answerIndexResolved;
          if (answerIndexRaw != null) {
            answerIndexResolved = indexMap[answerIndexRaw];
          }
          answerIndexResolved ??= resolveAnswerIndex(
            answerCell,
            compactOptions,
          );

          if (answerIndexResolved == null ||
              answerIndexResolved < 0 ||
              answerIndexResolved >= compactOptions.length) {
            invalidRows++;
            continue;
          }

          lessonQuestions.add({
            'question': questionText,
            'options': compactOptions,
            'answerIndex': answerIndexResolved,
          });
        }

        if (lessonQuestions.isEmpty) {
          debugPrint(
            'Error: Quiz CSV ($sourceLabel): 0 questions for "$lessonTitle". '
            'Scanned $scannedRows rows, invalid $invalidRows. '
            'Check lesson header mapping and quiz CSV registration.',
          );
        }

        lessonQuestions.shuffle(Random());
        return lessonQuestions.take(count).toList();
      }

      final rows = await DataService().getRawQuizData();
      var lessonQuestions = buildQuestions(rows, 'primary');

      if (lessonQuestions.isEmpty) {
        debugPrint(
          ' Quiz CSV: Trying dedicated circulation CSV for "$lessonTitle".',
        );
        try {
          final fallbackRows =
              _circulationQuizCache ??
              await CsvRepository().fetchAndParseCsv(_circulationQuizCsvUrl);
          _circulationQuizCache = fallbackRows;
          lessonQuestions = buildQuestions(fallbackRows, 'circulation');
        } catch (e) {
          debugPrint('Error: Circulation CSV fallback failed: $e');
        }
      }

      return lessonQuestions;
    } catch (e) {
      debugPrint("Error loading CSV: $e");
      rethrow;
    }
  }

  bool _isSameLesson(String sectionInCsv, String requestedLesson) {
    String normalize(String input) {
      return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    }

    int? extractLessonNumber(String input) {
      final match = RegExp(r'(?:lesson|l)\\s*0*(\\d+)').firstMatch(input);
      if (match == null) return null;
      return int.tryParse(match.group(1) ?? '');
    }

    final normalizedSection = normalize(sectionInCsv);
    final normalizedRequested = normalize(requestedLesson);
    if (normalizedSection.isEmpty || normalizedRequested.isEmpty) {
      return false;
    }

    final sectionNumber = extractLessonNumber(normalizedSection);
    final requestedNumber = extractLessonNumber(normalizedRequested);
    if (sectionNumber != null && requestedNumber != null) {
      return sectionNumber == requestedNumber;
    }

    return normalizedSection.contains(normalizedRequested) ||
        normalizedRequested.contains(normalizedSection);
  }

  void _showQuizDialog(
    String lessonTitle,
    List<Map<String, dynamic>> questions,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      pageBuilder: (context, _, __) {
        return _QuizView(
          lessonTitle: lessonTitle,
          questions: questions,
          onComplete: (scorePercentage) async {
            // Save progress
            if (scorePercentage >= 70) {
              await _markCompleted(lessonTitle);
            }
          },
        );
      },
    );
  }

  Future<void> _markCompleted(String lessonTitle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_curriculumQuizKey(lessonTitle), true);

    if (mounted) {
      setState(() {
        _completedLessons[lessonTitle] = true;
        _quizCompleted[lessonTitle] = true;
      });
    }

    if (_currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .collection('curriculum_progress')
          .doc(lessonTitle) // e.g. "Lesson 1 - Subjects"
          .set({
            'completed': true,
            'timestamp': FieldValue.serverTimestamp(),
            'score': 100, // Or actual score? Assuming 90+ is enough
          });

      // Also trigger a reload to ensure stars update via syncItem logic
      await _loadProgress();
    } catch (e) {
      debugPrint("Error saving progress: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final lessons = _lessons;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Curriculum",
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: lessons.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHigh.withValues(
                              alpha: 0.62,
                            )
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Recommended to follow lessons in order for systematic learning.",
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final lesson = lessons[index - 1];
                return _buildLessonCard(lesson);
              },
            ),
    );
  }

  Widget _buildLessonCard(Map<String, String> lesson) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final rawTitle = lesson['title'] ?? 'Lesson';
    final rawSubtitle = lesson['topic'] ?? '';
    final title = _sanitizeCardText(rawTitle).isEmpty
        ? 'Lesson'
        : _sanitizeCardText(rawTitle);
    final subtitle = _sanitizeCardText(rawSubtitle);
    final isCompleted = _quizCompleted[rawTitle] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.9)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showLessonDetails(lesson, isCompleted),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: isDark ? 0.8 : 0.66,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isCompleted) ...[
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3DDC84).withValues(alpha: 0.95),
                          const Color(0xFF7CFFB2).withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _sanitizeCardText(String input) {
    if (input.isEmpty) return '';

    final ascii = input.replaceAll(RegExp(r'[^\x20-\x7E]'), ' ');
    return ascii.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Widget _buildSkeletonLoader() {
    return const RefreshLottieLoader(
      message: "Loading curriculum...",
      subtitle: "Building your lesson roadmap",
    );
  }

  void _showLessonDetails(Map<String, String> lesson, bool isCompleted) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Check if this lesson has a story book
    // Every lesson in our 28-lesson curriculum map is designed to have a Storybook
    final hasStoryBook =
        lesson['title'] != null && lesson['title']!.startsWith('Lesson ');
    final storyActionLabel = isCompleted ? "Review Lesson" : "Start Story Book";
    final storyActionIcon = isCompleted
        ? Icons.refresh_rounded
        : Icons.auto_stories;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _sanitizeCardText(lesson['title'] ?? 'Lesson'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),

            // For lessons with story books: 3 buttons in column
            if (hasStoryBook) ...[
              SizedBox(
                width: double.infinity,
                child: _buildActionBtn(
                  storyActionLabel,
                  storyActionIcon,
                  () async {
                    await _startStoryBook(lesson);
                  },
                  colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      "View Slides",
                      Icons.slideshow_rounded,
                      () {
                        Navigator.pop(context);
                        _handleViewSlides(lesson['file']!);
                      },
                      Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionBtn("Quiz", Icons.quiz_rounded, () {
                      Navigator.pop(context);
                      _handleTakeQuiz(lesson['title']!, lesson['topic']!);
                    }, colorScheme.primary),
                  ),
                ],
              ),
            ] else ...[
              // For other lessons: 2 buttons side by side
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      "View Slides",
                      Icons.slideshow_rounded,
                      () {
                        Navigator.pop(context);
                        _handleViewSlides(lesson['file']!);
                      },
                      Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionBtn("Quiz", Icons.quiz_rounded, () {
                      Navigator.pop(context);
                      _handleTakeQuiz(lesson['title']!, lesson['topic']!);
                    }, colorScheme.primary),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _openLesson(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => screen));
    if (!mounted) return;
    await _loadProgress();
    await _loadLessonQuizCompletion();
  }

  Future<void> _startStoryBook(Map<String, String> lesson) async {
    final title = lesson['title'];
    if (title == null) return;

    Navigator.pop(context);

    switch (title) {
      case 'Lesson 1 - Subjects':
        await _openLesson(const LessonSubjectsScreen());
        break;
      case 'Lesson 2 - Parts of Speech':
        await _openLesson(const LessonPartsOfSpeechScreen());
        break;
      case 'Lesson 3 - Articles':
        await _openLesson(const LessonArticlesScreen());
        break;
      case 'Lesson 4 - Irregular Verbs':
        await _openLesson(const LessonIrregularVerbsScreen());
        break;
      case 'Lesson 5 - Tense - Present':
        _showPresentTenseSelection(lesson);
        break;
      case 'Lesson 6 - Tense - Past':
        _showPastTenseSelection(lesson);
        break;
      case 'Lesson 7 - Tense - Future':
        _showFutureTenseSelection(lesson);
        break;
      case 'Lesson 8 - Sentence Pattern':
        await _openLesson(const LessonSentencePatternsScreen());
        break;
      case 'Lesson 9 - Subject-verb Agreement':
        await _openLesson(const LessonSubjectVerbAgreementScreen());
        break;
      case 'Lesson 10 - Modal Verbs':
        await _openLesson(const LessonModalVerbsScreen());
        break;
      case 'Lesson 11 - Types of Sentences':
        await _openLesson(const LessonTypesOfSentencesScreen());
        break;
      case 'Lesson 12 - Question Types':
        await _openLesson(const LessonQuestionTypesScreen());
        break;
      case 'Lesson 13 - Phrasal Verbs':
        await _openLesson(const LessonPhrasalVerbsScreen());
        break;
      case 'Lesson 14 - Prepositions':
        await _openLesson(const LessonPrepositionsScreen());
        break;
      case 'Lesson 15 - Prefixes & Suffixes':
        await _openLesson(const LessonPrefixesSuffixesScreen());
        break;
      case 'Lesson 16 - Determiners':
        await _openLesson(const LessonDeterminersScreen());
        break;
      case 'Lesson 17 - Punctuation':
        await _openLesson(const LessonPunctuationScreen());
        break;
      case 'Lesson 18 - Adverbs':
        await _openLesson(const LessonAdverbsScreen());
        break;
      case 'Lesson 19 - Correlative Conjunctions':
        await _openLesson(const LessonCorrelativeConjunctionsScreen());
        break;
      case 'Lesson 20 - Relative Pronoun':
        await _openLesson(const LessonRelativePronounScreen());
        break;
      case 'Lesson 21 - Verbal Nouns':
        await _openLesson(const LessonVerbalNounsScreen());
        break;
      case 'Lesson 22 - Comparatives & Superlatives':
        await _openLesson(const LessonComparativesScreen());
        break;
      case 'Lesson 23 - Active and Passive Voice':
        await _openLesson(const LessonActivePassiveScreen());
        break;
      case 'Lesson 24 - Direct and Indirect Speech':
        await _openLesson(const LessonDirectIndirectSpeechScreen());
        break;
      case 'Lesson 25 - Reported Questions':
        await _openLesson(const LessonReportedQuestionsScreen());
        break;
      case 'Lesson 26 - Conditionals':
        await _openLesson(const LessonConditionalsScreen());
        break;
      case 'Lesson 27 - Infinitives & Participles':
        await _openLesson(const LessonInfinitivesParticiplesScreen());
        break;
      case 'Lesson 28 - Linking Words':
        await _openLesson(const LessonLinkingWordsScreen());
        break;
      case 'Lesson 20 - Idioms':
        // Legacy support
        await _openLesson(const LessonIdiomsScreen());
        break;
    }
  }

  Future<void> _loadPlacementState() async {
    try {
      await PlacementStateService.ensureInitialized();
      await PlacementStateService.getPlacementQuizStatus();
      await PlacementStateService.getUserLevel();
    } catch (e) {
      debugPrint("Error loading placement state: $e");
    }
  }

  void _showPresentTenseSelection(Map<String, String> lesson) {
    final lessonGroup = LessonRegistry().getLessonGroup('lesson_3_present');
    if (lessonGroup == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TenseSubMenu(
        lessonGroup: lessonGroup,
        onLessonCompleted: (lessonId) async {
          await _loadProgress();
          await _loadLessonQuizCompletion();
        },
      ),
    );
  }

  void _showPastTenseSelection(Map<String, String> lesson) {
    final lessonGroup = LessonRegistry().getLessonGroup('lesson_4_past');
    if (lessonGroup == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TenseSubMenu(
        lessonGroup: lessonGroup,
        onLessonCompleted: (lessonId) async {
          await _loadProgress();
          await _loadLessonQuizCompletion();
        },
      ),
    );
  }

  void _showFutureTenseSelection(Map<String, String> lesson) {
    LessonGroup? lessonGroup = LessonRegistry().getLessonGroup(
      'lesson_5_future',
    );

    // Fallback if Hot Restart hasn't happened yet
    lessonGroup ??= LessonGroup(
      id: 'lesson_5_future',
      title: 'Lesson 5 - Tense - Future',
      subtitle: 'Select a branch to master',
      themeColor: Colors.cyanAccent,
      lessons: [
        LessonConfig(
          id: 'simple_future',
          title: '1. Simple Future',
          subtitle: 'Predictions & Plans',
          icon: Icons.rocket_launch,
          isUnlocked: true,
          screenBuilder: () => const LessonSimpleFutureScreen(),
          progressKey: 'lesson_5_simple_future_completed',
        ),
        LessonConfig(
          id: 'future_continuous',
          title: '2. Future Continuous',
          subtitle: 'Will be doing...',
          icon: Icons.rocket_launch,
          isUnlocked: true,
          screenBuilder: () => const LessonFutureContinuousScreen(),
          progressKey: 'lesson_5_future_continuous_completed',
        ),
        LessonConfig(
          id: 'future_perfect',
          title: '3. Future Perfect',
          subtitle: 'Will have done...',
          icon: Icons.rocket_launch,
          isUnlocked: true,
          screenBuilder: () =>
              const PlaceholderLessonScreen(title: 'Future Perfect'),
          progressKey: 'lesson_5_future_perfect_completed',
        ),
        LessonConfig(
          id: 'future_perfect_continuous',
          title: '4. Future Perf. Continuous',
          subtitle: 'Will have been doing...',
          icon: Icons.rocket_launch,
          isUnlocked: true,
          screenBuilder: () =>
              const PlaceholderLessonScreen(title: 'Future Perfect Continuous'),
          progressKey: 'lesson_5_future_perfect_continuous_completed',
        ),
      ],
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TenseSubMenu(
        lessonGroup: lessonGroup!,
        onLessonCompleted: (lessonId) async {
          await _loadProgress();
          await _loadLessonQuizCompletion();
        },
      ),
    );
  }

  Widget _buildActionBtn(
    String label,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizView extends StatefulWidget {
  final String lessonTitle;
  final List<Map<String, dynamic>> questions;
  final Function(int) onComplete;

  const _QuizView({
    required this.lessonTitle,
    required this.questions,
    required this.onComplete,
  });

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _showFeedback = false;
  bool _isAnswerCorrect = false;

  void _handleAnswer(int index) {
    if (_showFeedback) return;

    setState(() {
      _selectedAnswer = index;
      _isAnswerCorrect =
          index == widget.questions[_currentIndex]['answerIndex'];
      if (_isAnswerCorrect) _score++;
      _showFeedback = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showFeedback = false;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = (_score / widget.questions.length * 100).round();

    // Play SFX if passed
    if (percentage >= 70) {
      SoundService().playCompletion();
    }

    showModernDialog(
      context,
      title: percentage >= 70 ? "Excellent!" : "Good Try!",
      message: percentage >= 70
          ? "Lesson Completed!"
          : "Score 70% or more to complete.",
      content: SizedBox(
        height: 100,
        width: 100,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 8,
              backgroundColor: colorScheme.outlineVariant.withValues(
                alpha: 0.45,
              ),
              color: percentage >= 70
                  ? Colors.greenAccent
                  : colorScheme.primary,
            ),
            Center(
              child: Text(
                "$percentage%",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
      primaryButtonText: "Close",
      onPrimaryPressed: () {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Close quiz screen
        widget.onComplete(percentage);
      },
      icon: percentage >= 70 ? Icons.emoji_events_rounded : Icons.info_outline,
      accentColor: percentage >= 70 ? Colors.greenAccent : colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final question = widget.questions[_currentIndex];
    final options = (question['options'] as List).cast<String>();

    return Scaffold(
      backgroundColor: Colors.black54, // Overlay
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: isDark ? 0.5 : 0.18,
                ),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Question ${_currentIndex + 1}/${widget.questions.length}",
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                question['question'],
                style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              ...List.generate(options.length, (index) {
                final isSelected = _selectedAnswer == index;
                final isCorrectOption = index == question['answerIndex'];

                Color borderColor = colorScheme.outlineVariant.withValues(
                  alpha: 0.45,
                );
                Color bgColor = Colors.transparent;

                if (_showFeedback) {
                  if (isCorrectOption) {
                    borderColor = Colors.greenAccent;
                    bgColor = Colors.greenAccent.withValues(alpha: 0.1);
                  } else if (isSelected && !isCorrectOption) {
                    borderColor = Colors.redAccent;
                    bgColor = Colors.redAccent.withValues(alpha: 0.1);
                  }
                } else if (isSelected) {
                  borderColor = colorScheme.primary;
                  bgColor = colorScheme.primary.withValues(alpha: 0.1);
                }

                return GestureDetector(
                  onTap: () => _handleAnswer(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "${String.fromCharCode(65 + index)}.",
                          style: TextStyle(
                            color: borderColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            options[index],
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ),
                        if (_showFeedback && isCorrectOption)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                        if (_showFeedback && isSelected && !isCorrectOption)
                          const Icon(
                            Icons.cancel,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              if (_showFeedback)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _nextQuestion,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _currentIndex < widget.questions.length - 1
                          ? "Next"
                          : "Finish",
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
