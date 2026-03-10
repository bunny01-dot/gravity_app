import 'package:flutter/material.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/widgets/mastery_difficulty_dialog.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({super.key});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen>
    with TickerProviderStateMixin {
  final DataService _dataService = DataService();
  List<Map<String, String>> _exercises = [];
  bool _isLoading = true;
  List<String> _categories = [];
  String _selectedDifficulty = 'All';
  List<String> _completedIds = []; // Completed tracking

  // Track state per exercise
  final Map<int, ValueNotifier<bool>> _isRecording = {};
  final Map<int, ValueNotifier<bool>> _showFeedback = {};
  final Map<int, ValueNotifier<String>> _recognizedText = {};

  // Speech recognition
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadSettings();
    _loadCompletedStatus();
  }

  ValueNotifier<bool> _recordingFor(int index) {
    return _isRecording.putIfAbsent(index, () => ValueNotifier<bool>(false));
  }

  ValueNotifier<bool> _feedbackFor(int index) {
    return _showFeedback.putIfAbsent(index, () => ValueNotifier<bool>(false));
  }

  ValueNotifier<String> _recognizedFor(int index) {
    return _recognizedText.putIfAbsent(index, () => ValueNotifier<String>(''));
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onError: (error) => debugPrint('Speech recognition error: $error'),
      onStatus: (status) => debugPrint('Speech recognition status: $status'),
    );
    if (!_speechAvailable) {
      debugPrint('Speech recognition not available');
    }
  }

  Future<void> _loadCompletedStatus() async {
    final completed = await _dataService.getCompletedExerciseIds('speaking');
    if (mounted) {
      setState(() {
        _completedIds = completed;
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    String? difficulty = prefs.getString('difficulty_speaking');

    if (difficulty == null) {
      await Future.delayed(Duration.zero);
      if (!mounted) return;

      final selected = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const MasteryDifficultyDialog(
          title: "Speaking Mastery",
          initialLevel: 'Beginner',
        ),
      );

      difficulty = selected ?? 'Beginner';
      await prefs.setString('difficulty_speaking', difficulty);
    }

    setState(() {
      _selectedDifficulty = difficulty!;
    });
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final data = await _dataService.getSpeakingExercises();

    // Extract unique categories
    final categories = data
        .map((e) => e['category'] ?? 'General')
        .toSet()
        .toList();
    if (categories.isEmpty) categories.add('General');
    categories.sort();

    setState(() {
      _exercises = data;
      _categories = categories;
      _isLoading = false;
    });
    debugPrint(
      "SpeakingScreen: Loaded ${_exercises.length} exercises. Categories: $_categories",
    );
  }

  // Check periodically if speech recognition has stopped
  void _checkSpeechCompletion(int index, Map<String, String> exercise) {
    if (!mounted) return;

    // Check if still listening
    if (_speech.isListening) {
      // Still listening, check again in 500ms
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkSpeechCompletion(index, exercise);
      });
    } else {
      // Speech has stopped, process the result
      final recording = _recordingFor(index);
      if (mounted && recording.value) {
        recording.value = false;
        _processRecognizedSpeech(index, exercise);
      }
    }
  }

  // Process the recognized speech and show feedback
  void _processRecognizedSpeech(int index, Map<String, String> exercise) {
    final recognized = _recognizedFor(index).value;
    final expectedText = exercise['prompt'] ?? '';

    debugPrint(
      'Processing speech - Recognized: "$recognized", Expected: "$expectedText"',
    );

    _feedbackFor(index).value = true;

    // Mark progress
    // Use robust ID: Trim, and fallback to index if empty (handles missing CSV IDs)
    final String rawId = exercise['id']?.toString().trim() ?? '';
    final String idToSave = rawId.isNotEmpty ? rawId : index.toString();

    _dataService.saveMasteryProgress('speaking', idToSave);
    _loadCompletedStatus(); // Refresh badge immediately
  }

  void _showDifficultyDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => MasteryDifficultyDialog(
        title: "Speaking Mastery",
        initialLevel: _selectedDifficulty,
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedDifficulty = selected;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('difficulty_speaking', selected);
    }
  }

  int _selectedCategoryIndex = 0;

  @override
  void dispose() {
    for (final notifier in _isRecording.values) {
      notifier.dispose();
    }
    for (final notifier in _showFeedback.values) {
      notifier.dispose();
    }
    for (final notifier in _recognizedText.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    // Filter by difficulty globally
    final difficultyFiltered = _selectedDifficulty == 'All'
        ? _exercises
        : _exercises.where((e) {
            final level = e['level'] ?? 'Beginner';
            return level.toLowerCase().contains(
              _selectedDifficulty.toLowerCase(),
            );
          }).toList();

    // Get current category exercises
    final currentCategory = _categories.isNotEmpty
        ? _categories[_selectedCategoryIndex]
        : 'General';

    final categoryExercises = difficultyFiltered
        .where((e) => (e['category'] ?? 'General') == currentCategory)
        .toList();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF030305)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Speaking Mastery"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showDifficultyDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 16),
                _buildCategoryPills(),
                const SizedBox(height: 16),
                Expanded(
                  child: categoryExercises.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mic_off_rounded,
                                size: 48,
                                color: onSurface.withValues(alpha: 0.34),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "No '$currentCategory' exercises\nfor $_selectedDifficulty level",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.66),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: categoryExercises.length,
                          itemBuilder: (context, index) {
                            final exercise = categoryExercises[index];
                            final originalIndex = _exercises.indexOf(exercise);
                            if (originalIndex == -1) return const SizedBox();
                            return _buildSpeakingCard(exercise, originalIndex);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryPills() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (c, i) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          final category = _categories[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.82)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : onSurface.withValues(alpha: isDark ? 0.1 : 0.12),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? Colors.white60
                            : onSurface.withValues(alpha: 0.7)),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpeakingCard(Map<String, String> exercise, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recording = _recordingFor(index);
    final feedback = _feedbackFor(index);
    final recognized = _recognizedFor(index);
    final merged = Listenable.merge([recording, feedback, recognized]);

    return AnimatedBuilder(
      animation: merged,
      builder: (context, _) {
        final isRec = recording.value;
        final showFeed = feedback.value;
        final recognizedText = recognized.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E2C).withValues(alpha: 0.8)
                : const Color(0xFF2D6FB5).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF4BC0C8).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4BC0C8).withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4BC0C8).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exercise['task_type'] ?? 'Speaking',
                      style: const TextStyle(
                        color: Color(0xFF4BC0C8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Spacer(),
                  Builder(
                    builder: (context) {
                      final String rawId =
                          exercise['id']?.toString().trim() ?? '';
                      final String checkId = rawId.isNotEmpty
                          ? rawId
                          : index.toString();
                      final bool isCompleted = _completedIds.contains(checkId);

                      return Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.record_voice_over,
                        color: isCompleted ? Colors.green : Colors.white24,
                        size: 20,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Role / Prompt
              Text(
                exercise['prompt'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Interaction Area
              if (!showFeed)
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      if (!_speechAvailable) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Speech recognition not available'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      final isCurrentlyRecording = recording.value;

                      if (!isCurrentlyRecording) {
                        // Start listening
                        recording.value = true;
                        recognized.value = '';

                        await _speech.listen(
                          onResult: (result) {
                            recognized.value = result.recognizedWords;
                            debugPrint(
                              'Recognized: ${result.recognizedWords}',
                            );
                          },
                          listenFor: const Duration(
                            seconds: 60,
                          ), // Max listening time - extended for longer exercises
                          pauseFor: const Duration(
                            seconds: 5,
                          ), // Auto-stop after 5s silence - gives user time to think
                          onSoundLevelChange: (level) {
                            // Optional: could show sound level visualization
                          },
                          listenOptions: stt.SpeechListenOptions(
                            partialResults: true,
                            cancelOnError: true,
                            listenMode: stt.ListenMode.confirmation,
                          ),
                        );

                        // Wait for speech to complete (it will auto-stop after pauseFor duration)
                        Future.delayed(const Duration(milliseconds: 500), () {
                          _checkSpeechCompletion(index, exercise);
                        });
                      } else {
                        // Manual stop if user taps again
                        await _speech.stop();
                        recording.value = false;
                        _processRecognizedSpeech(index, exercise);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isRec ? 80 : 70,
                      height: isRec ? 80 : 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRec
                            ? Colors.redAccent.withValues(alpha: 0.2)
                            : const Color(0xFF4BC0C8).withValues(alpha: 0.2),
                        border: Border.all(
                          color: isRec
                              ? Colors.redAccent
                              : const Color(0xFF4BC0C8),
                          width: 2,
                        ),
                        boxShadow: isRec
                            ? [
                                BoxShadow(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        isRec ? Icons.mic : Icons.mic_none,
                        color:
                            isRec ? Colors.redAccent : const Color(0xFF4BC0C8),
                        size: 30,
                      ),
                    ),
                  ),
                ),

              if (!showFeed)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                      Text(
                        isRec ? "Listening..." : "Tap mic to speak",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isRec ? Colors.redAccent : Colors.white38,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isRec && recognizedText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            recognizedText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Feedback Section
              if (showFeed) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // What user said
                      if (recognizedText.isNotEmpty) ...[
                        Row(
                          children: const [
                            Icon(
                              Icons.record_voice_over,
                              color: Color(0xFF4BC0C8),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "What you said:",
                              style: TextStyle(
                                color: Color(0xFF4BC0C8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recognizedText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 12),
                      ],
                      // Expected response
                      Row(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Expected Response",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exercise['response'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 8),
                      const Text(
                        "Evaluated on:",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      Text(
                        exercise['criteria'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
