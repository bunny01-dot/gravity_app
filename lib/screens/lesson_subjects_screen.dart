import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/widgets/lesson_image.dart';
import 'package:gravity_app/widgets/language_toggle_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gravity_app/services/analytics_service.dart';

// Canonical State Model
enum LessonState { notStarted, storyCompleted, quizMastered }

class LessonSubjectsScreen extends StatefulWidget {
  const LessonSubjectsScreen({super.key});

  @override
  State<LessonSubjectsScreen> createState() => _LessonSubjectsScreenState();
}

class _LessonSubjectsScreenState extends State<LessonSubjectsScreen> {
  // State Machine
  LessonState _lessonState = LessonState.notStarted;
  bool _isLoading = true;
  bool _isReEntryLanding = false;

  // Navigation State
  int _currentPage = 0;
  int get _totalPages => _storyPages.length;
  bool _showQuiz = false;
  bool _showResults = false;
  bool _showCompletion = false;
  bool _showTranslation = false;

  // Quiz State
  int _currentQuestion = 0;
  int _correctAnswers = 0;
  final List<int?> _selectedAnswers = List.filled(8, null);
  bool _showFeedback = false;
  bool _isCorrect = false;

  // Quiz Questions
  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'When you talk about yourself, which word do you use?',
      'options': ['I ', 'You ', 'They '],
      'correct': 0,
    },
    {
      'question':
          'When talking about yourself and others together, which word?',
      'options': ['She ', 'We ', 'He '],
      'correct': 1,
    },
    {
      'question': 'When talking to someone, which word do you use?',
      'options': ['I ', 'You ', 'It '],
      'correct': 1,
    },
    {
      'question': 'For a boy or man, which pronoun?',
      'options': ['She ', 'He ', 'It '],
      'correct': 1,
    },
    {
      'question': 'For a girl or woman, which pronoun?',
      'options': ['He ', 'She ', 'They '],
      'correct': 1,
    },
    {
      'question': 'For a thing (like a book ), which pronoun?',
      'options': ['He ', 'She ', 'It '],
      'correct': 2,
    },
    {
      'question': 'For more than one person, which word?',
      'options': ['They ', 'It ', 'I '],
      'correct': 0,
    },
    {
      'question': 'Which pronoun for "the students are playing"?',
      'options': ['He ', 'We ', 'They '],
      'correct': 2,
    },
  ];

  List<Map<String, dynamic>> _activeQuestions = [];

  // Story Slides (image + text, following the modal-verbs storybook pattern)
  final List<Map<String, String>> _storyPages = [
    {
      'image': '01_intro.webp',
      'title': 'Who Is The Subject?',
      'focus': 'SUBJECT',
      'content':
          'In every sentence, someone or something does the action. That person, animal, or thing is the subject.',
      'tamilContent': '       .  ,     Subject.',
    },
    {
      'image': '02_first_singular.webp',
      'title': 'First Person Singular',
      'focus': 'I',
      'content':
          'Use "I" when you talk about yourself.\nExample: I read every day.',
      'tamilContent': '   "I"  .\n: I read every day.',
    },
    {
      'image': '03_first_plural.webp',
      'title': 'First Person Plural',
      'focus': 'WE',
      'content':
          'Use "we" when you and others do something together.\nExample: We play football after school.',
      'tamilContent': '     "we"  .\n: We play football after school.',
    },
    {
      'image': '04_second_singular.webp',
      'title': 'Second Person Singular',
      'focus': 'YOU',
      'content':
          'Use "you" when speaking to one person.\nExample: You sing very well.',
      'tamilContent': '    "you"  .\n: You sing very well.',
    },
    {
      'image': '05_second_plural.webp',
      'title': 'Second Person Plural',
      'focus': 'YOU (ALL)',
      'content':
          'The same word "you" is also used for more than one person.\nExample: You all are ready.',
      'tamilContent': '  "you"  .\n: You all are ready.',
    },
    {
      'image': '06_third_he.webp',
      'title': 'Third Person Singular',
      'focus': 'HE',
      'content':
          'Use "he" when talking about one boy or man.\nExample: He runs fast.',
      'tamilContent': ' /   "he"  .\n: He runs fast.',
    },
    {
      'image': '07_third_she.webp',
      'title': 'Third Person Singular',
      'focus': 'SHE',
      'content':
          'Use "she" when talking about one girl or woman.\nExample: She writes neatly.',
      'tamilContent': ' /   "she"  .\n: She writes neatly.',
    },
    {
      'image': '08_third_it.webp',
      'title': 'Third Person Singular',
      'focus': 'IT',
      'content':
          'Use "it" for one thing, place, or animal.\nExample: It is on the table.',
      'tamilContent': ' ,    "it"  .\n: It is on the table.',
    },
    {
      'image': '09_third_they.webp',
      'title': 'Third Person Plural',
      'focus': 'THEY',
      'content':
          'Use "they" for many people, animals, or things.\nExample: They are playing in the park.',
      'tamilContent': ' ,    "they"  .\n: They are playing in the park.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _activeQuestions = List.from(_quizQuestions);
    _loadValues();
  }

  Future<void> _loadValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storyDone = prefs.getBool('lesson1_storybook_completed') ?? false;
      final quizDone = prefs.getBool('lesson1_quiz_completed') ?? false;
      final quizScore = prefs.getInt('lesson1_quiz_score') ?? 0;
      final preferredLanguage =
          prefs.getString('preferred_language') ?? 'Tamil';

      setState(() {
        if (quizDone && quizScore >= 6) {
          _lessonState = LessonState.quizMastered;
          _isReEntryLanding = true;
        } else if (storyDone) {
          _lessonState = LessonState.storyCompleted;
          _isReEntryLanding = true;
        } else {
          _lessonState = LessonState.notStarted;
          _isReEntryLanding = false;
        }
        _showTranslation = preferredLanguage == 'Tamil';
        _isLoading = false;
      });

      AnalyticsService().logEvent('lesson_started', {
        'lesson_id': 'subjects_01',
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
    if (_currentQuestion < 7) {
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
    for (int i = 0; i < 8; i++) {
      if (_selectedAnswers[i] == _activeQuestions[i]['correct']) {
        _correctAnswers++;
      }
    }
    setState(() => _showResults = true);
    if (_correctAnswers >= 6) {
      _saveQuizCompletion();
    }
    AnalyticsService().logEvent('lesson_quiz_completed', {
      'lesson_id': 'subjects_01',
      'score': _correctAnswers,
      'passed': _correctAnswers >= 6,
    });
  }

  Future<void> _saveStoryBookCompletion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lesson1_storybook_completed', true);
      if (_lessonState != LessonState.quizMastered) {
        setState(() => _lessonState = LessonState.storyCompleted);
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('lessons')
            .doc('lesson_1_subjects')
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
      await prefs.setBool('lesson1_quiz_completed', true);
      await prefs.setInt('lesson1_quiz_score', _correctAnswers);
      await prefs.setBool('lesson1_storybook_completed', true);
      setState(() => _lessonState = LessonState.quizMastered);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('lessons')
            .doc('lesson_1_subjects')
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
      _selectedAnswers.fillRange(0, 8, null);
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
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4FACFE).withValues(alpha: 0.15),
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
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.1),
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
                      : const Color(0xFF4FACFE),
                )
                .animate()
                .fade(duration: 400.ms)
                .scale(
                  delay: 100.ms,
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 32),
            Text(
              isMastered ? 'Lesson Mastered!' : 'Lesson Completed',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            Text(
              isMastered
                  ? 'You have earned 2 Stars! '
                  : 'You have earned 1 Star! \nTake the quiz to earn Mastery.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 48),
            if (isMastered) ...[
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: _startReview,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Review Story"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: _skipToQuiz,
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text("Retake Quiz"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF4FACFE,
                    ).withValues(alpha: 0.2),
                    foregroundColor: const Color(0xFF4FACFE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  "Go Back",
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ] else ...[
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: _startReview,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Review Lesson"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 12),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: _skipToQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FACFE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    "Take Quiz",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  "Skip For Now",
                  style: TextStyle(color: Colors.white54),
                ),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStoryBookScreen() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () async {
                  final shouldPop = await _onWillPop();
                  if (shouldPop && mounted) Navigator.pop(context, true);
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child:
                          LessonImage(
                                lessonId: 'subjects',
                                imageName: _storyPages[_currentPage]['image']!,
                                fallbackAssetPath:
                                    'assets/Lessons/Lesson_01_Subjects/${_storyPages[_currentPage]['image']!}',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                              .animate(
                                key: ValueKey(
                                  _storyPages[_currentPage]['image'],
                                ),
                              )
                              .fadeIn(duration: 300.ms),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _storyPages[_currentPage]['title']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF7DD3FC),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if ((_storyPages[_currentPage]['tamilContent'] ??
                                    '')
                                .isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showTranslation = !_showTranslation;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _showTranslation
                                        ? const Color(
                                            0xFF4FACFE,
                                          ).withValues(alpha: 0.2)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: _showTranslation
                                          ? const Color(0xFF4FACFE)
                                          : Colors.white24,
                                    ),
                                  ),
                                  child: LanguageToggleIcon(
                                    language: 'Tamil',
                                    isActive: _showTranslation,
                                    size: 13,
                                    activeColor: const Color(0xFF4FACFE),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF4FACFE,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFF4FACFE,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            _storyPages[_currentPage]['focus']!,
                            style: const TextStyle(
                              color: Color(0xFF4FACFE),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _storyPages[_currentPage]['content']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        if (_showTranslation &&
                            (_storyPages[_currentPage]['tamilContent'] ?? '')
                                .isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _storyPages[_currentPage]['tamilContent']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.black26,
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
                children: List.generate(
                  _totalPages,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? const Color(0xFF4FACFE)
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: const Color(0xFF4FACFE),
            ).animate().scale(curve: Curves.elasticOut),
            const SizedBox(height: 32),
            const Text(
              "Lesson Complete!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Ready for the quiz?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: _startQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FACFE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Start Quiz",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 220,
              child: OutlinedButton.icon(
                onPressed: _retryLesson,
                icon: const Icon(Icons.refresh),
                label: const Text("Review Lesson"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4FACFE),
                  side: const BorderSide(color: Color(0xFF4FACFE), width: 1.8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
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
                "Question ${_currentQuestion + 1}/8",
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
                  final isCorrectOption = index == question['correct'];
                  Color color = Colors.white10;
                  if (_showFeedback) {
                    if (isCorrectOption)
                      color = Colors.green;
                    else if (isSelected)
                      color = Colors.red;
                  } else if (isSelected) {
                    color = const Color(0xFF4FACFE);
                  }
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
                            if (_showFeedback && isCorrectOption)
                              const Icon(Icons.check, color: Colors.white),
                            if (_showFeedback && isSelected && !isCorrectOption)
                              const Icon(Icons.close, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                if (selectedAnswer != null)
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    child: Text(_currentQuestion < 7 ? "Next" : "Finish"),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsScreen() {
    final passed = _correctAnswers >= 6;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              passed ? Icons.emoji_events : Icons.refresh,
              size: 80,
              color: passed ? Colors.amber : Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              passed ? "Excellent!" : "Good Try!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You scored $_correctAnswers / 8",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: _retryLesson,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: const Color(0xFF4FACFE).withValues(alpha: 0.45),
                  ),
                ),
                child: const Text("Review Lesson"),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: passed
                    ? () => Navigator.of(context).pop(true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(passed ? "Done" : "Complete Quiz To Finish"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
