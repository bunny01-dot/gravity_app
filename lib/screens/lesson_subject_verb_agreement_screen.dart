import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class LessonDragDrop extends LessonUnit {
  final String question;
  final String draggableWord;
  final String correctTarget; // e.g., "Ravi (One)"
  final String wrongTarget; // e.g., "Use 'Play'"
  final String successMsg;
  final Color? color;

  LessonDragDrop({
    required this.question,
    required this.draggableWord,
    required this.correctTarget,
    required this.wrongTarget,
    required this.successMsg,
    this.color,
  });
}

class LessonSpeakingPractice extends LessonUnit {
  final String title;
  final String imagePath;
  final List<String> prompts;
  final List<String> summaryPoints;
  final String? exampleText;
  final String? chartSummary;
  final BoxFit? imageFit;

  LessonSpeakingPractice({
    required this.title,
    required this.imagePath,
    required this.prompts,
    this.summaryPoints = const [],
    this.exampleText,
    this.chartSummary,
    this.imageFit,
  });
}

// -----------------------------------------------------------------------------
// SCREEN: Subject-Verb Agreement
// -----------------------------------------------------------------------------
class LessonSubjectVerbAgreementScreen extends StatefulWidget {
  const LessonSubjectVerbAgreementScreen({super.key});

  @override
  State<LessonSubjectVerbAgreementScreen> createState() =>
      _LessonSubjectVerbAgreementScreenState();
}

