import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_image.dart';
import 'package:gravity_app/widgets/language_toggle_icon.dart';
import 'package:gravity_app/widgets/glass_ui.dart';
import 'package:gravity_app/services/speech_recognition_service.dart';
import 'package:gravity_app/services/active_route_service.dart';
import 'package:gravity_app/core/theme/app_colors.dart';

class LessonScaffold extends StatefulWidget {
  final String lessonId;
  final String title;
  final List<LessonUnit> slides;
  final List<Map<String, dynamic>> quizQuestions;
  final String assetPath;
  final String progressBaseKey;
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const LessonScaffold({
    super.key,
    required this.lessonId,
    required this.title,
    required this.slides,
    required this.quizQuestions,
    required this.assetPath,
    required this.progressBaseKey,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  });

  @override
  State<LessonScaffold> createState() => _LessonScaffoldState();
}

class _LessonScaffoldState extends State<LessonScaffold>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  int _currentIndex = 0;
  late final PageController _pageController;

  bool _showCompletion = false;
  bool _storyCompleted = false;
  bool _showQuiz = false;
  bool _showResults = false;
  bool _isReEntryLanding = false;

  late AnimationController _hintAnimationController;
  late Animation<Offset> _slideAnimation;
  bool _hasShownHint = false;

  String _preferredLanguage = 'Tamil';
  bool _showTranslation = false;

  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answerSelected = false;
  int? _selectedOptionIndex;

  bool _isListening = false;
  bool _hasSpoken = false;
  String _spokenText = '';
  int _speechSessionId = 0;

  @override
  void initState() {
    super.initState();
    final maxStoryIndex = widget.slides.isNotEmpty ? widget.slides.length : 0;
    _currentIndex = widget.initialStoryIndex.clamp(0, maxStoryIndex).toInt();
    final maxQuizIndex = widget.quizQuestions.isNotEmpty
        ? widget.quizQuestions.length - 1
        : 0;
    _currentQuestionIndex = widget.initialQuizIndex
        .clamp(0, maxQuizIndex)
        .toInt();
    _showQuiz = widget.initialMode == 'quiz';
    _pageController = PageController(initialPage: _currentIndex);
    _loadProgress();

    _hintAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-0.12, 0)).animate(
          CurvedAnimation(
            parent: _hintAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _checkAndPlayHint();
  }

  @override
  void dispose() {
    SpeechRecognitionService.stop();
    _hintAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _ensureMicPermission() async {
    if (await SpeechRecognitionService.hasPermission()) return true;
    final granted = await SpeechRecognitionService.requestPermission();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for speaking.'),
        ),
      );
    }
    return granted;
  }

  Future<void> _toggleSpeaking() async {
    if (_isListening) {
      await SpeechRecognitionService.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    final hasPermission = await _ensureMicPermission();
    if (!hasPermission) return;

    final sessionId = ++_speechSessionId;
    setState(() {
      _isListening = true;
      _spokenText = '';
      _hasSpoken = false;
    });

    final result = await SpeechRecognitionService.listen(
      timeout: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      onPartialResult: (partial) {
        if (!mounted || sessionId != _speechSessionId) return;
        setState(() => _spokenText = partial);
      },
    );

    if (!mounted || sessionId != _speechSessionId) return;

    setState(() {
      _isListening = false;
      if (result != null && result.trim().isNotEmpty) {
        _spokenText = result.trim();
        _hasSpoken = true;
      }
    });

    if ((result == null || result.trim().isEmpty) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No speech detected. Tap to try again.')),
      );
    }
  }

  Future<void> _checkAndPlayHint() async {
    final prefs = await SharedPreferences.getInstance();
    final hintKey = 'has_seen_swipe_hint_${widget.progressBaseKey}';
    final hasSeenHint = prefs.getBool(hintKey) ?? false;

    if (!hasSeenHint && mounted) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        await _precacheSlideImage(1);
        await _hintAnimationController.forward();
        await Future.delayed(const Duration(milliseconds: 120));
        await _hintAnimationController.reverse();
        await prefs.setBool(hintKey, true);
        setState(() => _hasShownHint = true);
      }
    } else {
      setState(() => _hasShownHint = true);
    }
  }

  Future<void> _saveActiveState({
    required String type,
    required int index,
  }) async {
    await ActiveRouteService.save(
      lessonId: widget.lessonId,
      index: index,
      type: type,
    );
  }

  Future<void> _clearActiveState() async {
    await ActiveRouteService.clear();
  }

  String? _extractUnitImagePath(LessonUnit unit) {
    if (unit is LessonSlide) return unit.imagePath;
    if (unit is LessonHighlightInteraction) return unit.imagePath;
    if (unit is LessonQuizInteraction) return unit.imagePath;
    if (unit is LessonSpeakingPractice) return unit.imagePath;
    return null;
  }

  Future<void> _precacheSlideImage(int index) async {
    if (!mounted || index < 0 || index >= widget.slides.length) return;

    final imagePath = _extractUnitImagePath(widget.slides[index]);
    if (imagePath == null || imagePath.isEmpty) return;

    final fallbackAssetPath = imagePath.startsWith('assets/')
        ? imagePath
        : '${widget.assetPath}$imagePath';

    final providers = await LessonImage.buildPrecacheProviders(
      lessonId: widget.lessonId,
      imageName: imagePath,
      fallbackAssetPath: fallbackAssetPath,
    );
    if (!mounted) return;

    for (final provider in providers) {
      if (!mounted) return;
      try {
        await precacheImage(
          provider,
          context,
        ).timeout(const Duration(milliseconds: 1600));
        return;
      } catch (_) {
        // Try the next source.
      }
    }
  }

  Future<void> _precacheInitialStoryWindow() async {
    if (_showQuiz || _showCompletion || _isReEntryLanding) return;
    if (widget.slides.isEmpty) return;

    final startIndex = _currentIndex.clamp(0, widget.slides.length - 1);
    final endIndex = (startIndex + 2).clamp(0, widget.slides.length - 1);

    for (int i = startIndex; i <= endIndex; i++) {
      if (!mounted) return;
      await _precacheSlideImage(i);
    }
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
      }
    }
    _preferredLanguage = lang ?? 'Tamil';

    bool storyDone =
        prefs.getBool('${widget.progressBaseKey}_story_completed') ?? false;
    bool quizDone =
        prefs.getBool('${widget.progressBaseKey}_quiz_completed') ?? false;

    if (mounted) {
      setState(() {
        _storyCompleted = storyDone;

        if (widget.initialMode == 'quiz' && !quizDone) {
          _showQuiz = true;
          _showCompletion = false;
          _isReEntryLanding = false;
        } else if (quizDone) {
          _isReEntryLanding = true;
          _showCompletion = true;
        } else if (storyDone) {
          _showCompletion = true;
        }
      });
      if (_showQuiz) {
        _saveActiveState(type: 'quiz', index: _currentQuestionIndex);
      } else if (!_showResults) {
        _saveActiveState(type: 'story', index: _currentIndex);
      }
    }

    // Warm up current + next slides before first paint of story pages.
    try {
      await _precacheInitialStoryWindow().timeout(
        const Duration(milliseconds: 2600),
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
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
        await prefs.setBool('${widget.progressBaseKey}_story_completed', true);
      }
      if (quizCompleted) {
        await prefs.setBool('${widget.progressBaseKey}_quiz_completed', true);
        await prefs.setBool('${widget.progressBaseKey}_completed', true);
        if (score != null) {
          await prefs.setInt('${widget.progressBaseKey}_score', score);
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
            .doc(widget.lessonId)
            .set(data, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving lesson: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (_showResults ||
        _showCompletion ||
        _isReEntryLanding ||
        _storyCompleted) {
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
        final dialogTheme = Theme.of(context);
        return Transform.scale(
          scale: a1.value,
          child: Dialog(
            backgroundColor: dialogTheme.brightness == Brightness.dark
                ? AppColors.lessonPanel
                : dialogTheme.colorScheme.surface,
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
                            backgroundColor: AppColors.lessonAccent,
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
    if (shouldPop == true) {
      await _clearActiveState();
    }
    return shouldPop ?? false;
  }

  void _handleAnswer(int optionIndex) {
    if (_answerSelected) return;

    final correctIndex = widget.quizQuestions[_currentQuestionIndex]['correct'];
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
    if (_currentQuestionIndex < widget.quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answerSelected = false;
        _selectedOptionIndex = null;
        _showTranslation = false;
      });
      _saveActiveState(type: 'quiz', index: _currentQuestionIndex);
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    final passingScore = (widget.quizQuestions.length * 0.7).ceil();
    final passed = _score >= passingScore;
    if (passed) {
      _saveProgress(quizCompleted: true, score: _score);
    }
    setState(() {
      _showQuiz = false;
      _showResults = true;
    });
    if (passed) {
      SoundService().playCompletion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldBg = theme.brightness == Brightness.dark
        ? AppColors.darkSurface
        : theme.scaffoldBackgroundColor;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.lessonAccent),
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
        backgroundColor: scaffoldBg,
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
                        itemCount: widget.slides.length + 1,
                        padEnds: false,
                        onPageChanged: (index) {
                          if (_isListening) {
                            SpeechRecognitionService.stop();
                          }
                          setState(() {
                            _currentIndex = index;
                            _isListening = false;
                            _hasSpoken = false;
                            _spokenText = '';
                            _speechSessionId++;
                          });
                          _saveActiveState(type: 'story', index: index);
                          for (int offset = 1; offset <= 2; offset++) {
                            final nextIndex = index + offset;
                            if (nextIndex < widget.slides.length) {
                              _precacheSlideImage(nextIndex);
                            }
                          }
                          if (index == widget.slides.length) {
                            if (!_storyCompleted) {
                              _saveProgress(storyCompleted: true);
                              SoundService().playCompletion();
                              setState(() => _storyCompleted = true);
                            }
                          }
                        },
                        itemBuilder: (context, index) {
                          if (index == widget.slides.length) {
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
          Text(
            widget.title,
            style: const TextStyle(
              color: AppColors.lessonAccent,
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
                  : _currentIndex == widget.slides.length
                  ? "Success"
                  : "${_currentIndex + 1}/${widget.slides.length}",
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
    final progress = ((_currentIndex + 1) / widget.slides.length).clamp(
      0.0,
      1.0,
    );
    return Container(
      height: 2,
      decoration: const BoxDecoration(color: Color(0xFF1E293B)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.lessonAccent, Colors.cyan.shade300],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitAtIndex(int index) {
    if (index >= widget.slides.length) return const SizedBox.shrink();
    final unit = widget.slides[index];

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
                lessonId: widget.lessonId,
                imageName: slide.imagePath,
                fallbackAssetPath: '${widget.assetPath}${slide.imagePath}',
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
              color: AppColors.lessonPanel,
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
                            color: AppColors.lessonAccent,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (slide.tamilContent.isNotEmpty)
                        _buildTranslationToggle(),
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
    bool isRevealed = false;
    return StatefulBuilder(
      builder: (context, setLimitState) {
        return Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LessonImage(
                    lessonId: widget.lessonId,
                    imageName: unit.imagePath,
                    fallbackAssetPath: '${widget.assetPath}${unit.imagePath}',
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
                  color: AppColors.lessonPanel,
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
                              unit.title,
                              style: const TextStyle(
                                color: AppColors.lessonAccent,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (unit.tamilContent.isNotEmpty)
                            _buildTranslationToggle(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        unit.introText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_showTranslation)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            _preferredLanguage == 'Hindi'
                                ? unit.hindiContent
                                : unit.tamilContent,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ).animate().fadeIn(),
                        ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          setLimitState(() => isRevealed = true);
                          SoundService().playCorrect();
                        },
                        child: AnimatedContainer(
                          duration: 300.ms,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRevealed
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.cyan.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRevealed
                                  ? Colors.green
                                  : AppColors.lessonAccent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Show Rule",
                                style: TextStyle(
                                  color: isRevealed
                                      ? Colors.greenAccent
                                      : AppColors.lessonAccent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (isRevealed) ...[
                                const SizedBox(height: 12),
                                ...unit.highlightItems.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item,
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        unit.exampleText,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
                      lessonId: widget.lessonId,
                      imageName: unit.imagePath,
                      fallbackAssetPath: '${widget.assetPath}${unit.imagePath}',
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
              color: AppColors.lessonPanel,
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
                            } else {
                              SoundService().playWrong();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: AppColors.lessonAccent.withValues(
                                  alpha: 0.3,
                                ),
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
    final showTranscript =
        _isListening || _hasSpoken || _spokenText.trim().isNotEmpty;
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
                lessonId: widget.lessonId,
                imageName: unit.imagePath,
                fallbackAssetPath: '${widget.assetPath}${unit.imagePath}',
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
              color: AppColors.lessonPanel,
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
                  Center(
                    child:
                        GestureDetector(
                              onTap: _toggleSpeaking,
                              child: AnimatedContainer(
                                duration: 300.ms,
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isListening
                                      ? Colors.redAccent
                                      : AppColors.lessonAccent,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (_isListening
                                                  ? Colors.redAccent
                                                  : AppColors.lessonAccent)
                                              .withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      spreadRadius: _isListening ? 10 : 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isListening ? Icons.stop : Icons.mic,
                                  color: Colors.black,
                                  size: 40,
                                ),
                              ),
                            )
                            .animate(target: _isListening ? 1 : 0)
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.1, 1.1),
                            ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isListening
                        ? "Listening..."
                        : (_hasSpoken ? "Captured" : "Tap to Speak"),
                    style: TextStyle(
                      color: _hasSpoken ? Colors.greenAccent : Colors.white54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (showTranscript)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Live Transcript",
                            style: TextStyle(
                              color: AppColors.lessonAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _spokenText.isNotEmpty
                                ? "\"$_spokenText\""
                                : "Listening...",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!showTranscript && unit.summaryPoints.isNotEmpty) ...[
                    const SizedBox(height: 8),
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showTranslation = !_showTranslation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _showTranslation
              ? AppColors.lessonAccent.withValues(alpha: 0.2)
              : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _showTranslation ? AppColors.lessonAccent : Colors.white24,
          ),
        ),
        child: LanguageToggleIcon(
          language: _preferredLanguage,
          isActive: _showTranslation,
          activeColor: AppColors.lessonAccent,
          inactiveColor: Colors.white54,
          size: 13,
        ),
      ),
    );
  }

  Widget _buildQuizScreen() {
    final question = widget.quizQuestions[_currentQuestionIndex];
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.lessonPanel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.lessonAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Question ${_currentQuestionIndex + 1} / ${widget.quizQuestions.length}",
                    style: const TextStyle(
                      color: AppColors.lessonAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => _showTranslation = !_showTranslation),
                    icon: LanguageToggleIcon(
                      language: _preferredLanguage,
                      isActive: _showTranslation,
                      activeColor: AppColors.lessonAccent,
                      inactiveColor: Colors.white54,
                      size: 16,
                    ),
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
                Text(
                  _preferredLanguage == 'Hindi'
                      ? (question['question_hindi'] ?? "")
                      : (question['question_tamil'] ?? ""),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.lessonAccent,
                    fontSize: 18,
                  ),
                ).animate().fadeIn(),
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
              Color bgColor = AppColors.lessonPanel;
              Color borderColor = Colors.white10;
              if (showColor) {
                bgColor = isCorrect
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2);
                borderColor = isCorrect ? Colors.green : Colors.red;
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
                    child: Text(
                      question['options'][index],
                      style: const TextStyle(color: Colors.white, fontSize: 18),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = widget.quizQuestions.length;
    final passed = _score >= (total * 0.7).ceil();
    final percentage = total > 0 ? (_score / total) * 100 : 0;
    final level = percentage >= 80
        ? 'Advanced'
        : percentage >= 70
        ? 'Intermediate'
        : 'Beginner';
    final levelColor = percentage >= 80
        ? Colors.amber
        : percentage >= 70
        ? AppColors.lessonAccent
        : Colors.orangeAccent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: GlassPanel(
            borderRadius: BorderRadius.circular(30),
            borderColor: passed
                ? Colors.amber.withValues(alpha: 0.45)
                : scheme.primary.withValues(alpha: 0.36),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  (passed ? Colors.amber : scheme.primary).withValues(
                    alpha: 0.17,
                  ),
                  scheme.surface.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.7 : 0.9,
                  ),
                ),
                scheme.surfaceContainerHighest.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.42 : 0.72,
                ),
              ],
            ),
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                  size: 80,
                  color: passed ? Colors.amber : Colors.orangeAccent,
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                Text(
                  passed ? "Lesson Mastered!" : "Try Again",
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color ?? Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "You scored $_score / $total",
                  style: TextStyle(
                    color: passed
                        ? Colors.greenAccent
                        : theme.textTheme.bodyLarge?.color?.withValues(
                            alpha: 0.84,
                          ),
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: levelColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    "Level: $level",
                    style: TextStyle(
                      color: levelColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: GradientActionButton(
                    onPressed: () async {
                      await _clearActiveState();
                      if (!mounted) return;
                      Navigator.pop(context, true);
                    },
                    colors: passed
                        ? const [Color(0xFFFFC857), Color(0xFFFF9F43)]
                        : [scheme.primary, scheme.secondary],
                    child: Text(
                      "Finish Lesson",
                      style: TextStyle(
                        color: passed ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!passed)
                  Row(
                    children: [
                      Expanded(
                        child: GradientActionButton(
                          onPressed: () {
                            setState(() {
                              _showResults = false;
                              _showQuiz = true;
                              _score = 0;
                              _currentQuestionIndex = 0;
                              _answerSelected = false;
                              _selectedOptionIndex = null;
                            });
                            _saveActiveState(
                              type: 'quiz',
                              index: _currentQuestionIndex,
                            );
                          },
                          child: const Text(
                            "Retake Quiz",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassGhostButton(
                          onPressed: () {
                            setState(() {
                              _showResults = false;
                              _showQuiz = false;
                              _showCompletion = false;
                              _isReEntryLanding = false;
                              _currentIndex = 0;
                            });
                            _saveActiveState(type: 'story', index: 0);
                            Future.delayed(
                              const Duration(milliseconds: 50),
                              () {
                                if (_pageController.hasClients) {
                                  _pageController.jumpToPage(0);
                                }
                              },
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh_rounded, size: 18),
                              SizedBox(width: 8),
                              Text("Review Story"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                if (passed) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: GlassGhostButton(
                      onPressed: () {
                        setState(() {
                          _showResults = false;
                          _showQuiz = false;
                          _showCompletion = false;
                          _isReEntryLanding = false;
                          _currentIndex = 0;
                        });
                        _saveActiveState(type: 'story', index: 0);
                        Future.delayed(const Duration(milliseconds: 50), () {
                          if (_pageController.hasClients) {
                            _pageController.jumpToPage(0);
                          }
                        });
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 20),
                          SizedBox(width: 8),
                          Text("Review Story"),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCompleteScreen() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: GlassPanel(
            borderRadius: BorderRadius.circular(30),
            borderColor: scheme.primary.withValues(alpha: 0.38),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.17),
                  scheme.surface.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.7 : 0.9,
                  ),
                ),
                scheme.surfaceContainerHighest.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.43 : 0.72,
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 80,
                  color: Colors.amberAccent,
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                Text(
                  "Well done!",
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color ?? Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "You've finished the lesson story.\nYou're ready for the quiz!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.8,
                        ) ??
                        Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: GradientActionButton(
                    onPressed: () {
                      setState(() => _showQuiz = true);
                      _saveActiveState(
                        type: 'quiz',
                        index: _currentQuestionIndex,
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
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
                  child: GlassGhostButton(
                    onPressed: () {
                      setState(() {
                        _showCompletion = false;
                        _isReEntryLanding = false;
                        _currentIndex = 0;
                      });
                      _saveActiveState(type: 'story', index: 0);
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (_pageController.hasClients) {
                          _pageController.jumpToPage(0);
                        }
                      });
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded),
                        SizedBox(width: 8),
                        Text(
                          "Review Story",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    await _clearActiveState();
                    if (!mounted) return;
                    Navigator.pop(context, true);
                  },
                  child: Text(
                    "Return to Menu",
                    style: TextStyle(
                      color:
                          theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.65,
                          ) ??
                          Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
