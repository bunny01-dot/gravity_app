import 'dart:math';

import 'package:gravity_app/services/data_service.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpeakingPracticeScreen extends StatefulWidget {
  const SpeakingPracticeScreen({super.key});

  @override
  State<SpeakingPracticeScreen> createState() => _SpeakingPracticeScreenState();
}

class _SpeakingPracticeScreenState extends State<SpeakingPracticeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DataService _dataService = DataService();

  // --- Data Loading ---
  List<Map<String, String>> _allContent = [];
  Set<String> _completedIds = {};
  String _selectedLevel = 'Beginner';
  int _currentIndex = 0;
  bool _isLoading = true;

  // --- Pronunciation Variables ---
  late stt.SpeechToText _speech;
  final ValueNotifier<bool> _isListening = ValueNotifier<bool>(false);
  final ValueNotifier<String> _spokenText = ValueNotifier<String>("");
  // double _confidence = 1.0; // Unused

  // Fallbacks
  // Defaults removed to allow true empty state
  String get _targetPronunciationPhrase {
    final list = _getFilteredContent('Pronunciation');
    if (list.isEmpty) return "";
    // Safety check for index
    if (_currentIndex >= list.length) _currentIndex = 0;
    return list[_currentIndex]['text'] ?? "";
  }

  double _pronunciationScore = 0.0;
  bool _hasSpoken = false;

  // --- Dictation Variables ---
  late FlutterTts _flutterTts;
  final TextEditingController _dictationController = TextEditingController();

  // Fallbacks
  String get _targetDictationPhrase {
    final list = _getFilteredContent('Dictation');
    if (list.isEmpty) return "";
    // Safety check for index
    if (_currentIndex >= list.length) _currentIndex = 0;
    return list[_currentIndex]['text'] ?? "";
  }

  bool _isPlayingAudio = false;
  List<bool?> _dictationResult =
      []; // true = correct, false = wrong, null = no entry
  bool _hasCheckedDictation = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
          _resetState();
          // Auto-jump will happen if _jumpToNextIncompleteLesson is called,
          // but since we just reset, we should call it here.
          _jumpToNextIncompleteLesson();
        });
      }
    });

    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedLevel = prefs.getString('difficulty_speaking') ?? 'Beginner';
    });
    _loadContent();
  }

  Future<void> _loadContent({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    // 1. Load Completed IDs first
    final completed = await _dataService.getCompletedExerciseIds('speaking');

    // 2. Try Loading from Local Cache first
    var data = await _dataService.getAllItems('speaking');

    // 3. If empty, invalid, or forced, fetch from Google Sheet
    if (forceRefresh || data.isEmpty) {
      await _dataService.forceRefreshData();
      data = await _dataService.getAllItems('speaking');
    }

    if (mounted) {
      setState(() {
        _completedIds = completed.toSet();
        _allContent = data;
        _isLoading = false;
      });
      // Initial jump after content load
      _jumpToNextIncompleteLesson();
    }
  }

  void _jumpToNextIncompleteLesson() {
    // Determine category based on current tab
    final currentCategory = _selectedTabIndex == 0
        ? 'Pronunciation'
        : 'Dictation';
    final filtered = _getFilteredContent(currentCategory);

    // Find first item that is NOT in _completedIds
    int firstIncomplete = 0;
    bool foundIncomplete = false;

    for (int i = 0; i < filtered.length; i++) {
      final item = filtered[i];
      final id =
          item['id']?.toString() ?? item['text']?.hashCode.toString() ?? '';

      if (!_completedIds.contains(id)) {
        firstIncomplete = i;
        foundIncomplete = true;
        break;
      }
    }

    // If all completed, stays at 0
    if (!foundIncomplete && filtered.isNotEmpty) {
      // Optional: Could set to last index? Or 0. 0 is fine.
      firstIncomplete = 0;
    }

    // Update index safely
    if (mounted) {
      setState(() {
        if (filtered.isNotEmpty) {
          _currentIndex = firstIncomplete;
        } else {
          _currentIndex = 0;
        }
      });
    }
  }

  List<Map<String, String>> _getFilteredContent(String category) {
    // Normalizing category strings just in case
    return _allContent.where((item) {
      final cat = item['category']?.toString().toLowerCase().trim() ?? '';
      final lvl = item['level']?.toString().toLowerCase().trim() ?? '';

      // Check if category starts with the target (e.g. "Pronunciation" matches "Pronunciation")
      final catMatches = cat.contains(category.toLowerCase());
      final lvlMatches = lvl == _selectedLevel.toLowerCase();

      return catMatches && lvlMatches;
    }).toList();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Slower for dictation
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _isListening.dispose();
    _spokenText.dispose();
    _flutterTts.stop();
    _dictationController.dispose();
    super.dispose();
  }

  // --- Pronunciation Logic ---

  void _listen() async {
    if (!_isListening.value) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            _isListening.value = false;
            _calculateScore();
          }
        },
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        _isListening.value = true;
        if (_hasSpoken) {
          setState(() {
            _hasSpoken = false;
          });
        } else {
          _hasSpoken = false;
        }
        _spokenText.value = "";
        _speech.listen(
          onResult: (val) {
            _spokenText.value = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              // _confidence = val.confidence;
            }
            // Optional: If we want faster feedback on final result without waiting for status change
            if (val.finalResult) {
              // The status listener will handle the stop and calculation
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 2),
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            cancelOnError: true,
            listenMode: stt.ListenMode.dictation,
          ),
        );
      }
    } else {
      _isListening.value = false;
      _speech.stop();
      _calculateScore();
    }
  }

  void _calculateScore() {
    if (_spokenText.value.isEmpty) return;

    // Normalize strings (lowercase, remove punctuation) generally handles basic comparison
    String target = _targetPronunciationPhrase.toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );
    String spoken = _spokenText.value.toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );

    // Levenshtein distance simple implementation usage manual or via similarity ratio
    int distance = _levenshtein(target, spoken);
    int maxLength = max(target.length, spoken.length);
    if (maxLength == 0) {
      _pronunciationScore = 1.0;
    } else {
      _pronunciationScore = 1.0 - (distance / maxLength);
    }

    if (_pronunciationScore > 0.6) {
      // Save Progress
      final filtered = _getFilteredContent('Pronunciation');
      if (_currentIndex < filtered.length) {
        final item = filtered[_currentIndex];
        // Use ID if available, otherwise fallback to text hash or index (less reliable)
        final id = item['id'] ?? item['text'].hashCode.toString();
        _dataService.saveMasteryProgress('speaking', id);
        setState(() {
          _completedIds.add(id);
        });
      }
    }

    setState(() {
      _hasSpoken = true;
    });
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    int la = a.length;
    int lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;

    List<int> v0 = List<int>.filled(lb + 1, 0);
    List<int> v1 = List<int>.filled(lb + 1, 0);

    for (int i = 0; i <= lb; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < la; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < lb; j++) {
        int cost = (a.codeUnitAt(i) == b.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= lb; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[lb];
  }

  // --- Dictation Logic ---

  Future<void> _speakDictation() async {
    setState(() => _isPlayingAudio = true);
    await _flutterTts.speak(_targetDictationPhrase);
    setState(() => _isPlayingAudio = false);
  }

  void _checkDictation() {
    List<String> targetWords = _targetDictationPhrase.split(' ');
    List<String> userWords = _dictationController.text.trim().split(' ');

    _dictationResult = []; // Reset

    for (int i = 0; i < targetWords.length; i++) {
      if (i < userWords.length) {
        String t = targetWords[i].toLowerCase().replaceAll(
          RegExp(r'[^\w\s]'),
          '',
        );
        String u = userWords[i].toLowerCase().replaceAll(
          RegExp(r'[^\w\s]'),
          '',
        );
        _dictationResult.add(t == u);
      } else {
        _dictationResult.add(false); // Creating a mismatch
      }
    }

    setState(() {
      _hasCheckedDictation = true;
    });

    bool allCorrect = _dictationResult.every((r) => r == true);
    if (allCorrect) {
      final filtered = _getFilteredContent('Dictation');
      if (_currentIndex < filtered.length) {
        final item = filtered[_currentIndex];
        final id = item['id'] ?? item['text'].hashCode.toString();
        _dataService.saveMasteryProgress('speaking', id);
        setState(() {
          _completedIds.add(id);
        });
      }
    }

    FocusScope.of(context).unfocus(); // Close keyboard
  }

  int _selectedTabIndex = 0; // 0: Pronunciation, 1: Dictation

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Speaking & Dictation',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: BackButton(color: colorScheme.onSurface),
        actions: [
          IconButton(
            onPressed: () => _loadContent(forceRefresh: true),
            icon: Icon(Icons.sync_rounded, color: colorScheme.onSurfaceVariant),
            tooltip: "Refresh Content",
          ),
          IconButton(
            onPressed: _showLessonList,
            icon: Icon(Icons.list_alt_rounded, color: colorScheme.onSurface),
            tooltip: "Lesson List",
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildTabPills(),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildPronunciationTab()
                : _buildDictationTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPills() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.48)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillItem("Pronunciation", 0),
          const SizedBox(width: 8),
          _buildPillItem("Dictation", 1),
        ],
      ),
    );
  }

  Widget _buildPillItem(String label, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        if (_selectedTabIndex != index) {
          setState(() {
            _selectedTabIndex = index;
            // Reset interaction state (text, score) but logic will handle index
            _resetState();
          });
          // Find the correct lesson index for the newly selected category
          _jumpToNextIncompleteLesson();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _resetState() {
    setState(() {
      _hasSpoken = false;
      _hasCheckedDictation = false;
      _dictationController.clear();
      _dictationResult = [];
      _pronunciationScore = 0.0;
      _spokenText.value = "";
    });
  }

  Widget _buildNavigationControls(int count, {required bool canAdvance}) {
    final colorScheme = Theme.of(context).colorScheme;

    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _currentIndex > 0
              ? () {
                  setState(() {
                    _currentIndex--;
                  });
                  _resetState();
                }
              : null,
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: _currentIndex > 0
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        Text(
          "${_currentIndex + 1} / $count",
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: (_currentIndex < count - 1 && canAdvance)
              ? () {
                  setState(() {
                    _currentIndex++;
                  });
                  _resetState();
                }
              : null,
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            color: (_currentIndex < count - 1 && canAdvance)
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildPronunciationTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _getFilteredContent('Pronunciation');

    // NEW: Empty State Handling
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_off_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No pronunciation exercises available.",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Ensure index is valid
    if (_currentIndex >= filtered.length) {
      _currentIndex = 0;
    }

    final currentText = filtered[_currentIndex]['text'] ?? "";

    Color scoreColor = Colors.grey;
    String feedback = "Press the mic and read the text above.";
    if (_hasSpoken) {
      if (_pronunciationScore > 0.8) {
        scoreColor = Colors.greenAccent;
        feedback = "Excellent! Your pronunciation is clear.";
      } else if (_pronunciationScore > 0.5) {
        scoreColor = Colors.orangeAccent;
        feedback = "Good effort! Try to articulate more clearly.";
      } else {
        scoreColor = Colors.redAccent;
        feedback = "Try again. Listen to how it sounds.";
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavigationControls(filtered.length, canAdvance: _hasSpoken),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              currentText,
              style: TextStyle(
                fontSize: 22,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          // Dynamic Score Ring or Mic Button
          ValueListenableBuilder<bool>(
            valueListenable: _isListening,
            builder: (context, isListening, _) {
              return Column(
                children: [
                  GestureDetector(
                    onTap: _listen,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isListening ? colorScheme.primary : Colors.transparent,
                        border: Border.all(
                          color: isListening
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: 3,
                        ),
                        boxShadow: isListening
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        isListening ? Icons.mic : Icons.mic_none,
                        color: isListening
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        size: 50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isListening ? "Listening..." : "Tap to Speak",
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
          if (_hasSpoken) ...[
            Text(
              "Accuracy: ${(_pronunciationScore * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                color: scoreColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              feedback,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Text(
              "App heard: \"${_spokenText.value}\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (_currentIndex < filtered.length - 1) ...[
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentIndex++;
                    _resetState();
                  });
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text("Next Exercise"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildDictationTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _getFilteredContent('Dictation');

    // NEW: Empty State Handling
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No dictation exercises available.",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Index safety check done in getter usually, but good to be safe for count display
    int count = filtered.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNavigationControls(count, canAdvance: _hasCheckedDictation),
          const SizedBox(height: 20),
          const Text(
            "Listen to the audio and type exactly what you hear.",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Center(
            child: IconButton.filled(
              onPressed: _isPlayingAudio ? null : _speakDictation,
              icon: Icon(
                _isPlayingAudio ? Icons.volume_up : Icons.play_arrow_rounded,
              ),
              iconSize: 48,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.all(20),
              ),
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _dictationController,
            style: TextStyle(color: colorScheme.onSurface),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Type here...",
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              filled: true,
              fillColor: isDark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _checkDictation,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Check Answer",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 40),
          if (_hasCheckedDictation) ...[
            // Overall Result Header
            Row(
              children: [
                Icon(
                  _dictationResult.every((r) => r == true)
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: _dictationResult.every((r) => r == true)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  _dictationResult.every((r) => r == true)
                      ? "Excellent! Correct."
                      : "Not quite right. See below:",
                  style: TextStyle(
                    color: _dictationResult.every((r) => r == true)
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!_dictationResult.every((r) => r == true))
              Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "Transcription Check:",
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildDictationFeedback(),
            ),
            if (_currentIndex < filtered.length - 1) ...[
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentIndex++;
                      _resetState();
                    });
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text("Next Exercise"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showLessonList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final currentCategory = _tabController.index == 0
        ? 'Pronunciation'
        : 'Dictation';
    final filtered = _getFilteredContent(currentCategory);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "$currentCategory List ($_selectedLevel)",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            "No lessons found",
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          separatorBuilder: (context, index) => Divider(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final text = item['text'] ?? '';
                            final isCurrent = index == _currentIndex;

                            return ListTile(
                              onTap: () {
                                setState(() {
                                  _currentIndex = index;
                                  _resetState();
                                });
                                Navigator.pop(context);
                              },
                              selected: isCurrent,
                              selectedTileColor: colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: isCurrent
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHighest,
                                foregroundColor: isCurrent
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                                child: Text("${index + 1}"),
                              ),
                              title: Text(
                                text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrent
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: isCurrent
                                  ? Icon(
                                      Icons.bar_chart_rounded,
                                      color: colorScheme.primary,
                                    )
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildDictationFeedback() {
    List<String> targetWords = _targetDictationPhrase.split(' ');
    List<Widget> widgets = [];

    for (int i = 0; i < targetWords.length; i++) {
      bool isCorrect = false;
      if (i < _dictationResult.length) {
        isCorrect = _dictationResult[i] ?? false;
      }

      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCorrect
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isCorrect ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Text(
            targetWords[i],
            style: TextStyle(
              color: isCorrect ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}
