import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:math';
import 'package:gravity_app/services/data_service.dart';

import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'assignment_screen.dart';
import 'package:gravity_app/services/tts_service.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/services/stage_progress_service.dart';

class DailyQuizScreen extends StatefulWidget {
  final List<Map<String, String>> vocabList;
  final List<Map<String, String>> verbList;
  final String preferredLanguage;
  final int? stage;
  final List<int> coveredStages;
  final DateTime? date;
  final List<DateTime> coveredDates;

  const DailyQuizScreen({
    super.key,
    required this.vocabList,
    required this.verbList,
    this.preferredLanguage = 'Tamil',
    this.stage,
    this.coveredStages = const [],
    this.date,
    this.coveredDates = const [],
  });

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen>
    with TickerProviderStateMixin {
  final TtsService _ttsService = TtsService();
  final SoundService _soundService = SoundService();
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  bool _viewingResults = false;
  int? _selectedOptionIndex;
  late ConfettiController _confettiController;
  final List<Map<String, String>> _wrongAnswers = []; // Track wrong answers
  bool _nextLevelUnlocked = false;
  int? _nextUnlockedStage;
  bool _isFinishingQuiz = false;
  late AnimationController _captureController;
  late AnimationController _blackHolePulseController;
  final GlobalKey _quizStackKey = GlobalKey();
  final GlobalKey _blackHoleIconKey = GlobalKey();
  final Map<int, GlobalKey> _optionItemKeys = <int, GlobalKey>{};
  bool _showCaptureWord = false;
  String _captureWord = '';
  Offset _captureStart = Offset.zero;
  Offset _captureEnd = Offset.zero;
  Offset? _lastTapGlobalPosition;

  GlobalKey _optionKeyFor(int index) =>
      _optionItemKeys.putIfAbsent(index, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _captureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _blackHolePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _checkStatus();
  }

  @override
  void dispose() {
    _captureController.dispose();
    _blackHolePulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    final random = Random();
    List<QuizQuestion> allGeneratedQuestions = [];

    // 1. Fallback Pool for low-data users (Pedagogy Check)
    final List<String> fallbackMeanings = [
      "Running quickly",
      "A beautiful flower",
      "The act of thinking",
      "A large mountain",
      "To swim deep",
      "A friendly greeting",
      "Eating delicious food",
      "Sleeping peacefully",
      "Writing a letter",
      "Building a house",
      "Driving a car",
      "Singing a song",
      "Painting a picture",
      "Reading a book",
      "Playing a game",
      "Learning a lesson",
      "Walking in the park",
      "Flying in the sky",
      "Cooking dinner",
      "Cleaning the room",
    ];

    final allVocab = List<Map<String, String>>.from(widget.vocabList);
    final allVerbs = List<Map<String, String>>.from(widget.verbList);

    // --- GENERIC DISTRACTOR HELPER ---
    List<String> getDistractors(String correct, List<String> sourcePool) {
      // Filter out the correct answer
      final pool = sourcePool
          .where((s) => s != correct && s.isNotEmpty)
          .toList();
      pool.shuffle(random);

      // If we don't have enough real distractors, mix in fallbacks
      if (pool.length < 3) {
        final needed = 3 - pool.length;
        // Shuffle fallbacks to ensure variety
        final errors = List<String>.from(fallbackMeanings)..shuffle(random);
        pool.addAll(errors.take(needed));
      }
      return pool.take(3).toList();
    }

    // --- Generate Vocab Questions ---
    List<QuizQuestion> vocabQuestions = [];

    for (var item in allVocab) {
      final word = item['word'] ?? '';
      // Use tamil_meaning primarily, fallback to 'meaning' or empty
      final meaning = item['tamil_meaning']?.isNotEmpty == true
          ? item['tamil_meaning']!
          : (item['meaning'] ?? '');

      if (word.isEmpty || meaning.isEmpty) continue;

      // Get distractors from other vocab items
      final allMeanings = allVocab
          .map(
            (e) => e['tamil_meaning']?.isNotEmpty == true
                ? e['tamil_meaning']!
                : (e['meaning'] ?? ''),
          )
          .where((m) => m.isNotEmpty)
          .toList(); // Keep duplicates initially if any, mapped

      final options = getDistractors(meaning, allMeanings);
      options.add(meaning);
      options.shuffle(random);

      vocabQuestions.add(
        QuizQuestion(
          questionText: "Meaning of '$word'?",
          correctAnswer: meaning,
          options: options,
          type: 'vocab',
          word: word,
        ),
      );
    }

    // --- Generate Verb Questions ---
    List<QuizQuestion> verbQuestions = [];

    for (var item in allVerbs) {
      final v1 = item['v1'] ?? '';
      final v2 = item['v2'] ?? '';
      final v3 = item['v3'] ?? '';

      if (v1.isEmpty || v2.isEmpty || v3.isEmpty) continue;

      bool askV2 = random.nextBool();
      final targetForm = askV2 ? "V2 (Past)" : "V3 (Past Participle)";
      String correctAns = askV2 ? v2 : v3;
      final optionsSet = _buildConfusingVerbOptions(
        allVerbs: allVerbs,
        v1: v1,
        v2: v2,
        v3: v3,
        askV2: askV2,
        random: random,
      );

      verbQuestions.add(
        QuizQuestion(
          questionText: "What is the $targetForm form of the verb '$v1'?",
          correctAnswer: correctAns,
          options: optionsSet,
          type: 'verb',
          word: v1,
        ),
      );
    }

    // --- Combine & Balance ---
    int vocabCount = widget.vocabList.length;
    if (vocabCount < 1) vocabCount = 3; // Minimal fallback
    int totalNeeded = vocabCount * 2;

    int half = (totalNeeded / 2).ceil();

    vocabQuestions.shuffle(random);
    verbQuestions.shuffle(random);

    allGeneratedQuestions.addAll(vocabQuestions.take(half));
    int remaining = totalNeeded - allGeneratedQuestions.length;
    allGeneratedQuestions.addAll(verbQuestions.take(remaining));

    // Keep at least one verb question when verb data exists.
    if (verbQuestions.isNotEmpty &&
        !allGeneratedQuestions.any((q) => q.type == 'verb')) {
      allGeneratedQuestions.removeLast();
      allGeneratedQuestions.add(verbQuestions.first);
    }

    // Fill rest if under target
    if (allGeneratedQuestions.length < totalNeeded) {
      if (vocabQuestions.length > half) {
        allGeneratedQuestions.addAll(
          vocabQuestions
              .skip(half)
              .take(totalNeeded - allGeneratedQuestions.length),
        );
      }
    }

    // Ensure we have something
    if (allGeneratedQuestions.isEmpty) {
      // Create at least one dummy question if data is totally broken but lists not empty
      // logic should prevent this, but just in case
    }

    allGeneratedQuestions.shuffle(random);
    if (allGeneratedQuestions.length > totalNeeded) {
      allGeneratedQuestions = allGeneratedQuestions.sublist(0, totalNeeded);
    }

    setState(() {
      _questions = allGeneratedQuestions;
    });
  }

  List<String> _buildConfusingVerbOptions({
    required List<Map<String, String>> allVerbs,
    required String v1,
    required String v2,
    required String v3,
    required bool askV2,
    required Random random,
  }) {
    final correct = askV2 ? v2 : v3;
    final otherForm = askV2 ? v3 : v2;
    final options = <String>{correct};

    // Priority 1: same-verb confusing options (hard distractors).
    final nearMisses = <String>[
      v1,
      _regularizedPastFrom(v1),
      '${correct}ed',
      '${otherForm}ed',
      _regularizedParticipleFrom(v1),
      otherForm,
      '${_regularizedPastFrom(v1)}ed',
      _regularizedPastFrom(otherForm),
      _regularizedParticipleFrom(otherForm),
      '${v1}d',
      '${v1}en',
      '${v1}ing',
    ];

    for (final candidate in nearMisses) {
      final value = candidate.trim();
      if (value.isEmpty || value == correct) {
        continue;
      }
      options.add(value);
      if (options.length >= 4) break;
    }

    // Priority 2: if still sparse, borrow forms from other verbs.
    if (options.length < 4) {
      final otherDistractors = <String>[];
      for (final other in allVerbs) {
        if ((other['v1'] ?? '').trim().toLowerCase() == v1.toLowerCase()) {
          continue;
        }
        otherDistractors.add((other['v2'] ?? '').trim());
        otherDistractors.add((other['v3'] ?? '').trim());
      }
      otherDistractors.shuffle(random);
      for (final d in otherDistractors) {
        if (d.isEmpty || d == correct) continue;
        options.add(d);
        if (options.length >= 4) break;
      }
    }

    // Priority 3: guaranteed fill.
    while (options.length < 4) {
      options.add('$v1${["ed", "en", "s", "ing"][random.nextInt(4)]}');
    }

    final list = options.toList()..shuffle(random);
    return list.take(4).toList();
  }

  String _regularizedPastFrom(String baseForm) {
    final base = baseForm.trim().toLowerCase();
    if (base.isEmpty) return '';
    if (base.endsWith('e')) return '${base}d';

    if (base.length > 1 &&
        base.endsWith('y') &&
        !_isVowel(base[base.length - 2])) {
      return '${base.substring(0, base.length - 1)}ied';
    }

    return '${base}ed';
  }

  String _regularizedParticipleFrom(String baseForm) {
    final past = _regularizedPastFrom(baseForm);
    if (past.isEmpty) return '';
    if (past.endsWith('ed')) return '${past.substring(0, past.length - 1)}n';
    return '${past}n';
  }

  bool _isVowel(String ch) {
    const vowels = {'a', 'e', 'i', 'o', 'u'};
    return vowels.contains(ch.toLowerCase());
  }

  void _handleAnswer(
    int index,
    BuildContext optionContext,
    Offset? tapGlobalPosition,
  ) {
    if (_isAnswered) return;
    final launchTapPosition = tapGlobalPosition;
    _lastTapGlobalPosition = null;

    // Set flag IMMEDIATELY to prevent race condition
    _isAnswered = true;

    setState(() {
      _selectedOptionIndex = index;
    });

    final isCorrect =
        _questions[_currentQuestionIndex].options[index] ==
        _questions[_currentQuestionIndex].correctAnswer;

    if (isCorrect) {
      _score++;
      _soundService.playSuccess();
    } else {
      _soundService.playError();

      // Track wrong answer for black hole
      final currentQuestion = _questions[_currentQuestionIndex];
      final correctOptionIndex = currentQuestion.options.indexOf(
        currentQuestion.correctAnswer,
      );
      _wrongAnswers.add({
        'word': currentQuestion.word,
        'type': currentQuestion.type,
        'correct_answer': currentQuestion.correctAnswer,
      });
      _triggerCorrectOptionCapture(
        correctOptionIndex: correctOptionIndex,
        correctWord: currentQuestion.correctAnswer,
        fallbackSourceContext: optionContext,
        tapGlobalPosition: launchTapPosition,
      );
    }

    // Wait and go to next (increased wait time to allow reading explanation)
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;

      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _isAnswered = false;
          _selectedOptionIndex = null;
        });
      } else {
        _finishQuiz();
      }
    });
  }

  void _startBlackHoleCapture({
    required BuildContext sourceContext,
    required String correctWord,
    BuildContext? correctOptionContext,
    Offset? tapGlobalPosition,
  }) {
    final stackContext = _quizStackKey.currentContext;
    if (stackContext == null) return;

    final stackBox = stackContext.findRenderObject() as RenderBox?;
    final sourceBox = sourceContext.findRenderObject() as RenderBox?;
    final correctOptionBox =
        correctOptionContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return;

    final iconContext = _blackHoleIconKey.currentContext;
    final iconBox = iconContext?.findRenderObject() as RenderBox?;

    Offset sourceLocal;
    if (correctOptionBox != null) {
      final correctCenter = correctOptionBox.localToGlobal(
        correctOptionBox.size.center(Offset.zero),
      );
      sourceLocal = stackBox.globalToLocal(correctCenter);
    } else if (tapGlobalPosition != null) {
      sourceLocal = stackBox.globalToLocal(tapGlobalPosition);
    } else if (sourceBox != null) {
      final sourceCenter = sourceBox.localToGlobal(
        sourceBox.size.center(Offset.zero),
      );
      sourceLocal = stackBox.globalToLocal(sourceCenter);
    } else {
      // Conservative fallback: launch near lower-center if source is unavailable.
      sourceLocal = Offset(
        stackBox.size.width * 0.5,
        stackBox.size.height * 0.78,
      );
    }

    Offset iconLocalCenter;
    if (iconBox != null) {
      final iconCenter = iconBox.localToGlobal(
        iconBox.size.center(Offset.zero),
      );
      iconLocalCenter = stackBox.globalToLocal(iconCenter);
    } else {
      // Fallback target: top-right app-bar action area.
      final topInset = MediaQuery.of(context).padding.top;
      iconLocalCenter = Offset(stackBox.size.width - 30, topInset + 28);
    }

    setState(() {
      _captureWord = correctWord;
      _captureStart = sourceLocal;
      _captureEnd = iconLocalCenter;
      _showCaptureWord = true;
    });

    _blackHolePulseController.forward(from: 0);
    _captureController.forward(from: 0).whenComplete(() async {
      if (!mounted) return;
      setState(() => _showCaptureWord = false);
    });
  }

  void _triggerCorrectOptionCapture({
    required int correctOptionIndex,
    required String correctWord,
    required BuildContext fallbackSourceContext,
    Offset? tapGlobalPosition,
  }) {
    void launchWithContext(BuildContext? correctOptionContext) {
      _startBlackHoleCapture(
        sourceContext: fallbackSourceContext,
        correctWord: correctWord,
        correctOptionContext: correctOptionContext,
        tapGlobalPosition: tapGlobalPosition,
      );
    }

    // Wait one frame for highlight/render updates.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final firstContext = _optionItemKeys[correctOptionIndex]?.currentContext;
      if (firstContext != null) {
        launchWithContext(firstContext);
        return;
      }

      // Retry one extra frame in case list/layout just updated.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final secondContext =
            _optionItemKeys[correctOptionIndex]?.currentContext;
        launchWithContext(secondContext);
      });
    });
  }

  Widget _buildBlackHoleActionIcon() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: "Wrong answers are added to Black Hole",
      child: SizedBox(
        key: _blackHoleIconKey,
        width: 46,
        height: 46,
        child: Center(
          child: AnimatedBuilder(
            animation: _blackHolePulseController,
            builder: (context, _) {
              final t = _blackHolePulseController.value;
              final open = sin(pi * t).clamp(0.0, 1.0);
              final wobble = 0.08 * sin(6 * pi * t) * (1 - t);
              final scale = 1 + (0.18 * open);
              final swirl = 2 * pi * t;
              final coreSize = 7.5 + (8.5 * open);
              final borderWidth = 1.2 + (0.8 * open);
              final glowAlpha = 0.2 + (0.4 * open);

              return Transform.rotate(
                angle: wobble,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF9E86FF,
                          ).withValues(alpha: glowAlpha),
                          blurRadius: 12 + (8 * open),
                          spreadRadius: 1.2 + (2.2 * open),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(-0.2, -0.15),
                              colors: [
                                const Color(0xFFB9A7FF).withValues(alpha: 0.95),
                                const Color(0xFF6C63FF).withValues(alpha: 0.85),
                                isDark
                                    ? const Color(0xFF111827)
                                    : const Color(0xFF1F2937),
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(
                                      alpha: 0.28 + (0.2 * open),
                                    )
                                  : colorScheme.surface.withValues(
                                      alpha: 0.88 + (0.08 * open),
                                    ),
                              width: borderWidth,
                            ),
                          ),
                        ),
                        Transform.rotate(
                          angle: swirl,
                          child: Icon(
                            Icons.cyclone,
                            size: 15,
                            color: isDark
                                ? Colors.white70
                                : colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                        Container(
                          width: coreSize,
                          height: coreSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.96),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureWordAnimation() {
    if (!_showCaptureWord) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _captureController,
          builder: (context, child) {
            final t = _captureController.value;
            final xProgress = Curves.easeInOutCubic.transform(t);
            final yProgress = Curves.easeIn.transform(t);
            final x =
                _captureStart.dx +
                (_captureEnd.dx - _captureStart.dx) * xProgress;
            final yBase =
                _captureStart.dy +
                (_captureEnd.dy - _captureStart.dy) * yProgress;
            final y = yBase - (sin(pi * t) * 70);
            final scale = 1 - (0.35 * t);
            final opacity = t < 0.85
                ? 1.0
                : (1 - ((t - 0.85) / 0.15)).clamp(0.0, 1.0);

            return Align(
              alignment: Alignment.topLeft,
              child: Transform.translate(
                offset: Offset(x, y),
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(scale: scale, child: child),
                  ),
                ),
              ),
            );
          },
          child: Container(
            constraints: const BoxConstraints(maxWidth: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  (isDark
                          ? colorScheme.surfaceContainerHigh
                          : colorScheme.surface)
                      .withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.7),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              _captureWord,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkStatus() async {
    bool passed;
    if (widget.coveredStages.isNotEmpty) {
      final stageChecks = await Future.wait(
        widget.coveredStages.map((s) => DataService().hasPassedQuizForStage(s)),
      );
      passed = stageChecks.isNotEmpty && stageChecks.every((v) => v);
    } else if (widget.stage != null && widget.stage! > 0) {
      passed = await DataService().hasPassedQuizForStage(widget.stage!);
    } else {
      final targetDate = widget.date ?? DateTime.now();
      passed = await DataService().hasPassedQuiz(targetDate);
    }

    // Only block "Today's" quiz if passed. Allow retries of past dates if accessed (e.g. from Missed Screen).
    // If retrying a missed date that is ALREADY passed, we should probably allow it or show success?
    // Let's assume user wants to RETAKE to improve. So don't block UNLESS it is today.

    final isAdhocTodayQuiz =
        widget.date == null &&
        widget.stage == null &&
        widget.coveredStages.isEmpty;

    if (isAdhocTodayQuiz && passed && mounted) {
      // Restore past result for viewing
      // We assume score is 100% or whatever saved if we don't fetch exact score here easily
      // For simplicity in this "fix" context, we show success state or fetch via DataService if needed.
      // Better: we can actually just generate questions (to have count) and show result screen immediately.

      // Fetch actual score to show correct state
      final prefs = await SharedPreferences.getInstance();
      int savedScore = 0;
      int savedTotal = 10;
      if (widget.stage != null && widget.stage! > 0) {
        savedScore = prefs.getInt('quiz_score_stage_${widget.stage!}') ?? 0;
        savedTotal = prefs.getInt('quiz_total_stage_${widget.stage!}') ?? 10;
      } else if (widget.coveredStages.isNotEmpty) {
        final latestStage = widget.coveredStages.last;
        savedScore = prefs.getInt('quiz_score_stage_$latestStage') ?? 0;
        savedTotal = prefs.getInt('quiz_total_stage_$latestStage') ?? 10;
      } else {
        final today = DateTime.now().toIso8601String().split('T')[0];
        savedScore = prefs.getInt('quiz_score_$today') ?? 0;
        savedTotal = prefs.getInt('quiz_total_$today') ?? 10;
      }

      setState(() {
        // Dummy questions generation if needed to avoid length 0 errors, or just use savedTotal
        _score = savedScore;
        // _questions length might be different if re-generated, but let's assume consistent for result view
        // Ideally we shouldn't re-generate random qs, but for pure result view "N/N", we use savedTotal.
        _viewingResults = true;
      });
      _generateQuestions(); // To populate questions for length reference if needed, though we rely on savedTotal for display

      // If we are viewing results, check if we need confetti
      if ((savedScore / savedTotal) >= 0.8) {
        _confettiController.play();
      }
    } else {
      _generateQuestions();
    }
  }

  void _finishQuiz() async {
    if (_isFinishingQuiz || _viewingResults) return;
    _isFinishingQuiz = true;

    final percentage = _questions.isEmpty
        ? 0
        : (_score / _questions.length) * 100;

    if (percentage >= 80) {
      _soundService.playCompletion();
      _confettiController.play();
    } else if (percentage >= 70) {
      _soundService.playSuccess();
    }

    if (mounted) {
      setState(() {
        _viewingResults = true;
      });
    }

    final dataService = DataService();
    final stageService = StageProgressService();

    try {
      final prefs = await SharedPreferences.getInstance();
      // SAVE RESULT FOR THE SPECIFIC DATE(S)
      if (widget.coveredStages.isNotEmpty) {
        for (final stage in widget.coveredStages) {
          await _runWithTimeout(
            dataService.saveQuizResultForStage(
              stage,
              _score,
              _questions.length,
            ),
            label: 'saveQuizResultForStage($stage)',
          );
          await _markAssessmentCompletion(
            prefs: prefs,
            stageService: stageService,
            stage: stage,
          );
          if (_wrongAnswers.isNotEmpty) {
            await _runWithTimeout(
              dataService.addToBlackHoleForStage(_wrongAnswers, stage),
              label: 'addToBlackHoleForStage($stage)',
            );
          }
        }
      } else if (widget.stage != null && widget.stage! > 0) {
        await _runWithTimeout(
          dataService.saveQuizResultForStage(
            widget.stage!,
            _score,
            _questions.length,
          ),
          label: 'saveQuizResultForStage(${widget.stage!})',
        );
        await _markAssessmentCompletion(
          prefs: prefs,
          stageService: stageService,
          stage: widget.stage!,
        );
        if (_wrongAnswers.isNotEmpty) {
          await _runWithTimeout(
            dataService.addToBlackHoleForStage(_wrongAnswers, widget.stage!),
            label: 'addToBlackHoleForStage(${widget.stage!})',
          );
        }
      } else if (widget.coveredDates.isNotEmpty) {
        // Aggregated Quiz (Missed Lessons)
        // Mark ALL dates as completed with this score
        for (final date in widget.coveredDates) {
          await _runWithTimeout(
            dataService.saveQuizResult(date, _score, _questions.length),
            label: 'saveQuizResult(${date.toIso8601String()})',
          );
          if (_wrongAnswers.isNotEmpty) {
            await _runWithTimeout(
              dataService.addToBlackHole(_wrongAnswers, date),
              label: 'addToBlackHole(${date.toIso8601String()})',
            );
          }
        }
      } else {
        // Single Day (Standard)
        final resultDate = widget.date ?? DateTime.now();
        await _runWithTimeout(
          dataService.saveQuizResult(resultDate, _score, _questions.length),
          label: 'saveQuizResult(${resultDate.toIso8601String()})',
        );
        if (_wrongAnswers.isNotEmpty) {
          await _runWithTimeout(
            dataService.addToBlackHole(_wrongAnswers, resultDate),
            label: 'addToBlackHole(${resultDate.toIso8601String()})',
          );
        }
      }
    } catch (e) {
      debugPrint('DailyQuiz: finalization failed: $e');
    } finally {
      _isFinishingQuiz = false;
    }
  }

  Future<void> _runWithTimeout(
    Future<void> operation, {
    required String label,
  }) async {
    try {
      await operation.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      debugPrint('DailyQuiz: timed out while $label');
    } catch (e) {
      debugPrint('DailyQuiz: failed while $label: $e');
    }
  }

  Future<void> _markAssessmentCompletion({
    required SharedPreferences prefs,
    required StageProgressService stageService,
    required int stage,
  }) async {
    final passed = stageService.isAssessmentPassed(_score, _questions.length);
    final assessmentKey = stageService.assessmentCompletedKey(stage);
    await prefs.setBool(assessmentKey, passed);
    unawaited(DataService().saveProgressToCloud(assessmentKey, passed));

    if (!passed) return;

    final currentStage = await stageService.getCurrentStage(prefs: prefs);
    if (stage != currentStage) return;

    final nextStage = await stageService.incrementStage(prefs: prefs);
    unawaited(
      DataService().saveProgressToCloud('current_learning_stage', nextStage),
    );
    _nextLevelUnlocked = true;
    _nextUnlockedStage = nextStage;
  }

  Map<String, dynamic> _completionResult() {
    return {
      'nextLevelUnlocked': _nextLevelUnlocked,
      if (_nextUnlockedStage != null) 'nextStage': _nextUnlockedStage,
      if (widget.stage != null) 'completedStage': widget.stage,
      'score': _score,
      'total': _questions.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Daily Quiz',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "No vocabulary loaded. Please sync data in Settings.",
              style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        // If viewing results, simple exit, no warning needed
        if (_viewingResults) {
          Navigator.pop(context, _completionResult());
          return;
        }

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colorScheme.surfaceContainerHigh,
            title: Text(
              'Exit Quiz?',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            content: Text(
              'Your progress will be lost. Are you sure?',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('Exit'),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          Navigator.pop(context, _completionResult());
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          key: _quizStackKey,
          children: [
            _viewingResults ? _buildResultScreen() : _buildQuizContent(),
            if (_showCaptureWord) _buildCaptureWordAnimation(),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate safely
    int total = _questions.isEmpty ? 1 : _questions.length;
    // Fallback if _questions empty due to restore
    if (total == 0) total = 10;

    final percentage = (_score / total) * 100;
    final isMastered = percentage >= 80;
    final isPassed = percentage >= 70;

    String title;
    String message;
    IconData icon;
    Color color;
    Color actionTextColor;

    if (isMastered) {
      title = "Excellent Work! ";
      message = "You scored $_score/$total and truly mastered this lesson.";
      icon = Icons.emoji_events_rounded;
      color = const Color(0xFF00F2FE);
      actionTextColor = Colors.black;
    } else if (isPassed) {
      title = "Good Job! ";
      message = "You scored $_score/$total. Review to reach mastery!";
      icon = Icons.check_circle_rounded;
      color = Colors.greenAccent;
      actionTextColor = Colors.black;
    } else {
      title = "Keep Practicing ";
      message = "You scored $_score/$total. Check the review list to improve.";
      icon = Icons.school_rounded;
      color = Colors.orangeAccent;
      actionTextColor = Colors.black;
    }
    if (ThemeData.estimateBrightnessForColor(color) == Brightness.dark) {
      actionTextColor = Colors.white;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 80,
                  color: color,
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Actions
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, _completionResult()),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Finish",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: actionTextColor,
                      ),
                    ),
                  ),
                ),
                if (!isMastered) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Redirect to assignment/review logic
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssignmentScreen(
                              wrongAnswers: List<Map<String, String>>.from(
                                _wrongAnswers,
                              ),
                              score: _score,
                              total: total,
                              preferredLanguage: widget.preferredLanguage,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Review Mistakes",
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizContent() {
    final question = _questions[_currentQuestionIndex];
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        AppBar(
          title: Text(
            "Question ${_currentQuestionIndex + 1}/${_questions.length}",
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0,
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildBlackHoleActionIcon(),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Bar
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: colorScheme.outlineVariant.withValues(
                    alpha: 0.35,
                  ),
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
                const SizedBox(height: 40),

                // Question Text
                Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            question.questionText,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _ttsService.speak(question.word),
                          icon: Icon(
                            Icons.volume_up_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    )
                    .animate(key: ValueKey(_currentQuestionIndex))
                    .fadeIn()
                    .slideY(begin: 0.1, end: 0),

                const Spacer(),

                // Options
                ...List.generate(question.options.length, (index) {
                  final option = question.options[index];
                  final optionKey = _optionKeyFor(index);
                  Color color = isDark
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surface;
                  Color textColor = colorScheme.onSurface;

                  if (_isAnswered) {
                    if (option == question.correctAnswer) {
                      color = Colors.greenAccent.withValues(alpha: 0.2);
                      textColor = Colors.greenAccent;
                    } else if (index == _selectedOptionIndex) {
                      color = Colors.redAccent.withValues(alpha: 0.2);
                      textColor = Colors.redAccent;
                    }
                  }

                  return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Builder(
                          builder: (optionContext) => InkWell(
                            onTapDown: (details) {
                              _lastTapGlobalPosition = details.globalPosition;
                            },
                            onTap: () => _handleAnswer(
                              index,
                              optionContext,
                              _lastTapGlobalPosition,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              key: optionKey,
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      _isAnswered &&
                                          index == _selectedOptionIndex
                                      ? textColor
                                      : colorScheme.outlineVariant.withValues(
                                          alpha: 0.4,
                                        ),
                                ),
                              ),
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate(key: ValueKey(option))
                      .fadeIn(delay: (100 * index).ms);
                }),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class QuizQuestion {
  final String questionText;
  final String correctAnswer;
  final List<String> options;
  final String type; // 'vocab' or 'verb'
  final String word;

  QuizQuestion({
    required this.questionText,
    required this.correctAnswer,
    required this.options,
    required this.type,
    this.word = '',
  });
}
