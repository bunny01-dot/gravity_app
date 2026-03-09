import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/widgets/modern_glass_dialog.dart';
import 'package:confetti/confetti.dart';
import 'package:gravity_app/services/sound_service.dart'; // Import SoundService

class FocusedQuizScreen extends StatefulWidget {
  const FocusedQuizScreen({super.key});

  @override
  State<FocusedQuizScreen> createState() => _FocusedQuizScreenState();
}

class _FocusedQuizScreenState extends State<FocusedQuizScreen> {
  final DataService _dataService = DataService();
  late ConfettiController _confettiController;

  List<Map<String, String>> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _isAnswered = false;
  int? _selectedOptionIndex;

  // Track shuffled options to ensure they stay consistent during a question
  List<String> _currentOptions = [];
  String _currentCorrectAnswer = '';

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _loadQuizData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizData() async {
    // 1. Helper to get clean meaning
    String getMeaning(Map<String, String> item) {
      return item['meaning'] ??
          item['tamil_meaning'] ??
          item['hindi_meaning'] ??
          '';
    }

    // 2. Load Black Hole Items
    final blackHoleItems = await _dataService.getBlackHoleItems();

    if (blackHoleItems.isEmpty) {
      if (mounted) {
        setState(() {
          _questions = [];
          _isLoading = false;
        });
      }
      return;
    }

    // 3. Load Distractor Pool (General Vocab) to ensure we have options
    final allVocab = await _dataService.getAllItems('vocabulary');

    // 4. Generate Questions
    List<Map<String, String>> generatedQuestions = [];

    for (var item in blackHoleItems) {
      String word = item['word'] ?? '';
      String correctMeaning = getMeaning(item);

      if (word.isEmpty || correctMeaning.isEmpty) continue;

      // Start with correct answer
      List<String> options = [correctMeaning];

      // Add distractors from other black hole items
      final otherBH = blackHoleItems
          .where((i) => i != item && getMeaning(i).isNotEmpty)
          .toList();
      otherBH.shuffle();

      for (var o in otherBH.take(3)) {
        final m = getMeaning(o);
        if (!options.contains(m)) options.add(m);
      }

      // If still need options, fill from general vocab
      if (options.length < 4) {
        final pool = allVocab
            .where(
              (v) =>
                  getMeaning(v).isNotEmpty && !options.contains(getMeaning(v)),
            )
            .toList();
        pool.shuffle();
        for (var p in pool.take(4 - options.length)) {
          options.add(getMeaning(p));
        }
      }

      // Ensure we have at least 2 options to make it a quiz
      if (options.length < 2) continue;

      // Map to question structure
      // Pad with empty if < 4 (UI handles this by checking length)
      while (options.length < 4) {
        options.add('');
      }

      // We explicitly shuffle inside _prepareQuestion, but we need to assign slots here
      // Actually _prepareQuestion shuffles them for display. We just need to store them.
      // We will store them in option1..4. Shuffle logic in _prepare needs them there.
      // Wait, _prepareQuestion logic:
      // gets op1, op2, op3, op4. Shuffles them.
      // So order here doesn't matter much, but let's mix it up slightly for stored data cleanliness.
      options.shuffle();

      generatedQuestions.add({
        'id': item['id'] ?? word,
        'question': "What is the meaning of \"$word\"?",
        'answer': correctMeaning,
        'option1': options[0],
        'option2': options[1],
        'option3': options[2],
        'option4': options[3],
      });
    }

    generatedQuestions.shuffle();

    if (mounted) {
      setState(() {
        _questions = generatedQuestions;
        _isLoading = false;
      });
      if (_questions.isNotEmpty) {
        _prepareQuestion(_currentIndex);
      }
    }
  }

  void _prepareQuestion(int index) {
    if (index >= _questions.length) return;

    final q = _questions[index];
    final op1 = q['option1'] ?? '';
    final op2 = q['option2'] ?? '';
    final op3 = q['option3'] ?? '';
    final op4 = q['option4'] ?? '';
    final ans = q['answer'] ?? '';

    List<String> rawOptions = [
      op1,
      op2,
      op3,
      op4,
    ].where((s) => s.isNotEmpty).toList();

    // Ensure answer is in options if not present (simple fallback)
    if (!rawOptions.contains(ans)) {
      // If answer key matches option text, fine.
      // Sometimes answer is 'A', '1' or the full text.
      // We assume full text for now based on data service structure.
      // If it's missing, add it? Or maybe it is one of them?
      // Let's assume the CSV provides specific options and one matches 'answer'.
    }

    rawOptions.shuffle();

    setState(() {
      _currentOptions = rawOptions;
      _currentCorrectAnswer = ans;
      _isAnswered = false;
      _selectedOptionIndex = null;
    });
  }

