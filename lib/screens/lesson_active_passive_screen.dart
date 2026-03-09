import 'package:flutter/material.dart';
import 'package:gravity_app/widgets/language_toggle_icon.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gravity_app/services/lesson_content_service.dart';
import 'package:gravity_app/widgets/lesson_image.dart';
import 'package:gravity_app/widgets/lesson_speaking_practice_panel.dart';
// import 'package:gravity_app/widgets/lesson_speaking_card.dart'; // Removed - not used

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
    required this.summaryPoints,
    this.imageFit,
  });
}

// -----------------------------------------------------------------------------
// SCREEN: Active and Passive Voice
// -----------------------------------------------------------------------------
class LessonActivePassiveScreen extends StatefulWidget {
  const LessonActivePassiveScreen({super.key});

  @override
  State<LessonActivePassiveScreen> createState() =>
      _LessonActivePassiveScreenState();
}

class _LessonActivePassiveScreenState extends State<LessonActivePassiveScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isLoading = true;
  late List<LessonUnit> _slides;

  // View State
  bool _showTranslation = false;
  String _preferredLanguage = 'Tamil';

  // Quiz State
  int? _selectedQuizIndex;
  bool _isQuizCorrect = false;
  bool _showQuizFeedback = false;

  // Final Quiz State
  bool _storyComplete = false;
  bool _showFinalQuiz = false;
  int _finalQuizIndex = 0;
  int _finalQuizScore = 0;
  int? _selectedFinalQuizOption;
  bool _showFinalQuizFeedback = false;
  bool _lessonCompleted = false;
  bool _completionSaved = false;

  // Animation
  late AnimationController _hintAnimationController;
  late Animation<Offset> _slideAnimation;
  bool _hasShownHint = false;

  @override
  void initState() {
    super.initState();
    _initializeContent();
    _loadProgress();

    // Initialize hint animation
    _hintAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.12, 0), // Slide 12% left
        ).animate(
          CurvedAnimation(
            parent: _hintAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _checkAndPlayHint();

    //  Cloud Asset Preload
    LessonContentService().preloadNextLessons('active_passive');
  }

  Future<void> _checkAndPlayHint() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenHint =
        prefs.getBool('has_seen_swipe_hint_lesson_active_passive') ?? false;

    if (!hasSeenHint && mounted) {
      setState(() => _hasShownHint = false);

      // Wait a bit for layout
      await Future.delayed(const Duration(milliseconds: 500));

      await _precacheNextSlideImage();

      if (mounted && !_hasShownHint) {
        await _hintAnimationController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        await _hintAnimationController.reverse();

        await prefs.setBool('has_seen_swipe_hint_lesson_active_passive', true);
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
    } else if (nextUnit is LessonQuizInteraction) {
      imagePath = nextUnit.imagePath;
    } else if (nextUnit is LessonSpeakingPractice) {
      imagePath = nextUnit.imagePath;
    }

    if (imagePath == null || imagePath.isEmpty) return;
    if (!imagePath.startsWith('assets/')) return;
    await precacheImage(AssetImage(imagePath), context);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _hintAnimationController.dispose();
    super.dispose();
  }

  // Final Quiz Questions
  final List<Map<String, dynamic>> _finalQuizQuestions = [
    {
      'question': 'Convert to Passive: "Ravi eats dosa."',
      'question_tamil': 'Passive  : "Ravi eats dosa."',
      'question_hindi': 'Passive  : "Ravi eats dosa."',
      'options': [
        'Dosa is eaten by Ravi.',
        'Dosa was eaten by Ravi.',
        'Dosa eats Ravi.',
        'Ravi is eating dosa.',
      ],
      'correct': 0,
      'explanation': 'Present tense  is + V3 (eaten)',
    },
    {
      'question': 'Which is Passive Voice?',
      'question_tamil': ' Passive Voice?',
      'question_hindi': '  Passive Voice ?',
      'options': [
        'Mom cooks rice.',
        'The room was cleaned.',
        'He is writing.',
        'She will dance.',
      ],
      'correct': 1,
      'explanation': '"Was cleaned" uses BE + V3 structure',
    },
    {
      'question': 'Convert to Passive: "They played cricket."',
      'question_tamil': 'Passive  : "They played cricket."',
      'question_hindi': 'Passive  : "They played cricket."',
      'options': [
        'Cricket plays them.',
        'Cricket is played.',
        'Cricket was played by them.',
        'They were playing cricket.',
      ],
      'correct': 2,
      'explanation': 'Past tense  was/were + V3',
    },
    {
      'question': 'Active: "He is writing a letter."  Passive:',
      'question_tamil': 'Active: "He is writing a letter."  Passive ?',
      'question_hindi': 'Active: "He is writing a letter."  Passive  ?',
      'options': [
        'A letter is written.',
        'A letter is being written.',
        'A letter was written.',
        'He writes a letter.',
      ],
      'correct': 1,
      'explanation': 'Continuous tense needs BEING + V3',
    },
    {
      'question': 'Which part comes first in Passive Voice?',
      'question_tamil': 'Passive Voice-   ?',
      'question_hindi': 'Passive Voice       ?',
      'options': ['Subject (doer)', 'Object (receiver)', 'Verb', 'By'],
      'correct': 1,
      'explanation': 'Object becomes the subject in passive voice',
    },
    {
      'question': 'Convert: "She will sing a song."',
      'question_tamil': ': "She will sing a song."',
      'question_hindi': ': "She will sing a song."',
      'options': [
        'A song will be sung by her.',
        'A song is sung.',
        'She sings a song.',
        'A song was sung.',
      ],
      'correct': 0,
      'explanation': 'Future tense  will be + V3',
    },
  ];

  void _initializeContent() {
    final String assetPath = 'assets/Lessons/Lesson_12_Active_Passive/';

    _slides = [
      // Slide 1  Hook
      LessonSlide(
        title: "Who is the Focus?",
        content:
            "Active Focus: The DOER (Ravi).\nPassive Focus: The RESULT (Dosa).\n\nActive: Ravi eats dosa.\nPassive: Dosa is eaten by Ravi.",
        imagePath: '${assetPath}active_passive_hook_square.webp',
        imageFit: BoxFit.contain,
        tamilContent:
            "Active:    (Ravi).\nPassive:     (Dosa).\nActive:   .\nPassive:   .",
        hindiContent:
            "Active:    (Ravi).\nPassive:    (Dosa).\nActive:    \nPassive:      ",
      ),

      // Slide 2  Rules
      LessonSlide(
        title: "Conversion Rules",
        content:
            "1. Object becomes Subject.\n2. Add 'BE' verb (is, was, will be).\n3. Verb = Past Participle (V3).\n4. Add 'by' + Subject.\n\nObject + BE + V3 + by Subject",
        imagePath: '${assetPath}active_passive_structure_square.webp',
        imageFit: BoxFit.contain,
        tamilContent:
            "1. Object -> Subject  .\n2. 'BE'   (is, was).\n3.  -> V3 (Past Participle).\n4. 'by' .",
        hindiContent:
            "1. Object -> Subject  \n2. 'BE'   (is, was)\n3.  -> V3 (Past Participle)\n4. 'by' ",
        formula: "Object + Be + V3 + by Subject",
      ),

      // Slide 3  Present Tense
      LessonSlide(
        title: "Present Tense",
        content:
            "Active: Ravi eats dosa.\nPassive: Dosa IS EATEN by Ravi.\n\nHelper: am/is/are + V3",
        imagePath: '${assetPath}present_voice_square.webp',
        imageFit: BoxFit.contain,
        tamilContent:
            ":\nRavi eats dosa. -> Dosa is eaten by Ravi.\n(Is + V3 ).",
        hindiContent:
            " :\nRavi eats dosa. -> Dosa is eaten by Ravi.\n(Is + V3   )",
        formula: "am/is/are + V3",
      ),

      // Slide 4  Past Tense
      LessonSlide(
        title: "Past Tense",
        content:
            "Active: Ravi ate dosa.\nPassive: Dosa WAS EATEN by Ravi.\n\nHelper: was/were + V3",
        imagePath: '${assetPath}past_voice_square.webp',
        imageFit: BoxFit.contain,
        tamilContent:
            ":\nRavi ate dosa. -> Dosa was eaten by Ravi.\n(Was + V3 ).",
        hindiContent:
            ":\nRavi ate dosa. -> Dosa was eaten by Ravi.\n(Was + V3   )",
        formula: "was/were + V3",
      ),

      // Slide 5  Future Tense
      LessonSlide(
        title: "Future Tense",
        content:
            "Active: Ravi will eat dosa.\nPassive: Dosa WILL BE EATEN by Ravi.\n\nHelper: will be + V3",
        imagePath: '${assetPath}voice_reference_square.webp',
        imageFit: BoxFit.contain,
        tamilContent:
            ":\nRavi will eat dosa. -> Dosa will be eaten by Ravi.\n(Will be + V3 ).",
        hindiContent:
            " :\nRavi will eat dosa. -> Dosa will be eaten by Ravi.\n(Will be + V3   )",
        formula: "will be + V3",
      ),

      // Slide 6  Continuous Tense
      LessonSlide(
        title: "Continuous Tense",
        content:
            "Active: Ravi is eating dosa.\nPassive: Dosa is BEING EATEN by Ravi.\n\nHelper: is/are/was/were + BEING + V3",
        imagePath: '${assetPath}passive_when_square.webp',
        imageFit: BoxFit.contain,
        tamilContent:
            " :\nRavi is eating dosa. -> Dosa is being eaten by Ravi.\n(Being + V3 ).",
        hindiContent:
            " :\nRavi is eating dosa. -> Dosa is being eaten by Ravi.\n(Being + V3  )",
        formula: "Be + BEING + V3",
      ),

      // Slide 7  Quiz: Recognition
      LessonQuizInteraction(
        title: "Voice Detective",
        question: "Is this Passive?\n'The room was cleaned yesterday.'",
        options: ["Yes, Passive", "No, Active"],
        correctIndex: 0,
        explanation:
            "Yes! 'Was cleaned' (Be + V3) shows the room received the action.",
        imagePath: '${assetPath}voice_quiz_square.webp',
        imageFit: BoxFit.contain,
      ),

      // Slide 8  Quiz: Present Tense
      LessonQuizInteraction(
        title: "Convert to Passive",
        question: "Active: She sings a song.",
        options: [
          "A song is sung by her.",
          "A song was sung by her.",
          "A song being sung.",
          "She is sung a song.",
        ],
        correctIndex: 0,
        explanation: "Present tense -> is + sung (V3).",
        imagePath: '${assetPath}voice_arrow_flow_square.webp',
        imageFit: BoxFit.contain,
      ),

      // Slide 9  Quiz: Continuous
      LessonQuizInteraction(
        title: "Continuous Challenge",
        question: "Active: He is writing a letter.",
        options: [
          "A letter is written.",
          "A letter is being written by him.",
          "A letter was written.",
          "A letter writing by him.",
        ],
        correctIndex: 1,
        explanation: "Continuous 'is writing' -> 'is BEING written'.",
        imagePath: '${assetPath}voice_reference_square.webp',
        imageFit: BoxFit.contain,
      ),

      // Slide 10  Speaking Practice
      LessonSpeakingPractice(
        title: "Speaking Practice",
        imagePath: '${assetPath}phrasal_speaking_square.webp',
        prompts: [
          "Dosa is eaten by Ravi.",
          "The room was cleaned by Mom.",
          "Cricket is played by them.",
        ],
        summaryPoints: [
          "Object first",
          "Add BE verb",
          "Use V3 (Past Participle)",
          "Add 'by' doer (optional)",
        ],
        imageFit: BoxFit.contain,
      ),
    ];
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('preferred_language') ?? 'Tamil';
    if (mounted) {
      setState(() {
        _preferredLanguage = lang;
        _isLoading = false;
      });
    }
  }

  Future<void> _completeLesson() async {
    SoundService().playCompletion();

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lesson_12_active_passive_completed', true);

    // Save to Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lessons')
          .doc('lesson_12_active_passive')
          .set({
            'completed': true,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 60,
                color: Colors.amberAccent,
              ),
              SizedBox(height: 10),
              Text("Lesson Mastered!", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            "You can now flip sentences from Active to Passive!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Return to menu with result
              },
              child: const Text(
                "Awesome!",
                style: TextStyle(color: Colors.cyanAccent, fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_lessonCompleted || _storyComplete) {
      return true;
    }
    if (_currentIndex < 1) {
      return true;
    }
    return (await showGeneralDialog<bool>(
          context: context,
          pageBuilder: (context, animation, secondaryAnimation) {
            return ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
              ),
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
                        size: 60,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Leave Lesson?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Progress will be lost.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                              onPressed: () => Navigator.of(context).pop(false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
        )) ??
        false;
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

    // Show story complete screen
    if (_storyComplete) {
      return _buildStoryCompleteScreen();
    }

    // Show final quiz
    if (_showFinalQuiz) {
      return _buildFinalQuizPage();
    }

    // Show completion page
    if (_lessonCompleted) {
      return _buildCompletionPage();
    }

    // Show normal slides
    final progress = (_currentIndex + 1) / _slides.length;

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
              // Header
              _buildHeader(progress),

              // Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                      _selectedQuizIndex = null;
                      _isQuizCorrect = false;
                      _showQuizFeedback = false;
                    });

                    // If reached last slide, show story complete screen
                    if (index == _slides.length - 1) {
                      Future.delayed(const Duration(milliseconds: 800), () {
                        if (mounted) {
                          setState(() {
                            _storyComplete = true;
                          });
                        }
                      });
                    }
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _buildSlideContent(_slides[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () async {
                  if (await _onWillPop() && mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
              Text(
                "Active & Passive (${_currentIndex + 1}/${_slides.length})",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showTranslation = !_showTranslation;
                  });
                },
                icon: Icon(
                  _showTranslation ? Icons.translate : Icons.translate_outlined,
                  color: Colors.cyanAccent,
                  size: 20,
                ),
                label: const Text(
                  '',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              color: Colors.cyanAccent,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideContent(LessonUnit slide) {
    Key key = ValueKey(_currentIndex);
    if (slide is LessonSlide) {
      return _buildStandardSlide(slide, key);
    } else if (slide is LessonQuizInteraction) {
      return _buildQuizSlide(slide, key);
    } else if (slide is LessonSpeakingPractice) {
      return _buildSpeakingSlide(slide, key);
    }
    return const SizedBox.shrink();
  }

  Widget _buildStandardSlide(LessonSlide slide, Key key) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            padding: const EdgeInsets.all(12),
            child: SlideTransition(
              position: _slideAnimation,
              child: LessonImage(
                lessonId: 'active_passive',
                imageName: slide.imagePath.split('/').last,
                fallbackAssetPath: slide.imagePath,
                fit: slide.imageFit ?? BoxFit.contain,
              ).animate().fadeIn(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.title,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  slide.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
                if (_showTranslation) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      _preferredLanguage == 'Hindi'
                          ? slide.hindiContent
                          : slide.tamilContent,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ).animate().fadeIn(),
                ],
                if (slide.formula != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: Text(
                      "Rule: ${slide.formula}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizSlide(LessonQuizInteraction slide, Key key) {
    return Column(
      key: key,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20),
            ),
            child: LessonImage(
              lessonId: 'active_passive',
              imageName: slide.imagePath.split('/').last,
              fallbackAssetPath: slide.imagePath,
              fit: slide.imageFit ?? BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          slide.title,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          slide.question,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(slide.options.length, (index) {
          final isSelected = _selectedQuizIndex == index;
          final isCorrect = index == slide.correctIndex;
          Color bgColor = Colors.white10;
          Color borderColor = Colors.white24;

          if (_showQuizFeedback) {
            if (isCorrect) {
              bgColor = Colors.greenAccent.withValues(alpha: 0.2);
              borderColor = Colors.greenAccent;
            } else if (isSelected && !isCorrect) {
              bgColor = Colors.redAccent.withValues(alpha: 0.2);
              borderColor = Colors.redAccent;
            }
          } else if (isSelected) {
            bgColor = Colors.cyanAccent.withValues(alpha: 0.2);
            borderColor = Colors.cyanAccent;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: _showQuizFeedback
                  ? null
                  : () {
                      setState(() {
                        _selectedQuizIndex = index;
                        _showQuizFeedback = true;
                        _isQuizCorrect = (index == slide.correctIndex);
                        if (_isQuizCorrect) {
                          SoundService().playCorrect();
                        } else {
                          SoundService().playWrong();
                        }
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Text(
                      String.fromCharCode(65 + index), // A, B, C...
                      style: TextStyle(
                        color: borderColor == Colors.white24
                            ? Colors.white54
                            : borderColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        slide.options[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (_showQuizFeedback && isCorrect)
                      const Icon(Icons.check_circle, color: Colors.greenAccent),
                    if (_showQuizFeedback && isSelected && !isCorrect)
                      const Icon(Icons.cancel, color: Colors.redAccent),
                  ],
                ),
              ),
            ),
          );
        }),
        if (_showQuizFeedback)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isQuizCorrect
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _isQuizCorrect
                  ? "Correct! ${slide.explanation}"
                  : "Incorrect. ${slide.explanation}",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isQuizCorrect ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ).animate().fadeIn(),
      ],
    );
  }

  Widget _buildSpeakingSlide(LessonSpeakingPractice slide, Key key) {
    return SingleChildScrollView(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: LessonImage(
              lessonId: 'active_passive',
              imageName: slide.imagePath.split('/').last,
              fallbackAssetPath: slide.imagePath,
              fit: slide.imageFit ?? BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            slide.title,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Speaking Practice",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Read each sentence out loud.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const SizedBox(height: 12),
                const LessonSpeakingPracticePanel(),
                const SizedBox(height: 12),
                ...slide.prompts.map(
                  (prompt) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          color: Colors.white54,
                          size: 10,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            prompt,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Key Points:",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...slide.summaryPoints.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: Colors.cyanAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStoryCompleteScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F172A)
          : Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                      Icons.check_circle_outline,
                      size: 100,
                      color: Color(0xFF4FACFE),
                    )
                    .animate()
                    .fade(duration: 500.ms)
                    .scale(duration: 500.ms, curve: Curves.elasticOut),

                const SizedBox(height: 32),

                const Text(
                  "Well done!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                const Text(
                  "Story complete. Take the quiz to master it.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showFinalQuiz = true;
                        _storyComplete = false;
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _storyComplete = false;
                      _currentIndex = 0;
                    });
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(0);
                      }
                    });
                    SoundService().playTap();
                  },
                  child: const Text(
                    "Review Story",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalQuizPage() {
    final currentQuestion = _finalQuizQuestions[_finalQuizIndex];
    final progress = (_finalQuizIndex + 1) / _finalQuizQuestions.length;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F172A)
          : Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Quiz Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () {
                          setState(() {
                            _showFinalQuiz = false;
                            _finalQuizIndex = 0;
                            _finalQuizScore = 0;
                            _selectedFinalQuizOption = null;
                            _showFinalQuizFeedback = false;
                          });
                        },
                      ),
                      Text(
                        "Quiz ${_finalQuizIndex + 1}/${_finalQuizQuestions.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
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
                      Text(
                        "Score: $_finalQuizScore",
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white10,
                      color: Colors.cyanAccent,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // Quiz Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        currentQuestion['question'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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
                              ? (currentQuestion['question_hindi'] ?? "")
                              : (currentQuestion['question_tamil'] ?? ""),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                    ],
                    const SizedBox(height: 30),
                    ...List.generate(currentQuestion['options'].length, (
                      index,
                    ) {
                      final isSelected = _selectedFinalQuizOption == index;
                      final isCorrect = index == currentQuestion['correct'];
                      Color bgColor = Colors.white10;
                      Color borderColor = Colors.white24;

                      if (_showFinalQuizFeedback) {
                        if (isCorrect) {
                          bgColor = Colors.greenAccent.withValues(alpha: 0.2);
                          borderColor = Colors.greenAccent;
                        } else if (isSelected && !isCorrect) {
                          bgColor = Colors.redAccent.withValues(alpha: 0.2);
                          borderColor = Colors.redAccent;
                        }
                      } else if (isSelected) {
                        bgColor = Colors.cyanAccent.withValues(alpha: 0.2);
                        borderColor = Colors.cyanAccent;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: _showFinalQuizFeedback
                              ? null
                              : () {
                                  setState(() {
                                    _selectedFinalQuizOption = index;
                                    _showFinalQuizFeedback = true;
                                    if (isCorrect) {
                                      _finalQuizScore++;
                                      SoundService().playCorrect();
                                    } else {
                                      SoundService().playWrong();
                                    }
                                  });
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: borderColor.withValues(alpha: 0.2),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index),
                                      style: TextStyle(
                                        color: borderColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    currentQuestion['options'][index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (_showFinalQuizFeedback && isCorrect)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.greenAccent,
                                    size: 24,
                                  ),
                                if (_showFinalQuizFeedback &&
                                    isSelected &&
                                    !isCorrect)
                                  const Icon(
                                    Icons.cancel,
                                    color: Colors.redAccent,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    if (_showFinalQuizFeedback) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              _selectedFinalQuizOption ==
                                  currentQuestion['correct']
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _selectedFinalQuizOption ==
                                    currentQuestion['correct']
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedFinalQuizOption ==
                                      currentQuestion['correct']
                                  ? Icons.check_circle
                                  : Icons.info,
                              color:
                                  _selectedFinalQuizOption ==
                                      currentQuestion['correct']
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currentQuestion['explanation'],
                              style: TextStyle(
                                color:
                                    _selectedFinalQuizOption ==
                                        currentQuestion['correct']
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(),
                    ],
                  ],
                ),
              ),
            ),

            // Next Button
            if (_showFinalQuizFeedback)
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () {
                    if (_finalQuizIndex < _finalQuizQuestions.length - 1) {
                      setState(() {
                        _finalQuizIndex++;
                        _selectedFinalQuizOption = null;
                        _showFinalQuizFeedback = false;
                      });
                    } else {
                      setState(() {
                        _lessonCompleted = true;
                      });
                    }
                    setState(() {
                      _showTranslation = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _finalQuizIndex < _finalQuizQuestions.length - 1
                        ? "Next Question"
                        : "See Results",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionPage() {
    final passingScore = (_finalQuizQuestions.length * 0.7).ceil();
    final passed = _finalQuizScore >= passingScore;

    if (passed && !_completionSaved) {
      _completionSaved = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _completeLesson();
        }
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F172A)
          : Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.3),
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 20),
              ],
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
                  "You scored $_finalQuizScore / ${_finalQuizQuestions.length}",
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                              _showFinalQuiz = true;
                              _lessonCompleted = false;
                              _finalQuizIndex = 0;
                              _finalQuizScore = 0;
                              _selectedFinalQuizOption = null;
                              _showFinalQuizFeedback = false;
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
        ),
      ),
    );
  }
}
