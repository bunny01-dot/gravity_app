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

class LessonMultiQuiz extends LessonUnit {
  final String title;
  final List<Map<String, String>> questions; // text, answer

  LessonMultiQuiz({required this.title, required this.questions});
}

class LessonSeparableDragDrop extends LessonUnit {
  final String instruction;
  final String sentencePart1; // "Turn"
  final String sentencePart2; // "off"
  final String draggableObject; // "TV"
  final String successMsg;

  LessonSeparableDragDrop({
    required this.instruction,
    required this.sentencePart1,
    required this.sentencePart2,
    required this.draggableObject,
    required this.successMsg,
  });
}

class LessonSpeakingPractice extends LessonUnit {
  final String title;
  final String imagePath;
  final List<String> prompts;
  final String? exampleText;
  final String? topList;
  final BoxFit? imageFit;

  LessonSpeakingPractice({
    required this.title,
    required this.imagePath,
    required this.prompts,
    this.exampleText,
    this.topList,
    this.imageFit,
  });
}

// -----------------------------------------------------------------------------
// SCREEN: Phrasal Verbs
// -----------------------------------------------------------------------------
class LessonPhrasalVerbsScreen extends StatefulWidget {
  const LessonPhrasalVerbsScreen({super.key});

  @override
  State<LessonPhrasalVerbsScreen> createState() =>
      _LessonPhrasalVerbsScreenState();
}

