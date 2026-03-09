import 'package:flutter/material.dart';

import 'package:gravity_app/services/data_service.dart';

import 'package:gravity_app/services/tts_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:gravity_app/widgets/mastery_difficulty_dialog.dart';

import 'package:gravity_app/widgets/mastery_level_map.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final DataService _dataService = DataService();

  final TtsService _ttsService = TtsService();

  List<Map<String, String>> _exercises = [];

  bool _isLoading = true;

  String _selectedDifficulty = 'All'; // Filter State

  bool _autoPlayEnabled = false; // Auto-play setting

  // Audio State (TTS)

  int? _playingIndex;

  bool _isPlaying = false;

  List<dynamic> _voices = [];

  double _speechRate = 0.5; // Default Speed

  // Answers

  final Map<String, String> _userInputs = {};

  final Map<String, bool> _showResult = {};

  final Map<String, String> _activeHints = {}; // New Hint State

  Set<String> _completedIds = {}; // Track completed exercises

  @override
  void initState() {
    super.initState();

    _loadSettings();

    _loadVoices();

    // Set completion handler is optional if we awaitSpeakCompletion(true)

    // but useful for cleanup if something goes wrong or interrupt

    _ttsService.setCompletionHandler(() {
      // Handled by await flow usually
    });
  }

  Future<void> _loadVoices() async {
    final voices = await _ttsService.getVoices();

    if (mounted) {
      setState(() {
        _voices = voices;
      });
    }
  }

  @override
  void dispose() {
    _ttsService.stop();

    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    String? difficulty = prefs.getString('difficulty_listening');

    if (difficulty == null) {
      // Defer dialog to next frame to avoid build conflicts

      await Future.delayed(Duration.zero);

      if (!mounted) return;

      final selected = await showDialog<String>(
        context: context,

        barrierDismissible: false,

        builder: (context) =>
            const MasteryDifficultyDialog(title: "Listening Mastery"),
      );

      difficulty = selected ?? 'Beginner';

      await prefs.setString('difficulty_listening', difficulty);

      // Sync to cloud

      await DataService().saveProgressToCloud(
        'difficulty_listening',

        difficulty,
      );
    }

    setState(() {
      _selectedDifficulty = difficulty!;

      _autoPlayEnabled = prefs.getBool('auto_play_audio') ?? false;
    });

    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final data = await _dataService.getListeningExercises();

    final completed = await _dataService.getCompletedExerciseIds('listening');

    setState(() {
      _exercises = data;

      _completedIds = completed.toSet();

      _isLoading = false;
    });
  }

  Future<void> _playTts(
    Map<String, String> exercise,

    int index, {

    StateSetter? dialogSetState,
  }) async {
    if (_playingIndex == index && _isPlaying) {
      await _ttsService.stop();

      if (mounted) {
        void update() {
          _isPlaying = false;
        }

        setState(update);

        if (dialogSetState != null) dialogSetState(update);
      }

      return;
    }

    // Stop current

    await _ttsService.stop();

    if (mounted) {
      void update() {
        _playingIndex = index;

        _isPlaying = true;
      }

      setState(update);

      if (dialogSetState != null) dialogSetState(update);
    }

    String sp1 = exercise['sp1'] ?? '';

    String sp2 = exercise['sp2'] ?? '';

    try {
      Map<String, String>? v1;

      Map<String, String>? v2;

      // Simple Voice Selection Logic

      if (_voices.length >= 2) {
        // Ideally find English voices

        var enVoices = _voices.where((v) {
          if (v is Map) {
            return v.toString().contains('en-US') ||
                v.toString().contains('en_US');
          }

          return false;
        }).toList();

        if (enVoices.isEmpty) enVoices = _voices.toList();

        if (enVoices.isNotEmpty) {
          v1 = Map<String, String>.from(enVoices[0] as Map);

          if (enVoices.length > 1) {
            v2 = Map<String, String>.from(enVoices[1] as Map);
          } else {
            v2 = v1;
          }
        }
      }

      // Speak SP 1

      if (sp1.isNotEmpty) {
        if (v1 != null) await _ttsService.setVoice(v1);

        await _ttsService.speak(sp1);

        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Speak SP 2

      if (sp2.isNotEmpty && _isPlaying) {
        if (v2 != null) await _ttsService.setVoice(v2);

        await _ttsService.speak(sp2);
      }
    } catch (e) {
      debugPrint("Playback error: $e");
    } finally {
      if (mounted) {
        void update() {
          _isPlaying = false;
        }

        setState(update);

        if (dialogSetState != null) dialogSetState(update);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    // GUARD: Detect empty filtered results

    final bool hasData = _exercises.isNotEmpty;

    final bool hasFilteredData = _filteredExercises.isNotEmpty;

    // Debug logging for "No lesson found" investigation

    if (hasData && !hasFilteredData) {
      debugPrint('[WARN] LISTENING MASTERY FILTER ISSUE:');

      debugPrint('  Total exercises loaded: ${_exercises.length}');

      debugPrint('  Filtered exercises: ${_filteredExercises.length}');

      debugPrint('  Selected difficulty: $_selectedDifficulty');

      debugPrint(
        '  Available levels in data: ${_exercises.map((e) => e['level']).toSet()}',
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF030305)
          : theme.scaffoldBackgroundColor,

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasData
          ? _buildNoDataMessage('No listening exercises found in assets.')
          : !hasFilteredData
          ? _buildNoDataMessage(
              'No "$_selectedDifficulty" level exercises found.\n\n'
              'Try selecting "All" or a different difficulty level.',

              showFilterButton: true,
            )
          : MasteryLevelMap(
              title: "Listening Mastery",

              exercises: _filteredExercises,

              completedIds: _completedIds.toList(),

              onTapExercise: (exercise) {
                int index = _filteredExercises.indexOf(exercise);

                _openListeningDialog(exercise, index);
              },

              onBack: () => Navigator.pop(context),

              useStarRating: true,

              layoutType: LevelMapLayout.timeline,

              actions: [
                IconButton(
                  icon: Icon(Icons.filter_list, color: onSurface),

                  onPressed: () => _showDifficultyDialog(),
                ),
              ],
            ),
    );
  }

  Widget _buildNoDataMessage(String message, {bool showFilterButton = false}) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(
              Icons.search_off_rounded,

              size: 80,

              color: onSurface.withValues(alpha: 0.34),
            ),

            const SizedBox(height: 24),

            Text(
              'No Lessons Available',

              style: TextStyle(
                color: onSurface,

                fontSize: 24,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              message,

              textAlign: TextAlign.center,

              style: TextStyle(
                color: onSurface.withValues(alpha: 0.72),

                fontSize: 16,

                height: 1.5,
              ),
            ),

            if (showFilterButton) ...[
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: () async {
                  // Reset to "All"

                  setState(() => _selectedDifficulty = 'All');

                  final prefs = await SharedPreferences.getInstance();

                  await prefs.setString('difficulty_listening', 'All');
                },

                icon: const Icon(Icons.restart_alt_rounded),

                label: const Text('Show All Levels'),

                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFE5196),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,

                    vertical: 16,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            TextButton.icon(
              onPressed: () => Navigator.pop(context),

              icon: Icon(
                Icons.arrow_back,
                color: onSurface.withValues(alpha: 0.62),
              ),

              label: Text(
                'Go Back',

                style: TextStyle(color: onSurface.withValues(alpha: 0.62)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDifficultyDialog() async {
    final selected = await showDialog<String>(
      context: context,

      builder: (context) =>
          const MasteryDifficultyDialog(title: "Listening Mastery"),
    );

    if (selected != null) {
      setState(() {
        _selectedDifficulty = selected;
      });

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('difficulty_listening', selected);

      await DataService().saveProgressToCloud('difficulty_listening', selected);
    }
  }

  void _openListeningDialog(Map<String, String> exercise, int index) {
    bool hasAutoPlayed = false;

    showDialog(
      context: context,

      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Trigger Auto-Play if enabled and not yet played

          if (_autoPlayEnabled && !hasAutoPlayed) {
            hasAutoPlayed = true;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _playTts(exercise, index, dialogSetState: setDialogState);
              }
            });
          }

          return Dialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E2C)
                : const Color(0xFF2D6FB5),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),

            child: SingleChildScrollView(
              child: _buildListeningCard(
                exercise,

                index,

                setDialogState,

                onNext: () {
                  Navigator.pop(context); // Close Current Dialog

                  // Wait a brief moment to show map transition if desired, or immediately open next

                  if (index + 1 < _filteredExercises.length) {
                    // Trigger map refresh to show unlocked status

                    // Just triggering rebuild via parent is tricky without callback return.

                    // But we can just open the next one, and when that closes, we are back at map.

                    // User requested "lesson menu should open and take me to the next lesson".

                    // Opening next dialog immediately satisfies "take me to next lesson" but skips "menu should open".

                    // So we will just Pop, and let the user click the next one?

                    // "Take me to the next lesson" usually implies auto-navigation.

                    // Compromise: Pop -> Wait -> Open Next.

                    // This briefly shows the map.

                    Future.delayed(const Duration(milliseconds: 1000), () {
                      if (mounted) {
                        _openListeningDialog(
                          _filteredExercises[index + 1],

                          index + 1,
                        );
                      }
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("All missions completed for this level!"),

                        backgroundColor: Color(0xFFFE5196),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    ).then((_) {
      // When dialog closes (either by back or next), refresh the map state

      // AND stop any playing audio immediately

      _ttsService.stop();

      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }

      _loadExercises();
    });
  }

  // Filter Logic

  List<Map<String, String>> get _filteredExercises {
    if (_selectedDifficulty == 'All') return _exercises;

    return _exercises.where((e) {
      final level = e['level'] ?? 'Beginner';

      return level.toLowerCase().contains(_selectedDifficulty.toLowerCase());
    }).toList();
  }

  Widget _buildListeningCard(
    Map<String, String> exercise,

    int index,

    StateSetter setDialogState, {

    required VoidCallback onNext,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool isCurrent = _playingIndex == index;

    final id = exercise['id'] ?? index.toString();

    bool resultVisible = _showResult[id] ?? false;

    String question = exercise['question'] ?? 'Listen to the audio.';

    String correctAnswer = exercise['answer'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : const Color(0xFF2D6FB5),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: isCurrent
              ? const Color(0xFFFE5196)
              : (isDark
                    ? Colors.white12
                    : Colors.white.withValues(alpha: 0.24)),

          width: isCurrent ? 2 : 1,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),

                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFFFE5196).withValues(alpha: 0.2)
                      : Colors.white10,

                  shape: BoxShape.circle,
                ),

                child: Icon(
                  Icons.headphones,

                  color: isCurrent ? const Color(0xFFFE5196) : Colors.white54,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      exercise['title'] ?? 'Mission Briefing',

                      style: const TextStyle(
                        color: Colors.white,

                        fontWeight: FontWeight.bold,

                        fontSize: 16,
                      ),
                    ),

                    Text(
                      "Listen closely...",

                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),

                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // TTS Player Control
          GestureDetector(
            onTap: () =>
                _playTts(exercise, index, dialogSetState: setDialogState),

            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black26
                    : Colors.white.withValues(alpha: 0.12),

                borderRadius: BorderRadius.circular(16),

                border: isCurrent && _isPlaying
                    ? Border.all(color: const Color(0xFFFE5196), width: 1)
                    : null,
              ),

              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(
                    (isCurrent && _isPlaying)
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,

                    color: const Color(0xFFFE5196),

                    size: 32,
                  ),

                  const SizedBox(width: 12),

                  Text(
                    (isCurrent && _isPlaying)
                        ? "Playing Audio..."
                        : "Play Communication",

                    style: const TextStyle(
                      color: Colors.white,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (isCurrent && _isPlaying) ...[
                    const SizedBox(width: 12),

                    const SizedBox(
                      width: 12,

                      height: 12,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,

                        color: Color(0xFFFE5196),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Speed Control
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.white54, size: 20),

              const SizedBox(width: 8),

              Text(
                "Speed: ${_speechRate.toStringAsFixed(1)}x",

                style: const TextStyle(color: Colors.white70),
              ),

              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFFE5196),

                    thumbColor: const Color(0xFFFE5196),

                    inactiveTrackColor: Colors.white10,

                    overlayColor: const Color(
                      0xFFFE5196,
                    ).withValues(alpha: 0.2),
                  ),

                  child: Slider(
                    value: _speechRate,

                    min: 0.25,

                    max: 1.0,

                    divisions: 3,

                    label: _speechRate.toStringAsFixed(2),

                    onChanged: (val) async {
                      setDialogState(() {
                        _speechRate = val;
                      });

                      setState(() {
                        _speechRate = val;
                      });

                      await _ttsService.setSpeechRate(val);

                      // Restart playback if currently playing

                      if (_isPlaying && _playingIndex == index) {
                        await _ttsService.stop();

                        // Small delay to ensure stop completes

                        await Future.delayed(const Duration(milliseconds: 100));

                        // Restart playback with new speed

                        _playTts(
                          exercise,

                          index,

                          dialogSetState: setDialogState,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Question Section
          Text(
            question,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 16,

              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            enabled: !resultVisible,

            onChanged: (val) => _userInputs[id] = val,

            controller: TextEditingController(text: _userInputs[id] ?? ''),

            style: const TextStyle(color: Colors.white),

            decoration: InputDecoration(
              hintText: "Type your answer...",

              hintStyle: const TextStyle(color: Colors.white24),

              filled: true,

              fillColor: Colors.black26,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),

                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Show Inline Hint if Active
          if (_activeHints.containsKey(id))
            Container(
              margin: const EdgeInsets.only(bottom: 16),

              padding: const EdgeInsets.all(12),

              width: double.infinity,

              decoration: BoxDecoration(
                color: const Color(0xFFFE5196).withValues(alpha: 0.1),

                borderRadius: BorderRadius.circular(12),

                border: Border.all(
                  color: const Color(0xFFFE5196).withValues(alpha: 0.3),
                ),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb,

                    color: Color(0xFFFE5196),

                    size: 16,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      "Hint: ${_activeHints[id]}",

                      style: const TextStyle(
                        color: Color(0xFFFE5196),

                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Hint and Check Answer buttons
          if (!resultVisible)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                // Hint Button
                TextButton.icon(
                  onPressed: () {
                    // Show first 3 words as hint

                    final words = correctAnswer.split(' ');

                    final hint = '${words.take(3).join(' ')}...';

                    setDialogState(() {
                      // We need a variable to store hint? The Dialog is stateful.

                      // But the builder doesn't have a local hint state variable declared above?

                      // Let's check _buildListeningCard. It's a method. We need state.

                      // We should add `String? _activeHint;` to the class state or pass it.

                      // Since this is inside `_buildListeningCard` which is called by `StatefulBuilder`,

                      // we can verify if `StatefulBuilder` maintains state. It does, but we need a place to store it.

                      // Use `_userInputs` map or a new map `_hints` in the class?

                      // Let's use a new map `_activeHints` in the class to be safe.

                      _activeHints[id] = hint;
                    });
                  },

                  icon: const Icon(Icons.lightbulb_outline, size: 18),

                  label: const Text("Hint"),

                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                ),

                // Check Answer Button
                FilledButton(
                  onPressed: () async {
                    // Logic check for progress tracking

                    String userText = _userInputs[id]?.trim() ?? '';

                    String correct = correctAnswer.trim();

                    // Debug logging

                    debugPrint('=== Answer Check Debug ===');

                    debugPrint('User input: "$userText"');

                    debugPrint('Correct answer: "$correct"');

                    debugPrint(
                      'Normalized user: "${_normalizeText(userText)}"',
                    );

                    debugPrint(
                      'Normalized correct: "${_normalizeText(correct)}"',
                    );

                    // Fuzzy Matching Validation

                    if (_isAnswerCorrect(userText, correct)) {
                      // 1. Save to Cloud/Disk (Await to ensure consistency)

                      await _dataService.saveMasteryProgress('listening', id);

                      // 2. Update Dialog UI (Show 'Next' button)

                      if (mounted) {
                        // Don't update _completedIds here - will be updated when Next Mission is clicked

                        // This ensures the animation triggers on the map

                        // _completedIds.add(id);

                        // setState(() {});

                        setDialogState(() {
                          _showResult[id] = true;
                        });
                      }
                    } else {
                      // Show error/shake with more detailed feedback

                      final distance = _levenshteinDistance(
                        _normalizeText(userText),

                        _normalizeText(correct),
                      );

                      debugPrint('Levenshtein distance: $distance');

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Incorrect. Try again! (Tip: Check spelling and punctuation)",
                          ),

                          backgroundColor: Colors.redAccent,

                          duration: const Duration(milliseconds: 2000),
                        ),
                      );
                    }
                  },

                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFE5196),
                  ),

                  child: const Text("Check Answer"),
                ),
              ],
            ),

          if (resultVisible)
            Container(
              margin: const EdgeInsets.only(top: 16),

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: const Color(0xFFFE5196).withValues(alpha: 0.1),

                borderRadius: BorderRadius.circular(12),

                border: Border.all(
                  color: const Color(0xFFFE5196).withValues(alpha: 0.3),
                ),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    "Correct Answer:",

                    style: TextStyle(
                      color: Color(0xFFFE5196),

                      fontWeight: FontWeight.bold,

                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    correctAnswer,

                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,

                    children: [
                      FilledButton.icon(
                        onPressed: onNext,

                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),

                        label: const Text("Next Mission"),

                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFE5196),

                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _isAnswerCorrect(String user, String correct) {
    if (user.isEmpty) return false;

    // 1. Normalize (Lowercase, Trim, Remove Punctuation, Collapse Whitespace)

    String normUser = _normalizeText(user);

    String normCorrect = _normalizeText(correct);

    // 2. Exact Match Check

    if (normUser == normCorrect) return true;

    // 3. Levenshtein Distance (Fuzzy Match)

    // Allow 1 error per 5-6 characters, minimum 1 or 2 edits allowed for short words

    int distance = _levenshteinDistance(normUser, normCorrect);

    int maxLength = normUser.length > normCorrect.length
        ? normUser.length
        : normCorrect.length;

    // Threshold: Allow ~30% error rate or at least 2 chars for longer sentences

    // Increased from 25% to 30% to be more forgiving of minor typos

    double errorRate = distance / maxLength;

    debugPrint(
      'Fuzzy match - Distance: $distance, MaxLength: $maxLength, ErrorRate: ${(errorRate * 100).toStringAsFixed(1)}%',
    );

    if (errorRate <= 0.30 || (distance <= 2 && maxLength > 5)) {
      debugPrint('[OK] Answer accepted (fuzzy match)');

      return true;
    }

    debugPrint(' Answer rejected (error rate too high)');

    return false;
  }

  String _normalizeText(String input) {
    return input
        .toLowerCase()
        // Remove all punctuation except spaces (and maybe apostrophes if crucial, but let's be loose)
        // Actually, removing apostrophes helps: "it's" vs "its"
        .replaceAll(RegExp(r"[^\w\s]"), "")
        // Replace multiple spaces with single space
        .replaceAll(RegExp(r"\s+"), " ")
        .trim();
  }

  int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;

    if (s.isEmpty) return t.length;

    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);

    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < t.length + 1; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;

        v1[j + 1] = [
          v1[j] + 1,

          v0[j + 1] + 1,

          v0[j] + cost,
        ].reduce((curr, next) => curr < next ? curr : next);
      }

      for (int j = 0; j < t.length + 1; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }
}
