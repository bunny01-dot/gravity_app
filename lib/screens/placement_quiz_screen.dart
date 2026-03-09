import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/widgets/modern_glass_dialog.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/services/sfx/sfx_manager.dart';
import 'package:gravity_app/services/sfx/sfx_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/widgets/space_dust_background.dart';
import 'package:gravity_app/services/placement_state_service.dart';
import 'package:gravity_app/dashboard.dart';

class PlacementQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String section; // 'Beginner', 'Intermediate', 'Advanced'

  PlacementQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.section,
  });
}

class PlacementQuizScreen extends StatefulWidget {
  final bool isFirstTime;

  const PlacementQuizScreen({
    super.key,
    this.isFirstTime = false, // Default to false for backwards compatibility
  });

  @override
  State<PlacementQuizScreen> createState() => _PlacementQuizScreenState();
}

class _PlacementQuizScreenState extends State<PlacementQuizScreen>
    with WidgetsBindingObserver {
  final DataService _dataService = DataService();
  int _currentIndex = 0;
  final Map<int, int> _userAnswers = {}; // index -> selectedOptionIndex
  bool _isAnswered = false;
  bool _allowExit = false;
  bool _isCompletingQuiz = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProgress();
    _setupSfx();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveProgress();
    }
  }

  Future<void> _setupSfx() async {
    // Force specific sound mappings for the quiz to match user request
    await SfxManager().mapActionToSound(SfxAction.answerCorrect, 'crisp_click');
    await SfxManager().mapActionToSound(SfxAction.answerWrong, 'wrong_soft');
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt('placement_quiz_current_index');
      final savedAnswersJson = prefs.getString('placement_quiz_answers');

      if (savedIndex != null || savedAnswersJson != null) {
        if (!mounted) return;
        setState(() {
          if (savedIndex != null && savedIndex < _questions.length) {
            _currentIndex = savedIndex;
          }
          if (savedAnswersJson != null) {
            final Map<String, dynamic> decoded = jsonDecode(savedAnswersJson);
            decoded.forEach((key, value) {
              _userAnswers[int.parse(key)] = value as int;
            });
          }
          _isAnswered = _userAnswers.containsKey(_currentIndex);
        });
        debugPrint(
          " Placement Quiz: Restored progress at index $_currentIndex",
        );

        // Recovery guard: if app closed right after answering final question,
        // auto-finish so user doesn't get stuck on the last question.
        final atLastQuestion = _currentIndex == _questions.length - 1;
        final hasCurrentAnswer = _userAnswers.containsKey(_currentIndex);
        if (atLastQuestion && hasCurrentAnswer) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _completeQuiz();
          });
        }
      }
    } catch (e) {
      debugPrint("Error: Error loading placement quiz progress: $e");
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('placement_quiz_current_index', _currentIndex);

      // Convert Map<int, int> to Map<String, int> for JSON
      final mapToSave = _userAnswers.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      await prefs.setString('placement_quiz_answers', jsonEncode(mapToSave));
    } catch (e) {
      debugPrint("Error: Error saving placement quiz progress: $e");
    }
  }

  Future<void> _clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('placement_quiz_current_index');
      await prefs.remove('placement_quiz_answers');
      debugPrint("[CLEAN] Placement Quiz: Local progress cleared");
    } catch (e) {
      debugPrint("Error: Error clearing placement quiz progress: $e");
    }
  }

  final List<PlacementQuestion> _questions = [
    // --- SECTION 1: BEGINNER (1-9) ---
    PlacementQuestion(
      question: "Which sentence is correct?",
      options: [
        "She don't like apples.",
        "She doesn't like apples.",
        "She not like apples.",
        "She isn't likes apples.",
      ],
      correctIndex: 1,
      section: 'Beginner',
    ),
    PlacementQuestion(
      question: "I saw ___ airplane in the sky.",
      options: ["the", "an", "a", "(no article)"],
      correctIndex: 1,
      section: 'Beginner',
    ),
    PlacementQuestion(
      question: "My brother ___ video games every weekend.",
      options: ["plays", "playing", "play", "is play"],
      correctIndex: 0,
      section: 'Beginner',
    ),
    PlacementQuestion(
      question: "In \"The fast car won the race\", 'fast' is a:",
      options: ["Noun", "Verb", "Adverb", "Adjective"],
      correctIndex: 3,
      section: 'Beginner',
    ),
    PlacementQuestion(
      question: "The cat is hiding ___ the table.",
      options: ["of", "under", "in", "at"],
      correctIndex: 1,
      section: 'Beginner',
    ),
    PlacementQuestion(
      question: "Yesterday, we ___ to the park.",
      options: ["went", "goes", "go", "gone"],
      correctIndex: 0,
      section: 'Beginner',
    ),
    PlacementQuestion(
      question: "Plural of child:",
      options: ["childs", "childrens", "childer", "children"],
      correctIndex: 3,
      section: 'Beginner',
    ),
    PlacementQuestion(
      question: "Opposite of difficult:",
      options: ["hard", "easy", "heavy", "soft"],
      correctIndex: 1,
      section: 'Beginner',
    ),
    PlacementQuestion(
      question: "Please give the book to ___.",
      options: ["I", "me", "my", "mine"],
      correctIndex: 1,
      section: 'Beginner',
    ),

    // --- SECTION 2: INTERMEDIATE (10-18) ---
    PlacementQuestion(
      question: "You ___ smoke here. It's forbidden.",
      options: ["must not", "don't have to", "might not", "couldn't"],
      correctIndex: 0,
      section: 'Intermediate',
    ),
    PlacementQuestion(
      question: "Look at those clouds! It ___ rain.",
      options: ["will", "shall", "rains", "is going to"],
      correctIndex: 3,
      section: 'Intermediate',
    ),
    PlacementQuestion(
      question: "This problem is ___ than the last one.",
      options: [
        "complicateder",
        "more complicated",
        "most complicated",
        "as complicated",
      ],
      correctIndex: 1,
      section: 'Intermediate',
    ),
    PlacementQuestion(
      question: "I wanted to buy it, ___ it was too expensive.",
      options: ["or", "but", "so", "because"],
      correctIndex: 1,
      section: 'Intermediate',
    ),
    PlacementQuestion(
      question: "He speaks English very ___.",
      options: ["well", "good", "best", "nice"],
      correctIndex: 0,
      section: 'Intermediate',
    ),
    PlacementQuestion(
      question: "She enjoys ___ books.",
      options: ["read", "to read", "reads", "reading"],
      correctIndex: 3,
      section: 'Intermediate',
    ),
    PlacementQuestion(
      question: "The telephone ___ by Bell.",
      options: ["invented", "was invented", "is invented", "has invent"],
      correctIndex: 1,
      section: 'Intermediate',
    ),
    PlacementQuestion(
      question: "What does this sentence mean? \"I might come later.\"",
      options: [
        "I am unsure",
        "I will definitely come",
        "I am refusing",
        "I already came",
      ],
      correctIndex: 0,
      section: 'Intermediate',
    ),
    PlacementQuestion(
      question: "If it rains, we ___ the picnic.",
      options: ["cancel", "would cancel", "cancelled", "will cancel"],
      correctIndex: 3,
      section: 'Intermediate',
    ),

    // --- SECTION 3: ADVANCED (19-25) ---
    PlacementQuestion(
      question: "If I ___ you, I would accept the offer.",
      options: ["am", "were", "was", "have been"],
      correctIndex: 1,
      section: 'Advanced',
    ),
    PlacementQuestion(
      question: "By the time we arrive, the movie ___.",
      options: [
        "will have started",
        "will start",
        "has starting",
        "is starting",
      ],
      correctIndex: 0,
      section: 'Advanced',
    ),
    PlacementQuestion(
      question: "He said, \"I'm busy now.\"",
      options: [
        "He said he is busy now.",
        "He said he was busy now.",
        "He said I am busy then.",
        "He said he was busy then.",
      ],
      correctIndex: 3,
      section: 'Advanced',
    ),
    PlacementQuestion(
      question: "The artist, ___ paintings are famous, lives here.",
      options: ["who", "whose", "whom", "which"],
      correctIndex: 1,
      section: 'Advanced',
    ),
    PlacementQuestion(
      question: "\"To sit on the fence\" means:",
      options: [
        "to be undecided",
        "to be lazy",
        "to be unsafe",
        "to be relaxed",
      ],
      correctIndex: 0,
      section: 'Advanced',
    ),
    PlacementQuestion(
      question: "Ambiguous means:",
      options: ["clear", "detailed", "wrong", "unclear / multiple meanings"],
      correctIndex: 3,
      section: 'Advanced',
    ),
    PlacementQuestion(
      question:
          "Ravi read the message twice. It sounded polite, but the tone made him uneasy. What can we infer?",
      options: [
        "Ravi is happy",
        "The message is informal",
        "Ravi senses hidden concern",
        "The message is confusing",
      ],
      correctIndex: 2,
      section: 'Advanced',
    ),
  ];

  void _handleAnswer(int optionIndex) {
    // Determine correctness for immediate SFX feedback
    final currentQuestion = _questions[_currentIndex];
    final isCorrect = optionIndex == currentQuestion.correctIndex;

    if (isCorrect) {
      SoundService().playCorrect();
    } else {
      SoundService().playWrong();
    }

    setState(() {
      _userAnswers[_currentIndex] = optionIndex;
      _isAnswered = true;
    });

    _saveProgress(); // Save progress locally after each answer

    // Auto-advance with a delay so user can see the feedback
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        if (_currentIndex < _questions.length - 1) {
          setState(() {
            _currentIndex++;
            _isAnswered = _userAnswers.containsKey(_currentIndex);
          });
          _saveProgress(); // Save progress locally after advancing
        } else {
          _completeQuiz();
        }
      }
    });
  }

  Future<void> _completeQuiz() async {
    if (_isCompletingQuiz) return;
    _isCompletingQuiz = true;

    // 1. Calculate scores per section
    int beginnerCorrect = 0;
    int intermediateCorrect = 0;
    int advancedCorrect = 0;
    int totalScore = 0;

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final isCorrect = _userAnswers[i] == q.correctIndex;
      if (isCorrect) {
        totalScore++;
        if (q.section == 'Beginner') beginnerCorrect++;
        if (q.section == 'Intermediate') intermediateCorrect++;
        if (q.section == 'Advanced') advancedCorrect++;
      }
    }

    // 2. Evaluate placement decision
    // Requested behavior:
    // - 0..10   => Beginner
    // - 11..18  => Intermediate
    // - 19..25  => Advanced only if all section gates pass; else Intermediate
    String finalLevel = 'C';

    final passedBeginner = beginnerCorrect >= 6;
    final passedIntermediate = intermediateCorrect >= 6;
    final passedAdvanced = advancedCorrect >= 4;

    if (totalScore <= 10) {
      finalLevel = 'C';
    } else if (totalScore <= 18) {
      finalLevel = 'B';
    } else if (passedBeginner && passedIntermediate && passedAdvanced) {
      finalLevel = 'A';
    } else {
      finalLevel = 'B';
    }

    debugPrint(
      'Placement result -> score: $totalScore/${_questions.length}, '
      'beginner: $beginnerCorrect, intermediate: $intermediateCorrect, '
      'advanced: $advancedCorrect, levelCode: $finalLevel',
    );

    // 3. Save Placement Result (best-effort; don't block result UI on cloud errors)
    try {
      await _dataService.savePlacementResult(finalLevel, totalScore);
    } catch (e) {
      debugPrint('Error: Placement save failed (continuing locally): $e');
    }

    // 4. Save completion flags (CRITICAL for onboarding flow)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('placement_score', totalScore);
      final mappedLevel = PlacementStateService.mapPlacementCodeToUserLevel(
        finalLevel,
      );
      await PlacementStateService.markCompleted(
        userLevel: mappedLevel,
        placementCode: finalLevel,
      );

      // 5. Clear local quiz progress
      await _clearProgress();
    } catch (e) {
      debugPrint('Error: Placement completion flag save failed: $e');
    } finally {
      if (mounted) {
        setState(() => _allowExit = true);
        _showResultDialog(finalLevel, totalScore);
      }
      _isCompletingQuiz = false;
    }
  }

  void _showResultDialog(String level, int score) {
    String levelName = level == 'A'
        ? "Advanced"
        : (level == 'B' ? "Intermediate" : "Beginner");
    String message =
        "Congratulations! Your score: $score/${_questions.length}. "
        "Based on your performance, you have been placed in the $levelName level.";

    showModernDialog(
      context,
      title: "Quiz Completed!",
      message: message,
      icon: Icons.emoji_events_rounded,
      primaryButtonText: widget.isFirstTime ? "Continue to Dashboard" : "Close",
      onPrimaryPressed: () {
        Navigator.of(context, rootNavigator: true).pop(); // Close dialog

        if (!mounted) return;

        if (widget.isFirstTime) {
          // Navigate to Dashboard (replacing the entire stack)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        } else {
          // Close the quiz if possible; otherwise fallback to dashboard
          if (Navigator.of(context).canPop()) {
            Navigator.pop(context);
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (route) => false,
            );
          }
        }
      },
      accentColor: const Color(0xFF4FACFE),
    );
  }

  Future<bool> _onWillPop() async {
    if (_allowExit) return true;
    // Show exit confirmation dialog
    bool shouldExit = false;
    await showModernDialog(
      context,
      title: "Almost there!",
      message: "You are almost there. Do you want to finish the quiz?",
      primaryButtonText: "Continue Quiz",
      onPrimaryPressed: () {
        Navigator.pop(context);
        shouldExit = false;
      },
      secondaryButtonText: "Exit Quiz",
      onSecondaryPressed: () {
        Navigator.pop(context);
        shouldExit = true;
      },
      accentColor: Colors.orangeAccent,
      icon: Icons.warning_amber_rounded,
    );
    return shouldExit;
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final scaffoldBg = isDark
        ? const Color(0xFF030305)
        : theme.scaffoldBackgroundColor;

    return PopScope(
      canPop: _allowExit,
      onPopInvokedWithResult: (bool didPop, Object? _) async {
        if (didPop) return;
        final bool shouldExit = await _onWillPop();
        if (!context.mounted) return;
        if (shouldExit) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: Stack(
          children: [
            // Background Blobs
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
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.22)
                    : onSurface.withValues(alpha: 0.06),
              ),
            ),

            Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                    onPressed: () async {
                      final exit = await _onWillPop();
                      if (!context.mounted) return;
                      if (exit) Navigator.pop(context);
                    },
                  ),
                  title: Text(
                    "Question ${_currentIndex + 1} of ${_questions.length}",
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  centerTitle: true,
                ),
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : onSurface.withValues(alpha: 0.08),
                      color: const Color(0xFF6C63FF),
                      minHeight: 6,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        // Question Text
                        Text(
                              currentQuestion.question,
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                                letterSpacing: 0.5,
                              ),
                            )
                            .animate(key: ValueKey(_currentIndex))
                            .fadeIn(duration: 400.ms)
                            .moveY(begin: 10, end: 0),

                        const SizedBox(height: 48),

                        // Options
                        Expanded(
                          child: ListView.separated(
                            itemCount: currentQuestion.options.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              bool isSelected =
                                  _userAnswers[_currentIndex] == index;
                              return _buildOptionButton(
                                index,
                                currentQuestion.options[index],
                                isSelected,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Space Dust (Floating OVER the UI so it doesn't get blurred)
            Positioned.fill(
              child: const IgnorePointer(child: SpaceDustBackground()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(int index, String text, bool isSelected) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final currentQuestion = _questions[_currentIndex];
    final bool showResult = _isAnswered;
    final bool isCorrect = index == currentQuestion.correctIndex;
    final bool isWrong = isSelected && !isCorrect;

    Color itemColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : onSurface.withValues(alpha: 0.05);
    Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : onSurface.withValues(alpha: 0.1);
    Widget leadingWidget = Text(
      String.fromCharCode(65 + index),
      style: TextStyle(
        color: isSelected ? Colors.white : onSurface.withValues(alpha: 0.54),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );

    if (showResult) {
      if (isCorrect) {
        itemColor = Colors.green.withValues(alpha: 0.2);
        borderColor = Colors.greenAccent;
        leadingWidget = const Icon(
          Icons.check_circle_rounded,
          color: Colors.greenAccent,
          size: 24,
        );
      } else if (isWrong) {
        itemColor = Colors.red.withValues(alpha: 0.2);
        borderColor = Colors.redAccent;
        leadingWidget = const Icon(
          Icons.cancel_rounded,
          color: Colors.redAccent,
          size: 24,
        );
      }
    } else if (isSelected) {
      itemColor = const Color(0xFF6C63FF).withValues(alpha: 0.3);
      borderColor = const Color(0xFF6C63FF);
    }

    return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: InkWell(
              onTap: _isAnswered ? null : () => _handleAnswer(index),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: itemColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: (isSelected || (showResult && isCorrect))
                      ? [
                          BoxShadow(
                            color: (showResult && isCorrect)
                                ? Colors.greenAccent.withValues(alpha: 0.2)
                                : const Color(
                                    0xFF6C63FF,
                                  ).withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: (isSelected && !showResult)
                            ? const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF8B80FF)],
                              )
                            : null,
                        color: (isSelected && !showResult)
                            ? null
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : onSurface.withValues(alpha: 0.08)),
                        border: Border.all(
                          color: isSelected
                              ? (isDark
                                    ? Colors.white24
                                    : onSurface.withValues(alpha: 0.24))
                              : (isDark
                                    ? Colors.white12
                                    : onSurface.withValues(alpha: 0.12)),
                        ),
                      ),
                      child: Center(child: leadingWidget),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : onSurface.withValues(alpha: 0.7),
                          fontSize: 17,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(key: ValueKey("$_currentIndex-$index"))
        .fadeIn(delay: Duration(milliseconds: 100 * index))
        .moveY(begin: 20, end: 0, curve: Curves.easeOutCubic);
  }
}
