import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';

class HangmanGameScreen extends StatefulWidget {
  const HangmanGameScreen({super.key});

  @override
  State<HangmanGameScreen> createState() => _HangmanGameScreenState();
}

class _HangmanGameScreenState extends State<HangmanGameScreen> {
  final List<String> _words = [
    "FLUTTER",
    "GRAVITY",
    "WIDGET",
    "CODING",
    "DART",
    "MOBILE",
    "ANDROID",
  ];
  final List<String> _hints = [
    "A popular UI toolkit by Google.",
    "The force that attracts a body towards the center of the earth.",
    "A building block of Flutter UI.",
    "Writing instructions for computers.",
    "The language used for Flutter.",
    "A type of phone or app.",
    "Google's mobile operating system.",
  ];

  late String _targetWord;
  late String _hint;
  final Set<String> _guessedLetters = {};
  int _incorrectAttempts = 0;
  static const int _maxAttempts = 6;
  int _currentWordIndex = 0;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _targetWord = _words[_currentWordIndex];
      _hint = _hints[_currentWordIndex];
      _guessedLetters.clear();
      _incorrectAttempts = 0;
    });
  }

  void _handleGuess(String letter) {
    if (_guessedLetters.contains(letter) ||
        _incorrectAttempts >= _maxAttempts) {
      return;
    }

    setState(() {
      _guessedLetters.add(letter);
      if (!_targetWord.contains(letter)) {
        _incorrectAttempts++;
        SoundService().playError();
      } else {
        SoundService().playSuccess();
      }
    });

    if (_incorrectAttempts >= _maxAttempts) {
      _showGameOver(false);
    } else if (_isWordGuessed()) {
      _showGameOver(true);
    }
  }

  bool _isWordGuessed() {
    for (int i = 0; i < _targetWord.length; i++) {
      if (!_guessedLetters.contains(_targetWord[i])) {
        return false;
      }
    }
    return true;
  }

  void _showGameOver(bool won) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        title: Text(
          won ? "You Won!" : "Game Over",
          style: TextStyle(color: onSurface),
        ),
        content: Text(
          won
              ? "Great job! The word was $_targetWord."
              : "You ran out of attempts! The word was $_targetWord.",
          style: TextStyle(color: onSurface.withValues(alpha: 0.72)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_currentWordIndex < _words.length - 1) {
                setState(() => _currentWordIndex++);
                _startNewGame();
              } else {
                Navigator.pop(context); // Exit
              }
            },
            child: Text(
              _currentWordIndex < _words.length - 1 ? "Next Word" : "Exit",
              style: const TextStyle(color: Color(0xFFFF6B6B)),
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

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Hangman"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Hangman Display (Custom Painter or Simple Steps)
            // For now, simple text or icons to represent lives
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_maxAttempts, (index) {
                return Icon(
                      Icons.favorite,
                      color: index < (_maxAttempts - _incorrectAttempts)
                          ? Colors.redAccent
                          : Colors.grey,
                      size: 32,
                    )
                    .animate(
                      target: index < (_maxAttempts - _incorrectAttempts)
                          ? 0
                          : 1,
                    )
                    .shake();
              }),
            ),
            const SizedBox(height: 20),

            // Hangman Graphic (Simplified)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white10
                    : onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child:
                    Icon(
                          _getHangmanIcon(_incorrectAttempts),
                          size: 100,
                          color: onSurface,
                        )
                        .animate(key: ValueKey(_incorrectAttempts))
                        .scale(duration: 300.ms, curve: Curves.elasticOut),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              "Hint: $_hint",
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.56),
                fontStyle: FontStyle.italic,
              ),
            ),

            const Spacer(),

            // Word Blanks
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: _targetWord.split('').map((char) {
                bool isRevealed = _guessedLetters.contains(char);
                return Container(
                  width: 40,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: onSurface, width: 2),
                    ),
                  ),
                  child: Text(
                    isRevealed ? char : "",
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // Keyboard
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split('').map((letter) {
                bool isGuessed = _guessedLetters.contains(letter);
                bool isCorrect = _targetWord.contains(letter);

                return GestureDetector(
                  onTap: isGuessed ? null : () => _handleGuess(letter),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isGuessed
                          ? (isCorrect
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.red.withValues(alpha: 0.3))
                          : cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isGuessed
                            ? (isCorrect ? Colors.green : Colors.red)
                            : onSurface.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: isGuessed
                            ? onSurface.withValues(alpha: 0.38)
                            : onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  IconData _getHangmanIcon(int mistakes) {
    if (mistakes == 0) return Icons.sentiment_satisfied_alt;
    if (mistakes == 1) return Icons.sentiment_neutral;
    if (mistakes == 2) return Icons.sentiment_dissatisfied;
    if (mistakes == 3) return Icons.mood_bad;
    if (mistakes == 4) return Icons.warning_amber_rounded;
    if (mistakes == 5) return Icons.error_outline;
    return Icons.cancel_outlined; // Dead
  }
}