class _LessonPhrasalVerbsScreenState extends State<LessonPhrasalVerbsScreen>
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

  // Interaction States
  final Map<int, bool> _multiQuizSolved = {}; // Track solved items in MultiQuiz
  bool _separableSolved = false;

  // Lesson Content
  late List<LessonUnit> _slides;

  // Base Asset Path
  final String _assetPath = 'assets/Lessons/Lesson_Phrasal_Verbs/';

  // Hardcoded Quiz (End of Lesson)
  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'Please ___ the light. (Start)',
      'question_tamil': 'Please ___ the light. (Start)',
      'question_hindi': 'Please ___ the light. (Start)',
      'options': ['turn on', 'turn off', 'turn up'],
      'correct': 0,
    },
    {
      'question': 'I ___ at 6 AM. (Awake)',
      'question_tamil': 'I ___ at 6 AM. (Awake)',
      'question_hindi': 'I ___ at 6 AM. (Awake)',
      'options': ['get in', 'wake up', 'look after'],
      'correct': 1,
    },
    {
      'question': 'Can you ___ the baby? (Care)',
      'question_tamil': 'Can you ___ the baby? (Care)',
      'question_hindi': 'Can you ___ the baby? (Care)',
      'options': ['look at', 'look for', 'look after'],
      'correct': 2,
    },
    {
      'question': 'Don\'t ___! (Stop trying)',
      'question_tamil': 'Don\'t ___! (Stop trying)',
      'question_hindi': 'Don\'t ___! (Stop trying)',
      'options': ['give in', 'give up', 'give out'],
      'correct': 1,
    },
    {
      'question': '___ your shoes. (Remove)',
      'question_tamil': '___ your shoes. (Remove)',
      'question_hindi': '___ your shoes. (Remove)',
      'options': ['Take off', 'Take out', 'Take on'],
      'correct': 0,
    },
    {
      'question': 'Did you ___ the answer?',
      'question_tamil': 'Did you ___ the answer?',
      'question_hindi': 'Did you ___ the answer?',
      'options': ['find out', 'find in', 'look out'],
      'correct': 0,
    },
    {
      'question': 'She ___ the form.',
      'question_tamil': 'She ___ the form.',
      'question_hindi': 'She ___ the form.',
      'options': ['filled up', 'filled out', 'filled in'],
      'correct': 1,
    },
    {
      'question': 'The plane ___. (Departed)',
      'question_tamil': 'The plane ___. (Departed)',
      'question_hindi': 'The plane ___. (Departed)',
      'options': ['took on', 'took off', 'took out'],
      'correct': 1,
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
        prefs.getBool('has_seen_swipe_hint_lesson_phrasal_verbs') ?? false;

    if (!hasSeenHint && mounted) {
      setState(() => _hasShownHint = false);

      // Wait a bit for layout
      await Future.delayed(const Duration(milliseconds: 500));

      await _precacheNextSlideImage();

      if (mounted && !_hasShownHint) {
        await _hintAnimationController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        await _hintAnimationController.reverse();

        await prefs.setBool('has_seen_swipe_hint_lesson_phrasal_verbs', true);
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
      // 1. Hook
      LessonSlide(
        title: "Magic Verbs",
        content:
            "Phrasal Verbs are magic!\nOne word like 'Pick' + 'Up' = A NEW meaning!",
        imagePath: 'ravi_pick_up_square.webp',
        hindiContent: "'Pick' + 'Up'     !",
        tamilContent: "'Pick' + 'Up'     !",
        imageFit: BoxFit.contain,
        formula: "Verb + Preposition",
      ),
      // 2. Definition
      LessonSlide(
        title: "Verb + Particle",
        content:
            "It is a Verb (Action) + Particle (like on, off, up).\n\nLook (See) + After (Behind) = Care for!",
        imagePath: 'phrasal_vs_literal_square.webp',
        hindiContent: "  +  (on, off, up) ",
        tamilContent: "  + .",
        imageFit: BoxFit.contain,
      ),
      // 3. Separable
      LessonSlide(
        title: "Separable?",
        content:
            "Can you put the object in the middle?\n\nYES: Turn the light off.\nNO: Look after Ravi.\n\nSome can communicate, some stick together!",
        imagePath: 'separable_inseparable_square.webp',
        hindiContent: "        ?",
        tamilContent: "   ?",
        imageFit: BoxFit.contain,
      ),
      // 4. Home
      LessonSlide(
        title: "At Home",
        content:
            "We use these everyday!\n\nWake up (Stop sleeping)\nTurn off (Stop power)\nClean up (Tidy)",
        imagePath: 'home_phrasals_square.webp',
        hindiContent: "     !",
        tamilContent: "   !",
        imageFit: BoxFit.contain,
      ),
      // 5. School
      LessonSlide(
        title: "At School",
        content:
            "Teachers use these all the time.\n\nHand in (Submit)\nLook up (Search)\nWork out (Solve)",
        imagePath: 'school_phrasals_square.webp',
        hindiContent: "      ",
        tamilContent: "  .",
        imageFit: BoxFit.contain,
      ),
      // 6. Particles
      LessonSlide(
        title: "Secret Codes",
        content:
            "UP often means 'Finish'.\nOFF often means 'Stop'.\n\nClean up (Finish cleaning)\nTurn off (Stop the light)",
        imagePath: 'particle_meanings_square.webp',
        hindiContent: "UP =  OFF = ",
        tamilContent: "UP = . OFF = .",
        imageFit: BoxFit.contain,
      ),
      // 7. Detective
      LessonMultiQuiz(
        title: "Phrasal Verb Detective",
        questions: [
          {'text': 'Ravi ___ his room.', 'answer': 'cleaned up'},
          {'text': 'Please ___ the TV.', 'answer': 'turn off'},
          {'text': 'Mom ___ Ravi.', 'answer': 'looks after'},
          {'text': 'Plane ___ at 5 PM.', 'answer': 'takes off'},
          {'text': 'Don\'t ___ trying!', 'answer': 'give up'},
        ],
      ),
      // 8. Separable Drag Drop
      LessonSeparableDragDrop(
        instruction: "Pick Up the Book!",
        sentencePart1: "Pick",
        sentencePart2: "up",
        draggableObject: "the book",
        successMsg: "Correct! Nouns can go in the middle OR end.",
      ),
      // 9. Speaking
      LessonSpeakingPractice(
        title: "Speaking Practice",
        imagePath: 'phrasal_speaking_square.webp',
        prompts: [
          "I cleaned up my room.",
          "Please turn off the light.",
          "Don't give up!",
        ],
        exampleText: "I cleaned up my room",
        topList:
            "Top 10: turn on/off, pick up, look after, clean up, wake up, give up, work out",
        imageFit: BoxFit.contain,
      ),
    ];
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    // Load preferred language
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

    // Load lesson progress
    bool storyDone =
        prefs.getBool('lesson_phrasal_verbs_story_completed') ?? false;
    bool quizDone =
        prefs.getBool('lesson_phrasal_verbs_quiz_completed') ?? false;

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
        await prefs.setBool('lesson_phrasal_verbs_story_completed', true);
      }
      if (quizCompleted) {
        await prefs.setBool('lesson_phrasal_verbs_quiz_completed', true);
        await prefs.setBool('lesson_phrasal_verbs_completed', true);
        if (score != null) {
          await prefs.setInt('lesson_phrasal_verbs_score', score);
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
            .doc('lesson_phrasal_verbs')
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
                            _separableSolved = false;
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
            "Phrasal Verbs",
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
    } else if (unit is LessonMultiQuiz) {
      return _buildMultiQuizLayout(unit);
    } else if (unit is LessonSeparableDragDrop) {
      return _buildSeparableDragDrop(unit);
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
                lessonId: 'phrasal_verbs',
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

  Widget _buildMultiQuizLayout(LessonMultiQuiz unit) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: unit.questions.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final q = unit.questions[index];
              final isSolved = _multiQuizSolved[index] == true;

              return InkWell(
                onTap: isSolved
                    ? null
                    : () {
                        setState(() => _multiQuizSolved[index] = true);
                        SoundService().playCorrect();
                      },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSolved
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSolved ? Colors.green : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          q['text']!.replaceAll('___', '...'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isSolved)
                        Text(
                          q['answer']!,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        const Icon(Icons.help_outline, color: Colors.white54),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSeparableDragDrop(LessonSeparableDragDrop unit) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        unit.instruction,
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
                      // Target 1: Middle
                      DragTarget<String>(
                        builder: (context, candidateData, rejectedData) {
                          return AnimatedContainer(
                            duration: 300.ms,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: _separableSolved
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _separableSolved
                                    ? Colors.green
                                    : Colors.white24,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  unit.sentencePart1,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                const Icon(
                                  Icons.arrow_downward,
                                  color: Colors.white24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  unit.sentencePart2,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          );
                        },
                        onWillAcceptWithDetails: (data) => true,
                        onAcceptWithDetails: (data) {
                          setState(() => _separableSolved = true);
                          SoundService().playCorrect();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(unit.successMsg)),
                          );
                        },
                      ),
                      // Target 2: End
                      DragTarget<String>(
                        builder: (context, candidateData, rejectedData) {
                          return AnimatedContainer(
                            duration: 300.ms,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: _separableSolved
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _separableSolved
                                    ? Colors.green
                                    : Colors.white24,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${unit.sentencePart1} ${unit.sentencePart2}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                const Icon(
                                  Icons.arrow_downward,
                                  color: Colors.white24,
                                ),
                              ],
                            ),
                          );
                        },
                        onWillAcceptWithDetails: (data) => true,
                        onAcceptWithDetails: (data) {
                          // For noun, both correct.
                          setState(() => _separableSolved = true);
                          SoundService().playCorrect();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(unit.successMsg)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
            if (!_separableSolved)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Draggable<String>(
                  data: unit.draggableObject,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
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
                        unit.draggableObject,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(height: 50),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      unit.draggableObject,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().shake(delay: 500.ms),
                ),
              ),
          ],
        );
      },
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
                lessonId: 'phrasal_verbs',
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
                  if (unit.exampleText != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.cyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Example: ${unit.exampleText!}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const LessonSpeakingPracticePanel(),
                  if (unit.topList != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unit.topList!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 12,
                        ),
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
              const SizedBox(height: 16),
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
                  ? "You have fully mastered Phrasal Verbs!\nGreat job!"
                  : "You've finished the lesson story.\nNow take the quiz to master it!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            if (!_quizCompleted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showCompletion = false;
                      _showQuiz = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FACFE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 28),
                      SizedBox(width: 8),
                      Text(
                        "Start Quiz",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                  label: const Text("Review Lesson"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4FACFE),
                    side: const BorderSide(color: Color(0xFF4FACFE), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
            if (_quizCompleted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
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
