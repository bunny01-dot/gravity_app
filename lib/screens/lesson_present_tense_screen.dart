// ignore_for_file: unused_field, unused_element, unused_import
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gravity_app/services/analytics_service.dart';

// Canonical State Model
enum LessonState { notStarted, storyCompleted, quizMastered }

// Page Model
class LessonPage {
  final String image;
  final String? text;
  final String? teachingText;
  final String? labelInfo;
  final String? ruleBox;

  LessonPage({
    required this.image,
    this.text,
    this.teachingText,
    this.labelInfo,
    this.ruleBox,
  });
}

class LessonPresentTenseScreen extends StatefulWidget {
  const LessonPresentTenseScreen({super.key});

  @override
  State<LessonPresentTenseScreen> createState() =>
      _LessonPresentTenseScreenState();
}

class _LessonPresentTenseScreenState extends State<LessonPresentTenseScreen> {
  // State Machine
  LessonState _lessonState = LessonState.notStarted;
  bool _isLoading = true;
  bool _isReEntryLanding = false;

  // Navigation State
  int _currentPage = 0;
  int get _totalPages => _pages.length;
  bool _showQuiz = false;
  bool _showResults = false;
  bool _showCompletion = false;

  // Quiz State
  int _currentQuestion = 0;
  int _correctAnswers = 0;
  final List<int?> _selectedAnswers = List.filled(11, null);
  bool _showFeedback = false;
  bool _isCorrect = false;

  // ---------------------------------------------------------------------------
  // CONTENT & ASSETS
  // ---------------------------------------------------------------------------

