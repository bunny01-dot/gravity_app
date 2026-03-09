import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/lesson_content_service.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/widgets/language_toggle_icon.dart';
import 'package:gravity_app/widgets/lesson_image.dart';
import 'package:gravity_app/widgets/lesson_speaking_practice_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// -----------------------------------------------------------------------------
// DATA MODELS
// -----------------------------------------------------------------------------
abstract class LessonUnit {}

class LessonSlide extends LessonUnit {
  final String title;
  final String content;
  final String imagePath;
  final String? soundPath;
  final String hindiContent;
  final String tamilContent;
  final String? formula;
  final BoxFit? imageFit;

  LessonSlide({
    required this.title,
    required this.content,
    required this.imagePath,
    this.soundPath,
    this.hindiContent = "",
    this.tamilContent = "",
    this.formula,
    this.imageFit,
  });
}

class LessonHighlightInteraction extends LessonUnit {
  final String title;
  final String introText;
  final List<String> highlightItems;
  final String exampleText;
  final String imagePath;
  final String hindiContent;
  final String tamilContent;
  final BoxFit? imageFit;

  LessonHighlightInteraction({
    required this.title,
    required this.introText,
    required this.highlightItems,
    required this.exampleText,
    required this.imagePath,
    this.hindiContent = "",
    this.tamilContent = "",
    this.imageFit,
  });
}

class LessonQuizInteraction extends LessonUnit {
  final String title;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String imagePath;
  final BoxFit? imageFit;

  LessonQuizInteraction({
    required this.title,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.imagePath,
    this.imageFit,
  });
}

class LessonSpeakingPractice extends LessonUnit {
  final String title;
  final String? micIconPath;
  final String imagePath;
  final List<String> prompts;
  final List<String> summaryPoints;
  final BoxFit? imageFit;

  LessonSpeakingPractice({
    required this.title,
    this.micIconPath,
    required this.imagePath,
    required this.prompts,
    this.summaryPoints = const [],
    this.imageFit,
  });
}

// -----------------------------------------------------------------------------
// SCREEN: Past Perfect Continuous
// -----------------------------------------------------------------------------
class LessonPastPerfectContinuousScreen extends StatefulWidget {
  const LessonPastPerfectContinuousScreen({super.key});

  @override
  State<LessonPastPerfectContinuousScreen> createState() =>
      _LessonPastPerfectContinuousScreenState();
}

