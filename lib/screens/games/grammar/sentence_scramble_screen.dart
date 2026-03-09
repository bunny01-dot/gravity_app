import 'package:flutter/material.dart';
import 'package:gravity_app/utils/game_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/safe_game_content_provider.dart';

class SentenceScrambleScreen extends StatefulWidget {
  const SentenceScrambleScreen({super.key});

  @override
  State<SentenceScrambleScreen> createState() => _SentenceScrambleScreenState();
}

class _SentenceScrambleScreenState extends State<SentenceScrambleScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _isChecked = false;
  bool _isCorrect = false;
  bool _hasInsufficientContent = false;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _questions = [];

  late List<String> _availableWords = [];
  List<String> _placedWords = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasInsufficientContent = false;
    });

    try {
      final safeProvider = SafeGameContentProvider(DataService());
      final verbs = await safeProvider.getEligibleVerbs(minCount: 3);

      final List<Map<String, dynamic>> dynamicQuestions = [];

      for (var verb in verbs) {
        // Cycle tenses or random
        final tenses = ['present', 'past', 'future'];
        for (var tense in tenses) {
          final sentence = verb.exampleSentences[tense] ?? '';
          // Basic validation: Min 3 words, Max 12 words
          final wordCount = sentence.split(' ').length;
          if (wordCount >= 3 && wordCount <= 12) {
            final words = sentence.split(' ');
            final scramble = List<String>.from(words)..shuffle();

            // Avoid exact match by chance
            if (scramble.join(' ') == sentence) {
              scramble.shuffle();
            }

            dynamicQuestions.add({'sentence': sentence, 'scramble': scramble});
          }
        }
      }

      if (dynamicQuestions.length < 5) {
        debugPrint(
          "Sentence Scramble: Warning, fewer items than requested were fetched.",
        );
      }

      dynamicQuestions.shuffle();
      setState(() {
        _questions.clear();
        _questions.addAll(dynamicQuestions.take(10));
        _isLoading = false;
      });
      _loadQuestion();
    } catch (e) {
      debugPrint("Sentence Scramble: Error loading dynamic data: $e");
    }

    if (_questions.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasInsufficientContent = true;
      });
    }
  }

  void _loadQuestion() {
    _availableWords = List<String>.from(_questions[_currentIndex]['scramble']);
    // Ensure randomization if the source wasn't scrambled enough, though here it is manual.
    // _availableWords.shuffle();
    _placedWords = [];
    _isChecked = false;
    _isCorrect = false;
    setState(() {});
  }

  void _onWordDrop(String word) {
    if (_isChecked) return;
    setState(() {
      _availableWords.remove(word);
      _placedWords.add(word);
    });
    SoundService().playTap();
  }

  void _onWordRemove(String word) {
    if (_isChecked) return;
    setState(() {
      _placedWords.remove(word);
      _availableWords.add(word);
    });
    SoundService().playTap();
  }

  void _checkAnswer() {
    if (_placedWords.isEmpty) return;

    final correctSentence = GameUtils.normalizeString(
      _questions[_currentIndex]['sentence'] as String,
    );
    final userSentence = GameUtils.normalizeString(_placedWords.join(' '));

    setState(() {
      _isChecked = true;
      _isCorrect = userSentence == correctSentence;
    });

    if (_isCorrect) {
      _score++;
      SoundService().playSuccess();
    } else {
      SoundService().playError();
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadQuestion();
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        title: Text("Game Over", style: TextStyle(color: onSurface)),
        content: Text(
          "You scored $_score out of ${_questions.length}!",
          style: TextStyle(color: onSurface.withValues(alpha: 0.72)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              "Exit",
              style: TextStyle(color: Color(0xFFC779D0)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
                _score = 0;
              });
              _loadQuestion();
            },
            child: const Text(
              "Replay",
              style: TextStyle(color: Color(0xFFC779D0)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final scaffoldBg = isDark
        ? const Color(0xFF030305)
        : theme.scaffoldBackgroundColor;
    final cardBg = isDark ? const Color(0xFF1E1E2C) : Colors.white;

    if (_hasInsufficientContent) {
      return Scaffold(
        backgroundColor: Colors.indigo.shade50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.indigo),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text("No sentences found. Please complete more lessons."),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Sentence Scramble"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: isDark
                  ? Colors.white10
                  : onSurface.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFC779D0)),
            ),
            const SizedBox(height: 40),

            // Drop Zone (Sentence Builder)
            Text(
              "Drag words here to build the sentence:",
              style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            DragTarget<String>(
              onWillAcceptWithDetails: (details) => !_isChecked,
              onAcceptWithDetails: (details) => _onWordDrop(details.data),
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 120),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: candidateData.isNotEmpty
                          ? const Color(0xFFC779D0)
                          : (isDark
                                ? Colors.white24
                                : onSurface.withValues(alpha: 0.16)),
                      width: candidateData.isNotEmpty ? 2 : 1,
                    ),
                  ),
                  child: _placedWords.isEmpty
                      ? Center(
                          child: Text(
                            "Drop words here",
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.2),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _placedWords.map((word) {
                            return GestureDetector(
                              onTap: () => _onWordRemove(word),
                              child: Chip(
                                label: Text(word),
                                backgroundColor: const Color(0xFFC779D0),
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => _onWordRemove(word),
                              ),
                            ).animate().scale(duration: 200.ms);
                          }).toList(),
                        ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Available Words (Source)
            if (!_isChecked)
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _availableWords.map((word) {
                      return Draggable<String>(
                        data: word,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Chip(
                            label: Text(word),
                            backgroundColor: const Color(
                              0xFFC779D0,
                            ).withValues(alpha: 0.8),
                            labelStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            elevation: 8,
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: Chip(
                            label: Text(word),
                            backgroundColor: isDark
                                ? const Color(0xFF2A2A35)
                                : onSurface.withValues(alpha: 0.08),
                            labelStyle: TextStyle(color: onSurface),
                          ),
                        ),
                        child: Chip(
                          label: Text(word),
                          backgroundColor: isDark
                              ? const Color(0xFF2A2A35)
                              : onSurface.withValues(alpha: 0.08),
                          labelStyle: TextStyle(color: onSurface),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            else ...[
              // Feedback Area
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: _isCorrect ? Colors.greenAccent : Colors.redAccent,
                      size: 80,
                    ).animate().scale(curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text(
                      _isCorrect ? "Correct!" : "Incorrect",
                      style: TextStyle(
                        color: _isCorrect
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_isCorrect)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Answer: ${_questions[_currentIndex]['sentence']}",
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isChecked ? _nextQuestion : _checkAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC779D0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isChecked
                      ? (_currentIndex == _questions.length - 1
                            ? "Finish Game"
                            : "Next Sentence")
                      : "Check Answer",
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
}