  final List<LessonPage> _pages = [
    LessonPage(
      image: 'A boy brushing his teeth.webp',
      text: "He **brushes** his teeth.",
    ),
    LessonPage(
      image: 'A family prays together in peace.webp',
      text: "They **pray** together.",
    ),
    LessonPage(
      image: 'Boy reading a book with focus.webp',
      text: "I **read** a book.",
    ),
    LessonPage(
      image: 'Boy running swiftly in the park.webp',
      text: null, // Sentence already in image
      teachingText:
          "We use the simple present tense to talk about things we do regularly.\n\nDaily activities like running, eating, and studying are described using this tense.\n\nThe third person (he, she, it) adds **-s** to the verb.",
      ruleBox: "Rule:\nHe/She/It  verb + s",
    ),
    LessonPage(
      image: 'Boy smiling on his way to school.webp',
      text: "He **goes** to school.",
    ),

    // PAGE 6: SPECIAL TEACHING PAGE
    LessonPage(
      image: 'Boys playing football in the sun.webp',
      text: null,
      teachingText:
          "The simple present tense is used to talk about daily activities and regular actions.\n\nWhen the subject is **they**, the verb stays in its base form.\n\nThis example shows something that happens again and again.",
      labelInfo: "Base verb",
      ruleBox: "Rule:\nThey  base verb (no -s)",
    ),

    LessonPage(
      image: 'Drawing a sunny day scene.webp',
      text: "She **draws** a picture.",
    ),
    LessonPage(
      image: 'Energetic dog barking in the field.webp',
      text: "It **barks**.",
    ),
    LessonPage(
      image: 'Joyful girl singing with microphone.webp',
      text: "She **sings** well.",
    ),
    LessonPage(
      image: 'Studying together on a sunny day.webp',
      text: "They **study** together.",
    ),
    LessonPage(
      image: 'Tabby cat enjoying milk outdoors.webp',
      text: "It **drinks** milk.",
    ),
  ];

  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'He ___ his teeth.',
      'options': ['brush', 'brushes', 'brushing'],
      'correct': 1,
    },
    {
      'question': 'They ___ together.',
      'options': ['pray', 'prays', 'praying'],
      'correct': 0,
    },
    {
      'question': 'I ___ a book.',
      'options': ['read', 'reads', 'reading'],
      'correct': 0,
    },
    {
      'question': 'He ___ fast.',
      'options': ['run', 'runs', 'ran'],
      'correct': 1,
    },
    {
      'question': 'He ___ to school.',
      'options': ['go', 'goes', 'going'],
      'correct': 1,
    },
    {
      'question': 'They ___ football.',
      'options': ['play', 'plays', 'playing'],
      'correct': 0,
    },
    {
      'question': 'She ___ a picture.',
      'options': ['draw', 'draws', 'drawing'],
      'correct': 1,
    },
    {
      'question': 'It ___ .',
      'options': ['bark', 'barks', 'barking'],
      'correct': 1,
    },
    {
      'question': 'She ___ well.',
      'options': ['sing', 'sings', 'singing'],
      'correct': 1,
    },
    {
      'question': 'They ___ together.',
      'options': ['study', 'studies', 'studying'],
      'correct': 0,
    },
    {
      'question': 'It ___ milk.',
      'options': ['drink', 'drinks', 'drinking'],
      'correct': 1,
    },
  ];

  List<Map<String, dynamic>> _activeQuestions = [];

  @override
  void initState() {
    super.initState();
    _activeQuestions = List.from(_quizQuestions);
    _activeQuestions.shuffle();
    _loadValues();
  }

  // ---------------------------------------------------------------------------
  // LOGIC & PERSISTENCE
  // ---------------------------------------------------------------------------

  Future<void> _loadValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storyDone = prefs.getBool('lesson3_storybook_completed') ?? false;
      final quizDone = prefs.getBool('lesson3_quiz_completed') ?? false;
      final quizScore = prefs.getInt('lesson3_quiz_score') ?? 0;

      setState(() {
        if (quizDone && quizScore >= 8) {
          _lessonState = LessonState.quizMastered;
          _isReEntryLanding = true;
        } else if (storyDone) {
          _lessonState = LessonState.storyCompleted;
          _isReEntryLanding = true;
        } else {
          _lessonState = LessonState.notStarted;
          _isReEntryLanding = false;
        }
        _isLoading = false;
      });

      AnalyticsService().logEvent('lesson_started', {
        'lesson_id': 'present_tense_03',
        'state': _lessonState.toString(),
      });
    } catch (e) {
      debugPrint("Error loading state: $e");
      setState(() => _isLoading = false);
    }
  }

  void _startReview() {
    setState(() {
      _isReEntryLanding = false;
      _retryLesson();
    });
  }

  void _skipToQuiz() {
    setState(() {
      _isReEntryLanding = false;
      _startQuiz();
    });
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      SoundService().playTap();
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
      SoundService().playTap();
    } else if (_currentPage == _totalPages - 1) {
      _saveStoryBookCompletion();
      setState(() => _showCompletion = true);
      SoundService().playCompletion();
    }
  }

  void _startQuiz() {
    setState(() {
      _showCompletion = false;
      _showQuiz = true;
      _currentQuestion = 0;
      _activeQuestions.shuffle();
      // Reset selections
      _selectedAnswers.fillRange(0, 11, null);
    });
    SoundService().playTap();
  }

  void _selectAnswer(int answerIndex) {
    if (_showFeedback) return;
    setState(() {
      _selectedAnswers[_currentQuestion] = answerIndex;
      _showFeedback = true;
      _isCorrect = answerIndex == _activeQuestions[_currentQuestion]['correct'];
    });
    SoundService().playTap();
    if (_isCorrect) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _nextQuestion();
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestion < _quizQuestions.length - 1) {
      setState(() {
        _currentQuestion++;
        _showFeedback = false;
        _isCorrect = false;
      });
      SoundService().playTap();
    } else {
      _calculateScore();
      SoundService().playCompletion();
    }
  }

  void _calculateScore() {
    _correctAnswers = 0;
    for (int i = 0; i < _activeQuestions.length; i++) {
      if (_selectedAnswers[i] == _activeQuestions[i]['correct']) {
        _correctAnswers++;
      }
    }
    setState(() => _showResults = true);
    if (_correctAnswers >= 8) {
      _saveQuizCompletion();
    }
    AnalyticsService().logEvent('lesson_quiz_completed', {
      'lesson_id': 'present_tense_03',
      'score': _correctAnswers,
      'passed': _correctAnswers >= 8,
    });
  }

  Future<void> _saveStoryBookCompletion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lesson3_storybook_completed', true);
      if (_lessonState != LessonState.quizMastered) {
        setState(() => _lessonState = LessonState.storyCompleted);
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('lessons')
            .doc('lesson_3_present_tense')
            .set({
              'storybook_completed': true,
              'storybook_completed_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving storybook: $e');
    }
  }

  Future<void> _saveQuizCompletion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lesson3_quiz_completed', true);
      await prefs.setInt('lesson3_quiz_score', _correctAnswers);
      await prefs.setBool('lesson3_storybook_completed', true);
      setState(() => _lessonState = LessonState.quizMastered);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('lessons')
            .doc('lesson_3_present_tense')
            .set({
              'quiz_completed': true,
              'storybook_completed': true,
              'quiz_score': _correctAnswers,
              'quiz_completed_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving quiz: $e');
    }
  }

  void _retryLesson() {
    setState(() {
      _currentPage = 0;
      _showQuiz = false;
      _showResults = false;
      _showCompletion = false;
      _currentQuestion = 0;
      _correctAnswers = 0;
      _selectedAnswers.fillRange(0, 11, null);
      _showFeedback = false;
      _isCorrect = false;
    });
    SoundService().playTap();
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      pageBuilder: (context, a1, a2) => Container(),
      transitionBuilder: (context, a1, a2, child) {
        return Transform.scale(
          scale: a1.value,
          child: Dialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.orangeAccent,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Leave Lesson?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Progress will be lost.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Exit"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Stay"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
    return shouldPop ?? false;
  }

  // ---------------------------------------------------------------------------
  // BUILDERS
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF030305)
            : Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop(true);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF030305)
            : Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Background Elements (Orange/Pink Theme for 'Present Tense')
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF9966).withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF5E62).withValues(alpha: 0.1),
                ),
              ),
            ),
            SafeArea(
              child: _isReEntryLanding
                  ? _buildReEntryLanding()
                  : _showResults
                  ? _buildResultsScreen()
                  : _showCompletion
                  ? _buildCompletionScreen()
                  : _showQuiz
                  ? _buildQuizScreen()
                  : _buildStoryBookScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReEntryLanding() {
    final bool isMastered = _lessonState == LessonState.quizMastered;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isMastered
                  ? Icons.emoji_events_rounded
                  : Icons.check_circle_outline,
              size: 100,
              color: isMastered
                  ? const Color(0xFFFFD700)
                  : const Color(0xFFFF9966),
            ).animate().fade().scale(curve: Curves.elasticOut),
            const SizedBox(height: 32),
            Text(
              isMastered ? 'Lesson Mastered!' : 'Lesson Completed',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ).animate().slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            Text(
              isMastered
                  ? 'You have earned 2 Stars! '
                  : 'You have earned 1 Star! \nTake the quiz to earn Mastery.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 48),
            if (isMastered) ...[
              _buildButton("Review Story", Icons.refresh, _startReview, false),
              const SizedBox(height: 16),
              _buildButton(
                "Retake Quiz",
                Icons.quiz_outlined,
                _skipToQuiz,
                true,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  "Go Back",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ] else ...[
              _buildButton("Review Lesson", Icons.refresh, _startReview, false),
              const SizedBox(height: 12),
              _buildButton("Take Quiz", null, _skipToQuiz, true),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  "Skip For Now",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    String label,
    IconData? icon,
    VoidCallback onTap,
    bool primary,
  ) {
    return SizedBox(
      width: 220,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary
              ? const Color(0xFFFF9966)
              : Colors.white.withValues(alpha: 0.1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryBookScreen() {
    final page = _pages[_currentPage];

    // Rich Text Parser for **bold**
    List<TextSpan> _parseText(String text) {
      final parts = text.split('**');
      List<TextSpan> spans = [];
      for (int i = 0; i < parts.length; i++) {
        if (i % 2 == 1) {
          spans.add(
            TextSpan(
              text: parts[i],
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFD700),
              ),
            ),
          );
        } else {
          spans.add(TextSpan(text: parts[i]));
        }
      }
      return spans;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () async {
                  if (await _onWillPop() && mounted)
                    Navigator.pop(context, true);
                },
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (d) {
              if (d.primaryVelocity! > 0) _prevPage();
              if (d.primaryVelocity! < 0) _nextPage();
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/Lessons/Lesson_03_Tense_Present/01_Simple_Present/${page.image}',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 50,
                      ),
                    ),
                  ),
                ).animate(key: ValueKey(page.image)).fadeIn(duration: 300.ms),

                if (page.text != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.95),
                          ],
                        ),
                      ),
                      child:
                          Text.rich(
                                TextSpan(children: _parseText(page.text!)),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  height: 1.4,
                                ),
                              )
                              .animate(key: ValueKey('text_${page.image}'))
                              .fadeIn(delay: 500.ms)
                              .slideY(begin: 0.1, end: 0),
                    ),
                  ),

                if (page.teachingText != null) ...[
                  // Label (appears during "glow period" - simulated since we can't highlight PNG text)
                  if (page.labelInfo != null)
                    Positioned(
                      bottom: 320, // Above teaching panel
                      left: 0,
                      right: 0,
                      child: Center(
                        child:
                            Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    page.labelInfo!,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                                .animate(key: ValueKey('label_${page.image}'))
                                .fadeIn(
                                  delay: 500.ms,
                                ) // Appears with teaching text
                                .moveY(begin: 10, end: 0)
                                .fadeOut(delay: 1200.ms), // Visible for 1.2s
                      ),
                    ),
                  // Teaching Panel
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C).withValues(alpha: 0.95),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Teaching Explanation Text
                          Text.rich(
                                TextSpan(
                                  children: _parseText(page.teachingText!),
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  height: 1.5,
                                ),
                              )
                              .animate(key: ValueKey('teach_${page.image}'))
                              .fadeIn(delay: 500.ms),

                          // Rule Box (Section 3)
                          if (page.ruleBox != null) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFD700,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                page.ruleBox!,
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Navigation Bar
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: _prevPage,
                )
              else
                const SizedBox(width: 48),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  _totalPages,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? const Color(0xFFFF9966)
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                onPressed: _nextPage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: const Color(0xFFFF9966),
            ).animate().scale(),
            const SizedBox(height: 32),
            const Text(
              "Lesson Complete!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Ready for the quiz?",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 48),
            _buildButton("Start Quiz", null, _startQuiz, true),
            const SizedBox(height: 16),
            _buildButton("Review Lesson", Icons.refresh, _retryLesson, false),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "Skip For Now",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizScreen() {
    final question = _activeQuestions[_currentQuestion];
    final selectedAnswer = _selectedAnswers[_currentQuestion];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                "Question ${_currentQuestion + 1}/${_activeQuestions.length}",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  question['question'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                ...List.generate((question['options'] as List).length, (index) {
                  final option = question['options'][index];
                  final isSelected = selectedAnswer == index;
                  final isCorrect = index == question['correct'];
                  Color color = Colors.white10;
                  if (_showFeedback) {
                    if (isCorrect)
                      color = Colors.green;
                    else if (isSelected)
                      color = Colors.red;
                  } else if (isSelected)
                    color = const Color(0xFFFF9966);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _selectAnswer(index),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            if (_showFeedback && isCorrect)
                              const Icon(Icons.check, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                if (selectedAnswer != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9966),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentQuestion < _activeQuestions.length - 1
                            ? "Next"
                            : "Finish",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsScreen() {
    final passed = _correctAnswers >= 8;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            passed ? Icons.emoji_events : Icons.refresh,
            size: 80,
            color: passed ? Colors.amber : Colors.orange,
          ),
          const SizedBox(height: 24),
          Text(
            passed ? "Excellent!" : "Good Try!",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "You scored $_correctAnswers / 11",
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: passed
                  ? () => Navigator.of(context).pop(true)
                  : _retryLesson,
              style: ElevatedButton.styleFrom(
                backgroundColor: passed ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(passed ? "Done" : "Review Lesson"),
            ),
          ),
        ],
      ),
    );
  }
}