class _LessonSubjectVerbAgreementScreenState
    extends State<LessonSubjectVerbAgreementScreen>
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
  String _preferredLanguage = 'Tamil'; // Default
  bool _showTranslation = false;

  // Quiz State
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answerSelected = false;
  int? _selectedOptionIndex;
  bool _quizCompleted = false;

  // Drag Drop Interaction State
  bool _isDragSuccess = false;

  // Lesson Content
  late List<LessonUnit> _slides;

  // Base Asset Path
  final String _assetPath = 'assets/Lessons/Lesson_Subject_Verb_Agreement/';

  // Hardcoded Quiz (End of Lesson)
  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'The dog ___ fast.',
      'question_tamil': 'The dog ___ fast.',
      'question_hindi': 'The dog ___ fast.',
      'options': ['run', 'runs', 'running', 'to run'],
      'correct': 1,
    },
    {
      'question': 'Ravi and Sunny ___ happy.',
      'question_tamil': 'Ravi and Sunny ___ happy.',
      'question_hindi': 'Ravi and Sunny ___ happy.',
      'options': ['is', 'are', 'was', 'am'],
      'correct': 1,
    },
    {
      'question': 'The team ___ winning.',
      'question_tamil': 'The team ___ winning.',
      'question_hindi': 'The team ___ winning.',
      'options': ['is', 'are', 'were', 'have'],
      'correct': 0,
    },
    {
      'question': 'She ___ pizza.',
      'question_tamil': 'She ___ pizza.',
      'question_hindi': 'She ___ pizza.',
      'options': ['like', 'likes', 'liking', 'liked'],
      'correct': 1,
    },
    {
      'question': 'They ___ to the market.',
      'question_tamil': 'They ___ to the market.',
      'question_hindi': 'They ___ to the market.',
      'options': ['go', 'goes', 'going', 'gone'],
      'correct': 0,
    },
    {
      'question': 'Water ___ necessary for life.',
      'question_tamil': 'Water ___ necessary for life.',
      'question_hindi': 'Water ___ necessary for life.',
      'options': ['is', 'are', 'were', 'am'],
      'correct': 0,
    },
    {
      'question': 'The news ___ interesting.',
      'question_tamil': 'The news ___ interesting.',
      'question_hindi': 'The news ___ interesting.',
      'options': ['is', 'are', 'were', 'have'],
      'correct': 0,
    },
    {
      'question': 'One of the boys ___ absent.',
      'question_tamil': 'One of the boys ___ absent.',
      'question_hindi': 'One of the boys ___ absent.',
      'options': ['is', 'are', 'were', 'have'],
      'correct': 0,
    },
    {
      'question': 'You ___ my best friend.',
      'question_tamil': 'You ___ my best friend.',
      'question_hindi': 'You ___ my best friend.',
      'options': ['is', 'are', 'am', 'was'],
      'correct': 1,
    },
    {
      'question': 'Neither Ravi nor his friends ___ here.',
      'question_tamil': 'Neither Ravi nor his friends ___ here.',
      'question_hindi': 'Neither Ravi nor his friends ___ here.',
      'options': ['is', 'are', 'was', 'has'],
      'correct': 1, // 'friends' is nearer
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
        prefs.getBool('has_seen_swipe_hint_lesson_sub_verb') ?? false;

    if (!hasSeenHint && mounted) {
      setState(() => _hasShownHint = false);

      // Wait a bit for layout
      await Future.delayed(const Duration(milliseconds: 500));

      await _precacheNextSlideImage();

      if (mounted && !_hasShownHint) {
        await _hintAnimationController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        await _hintAnimationController.reverse();

        await prefs.setBool('has_seen_swipe_hint_lesson_sub_verb', true);
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
      // 1. Intro
      LessonSlide(
        title: "The Match Game",
        content:
            "The Subject (Who) and the Verb (Action) must MATCH.\n\nCorrect match = Correct sentence.",
        imagePath: 'subject_verb_match_square.webp',
        hindiContent: " (Subject)   (Verb)    ",
        tamilContent: " (Subject)   (Verb)  .",
        imageFit: BoxFit.contain,
        formula: "Subject <=> Verb",
      ),
      // 2. The Golden Rule
      LessonSlide(
        title: "The Golden Rule",
        content:
            "Singular Subject gets an \"S\".\nPlural Subject has NO \"S\".\n\nHe EATS (S).\nThey EAT (No S).",
        imagePath: 'singular_plural_rule_square.webp',
        hindiContent: "  \"S\"     \"S\"  ",
        tamilContent: " \"S\" .  \"S\" .",
        imageFit: BoxFit.contain,
      ),
      // 3. I and You
      LessonSlide(
        title: "I & You are Special",
        content:
            "\"I\" and \"You\" follow the PLURAL rule (usually).\n\nI EAT (not eats).\nYou RUN (not runs).",
        imagePath: 'i_you_special_square.webp',
        hindiContent: "\"I\"  \"You\"      ",
        tamilContent: "\"I\"  \"You\"   .",
        imageFit: BoxFit.contain,
      ),
      // 4. Drag & Drop 1
      LessonDragDrop(
        question: "Ravi is ONE boy. Drag the correct verb!",
        draggableWord: "Plays",
        correctTarget: "Ravi (One)",
        wrongTarget: "Use 'Play'",
        successMsg: "Correct! One boy = Plays",
        color: Colors.orangeAccent,
      ),
      // 5. AND Rule
      LessonSlide(
        title: "The \"AND\" Rule",
        content:
            "1 + 1 = 2.\nWhen you see \"AND\", it becomes Plural.\n\nRavi AND Sunny PLAY (not plays).",
        imagePath: 'and_plural_rule_square.webp',
        hindiContent: " \"AND\"  ,      ",
        tamilContent: "\"AND\"    (Plural) .",
        imageFit: BoxFit.contain,
      ),
      // 6. OR Rule
      LessonSlide(
        title: "The \"OR\" Rule",
        content:
            "If using \"OR\", match the verb to the NEAREST person.\n\nRavi or his FRIENDS ARE coming.",
        imagePath: 'or_nearest_rule_square.webp',
        hindiContent: "\"OR\"    ,      ",
        tamilContent: "\"OR\" ,     .",
        imageFit: BoxFit.contain,
      ),
      // 7. Collective Nouns
      LessonSlide(
        title: "Groups are ONE",
        content:
            "A Team implies ONE group. It is Singular.\n\nThe team WINS.\nMy family IS big.",
        imagePath: 'collective_nouns_square.webp',
        hindiContent: "  (Team)      ",
        tamilContent: "  (Team)  .  .",
        imageFit: BoxFit.contain,
      ),
      // 8. Uncountable
      LessonSlide(
        title: "Can you count it?",
        content:
            "If you cannot count it (Water, Air, Love), it is SINGULAR.\n\nWater IS cold.\nLove IS blind.",
        imagePath: 'tricky_words_square.webp',
        hindiContent: "     (, ),   ",
        tamilContent: "  (, )  .",
        imageFit: BoxFit.contain,
      ),
      // 9. Common Mistakes
      LessonSlide(
        title: "Tricky Words",
        content:
            "News and Maths end in \"S\" but are ONE thing.\n\nThe News IS good (not are).",
        imagePath: 'common_mistakes_square.webp',
        hindiContent: "News  Maths \"S\"        ",
        tamilContent: "News, Maths  \"S\"    .",
        imageFit: BoxFit.contain,
      ),
      // 10. Drag Drop 2
      LessonDragDrop(
        question: "The Team is a group (One).",
        draggableWord: "Wins",
        correctTarget: "The Team",
        wrongTarget: "Win",
        successMsg: "Correct! Group = One Unit.",
        color: Colors.cyanAccent,
      ),
      // 11. Speaking
      LessonSpeakingPractice(
        title: "Speaking Practice",
        imagePath: 'agreement_speaking_square.webp',
        prompts: [
          "My family loves me.",
          "Ravi and Sunny Play.",
          "He eats pizza.",
        ],
        exampleText: "My family loves me",
        imageFit: BoxFit.contain,
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
        prefs.getBool('lesson_subject_verb_story_completed') ?? false;
    bool quizDone =
        prefs.getBool('lesson_subject_verb_quiz_completed') ?? false;

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
        await prefs.setBool('lesson_subject_verb_story_completed', true);
      }
      if (quizCompleted) {
        await prefs.setBool('lesson_subject_verb_quiz_completed', true);
        await prefs.setBool('lesson_subject_verb_completed', true);
        if (score != null) {
          await prefs.setInt('lesson_subject_verb_score', score);
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
          data['completed'] = true;
          if (score != null) data['score'] = score;
          data['quiz_completed_at'] = FieldValue.serverTimestamp();
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('lessons')
            .doc('lesson_subject_verb_agreement')
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
      _quizCompleted = passed;
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
                        padEnds: false,
                        clipBehavior: Clip.none,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                            _isDragSuccess = false;
                          });

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
              if (await _onWillPop() && mounted) Navigator.pop(context, true);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20,
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
          const Text(
            "Subject-Verb Agreement",
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
    } else if (unit is LessonDragDrop) {
      return _buildDragDropLayout(unit);
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
                lessonId: 'subject_verb_agreement',
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

  Widget _buildDragDropLayout(LessonDragDrop unit) {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                unit.question,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DragTarget<String>(
                builder: (context, candidates, rejects) {
                  return AnimatedContainer(
                    duration: 300.ms,
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: _isDragSuccess
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isDragSuccess
                            ? Colors.green
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.download_rounded,
                          color: Colors.white54,
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          unit.correctTarget,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                },
                onWillAcceptWithDetails: (data) => true,
                onAcceptWithDetails: (data) {
                  setState(() => _isDragSuccess = true);
                  SoundService().playCorrect();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(unit.successMsg),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              DragTarget<String>(
                builder: (context, candidates, rejects) {
                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.close,
                          color: Colors.white24,
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          unit.wrongTarget,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white30),
                        ),
                      ],
                    ),
                  );
                },
                onWillAcceptWithDetails: (data) => true,
                onAcceptWithDetails: (data) {
                  SoundService().playWrong();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Try matching singular with singular!"),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (!_isDragSuccess)
          Expanded(
            flex: 2,
            child: Draggable<String>(
              data: unit.draggableWord,
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: unit.color ?? Colors.cyanAccent,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    unit.draggableWord,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              childWhenDragging: Container(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: unit.color ?? Colors.cyanAccent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  unit.draggableWord,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().shake(delay: 500.ms),
            ),
          )
        else
          const Spacer(flex: 2),
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
                lessonId: 'subject_verb_agreement',
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
                          _showTranslation = false;
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
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 32),
            Text(
              _quizCompleted ? "Lesson Mastered!" : "Well done!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _quizCompleted
                  ? "You have fully mastered Subject-Verb Agreement!\nGreat job!"
                  : "You've finished the lesson story.\nNow take the quiz to master it!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            if (!_quizCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showCompletion = false;
                      _showQuiz = true;
                    });
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Text(
                    "Start Quiz",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FACFE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showCompletion = false;
                    _isReEntryLanding = false;
                    _currentIndex = 0;
                  });
                  Future.delayed(const Duration(milliseconds: 50), () {
                    if (_pageController.hasClients) {
                      _pageController.jumpToPage(0);
                    }
                  });
                  SoundService().playTap();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  "Review Story",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            if (_quizCompleted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showCompletion = false;
                      _showQuiz = true;
                      _currentQuestionIndex = 0;
                      _score = 0;
                      _answerSelected = false;
                      _selectedOptionIndex = null;
                      _showTranslation = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4FACFE),
                    side: const BorderSide(color: Color(0xFF4FACFE), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Practice Again",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Return to Menu",
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
