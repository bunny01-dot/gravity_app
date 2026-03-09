import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/widgets/language_toggle_icon.dart';
import 'package:gravity_app/widgets/lesson_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gravity_app/services/analytics_service.dart';

// Canonical State Model
enum LessonState { notStarted, storyCompleted, quizMastered }

class LessonPartsOfSpeechScreen extends StatefulWidget {
  const LessonPartsOfSpeechScreen({super.key});

  @override
  State<LessonPartsOfSpeechScreen> createState() =>
      _LessonPartsOfSpeechScreenState();
}

class _LessonPartsOfSpeechScreenState extends State<LessonPartsOfSpeechScreen> {
  // State Machine
  LessonState _lessonState = LessonState.notStarted;
  bool _isLoading = true;
  bool _isReEntryLanding = false;

  // Navigation
  int _currentPage = 0;
  int get _totalPages => _storyPages.length;
  bool _showQuiz = false;
  bool _showResults = false;
  bool _showCompletion = false;
  bool _showTranslation = false;

  // Quiz
  int _currentQuestion = 0;
  int _correctAnswers = 0;
  final List<int?> _selectedAnswers = List.filled(8, null);
  bool _showFeedback = false;
  bool _isCorrect = false;

  // 8 Questions
  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'What is a Noun? ',
      'options': [
        'Action Word ',
        'Person, Place, or Thing ',
        'Describes Noun ',
      ],
      'correct': 1,
    },
    {
      'question': 'What is a Pronoun? ',
      'options': ['Replaces a Noun ', 'Connects Words ', 'Strong Emotion '],
      'correct': 0,
    },
    {
      'question': 'What is a Verb? ',
      'options': ['Thing ', 'Action Word ', 'Describes Action '],
      'correct': 1,
    },
    {
      'question': 'What is an Adjective? ',
      'options': ['Describes a Noun ', 'Replaces Noun ', 'Action '],
      'correct': 0,
    },
    {
      'question': 'What is an Adverb? ',
      'options': ['Person ', 'Describes Action ', 'Connector '],
      'correct': 1,
    },
    {
      'question': 'What is a Preposition? ',
      'options': ['Shows Location/Time ', 'Action ', 'Emotion '],
      'correct': 0,
    },
    {
      'question': 'What is a Conjunction? ',
      'options': ['Describes Noun ', 'Connects Words ', 'Location '],
      'correct': 1,
    },
    {
      'question': 'What is an Interjection? ',
      'options': ['Action ', 'Short Exclamation ', 'Thing '],
      'correct': 1,
    },
  ];

  List<Map<String, dynamic>> _activeQuestions = [];

  // Story Slides (modal-verbs pattern: image + concept + explanation + translation)
  final List<Map<String, String>> _storyPages = [
    {
      'image': 'noun.webp',
      'title': 'Nouns: Name Words',
      'focus': 'NOUN',
      'content':
          'A noun names a person, place, animal, or thing.\nExamples: Ravi, school, dog, book.',
      'tamilContent': 'Noun   .  , ,     .\n: Ravi, school, dog, book.',
    },
    {
      'image': 'pronoun.webp',
      'title': 'Pronouns: Replacing Nouns',
      'focus': 'PRONOUN',
      'content':
          'A pronoun replaces a noun to avoid repeating the same name.\nExamples: he, she, it, they.',
      'tamilContent': 'Pronoun  noun-   .       .\n: he, she, it, they.',
    },
    {
      'image': 'verb.webp',
      'title': 'Verbs: Action or State',
      'focus': 'VERB',
      'content':
          'A verb tells what the subject does, has, or is.\nExamples: run, write, eat, is.',
      'tamilContent': 'Verb  ,     .\n: run, write, eat, is.',
    },
    {
      'image': 'adjective.webp',
      'title': 'Adjectives: Describe Nouns',
      'focus': 'ADJECTIVE',
      'content':
          'An adjective describes or gives more detail about a noun.\nExamples: tall boy, red bag, happy child.',
      'tamilContent': 'Adjective  noun-  .\n: tall boy, red bag, happy child.',
    },
    {
      'image': 'adverb.webp',
      'title': 'Adverbs: Describe Verbs',
      'focus': 'ADVERB',
      'content':
          'An adverb tells how, when, where, or how often an action happens.\nExamples: quickly, yesterday, here, always.',
      'tamilContent':
          'Adverb   , , ,     .\n: quickly, yesterday, here, always.',
    },
    {
      'image': 'preposition.webp',
      'title': 'Prepositions: Position & Time',
      'focus': 'PREPOSITION',
      'content':
          'A preposition shows relation in place, direction, or time.\nExamples: in, on, under, before.',
      'tamilContent': 'Preposition  ,      .\n: in, on, under, before.',
    },
    {
      'image': 'conjunction.webp',
      'title': 'Conjunctions: Join Words',
      'focus': 'CONJUNCTION',
      'content':
          'A conjunction connects words, phrases, or clauses.\nExamples: and, but, because, or.',
      'tamilContent': 'Conjunction  ,   clauses-  .\n: and, but, because, or.',
    },
    {
      'image': 'interjection.webp',
      'title': 'Interjections: Sudden Feelings',
      'focus': 'INTERJECTION',
      'content':
          'An interjection shows sudden emotion.\nExamples: Wow!, Oh!, Ouch!, Hurray!',
      'tamilContent': 'Interjection     .\n: Wow!, Oh!, Ouch!, Hurray!',
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
      final storyDone = prefs.getBool('lesson2_storybook_completed') ?? false;
      final quizDone = prefs.getBool('lesson2_quiz_completed') ?? false;
      final quizScore = prefs.getInt('lesson2_quiz_score') ?? 0;
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
        'lesson_id': 'parts_of_speech_02',
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
    } else {
      SoundService().playWrong();
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
      'lesson_id': 'parts_of_speech_02',
      'score': _correctAnswers,
      'passed': _correctAnswers >= 6,
    });
  }

  Future<void> _saveStoryBookCompletion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lesson2_storybook_completed', true);
      if (_lessonState != LessonState.quizMastered) {
        setState(() => _lessonState = LessonState.storyCompleted);
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('lessons')
            .doc('lesson_2_parts_of_speech')
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
      await prefs.setBool('lesson2_quiz_completed', true);
      await prefs.setInt('lesson2_quiz_score', _correctAnswers);
      await prefs.setBool('lesson2_storybook_completed', true);
      setState(() => _lessonState = LessonState.quizMastered);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('lessons')
            .doc('lesson_2_parts_of_speech')
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
              left: -100,
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
              right: -50,
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
    final primaryColor = const Color(0xFF4FACFE); // Accent

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
                  color: isMastered ? const Color(0xFFFFD700) : primaryColor,
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
                    backgroundColor: primaryColor.withValues(alpha: 0.2),
                    foregroundColor: primaryColor,
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
                    backgroundColor: primaryColor,
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
    const primaryColor = Color(0xFF4FACFE);

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
                                lessonId: 'parts_of_speech',
                                imageName: _storyPages[_currentPage]['image']!,
                                fallbackAssetPath:
                                    'assets/Lessons/Lesson_02_PartsOfSpeech/${_storyPages[_currentPage]['image']!}',
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
                                  color: Colors.white,
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
                                        ? primaryColor.withValues(alpha: 0.2)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: _showTranslation
                                          ? primaryColor
                                          : Colors.white24,
                                    ),
                                  ),
                                  child: LanguageToggleIcon(
                                    language: 'Tamil',
                                    isActive: _showTranslation,
                                    size: 13,
                                    activeColor: primaryColor,
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
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            _storyPages[_currentPage]['focus']!,
                            style: const TextStyle(
                              color: Colors.white,
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
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _prevPage,
                )
              else
                const SizedBox(width: 48),
              Row(
                children: List.generate(
                  _totalPages,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 12 : 8,
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
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
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
                    if (isCorrectOption) {
                      color = Colors.green;
                    } else if (isSelected) {
                      color = Colors.red;
                    }
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
                                  fontSize: 16,
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
      ),
    );
  }
}
