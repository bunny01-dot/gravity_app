import 'package:flutter/material.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/tts_service.dart';
import 'package:gravity_app/widgets/tts_speed_control.dart'; // Speed Control
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/widgets/mastery_level_map.dart';
import 'package:gravity_app/widgets/mastery_difficulty_dialog.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final DataService _dataService = DataService();
  List<Map<String, String>> _exercises = [];
  bool _isLoading = true;
  String _selectedDifficulty = 'All'; // Filter State
  List<String> _completedIds = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCompletedStatus();
  }

  Future<void> _loadCompletedStatus() async {
    final completed = await _dataService.getCompletedExerciseIds('reading');
    if (mounted) {
      setState(() {
        _completedIds = completed;
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    String? difficulty = prefs.getString('difficulty_reading');

    if (difficulty == null) {
      await Future.delayed(Duration.zero);
      if (!mounted) return;

      final selected = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const MasteryDifficultyDialog(
          title: "Reading Mastery",
          initialLevel: 'Beginner',
        ),
      );

      difficulty = selected ?? 'Beginner';
      await prefs.setString('difficulty_reading', difficulty);
      // Sync to cloud
      await DataService().saveProgressToCloud('difficulty_reading', difficulty);
    }

    setState(() {
      _selectedDifficulty = difficulty!;
    });
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final data = await _dataService.getReadingExercises();
    setState(() {
      _exercises = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF030305)
          : theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : MasteryLevelMap(
              title: "Reading Mastery",
              exercises: _filteredExercises,
              completedIds: _completedIds,
              layoutType: LevelMapLayout.timeline,
              onTapExercise: _openExercise,
              onBack: () => Navigator.pop(context),
              useStarRating: true, // Enable 3-star ratings
              actions: [
                IconButton(
                  icon: Icon(Icons.filter_list, color: onSurface),
                  onPressed: _showDifficultyDialog,
                ),
              ],
            ),
    );
  }

  List<Map<String, String>> get _filteredExercises {
    if (_selectedDifficulty == 'All') return _exercises;
    return _exercises.where((e) {
      final level = e['level'] ?? 'Beginner';
      return level.toLowerCase().contains(_selectedDifficulty.toLowerCase());
    }).toList();
  }

  void _showDifficultyDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => MasteryDifficultyDialog(
        title: "Reading Mastery",
        initialLevel: _selectedDifficulty,
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedDifficulty = selected;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('difficulty_reading', selected);
      await DataService().saveProgressToCloud('difficulty_reading', selected);
    }
  }

  void _openExercise(Map<String, String> exercise) async {
    int currentIndex = _filteredExercises.indexOf(exercise);
    bool keepGoing = true;
    final navigator = Navigator.of(context);

    while (keepGoing && mounted) {
      // Ensure index is valid
      if (currentIndex < 0 || currentIndex >= _filteredExercises.length) {
        break;
      }

      final result = await navigator.push(
        MaterialPageRoute(
          builder: (context) => ExerciseDetailScreen(
            exercise: _filteredExercises[currentIndex],
            allExercises: _filteredExercises,
            currentIndex: currentIndex,
          ),
        ),
      );

      // Refresh on return (trigger map animation)
      await _loadCompletedStatus();

      if (result == 'next') {
        // Wait for map animation (800ms + buffer)
        await Future.delayed(const Duration(milliseconds: 1000));

        // Advance to next
        currentIndex++;
      } else {
        // User backed out normally
        keepGoing = false;
      }
    }
  }
}

