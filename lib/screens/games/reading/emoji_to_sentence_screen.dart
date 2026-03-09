import 'package:flutter/material.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/utils/safe_navigation.dart';

class EmojiToSentenceScreen extends StatefulWidget {
  const EmojiToSentenceScreen({super.key});

  @override
  State<EmojiToSentenceScreen> createState() => _EmojiToSentenceScreenState();
}

class _EmojiToSentenceScreenState extends State<EmojiToSentenceScreen> {
  final TextEditingController _controller = TextEditingController();

  final List<Map<String, dynamic>> _puzzles = [
    {
      'emojis': "  ",
      'answers': ["The boy goes to school", "A boy goes to school"],
      'hint': "Think about who is going where.",
    },
    {
      'emojis': "  ",
      'answers': ["The cat loves fish", "Cats love fish"],
      'hint': "Felines and seafood.",
    },
    {
      'emojis': "  ",
      'answers': [
        "It is raining at home",
        "Rain falls on the house",
        "Stay home when it rains",
      ],
      'hint': "Weather and shelter.",
    },
    {
      'emojis': "  ",
      'answers': [
        "I eat a delicious apple",
        "The apple is tasty",
        "Eating an apple",
      ],
      'hint': "Fruit and eating.",
    },
  ];

  int _currentIndex = 0;
  bool _checked = false;
  double _score = 0; // 0..1

  void _check() {
    if (_controller.text.isEmpty) return;
    String input = _controller.text.trim().toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );

    double bestSim = 0.0;

    List<String> valid = _puzzles[_currentIndex]['answers'];

    for (String ans in valid) {
      String cleanAns = ans.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
      if (input == cleanAns) {
        bestSim = 1.0;
        break;
      }

      double sim = _calculateSimilarity(input, cleanAns);
      if (sim > bestSim) bestSim = sim;
    }

    setState(() {
      _checked = true;
      _score = bestSim;
    });

    if (_score > 0.8) {
      SoundService().playSuccess();
    } else {
      SoundService().playError();
    }
  }

  void _next() {
    if (_currentIndex < _puzzles.length - 1) {
      setState(() {
        _currentIndex++;
        _checked = false;
        _score = 0;
        _controller.clear();
      });
    } else {
      SafeNavigation.tryPop(
        context,
        source: 'lib/screens/games/reading/emoji_to_sentence_screen.dart',
      );
    }
  }

  // Simple Jaccard similarity for words
  double _calculateSimilarity(String s1, String s2) {
    var set1 = s1.split(' ').toSet();
    var set2 = s2.split(' ').toSet();
    var intersection = set1.intersection(set2).length;
    var union = set1.union(set2).length;
    return intersection / union;
  }

  @override
  Widget build(BuildContext context) {
    var puzzle = _puzzles[_currentIndex];
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
        title: const Text("Emoji Translate"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),

            // Emoji Card
            Container(
              padding: const EdgeInsets.all(40),
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withValues(alpha: 0.3),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Text(
                puzzle['emojis'],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 48),
              ),
            ),

            const SizedBox(height: 48),

            TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              enabled: !_checked,
              style: TextStyle(color: onSurface, fontSize: 22),
              decoration: InputDecoration(
                hintText: "Type sentences...",
                hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.24)),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2A2A35)
                    : onSurface.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (_checked) ...[
              Text(
                _score > 0.8
                    ? "Great Job! Match: ${(_score * 100).toInt()}%"
                    : "Close! Match: ${(_score * 100).toInt()}%",
                style: TextStyle(
                  color: _score > 0.8 ? Colors.greenAccent : Colors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_score < 0.8)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Possible Answer: \"${puzzle['answers'][0]}\"",
                    style: TextStyle(color: onSurface.withValues(alpha: 0.54)),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E2DE2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Next Puzzle"),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _check,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E2DE2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    "Check Sentence",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
