import 'package:flutter/material.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/utils/safe_navigation.dart';

class StoryBuilderScreen extends StatefulWidget {
  const StoryBuilderScreen({super.key});

  @override
  State<StoryBuilderScreen> createState() => _StoryBuilderScreenState();
}

class _StoryBuilderScreenState extends State<StoryBuilderScreen> {
  // Demo Story Logic: '___' represents a blank
  final String _storyTemplate =
      "Yesterday, I ___ to the park. The sun ___ shining brightly. "
      "I saw a big dog ___ with a ball. It was a ___ day.";

  final List<List<String>> _optionsForBlanks = [
    ["go", "went", "gone"], // went
    ["is", "was", "were"], // was
    ["play", "playing", "played"], // playing
    ["boring", "sad", "wonderful"], // wonderful
  ];

  final List<String> _correctAnswers = ["went", "was", "playing", "wonderful"];

  // State
  late List<String?> _userSelections; // null if not selected yet
  bool _submitted = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _userSelections = List<String?>.filled(_optionsForBlanks.length, null);
  }

  void _onBlankTap(int index) {
    if (_submitted) return;

    showCustomBottomSheet(
      context: context,
      items: _optionsForBlanks[index].map((opt) {
        return ListTile(
          title: Text(opt, style: const TextStyle(fontSize: 18)),
          onTap: () {
            setState(() {
              _userSelections[index] = opt;
            });
            SafeNavigation.tryPop(
              context,
              source: 'lib/screens/games/reading/story_builder_screen.dart',
            );
          },
        );
      }).toList(),
    );
  }

  // Custom BottomSheet helper since generic showModalBottomSheet is async
  void showCustomBottomSheet({
    required BuildContext context,
    required List<Widget> items,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    showBaseModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((w) {
              if (w is ListTile) {
                return ListTile(
                  title: w.title,
                  textColor: onSurface,
                  onTap: w.onTap,
                );
              }
              return w;
            }).toList(),
          ),
        );
      },
    );
  }

  // Wrapper for Material's showModalBottomSheet to allow avoiding name collision
  Future<T?> showBaseModalBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    Color? backgroundColor,
    ShapeBorder? shape,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      backgroundColor: backgroundColor,
      shape: shape,
    );
  }

  void _checkAnswers() {
    if (_userSelections.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all blanks first!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int correctCount = 0;
    for (int i = 0; i < _correctAnswers.length; i++) {
      if (_userSelections[i] == _correctAnswers[i]) correctCount++;
    }

    setState(() {
      _submitted = true;
      _score = correctCount;
    });

    if (correctCount == _correctAnswers.length) {
      SoundService().playSuccess();
    } else {
      SoundService().playError();
    }
  }

  void _reset() {
    setState(() {
      _userSelections = List<String?>.filled(_optionsForBlanks.length, null);
      _submitted = false;
      _score = 0;
    });
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

    // Breakdown template into parts
    List<String> parts = _storyTemplate.split("___");

    // We construct a Wrap of Text spans
    List<Widget> textWidgets = [];

    for (int i = 0; i < parts.length; i++) {
      // Add static text part
      textWidgets.add(
        Text(
          parts[i],
          style: TextStyle(color: onSurface, fontSize: 18, height: 1.5),
        ),
      );

      // If not the last part, add a blank slot (because split removes delimiters)
      // Actually split creates N+1 parts for N blanks.
      if (i < _optionsForBlanks.length) {
        String? selected = _userSelections[i];
        bool isCorrect = _submitted && selected == _correctAnswers[i];

        Color bgColor;
        if (_submitted) {
          bgColor = isCorrect
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3);
        } else {
          bgColor = selected != null
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.white10;
        }

        textWidgets.add(
          GestureDetector(
            onTap: () => _onBlankTap(i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _submitted
                      ? (isCorrect ? Colors.green : Colors.red)
                      : (selected != null ? Colors.blueAccent : Colors.white30),
                ),
              ),
              child: Text(
                selected ?? "____",
                style: TextStyle(
                  color: onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  decoration: _submitted && !isCorrect
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ),
        );

        // If incorrect, show correction above/below? keeping simple for now.
        if (_submitted && !isCorrect) {
          textWidgets.add(
            Container(
              padding: const EdgeInsets.all(2),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _correctAnswers[i],
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Story Builder"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: textWidgets,
              ),
            ),

            const Spacer(),

            if (_submitted) ...[
              Text(
                _score == _correctAnswers.length
                    ? "Perfect Story!"
                    : "You got $_score / ${_correctAnswers.length}",
                style: TextStyle(
                  color: _score == _correctAnswers.length
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FACFE),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Try Again"),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _checkAnswers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FACFE),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    "Check Story",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