class ExerciseDetailScreen extends StatefulWidget {
  final Map<String, String> exercise;
  final List<Map<String, String>> allExercises;
  final int currentIndex;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.allExercises,
    required this.currentIndex,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  // State to track user inputs and check status
  final Map<String, String> _userInputs = {};
  final Map<String, bool?> _results = {}; // 'q1': true/false
  final TtsService _ttsService = TtsService();
  bool _isSpeaking = false;
  String _userLanguage = 'Tamil';
  bool _showTranslation = false;

  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
    _ttsService.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _loadUserLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userLanguage = prefs.getString('preferred_language') ?? 'Tamil';
      });
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final passageCardColor = isDark
        ? const Color(0xFF1E1E2C)
        : const Color(0xFF2D6FB5);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF030305)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(e['title'] ?? ''),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Passage
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: passageCardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.white.withValues(alpha: 0.26),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Passage",
                        style: TextStyle(
                          color: Color(0xFFC779D0),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Row(
                        children: [
                          const TtsSpeedControl(compact: true),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () async {
                              if (_isSpeaking) {
                                await _ttsService.stop();
                                setState(() => _isSpeaking = false);
                              } else {
                                setState(() => _isSpeaking = true);
                                await _ttsService.speak(
                                  e['passage'] ?? '',
                                  tag: false,
                                );
                                // Reset icon after speech completes
                                if (mounted) {
                                  setState(() => _isSpeaking = false);
                                }
                              }
                            },
                            icon: Icon(
                              _isSpeaking
                                  ? Icons.stop_circle_rounded
                                  : Icons.volume_up_rounded,
                              color: const Color(0xFFC779D0),
                            ),
                            tooltip: _isSpeaking
                                ? "Stop Reading"
                                : "Read Aloud",
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    e['passage'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.6,
                      fontFamily: 'Inter',
                    ),
                  ),
                  _buildTranslationSection(e),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Comprehension",
              style: TextStyle(
                color: onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Question 1
            if (e['q1']?.isNotEmpty ?? false) ...[
              _buildQuestionBlock(e['q1']!, e['a1']!, 'q1'),
              const SizedBox(height: 24),
            ],

            // Question 2
            if (e['q2']?.isNotEmpty ?? false) ...[
              _buildQuestionBlock(e['q2']!, e['a2']!, 'q2'),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
      floatingActionButton: _allQuestionsCorrect()
          ? FloatingActionButton.extended(
              onPressed: _goToNextExercise,
              backgroundColor: const Color(0xFFC779D0),
              label: const Text(
                "Next Mission",
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  bool _allQuestionsCorrect() {
    bool q1Correct = true;
    if (widget.exercise['q1']?.isNotEmpty ?? false) {
      q1Correct = _results['q1'] == true;
    }

    bool q2Correct = true;
    if (widget.exercise['q2']?.isNotEmpty ?? false) {
      q2Correct = _results['q2'] == true;
    }

    return q1Correct && q2Correct;
  }

  void _goToNextExercise() {
    final nextIndex = widget.currentIndex + 1;
    if (nextIndex < widget.allExercises.length) {
      // Navigate to next exercise via parent (to show map animation)
      Navigator.pop(context, 'next');
    } else {
      // All missions completed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All missions completed for this level!"),
          backgroundColor: Color(0xFFC779D0),
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildQuestionBlock(String question, String answer, String key) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final bool? isCorrect = _results[key];
    final bool isChecked = isCorrect != null;
    final TextEditingController controller = TextEditingController(
      text: _userInputs[key] ?? '',
    );
    // Ensure cursor stays at end if rebuilding (basic hack, ideally distinct controllers in state)
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            color: onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (val) => _userInputs[key] = val,
                    controller: controller, // Use controller to keep text
                    enabled:
                        !isChecked ||
                        (isCorrect ==
                            false), // Allow retry? Or lock? User said "If wrong, x, then show me correct answer". implies done.
                    // Let's lock it if Correct. If Wrong, maybe keep locked and show answer?
                    // User: "If wrong, x, then show me the correct answer."
                    style: TextStyle(color: isDark ? Colors.white : onSurface),
                    decoration: InputDecoration(
                      hintText: "Type your answer...",
                      hintStyle: TextStyle(
                        color: onSurface.withValues(alpha: 0.45),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.86),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  if (isChecked) ...[
                    const SizedBox(height: 8),
                    if (isCorrect == true)
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Correct!",
                            style: TextStyle(color: Colors.greenAccent),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.cancel,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Incorrect",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Answer: $answer",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : onSurface.withValues(alpha: 0.74),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (!isChecked ||
                isCorrect ==
                    false) // Allow retry if wrong? Or just show answer?
              // "Show me the correct answer" implies immediate feedback.
              // I'll hide button if correct.
              IconButton.filled(
                onPressed: () => _checkAnswer(key, answer),
                icon: const Icon(Icons.arrow_forward_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFC779D0),
                  padding: const EdgeInsets.all(12),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _checkAnswer(String key, String correctAns) {
    if ((_userInputs[key]?.isEmpty ?? true)) return;

    final input = _userInputs[key]!.trim().toLowerCase();
    final target = correctAns.trim().toLowerCase();

    // Logic: Simple normalization.
    // Remove final punctuation (.) from both to be safe
    final normInput = input.replaceAll(RegExp(r'[^\w\s]'), '');
    final normTarget = target.replaceAll(RegExp(r'[^\w\s]'), '');

    // Fuzzy Logic: 50% Similarity Threshold
    double similarity = _calculateSimilarity(normInput, normTarget);
    bool isCorrect = similarity >= 0.5;

    setState(() {
      _results[key] = isCorrect;

      // Check if ALL questions are now correct
      bool q1Correct = true;
      if (widget.exercise['q1']?.isNotEmpty ?? false) {
        q1Correct = _results['q1'] == true;
      }

      bool q2Correct = true;
      if (widget.exercise['q2']?.isNotEmpty ?? false) {
        q2Correct = _results['q2'] == true;
      }

      if (q1Correct && q2Correct) {
        DataService().saveMasteryProgress(
          'reading',
          widget.exercise['id'] ?? 'unknown',
        );
      }
    });
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    int dist = _levenshtein(s1, s2);
    int maxLength = s1.length > s2.length ? s1.length : s2.length;
    return 1.0 - (dist / maxLength);
  }

  int _levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.filled(s2.length + 1, 0);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s2.length + 1; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        int cost = (s1.codeUnitAt(i) == s2.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((curr, next) => curr < next ? curr : next);
      }

      for (int j = 0; j < s2.length + 1; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[s2.length];
  }

  Widget _buildTranslationSection(Map<String, String> e) {
    String translation = '';
    String label = '';

    if (_userLanguage == 'Tamil') {
      translation = e['tamil'] ?? '';
      label = 'Tamil';
    } else if (_userLanguage == 'Hindi') {
      translation = e['hindi'] ?? '';
      label = 'Hindi';
    }

    if (translation.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _showTranslation = !_showTranslation),
          child: Row(
            children: [
              Icon(
                Icons.translate,
                color: Colors.white.withValues(alpha: 0.6),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _showTranslation
                    ? "Hide Translation"
                    : "Show Translation ($label)",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
        if (_showTranslation) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFC779D0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFC779D0).withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              translation,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
