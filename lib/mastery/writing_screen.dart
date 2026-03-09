import 'package:flutter/material.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/widgets/mastery_level_map.dart';
import 'package:gravity_app/widgets/mastery_difficulty_dialog.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  final DataService _dataService = DataService();
  List<Map<String, String>> _exercises = [];
  bool _isLoading = true;

  // Track inputs and visibility for each exercise
  final Map<int, String> _userInputs = {};
  final Map<int, bool> _showAnswers = {};
  final Map<int, bool> _showHints = {};
  Set<String> _completedIds = {}; // Track completed exercises
  String _selectedDifficulty = 'All'; // Filter State
  String _userLanguage = 'Tamil'; // Default Language Preference

  // Drag & Drop State
  final Map<int, bool> _isDragDropMode = {};
  final Map<int, List<String>> _availableTokens = {};
  final Map<int, List<String>> _selectedTokens = {};

  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    String? difficulty = prefs.getString('difficulty_writing');

    if (difficulty == null) {
      await Future.delayed(Duration.zero);
      if (!mounted) return;

      final selected = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const MasteryDifficultyDialog(
          title: "Writing Mastery",
          initialLevel: 'Beginner',
        ),
      );

      difficulty = selected ?? 'Beginner';
      await prefs.setString('difficulty_writing', difficulty);
      // Sync to cloud
      await DataService().saveProgressToCloud('difficulty_writing', difficulty);
    }

    setState(() {
      _selectedDifficulty = difficulty!;
    });
    _loadExercises();
  }

  Future<void> _loadUserLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userLanguage = prefs.getString('preferred_language') ?? 'Tamil';
      });
    }
  }

  Future<void> _loadExercises() async {
    final data = await _dataService.getWritingExercises();
    final completed = await _dataService.getCompletedExerciseIds('writing');

    setState(() {
      _exercises = data;
      _completedIds = completed.toSet();
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
              title: "Writing Mastery",
              exercises: _filteredExercises,
              completedIds: _completedIds.toList(),
              onTapExercise: (exercise) {
                // Determine index for existing logic if needed
                int index = _filteredExercises.indexOf(exercise);
                _openWritingDialog(exercise, index);
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

  void _showDifficultyDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => MasteryDifficultyDialog(
        title: "Writing Mastery",
        initialLevel: _selectedDifficulty,
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedDifficulty = selected;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('difficulty_writing', selected);
      await DataService().saveProgressToCloud('difficulty_writing', selected);
    }
  }

  void _openWritingDialog(Map<String, String> exercise, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E2C)
            : const Color(0xFF2D6FB5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: _buildWritingCard(
                exercise,
                index,
                setDialogState,
                onNext: () async {
                  final messenger = ScaffoldMessenger.of(this.context);
                  Navigator.pop(context); // Close Current Dialog

                  // Wait for dialog to fully close and render a frame
                  await Future.delayed(const Duration(milliseconds: 100));

                  // Reload exercises to update completedIds - this triggers animation
                  await _loadExercises();

                  // Wait for animation to complete (800ms animation + 200ms buffer)
                  if (index + 1 < _filteredExercises.length) {
                    await Future.delayed(const Duration(milliseconds: 1000));
                    if (mounted) {
                      _openWritingDialog(
                        _filteredExercises[index + 1],
                        index + 1,
                      );
                    }
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("All missions completed for this level!"),
                        backgroundColor: Color(0xFFFEAC5E),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    ).then((_) {
      // Reload when user manually closes dialog (back button)
      // onNext handles reload when using Next Mission button
      if (mounted) {
        _loadExercises();
      }
    });
  }

  // Filter Logic
  List<Map<String, String>> get _filteredExercises {
    if (_selectedDifficulty == 'All') return _exercises;
    return _exercises.where((e) {
      final level = e['level'] ?? 'Beginner';
      return level.toLowerCase().contains(
        _selectedDifficulty.toLowerCase(),
      ); // Flexible match
    }).toList();
  }

  List<String> _generateTokensWithDistractors(String correct, String prompt) {
    String p = prompt.trim();
    String c = correct.trim();
    String target = c;

    // 1. Robust Target Extraction (Remove Prefix/Suffix)
    if (p.contains('___')) {
      final parts = p.split('___');
      final prefix = parts[0].trim(); // e.g. "He"
      final suffix = parts.length > 1
          ? parts[1].trim()
          : ''; // e.g. "to the store"

      // We try to match the prompt parts against the correct answer to isolate the middle
      // Normalizing for case/spacing is safer
      String lowerC = c.toLowerCase();
      String lowerPrefix = prefix.toLowerCase();
      String lowerSuffix = suffix.toLowerCase();

      int startIndex = 0;
      int endIndex = c.length;

      if (lowerPrefix.isNotEmpty && lowerC.indexOf(lowerPrefix) == 0) {
        startIndex = prefix.length;
      }

      if (lowerSuffix.isNotEmpty && lowerC.endsWith(lowerSuffix)) {
        endIndex = c.length - suffix.length;
      }

      if (startIndex < endIndex) {
        target = c.substring(startIndex, endIndex).trim();
      }
    }

    // 2. Distractor Logic
    List<String> options = [target];
    String lowerTarget = target.toLowerCase();

    // Common Grammar Groups
    final List<Set<String>> groups = [
      {'a', 'an', 'the'},
      {
        'in',
        'on',
        'at',
        'to',
        'for',
        'from',
        'with',
        'by',
        'of',
        'into',
        'onto',
      },
      {'is', 'am', 'are', 'was', 'were', 'be', 'been', 'being'},
      {'he', 'she', 'it', 'they', 'we', 'you', 'i'},
      {'his', 'her', 'their', 'my', 'your', 'our', 'its'},
      {'do', 'does', 'did', 'done'},
      {'has', 'have', 'had'},
      {'this', 'that', 'these', 'those'},
      {
        'can',
        'could',
        'shall',
        'should',
        'will',
        'would',
        'may',
        'might',
        'must',
      },
      {'who', 'what', 'where', 'when', 'why', 'how', 'which'},
      {'and', 'but', 'or', 'so', 'because', 'although', 'if', 'unless'},
      {'always', 'usually', 'often', 'never', 'sometimes'},
      {'much', 'many', 'some', 'any', 'few', 'little'},
      {'good', 'bad', 'better', 'worse', 'best', 'worst'},
      {'big', 'small', 'large', 'tiny', 'huge'},
      {'happy', 'sad', 'angry', 'excited', 'bored'},
    ];

    bool foundGroup = false;
    for (var group in groups) {
      if (group.contains(lowerTarget)) {
        List<String> distractors = group
            .where((w) => w != lowerTarget)
            .toList();
        distractors.shuffle();
        if (distractors.length > 3) distractors = distractors.sublist(0, 3);
        options.addAll(distractors);
        foundGroup = true;
        break;
      }
    }

    if (!foundGroup) {
      // Fallback: Pick 3 random words from a generic list or other exercises if available
      final fallbackDistractors = [
        'is',
        'the',
        'to',
        'for',
        'with',
        'play',
        'go',
        'run',
        'eat',
        'see',
      ];
      // Try to get from other exercises first
      if (_filteredExercises.isNotEmpty) {
        for (var ex in _filteredExercises) {
          if (options.length >= 4) break;
          // Extract a word from another answer
          String other = ex['answer'] ?? '';
          // Basic extraction
          List<String> words = other.split(' ');
          if (words.isNotEmpty) {
            String w = words[DateTime.now().millisecond % words.length];
            String cleanW = w.replaceAll(RegExp(r'[^\w]'), '');
            if (cleanW.isNotEmpty && !options.contains(cleanW)) {
              options.add(cleanW);
            }
          }
        }
      }

      // Fill remaining with generic fallbacks
      int safety = 0;
      while (options.length < 4 && safety < 20) {
        fallbackDistractors.shuffle();
        String tick = fallbackDistractors.first;
        if (!options.contains(tick)) options.add(tick);
        safety++;
      }
    }

    // Safety check: ensure target is in options
    if (!options.contains(target)) options.add(target);

    return options;
  }

  Widget _buildWritingCard(
    Map<String, String> exercise,
    int listIndex,
    StateSetter setDialogState, {
    required VoidCallback onNext,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use ID for unique tracking
    final String id = exercise['id'] ?? listIndex.toString();
    final int stateKey = id.hashCode;

    String correct = exercise['answer'] ?? '';
    String instructions = exercise['instruction'] ?? '';
    String prompt = exercise['input'] ?? '';

    bool isAnswerShown = _showAnswers[stateKey] ?? false;
    String userText = _userInputs[stateKey] ?? '';

    // Check if previously completed
    bool isMastered = _completedIds.contains(id);

    bool isChecked = isAnswerShown;
    bool isCorrect = false;

    if (isChecked && userText.isNotEmpty) {
      // Comparison Logic (Review for Fill-in-Blank)
      String normUser = userText.trim().toLowerCase().replaceAll(
        RegExp(r'[^\w\s]'),
        '',
      );
      String normCorrect = correct.trim().toLowerCase().replaceAll(
        RegExp(r'[^\w\s]'),
        '',
      );

      // Direct Match
      bool directMatch = normUser == normCorrect;

      // Reconstructed Match (Fill in blank)
      bool reconstructedMatch = false;
      if (_isDragDropMode[stateKey] == true && prompt.contains('___')) {
        String reconstructed = prompt.replaceFirst('___', userText);
        String normReconstructed = reconstructed.toLowerCase().replaceAll(
          RegExp(r'[^\w\s]'),
          '',
        );
        reconstructedMatch = normReconstructed == normCorrect;
      }

      isCorrect = directMatch || reconstructedMatch;
    }

    // Controller hack to persist text across rebuilds
    final TextEditingController controller = TextEditingController(
      text: _userInputs[stateKey],
    );
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    // Initialize Drag & Drop Mode if not set
    _isDragDropMode.putIfAbsent(stateKey, () => false);

    // Initialize Tokens if needed
    if (_isDragDropMode[stateKey] == true &&
        (!_availableTokens.containsKey(stateKey) ||
            _availableTokens[stateKey]!.isEmpty &&
                _selectedTokens[stateKey]!.isEmpty)) {
      // Smart Token Generation
      List<String> tokens = _generateTokensWithDistractors(correct, prompt);

      tokens.shuffle();
      _availableTokens[stateKey] = tokens;
      _selectedTokens[stateKey] = [];
    }

    // Helper to move token
    void moveToken(String token, bool toSelected) {
      if (isCorrect) return; // Locked if finished

      setDialogState(() {
        // Single Slot Logic for Fill-in-Blank:
        if (toSelected) {
          // If slot is occupied (has user input), return existing to available first
          String current = _userInputs[stateKey] ?? '';
          if (current.isNotEmpty) {
            _availableTokens[stateKey]?.add(current);
            _selectedTokens[stateKey]
                ?.clear(); // Should be redundant if we manage inputs only
          }

          _availableTokens[stateKey]?.remove(token);
          // We don't really rely on _selectedTokens list for ordering in this new mode,
          // but keeping it syncs for future extension or fallback logic.
          // For single slot, selected list has max 1 item.
          _selectedTokens[stateKey] = [token];

          _userInputs[stateKey] = token; // Single value
        } else {
          // Removing from slot
          _selectedTokens[stateKey]?.remove(token);
          _availableTokens[stateKey]?.add(token);
          _userInputs[stateKey] = "";
        }

        // Reset feedback
        if (isChecked) _showAnswers[stateKey] = false;
      });
      SoundService().playTap();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : const Color(0xFF2D6FB5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Badges and Focus (Wrap for overflow protection)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Mode Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  _isDragDropMode[stateKey] = false;
                                  _userInputs[stateKey] = ""; // Reset
                                  _showAnswers[stateKey] = false;
                                });
                              },
                              icon: const Icon(
                                Icons.keyboard_rounded,
                                size: 20,
                              ),
                              color: !(_isDragDropMode[stateKey] ?? false)
                                  ? const Color(0xFFFEAC5E)
                                  : Colors.white24,
                              tooltip: "Typing Mode",
                            ),
                            Container(
                              width: 1,
                              height: 20,
                              color: Colors.white10,
                            ),
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  _isDragDropMode[stateKey] = true;
                                  _userInputs[stateKey] = ""; // Reset
                                  _showAnswers[stateKey] = false;
                                  // Clear tokens to re-init shuffle next build
                                  _availableTokens.remove(stateKey);
                                  _selectedTokens[stateKey] = [];
                                });
                              },
                              icon: const Icon(
                                Icons.touch_app_rounded,
                                size: 20,
                              ),
                              color: (_isDragDropMode[stateKey] ?? false)
                                  ? const Color(0xFFFEAC5E)
                                  : Colors.white24,
                              tooltip: "Puzzle Mode",
                            ),
                          ],
                        ),
                      ),

                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEAC5E).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          exercise['type'] ?? 'Exercise',
                          style: const TextStyle(
                            color: Color(0xFFFEAC5E),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Level Badge with Color Logic
                  Builder(
                    builder: (context) {
                      String level = exercise['level'] ?? 'Beginner';
                      Color levelColor = Colors.greenAccent;
                      if (level.toLowerCase().contains('inter')) {
                        levelColor = Colors.orangeAccent;
                      }
                      if (level.toLowerCase().contains('adv')) {
                        levelColor = Colors.redAccent;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: levelColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          level,
                          style: TextStyle(
                            color: levelColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                instructions,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Hide static prompt in DragDrop mode as the UI displays it interactively
              if (exercise['input']!.isNotEmpty &&
                  (_isDragDropMode[stateKey] != true)) ...[
                Text(
                  "Prompt: ${exercise['input']}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    backgroundColor: Colors.white10,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // --- INPUT AREA (Conditional) ---
              if (_isDragDropMode[stateKey] == true) ...[
                // FILL-IN-THE-BLANK UI

                // 1. The Sentence with Drop Zone
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green.withValues(alpha: 0.5)
                          : (isChecked
                                ? Colors.red.withValues(alpha: 0.5)
                                : Colors.white10),
                    ),
                  ),
                  child: Builder(
                    builder: (context) {
                      // Split prompt into parts for the blank
                      // Expected Prompt Format: "He ___ to the store."
                      String p = exercise['input'] ?? '';
                      if (!p.contains('___')) {
                        // Fallback if no blank is defined
                        p = "$p ___";
                      }

                      List<String> parts = p.split('___');
                      String prefix = parts[0];
                      String suffix = parts.length > 1 ? parts[1] : '';

                      // Current value in blank
                      String currentValue = _userInputs[stateKey] ?? '';

                      return Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (prefix.isNotEmpty)
                            Text(
                              prefix,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                          const SizedBox(width: 8),

                          // THE DROP ZONE
                          DragTarget<String>(
                            onWillAcceptWithDetails: (data) =>
                                !isCorrect, // Lock if correct
                            onAcceptWithDetails: (data) {
                              moveToken(data.data, true); // Move to selected
                            },
                            builder: (context, candidateData, rejectedData) {
                              bool hasValue = currentValue.isNotEmpty;
                              bool isHovering = candidateData.isNotEmpty;

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 80,
                                  minHeight: 40,
                                ),
                                decoration: BoxDecoration(
                                  color: hasValue
                                      ? const Color(0xFFFEAC5E)
                                      : (isHovering
                                            ? Colors.white24
                                            : Colors.white10),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: hasValue
                                        ? Colors.transparent
                                        : Colors.white30,
                                    width: 2,
                                    style: hasValue
                                        ? BorderStyle.solid
                                        : BorderStyle.solid,
                                  ),
                                ),
                                child: hasValue
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            currentValue,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () {
                                              // Clear value (return to pool)
                                              moveToken(currentValue, false);
                                            },
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Icon(
                                        Icons.download_rounded,
                                        color: Colors.white24,
                                        size: 20,
                                      ),
                              );
                            },
                          ),

                          const SizedBox(width: 8),
                          if (suffix.isNotEmpty)
                            Text(
                              suffix,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Options Pool (Draggable)
                const Text(
                  "Drag the correct option:",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: (_availableTokens[stateKey] ?? []).map((token) {
                    return Draggable<String>(
                      data: token,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFEAC5E,
                            ).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 10),
                            ],
                          ),
                          child: Text(
                            token,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          token,
                          style: const TextStyle(color: Colors.transparent),
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () => moveToken(token, true), // Tap fallback
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            token,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                // TYPING UI (Standard)
                TextField(
                  controller: controller, // Use controller
                  onChanged: (val) {
                    _userInputs[stateKey] = val;
                    if (isChecked) {
                      setState(() {
                        _showAnswers[stateKey] = false;
                      });
                    }
                  },
                  enabled: !isCorrect,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Type your answer here...",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isChecked || !isCorrect)
                    FilledButton.icon(
                      onPressed: () {
                        // Tap Sound
                        SoundService().playTap();

                        // Get latest input directly from state
                        final currentInput = _userInputs[stateKey] ?? '';

                        if (currentInput.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please provide an answer first!"),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        setDialogState(() {
                          _showAnswers[stateKey] = true; // Mark as Checked
                        });

                        // Logic check for progress tracking
                        String normUser = currentInput
                            .trim()
                            .toLowerCase()
                            .replaceAll(RegExp(r'[^\w\s]'), '');
                        String normCorrect = correct
                            .trim()
                            .toLowerCase()
                            .replaceAll(RegExp(r'[^\w\s]'), '');

                        if (normUser == normCorrect) {
                          SoundService().playSuccess();
                          _dataService.saveMasteryProgress(
                            'writing',
                            exercise['id'] ?? listIndex.toString(),
                          );
                        } else {
                          SoundService().playError();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFEAC5E),
                        foregroundColor: Colors.black87,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text("Check Answer"),
                    ),
                ],
              ),

              // Hint Section (Dynamic based on Language Preference)
              if (!isChecked) ...[
                Builder(
                  builder: (context) {
                    // Determine if we have a relevant hint for the user's language
                    String hintText = '';
                    String hintLabel = '';

                    if (_userLanguage == 'Tamil' &&
                        exercise['tamil']?.isNotEmpty == true) {
                      hintText = exercise['tamil']!;
                      hintLabel = "Tamil";
                    } else if (_userLanguage == 'Hindi' &&
                        exercise['hindi']?.isNotEmpty == true) {
                      hintText = exercise['hindi']!;
                      hintLabel = "Hindi";
                    }

                    if (hintText.isEmpty) return const SizedBox.shrink();

                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              _showHints[stateKey] =
                                  !(_showHints[stateKey] ?? false);
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.translate_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                (_showHints[stateKey] ?? false)
                                    ? "Hide Hint"
                                    : "Need a Hint? ($hintLabel)",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showHints[stateKey] == true) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Text(
                              "$hintLabel: $hintText",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],

              // Feedback Section
              if (isChecked) ...[
                const SizedBox(height: 20),

                // Result Indicator
                Row(
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCorrect ? "Correct!" : "Not quite right",
                      style: TextStyle(
                        color: isCorrect
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // If incorrect (or strictly if requested "show me correct answer"), show correct answer
                if (!isCorrect)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEAC5E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFEAC5E).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Answer:",
                          style: TextStyle(
                            color: Color(0xFFFEAC5E),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          correct,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        if (exercise['explanation']?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          Text(
                            exercise['explanation']!,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else if (isCorrect) ...[
                  // Success Message/Explanation
                  if (exercise['explanation']?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        exercise['explanation']!,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Next Mission Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton.icon(
                        onPressed: onNext,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text("Next Mission"),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFEAC5E),
                          foregroundColor: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
          // Success Indicator (Top Right Tick)
          if (isMastered)
            const Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}