class _LessonPastPerfectContinuousScreenState
    extends State<LessonPastPerfectContinuousScreen>
    with SingleTickerProviderStateMixin {
  // State Machine
  bool _isLoading = true;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // Phase Management
  bool _showCompletion = false;
  bool _storyCompleted = false;
  bool _showQuiz = false;
  bool _showResults = false;
  bool _isReEntryLanding = false;
  // Swipe Hint Animation
  late AnimationController _hintAnimationController;
  late Animation<Offset> _slideAnimation;
  bool _hasShownHint = false;

  // Language & Translation
  String _preferredLanguage = 'Tamil';
  bool _showTranslation = false;

  // Quiz State
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answerSelected = false;
  int? _selectedOptionIndex;
  bool _quizCompleted = false;

  // Lesson Content
  late List<LessonUnit> _slides;

  // Asset Path
  final String _assetPath =
      'assets/Lessons/Lesson_04_Tense_Past/04_Past_Perfect_Continuous/';

  // Quiz Data
  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'Formula for Past Perfect Continuous?',
      'question_tamil': 'Past Perfect Continuous-  ?',
      'question_hindi': 'Past Perfect Continuous    ?',
      'options': [
        'had + been + V-ing',
        'has + been + V-ing',
        'was + V-ing',
        'had + V3',
      ],
      'correct': 0,
    },
    {
      'question': 'He ___ waiting for 2 hours when she arrived.',
      'question_tamil': ' ,  2    ___ .',
      'question_hindi': '  ,   2    ___ ',
      'options': ['is waiting', 'had waited', 'had been waiting', 'waited'],
      'correct': 2,
    },
    {
      'question': 'We use "FOR" with...',
      'question_tamil': '"FOR"-  ...',
      'question_hindi': ' "FOR"      ...',
      'options': [
        'A starting point (9 PM)',
        'A duration (2 hours)',
        'Future time',
        'Single actions',
      ],
      'correct': 1,
    },
    {
      'question': 'She was tired because she ___ running.',
      'question_tamil': '      ___.',
      'question_hindi': '       ___ ',
      'options': ['had been', 'has been', 'was', 'is'],
      'correct': 0,
    },
    {
      'question': 'How long ___ waiting before the bus came?',
      'question_tamil': '      ___?',
      'question_hindi': '        ___?',
      'options': ['had you been', 'have you been', 'did you', 'were you'],
      'correct': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeLessonContent();
    _loadProgress();

    // Initialize hint animation
    _hintAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.12, 0), // Slide 15% left
        ).animate(
          CurvedAnimation(
            parent: _hintAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _checkAndPlayHint();

    //  Cloud Asset Preload
    LessonContentService().preloadNextLessons('past_perfect_continuous');
  }

  @override
  void dispose() {
    _hintAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkAndPlayHint() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenHint =
        prefs.getBool('has_seen_swipe_hint_lesson_past_perfect_continuous') ??
        false;

    if (!hasSeenHint && mounted) {
      setState(() => _hasShownHint = false);

      // Wait a bit for layout
      await Future.delayed(const Duration(milliseconds: 500));

      await _precacheNextSlideImage();

      if (mounted && !_hasShownHint) {
        await _hintAnimationController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        await _hintAnimationController.reverse();

        await prefs.setBool(
          'has_seen_swipe_hint_lesson_past_perfect_continuous',
          true,
        );
        setState(() => _hasShownHint = true);
      }
    } else {
      setState(() => _hasShownHint = true);
    }
  }

  Future<void> _precacheNextSlideImage() async {
    if (_slides.length < 2) return;
    final nextUnit = _slides[1];
    String? imagePath;
    if (nextUnit is LessonSlide) {
      imagePath = nextUnit.imagePath;
    } else if (nextUnit is LessonHighlightInteraction) {
      imagePath = nextUnit.imagePath;
    } else if (nextUnit is LessonQuizInteraction) {
      imagePath = nextUnit.imagePath;
    } else if (nextUnit is LessonSpeakingPractice) {
      imagePath = nextUnit.imagePath;
    }

    if (imagePath == null || imagePath.isEmpty) return;
    final resolvedPath = imagePath.startsWith('assets/')
        ? imagePath
        : '$_assetPath$imagePath';
    await precacheImage(AssetImage(resolvedPath), context);
  }

  void _initializeLessonContent() {
    _slides = [
      LessonSlide(
        title: "How Long Had Ravi Been Doing It?",
        content:
            "Ravi had been studying for 3 hours when his mother called him for dinner.\nHow long had he been studying?",
        imagePath: 'ravi_been_studying_square.webp',
        hindiContent: " 3                     ?",
        tamilContent: " 3    ,      .     ?",
      ),
      LessonHighlightInteraction(
        title: "When We Use It",
        introText: "Use Past Perfect Continuous for:",
        highlightItems: [
          "Action in progress UNTIL another past time",
          "Imagine a duration leading up to a past event",
          "Reason/Cause for a past result",
        ],
        exampleText:
            "| Ravi had been studying for 3 hours when dinner was ready.\n| They had been playing for an hour when it began to rain.",
        imagePath: 'past_perfect_cont_timeline_square.webp',
        hindiContent: "      ",
        tamilContent: "       .",
      ),
      LessonSlide(
        title: "The Formula",
        content:
            "Subject + had + been + Verb(+ing)\n\n| I/You/He/She/We/They had been reading.\n| Ravi had been studying for 3 hours.\n| They had been waiting since morning.",
        imagePath: 'had_been_verb_table_square.webp',
        formula: "had + been + Verb(ing)",
        hindiContent: ": Subject + had + been + Verb(ing)",
        tamilContent: ": Subject + had + been + Verb(ing)",
      ),
      LessonSlide(
        title: "Ravi's Study Session",
        content:
            "Yesterday:\n2:00 PM  STARTED.\n...Studying...\n5:00 PM  Mom called.\n\nAt 5 PM, he HAD BEEN STUDYING for 3 hours.",
        imagePath: 'ravi_study_duration_square.webp',
        hindiContent: " 5 ,  3     ",
        tamilContent: " 5 ,  3    .",
      ),
      LessonSlide(
        title: "For vs. Since",
        content:
            "FOR (Duration):\n| 'He had been working for 4 hours.'\n\nSINCE (Start Point):\n| 'He had been working since 10 AM.'\n\nBoth tell us how long the action continued up to that past moment.",
        imagePath: 'for_since_past_perfect_square.webp',
        hindiContent: "For ()  Since ( )",
        tamilContent: "For ( ) vs Since ( ).",
      ),
      LessonSlide(
        title: "Evidence of Effort",
        content:
            "Often used to explain WHY someone was tired/wet/messy in the past:\n\n| 'He was sweating because he had been running.'\n| 'The road was wet because it had been raining.'",
        imagePath: 'evidence_duration_square.webp',
        hindiContent: "         ",
        tamilContent: "    .",
      ),
      LessonSlide(
        title: "Negative & Questions",
        content:
            "Negative:\nSubject + had not (hadn't) + been + V-ing\n| He hadn't been working long.\n\nQuestions:\nHad + Subject + been + V-ing?\n| Had you been waiting long?",
        imagePath: 'past_perfect_cont_qa_square.webp',
        formula: "hadn't been V-ing / Had you been V-ing?",
        hindiContent: "Negative: hadn't been. Question: Had you been...?",
        tamilContent: ": hadn't been. : Had you been...?",
      ),
      LessonQuizInteraction(
        title: "Quick Check!",
        question: "When the rain started, they ___ for 2 hours.",
        options: ["had been playing", "had played", "were playing"],
        correctIndex: 0,
        explanation:
            "Correct! 'Had been playing' emphasizes the duration up to that moment.",
        imagePath: 'past_perfect_cont_quiz_square.webp',
      ),
      LessonSpeakingPractice(
        title: "Speaking Practice",
        imagePath: 'past_perfect_cont_speaking_square.webp',
        prompts: [
          "I had been studying for... before...",
          "How long had you been waiting?",
          "She had been working since...",
        ],
        summaryPoints: [
          "I had been waiting for...",
          "She had been working since...",
        ],
      ),
    ];
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    String? lang = prefs.getString('preferred_language');
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data()!.containsKey('language')) {
        lang = userDoc.get('language');
        await prefs.setString('preferred_language', lang!);
      }
    }
    _preferredLanguage = lang ?? 'Tamil';

    bool storyDone =
        prefs.getBool('lesson_4_past_perfect_continuous_story_completed') ??
        false;
    bool quizDone =
        prefs.getBool('lesson_4_past_perfect_continuous_quiz_completed') ??
        false;

    if (mounted) {
      setState(() {
        _storyCompleted = storyDone;
        _quizCompleted = quizDone;
        _isLoading = false;

        if (quizDone) {
          _isReEntryLanding = true;
          _showCompletion = true;
        } else if (storyDone) {
          _isReEntryLanding = false;
          _showCompletion = true;
        } else {
          // Normal start
        }
      });
    }
  }

  Future<void> _saveProgress({
    bool storyCompleted = false,
    bool quizCompleted = false,
    int? score,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;

      if (storyCompleted) {
        await prefs.setBool(
          'lesson_4_past_perfect_continuous_story_completed',
          true,
        );
      }
      if (quizCompleted) {
        await prefs.setBool(
          'lesson_4_past_perfect_continuous_quiz_completed',
          true,
        );
        if (score != null) {
          await prefs.setInt('lesson_4_past_perfect_continuous_score', score);
        }
      }

      if (user != null) {
        Map<String, dynamic> data = {};
        if (storyCompleted) {
          data['story_completed'] = true;
          data['story_completed_at'] = FieldValue.serverTimestamp();
        }
        if (quizCompleted) {
          data['quiz_completed'] = true;
          if (score != null) data['score'] = score;
          data['quiz_completed_at'] = FieldValue.serverTimestamp();
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('lessons')
            .doc('lesson_4_past_perfect_continuous')
            .set(data, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving lesson: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (_quizCompleted ||
        _storyCompleted ||
        _showResults ||
        _showCompletion ||
        _isReEntryLanding) {
      return true;
    }
    if (_currentIndex < 1) {
      return true;
    }
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

  // --- QUIZ LOGIC ---

  void _handleAnswer(int optionIndex) {
    if (_answerSelected) return;

    final correctIndex = _quizQuestions[_currentQuestionIndex]['correct'];
    final isCorrect = optionIndex == correctIndex;

    setState(() {
      _answerSelected = true;
      _selectedOptionIndex = optionIndex;
      if (isCorrect) _score++;
    });

    if (isCorrect) {
      SoundService().playCorrect();
    } else {
      SoundService().playWrong();
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answerSelected = false;
        _selectedOptionIndex = null;
        _showTranslation = false;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    final passingScore = (_quizQuestions.length * 0.7).ceil();
    final passed = _score >= passingScore;
    if (passed) {
      _saveProgress(quizCompleted: true, score: _score);
    }
    setState(() {
      _quizCompleted = passed; // Mark as done in state so we show "Retake"
      _showQuiz = false;
      _showResults = true;
    });
    if (passed) {
      SoundService().playCompletion();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
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
            ? const Color(0xFF0F172A)
            : Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildModernHeader(),
              if (!_showResults &&
                  !_showQuiz &&
                  !_showCompletion &&
                  !_isReEntryLanding)
                _buildProgressBar(),
              Expanded(
                child: _showResults
                    ? _buildResultsScreen()
                    : _showQuiz
                    ? _buildQuizScreen()
                    : (_showCompletion || _isReEntryLanding)
                    ? _buildStoryCompleteScreen()
                    : PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _slides.length + 1,
                        padEnds: false, // For partial visibility effect
                        clipBehavior: Clip.none,
                        onPageChanged: (index) {
                          setState(() => _currentIndex = index);

                          if (index == _slides.length) {
                            if (!_storyCompleted) {
                              _saveProgress(storyCompleted: true);
                              SoundService().playCompletion();
                              setState(() => _storyCompleted = true);
                            }
                          }
                        },
                        itemBuilder: (context, index) {
                          if (index == _slides.length) {
                            return _buildStoryCompleteScreen();
                          }

                          Widget slideWidget = _buildUnitAtIndex(index);

                          // Apply hint animation only to first slide
                          if (index == 0 && !_hasShownHint) {
                            slideWidget = SlideTransition(
                              position: _slideAnimation,
                              child: slideWidget,
                            );
                          }

                          return slideWidget;
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(color: Color(0xFF1E293B)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () async {
              if (await _onWillPop() && mounted) Navigator.pop(context);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20,
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
          const Text(
            "Past Perfect Continuous",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              (_showResults ||
                      _showQuiz ||
                      _showCompletion ||
                      _isReEntryLanding)
                  ? "Quiz"
                  : _currentIndex == _slides.length
                  ? "Success"
                  : "${_currentIndex + 1}/${_slides.length}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = ((_currentIndex + 1) / _slides.length).clamp(0.0, 1.0);
    return Container(
      height: 2,
      decoration: const BoxDecoration(color: Color(0xFF1E293B)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.cyanAccent, Colors.cyan.shade300],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitAtIndex(int index) {
    if (index >= _slides.length) return const SizedBox.shrink();
    final unit = _slides[index];

    if (unit is LessonSlide) {
      return _buildSlideLayout(unit);
    } else if (unit is LessonHighlightInteraction) {
      return _buildHighlightLayout(unit);
    } else if (unit is LessonQuizInteraction) {
      return _buildQuizLayout(unit);
    } else if (unit is LessonSpeakingPractice) {
      return _buildSpeakingLayout(unit);
    } else {
      return const SizedBox.shrink();
    }
  }

  // --- LAYOUTS ---

  Widget _buildSlideLayout(LessonSlide slide) {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: LessonImage(
                lessonId: 'past_perfect_continuous',
                imageName: slide.imagePath,
                fallbackAssetPath: '$_assetPath${slide.imagePath}',
                fit: slide.imageFit ?? BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ).animate(key: ValueKey(slide.imagePath)).fadeIn(),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          slide.title,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (slide.tamilContent.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showTranslation = !_showTranslation;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _showTranslation
                                  ? Colors.cyanAccent.withValues(alpha: 0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _showTranslation
                                    ? Colors.cyanAccent
                                    : Colors.white24,
                              ),
                            ),
                            child: Text(
                              '\u0B85',
                              style: TextStyle(
                                color: _showTranslation
                                    ? Colors.cyanAccent
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    slide.content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_showTranslation)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        _preferredLanguage == 'Hindi'
                            ? slide.hindiContent
                            : slide.tamilContent,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ).animate().fadeIn(),
                    ),
                  if (slide.formula != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.cyan),
                      ),
                      child: Text(
                        slide.formula!,
                        style: TextStyle(
                          color: Colors.cyan[200],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightLayout(LessonHighlightInteraction unit) {
    return _buildSlideLayout(
      LessonSlide(
        title: unit.title,
        content: "${unit.introText}\n\n${unit.exampleText}",
        imagePath: unit.imagePath,
        tamilContent: unit.tamilContent,
        hindiContent: unit.hindiContent,
      ),
    );
  }

  Widget _buildQuizLayout(LessonQuizInteraction unit) {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: unit.imagePath.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: LessonImage(
                      lessonId: 'past_perfect_continuous',
                      imageName: unit.imagePath,
                      fallbackAssetPath: '$_assetPath${unit.imagePath}',
                      fit: unit.imageFit ?? BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ).animate(key: ValueKey(unit.imagePath)).fadeIn(),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        unit.question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      unit.question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ...List.generate(unit.options.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (index == unit.correctIndex) {
                              SoundService().playCorrect();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(unit.explanation),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(milliseconds: 1000),
                                ),
                              );
                            } else {
                              SoundService().playWrong();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Try Again"),
                                  backgroundColor: Colors.red,
                                  duration: Duration(milliseconds: 500),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.cyanAccent.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: Text(
                            unit.options[index],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakingLayout(LessonSpeakingPractice unit) {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: LessonImage(
                lessonId: 'past_perfect_continuous',
                imageName: unit.imagePath,
                fallbackAssetPath: '$_assetPath${unit.imagePath}',
                fit: unit.imageFit ?? BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ).animate(key: ValueKey(unit.imagePath)).fadeIn(),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    unit.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Read each sentence out loud.",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "This slide is practice only.",
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ...unit.prompts.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "- $p",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const LessonSpeakingPracticePanel(),
                  const SizedBox(height: 16),
                  if (unit.summaryPoints.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: unit.summaryPoints
                            .map(
                              (s) => Text(
                                s,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white30,
                                  fontSize: 12,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- QUIZ SCREENS (End of Lesson) ---

  Widget _buildQuizScreen() {
    final question = _quizQuestions[_currentQuestionIndex];
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Question ${_currentQuestionIndex + 1} / ${_quizQuestions.length}",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showTranslation = !_showTranslation;
                      });
                    },
                    icon: LanguageToggleIcon(
                      language: _preferredLanguage,
                      isActive: _showTranslation,
                      activeColor: Colors.cyanAccent,
                      inactiveColor: Colors.white54,
                      size: 16,
                    ),
                    tooltip: "Translate Question",
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                question['question'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_showTranslation) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    _preferredLanguage == 'Hindi'
                        ? (question['question_hindi'] ?? "")
                        : (question['question_tamil'] ?? ""),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: question['options'].length,
            itemBuilder: (context, index) {
              final isSelected = _selectedOptionIndex == index;
              final isCorrect = index == question['correct'];
              final showColor = _answerSelected && (isSelected || isCorrect);

              Color? bgColor = const Color(0xFF1E293B);
              Color borderColor = Colors.white10;
              Color textColor = Colors.white;

              if (showColor) {
                if (isCorrect) {
                  bgColor = Colors.green.withValues(alpha: 0.2);
                  borderColor = Colors.green;
                  textColor = Colors.greenAccent;
                } else if (isSelected) {
                  bgColor = Colors.red.withValues(alpha: 0.2);
                  borderColor = Colors.red;
                  textColor = Colors.redAccent;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _handleAnswer(index),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            question['options'][index],
                            style: TextStyle(color: textColor, fontSize: 18),
                          ),
                        ),
                        if (showColor && isCorrect)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                          ),
                        if (showColor && isSelected && !isCorrect)
                          const Icon(Icons.cancel, color: Colors.redAccent),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsScreen() {
    final passingScore = (_quizQuestions.length * 0.7).ceil();
    final passed = _score >= passingScore;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.emoji_events : Icons.refresh_rounded,
              size: 80,
              color: passed ? Colors.amber : Colors.orangeAccent,
            ).animate().scale(),
            const SizedBox(height: 24),
            Text(
              passed ? "Lesson Mastered!" : "Try Again",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You scored $_score / ${_quizQuestions.length}",
              style: TextStyle(
                color: passed ? Colors.greenAccent : Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!passed)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "You need 70% to pass.",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            const SizedBox(height: 32),
            if (passed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Finish Lesson",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text("Exit"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showResults = false;
                          _showQuiz = true;
                          _currentQuestionIndex = 0;
                          _score = 0;
                          _answerSelected = false;
                          _selectedOptionIndex = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Retake",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCompleteScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
                  _quizCompleted
                      ? Icons.emoji_events_rounded
                      : Icons.check_circle_outline,
                  size: 100,
                  color: _quizCompleted
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF4FACFE),
                )
                .animate()
                .fade(duration: 500.ms)
                .scale(duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 32),

            Text(
              _quizCompleted ? "Lesson Mastered!" : "Well done!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 16),

            Text(
              _quizCompleted
                  ? "Lesson Mastered!"
                  : "Story complete. Take the quiz to master it.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 48),

            if (_quizCompleted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isReEntryLanding = false;
                      _showCompletion = false;
                      _currentIndex = 0;
                    });
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(0);
                      }
                    });
                    SoundService().playTap();
                  },
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
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isReEntryLanding = false;
                      _showCompletion = false;
                      _showQuiz = true;
                      _score = 0;
                      _currentQuestionIndex = 0;
                      _answerSelected = false;
                      _selectedOptionIndex = null;
                      _showResults = false;
                      _showTranslation = false;
                    });
                    SoundService().playTap();
                  },
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text("Retake Quiz"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF4FACFE,
                    ).withValues(alpha: 0.2),
                    foregroundColor: const Color(0xFF4FACFE),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Go Back",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isReEntryLanding = false;
                      _showCompletion = false;
                      _showQuiz = true;
                    });
                    SoundService().playTap();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FACFE),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Take Mastery Quiz",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Continue to Next Lesson",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