  void _handleAnswer(int index) {
    if (_isAnswered) return;

    final selected = _currentOptions[index];
    // Check Full String Match or simple trimming
    bool isCorrect =
        selected.trim().toLowerCase() ==
        _currentCorrectAnswer.trim().toLowerCase();

    // Handle A/B/C/D logic if necessary, but CSV Import usually expands it.
    // Assuming exact match for now.

    setState(() {
      _isAnswered = true;
      _selectedOptionIndex = index;
      if (isCorrect) {
        _score++;
        // Save Mastery Progress
        final q = _questions[_currentIndex];
        final id = q['id'] ?? q['question'].hashCode.toString();
        _dataService.saveMasteryProgress('quiz', id);

        // SFX
        SoundService().playTap(); // Subtle positive
      } else {
        SoundService().playError();
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _prepareQuestion(_currentIndex);
      } else {
        _finishQuiz();
      }
    });
  }

  void _finishQuiz() {
    final percentage = _questions.isEmpty
        ? 0
        : (_score / _questions.length) * 100;

    if (percentage >= 70) {
      _confettiController.play();
      SoundService().playCompletion(); // Big finish
    } else {
      SoundService().playTap(); // Just finished
    }

    showModernDialog(
      context,
      title: "Quiz Completed",
      message:
          "You scored $_score/${_questions.length} (${percentage.toStringAsFixed(1)}%)",
      primaryButtonText: "Done",
      onPrimaryPressed: () => Navigator.of(context).pop(),
      icon: percentage >= 70
          ? Icons.emoji_events_rounded
          : Icons.assignment_late_rounded,
      accentColor: percentage >= 70
          ? const Color(0xFFFFD700)
          : Colors.orangeAccent,
      confettiController: _confettiController,
    ).then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = colorScheme.onSurface;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: onSurface),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.blur_on,
                size: 80,
                color: onSurface.withValues(alpha: 0.2),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 10.seconds),
              const SizedBox(height: 24),
              Text(
                "The Black Hole is empty.",
                style: TextStyle(
                  color: onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "This Focused Quiz is powered by your Black Hole words. Add difficult words to the Black Hole to generate a personalized quiz!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.62),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                label: const Text("Go Back"),
                icon: const Icon(Icons.arrow_back),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final questionData = _questions[_currentIndex];
    final questionText = questionData['question'] ?? 'Question';

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text("Question ${_currentIndex + 1}/${_questions.length}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      body: Stack(
        children: [
          // Subtle BG
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Progress Bar
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  backgroundColor: colorScheme.outlineVariant.withValues(
                    alpha: 0.35,
                  ),
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
                const SizedBox(height: 40),

                // Question Card
                Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceContainerHigh
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(
                              alpha: isDark ? 0.32 : 0.12,
                            ),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        questionText,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                    .animate(key: ValueKey(_currentIndex))
                    .fadeIn()
                    .slideY(begin: 0.1, end: 0),

                const Spacer(),

                // Options
                ...List.generate(_currentOptions.length, (index) {
                  final option = _currentOptions[index];
                  Color bgColor = isDark
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surface;
                  Color borderColor = colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  );

                  if (_isAnswered) {
                    if (option.trim().toLowerCase() ==
                        _currentCorrectAnswer.trim().toLowerCase()) {
                      bgColor = Colors.green.withValues(alpha: 0.2);
                      borderColor = Colors.greenAccent;
                    } else if (index == _selectedOptionIndex) {
                      bgColor = Colors.red.withValues(alpha: 0.2);
                      borderColor = Colors.redAccent;
                    }
                  }

                  return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _handleAnswer(index),
                          borderRadius: BorderRadius.circular(15),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color: onSurface,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (_isAnswered &&
                                    option.trim().toLowerCase() ==
                                        _currentCorrectAnswer
                                            .trim()
                                            .toLowerCase())
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.greenAccent,
                                  ),
                                if (_isAnswered &&
                                    index == _selectedOptionIndex &&
                                    option.trim().toLowerCase() !=
                                        _currentCorrectAnswer
                                            .trim()
                                            .toLowerCase())
                                  const Icon(
                                    Icons.cancel,
                                    color: Colors.redAccent,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .animate(key: ValueKey(option))
                      .fadeIn(delay: (100 * index).ms)
                      .slideX(begin: 0.1, end: 0);
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}
