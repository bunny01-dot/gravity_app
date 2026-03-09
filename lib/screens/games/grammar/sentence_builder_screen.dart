import 'package:flutter/material.dart';

import 'package:gravity_app/services/sound_service.dart';

class SentenceBuilderGameScreen extends StatefulWidget {
  const SentenceBuilderGameScreen({super.key});

  @override
  State<SentenceBuilderGameScreen> createState() =>
      _SentenceBuilderGameScreenState();
}

class _SentenceBuilderGameScreenState extends State<SentenceBuilderGameScreen> {
  // Current Selections
  int _selectedSubject = 0;
  int _selectedVerb = 0;
  int _selectedObject = 0;

  final List<String> subjects = [
    'The cat',
    'A dog',
    'My friend',
    'The bird',
    'We',
  ];
  final List<String> verbs = ['eats', 'chased', 'playing', 'sings', 'are'];
  final List<String> objects = [
    'fish.',
    'the ball.',
    'football.',
    'a song.',
    'happy.',
  ];

  // Valid Combinations (hashes or simple logic)
  // Logic: Some combinations make sense, others don't.
  // For this simple version, let's say:
  // Cat -> Eats -> Fish.
  // Dog -> Chased -> The ball.
  // Friend -> Playing -> Football (Valid grammar-ish? "My friend is playing football" - verb needs 'is'. Lets simplify options)

  // Revised Options for valid simple sentences
  final List<List<String>> _validSentences = [
    ['The cat', 'eats', 'fish.'],
    ['A dog', 'chased', 'the ball.'],
    ['My friend', 'plays', 'football.'], // changed verb in list below
    ['The bird', 'sings', 'a song.'],
    ['We', 'are', 'happy.'],
  ];

  late List<String> _subjects;
  late List<String> _verbs;
  late List<String> _objects;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  void _loadLists() {
    // Flatten valid sentences into lists and shuffle (or keep static for ease of wheel)
    // To make it a puzzle, we show all options.
    _subjects = _validSentences.map((e) => e[0]).toList()..shuffle();
    _verbs = _validSentences.map((e) => e[1]).toList()..shuffle();
    _objects = _validSentences.map((e) => e[2]).toList()..shuffle();
    setState(() {});
  }

  void _checkSentence() {
    String s = _subjects[_selectedSubject];
    String v = _verbs[_selectedVerb];
    String o = _objects[_selectedObject];

    // Check if this combination exists in _validSentences
    bool isValid = _validSentences.any(
      (list) => list[0] == s && list[1] == v && list[2] == o,
    );

    if (isValid) {
      SoundService().playSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Great sentence!"),
          backgroundColor: Colors.green,
        ),
      );
      // Maybe remove them or just shuffle and continue?
      // Let's shuffle for replayability
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadLists();
        setState(() {
          _selectedSubject = 0;
          _selectedVerb = 0;
          _selectedObject = 0;
        });
      });
    } else {
      SoundService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("That doesn't make sense! Try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
        title: const Text("Sentence Builder"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "Spin the wheels to build a correct sentence!",
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),

          // Slot Machine UI
          Container(
            height: 250,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC779D0), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC779D0).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                _buildWheel(
                  _subjects,
                  (val) => setState(() => _selectedSubject = val),
                  onSurface,
                ),
                Container(
                  width: 1,
                  color: isDark
                      ? Colors.white10
                      : onSurface.withValues(alpha: 0.1),
                ),
                _buildWheel(
                  _verbs,
                  (val) => setState(() => _selectedVerb = val),
                  onSurface,
                ),
                Container(
                  width: 1,
                  color: isDark
                      ? Colors.white10
                      : onSurface.withValues(alpha: 0.1),
                ),
                _buildWheel(
                  _objects,
                  (val) => setState(() => _selectedObject = val),
                  onSurface,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Preview
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white10
                  : onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "${_subjects.isNotEmpty ? _subjects[_selectedSubject] : ''} "
              "${_verbs.isNotEmpty ? _verbs[_selectedVerb] : ''} "
              "${_objects.isNotEmpty ? _objects[_selectedObject] : ''}",
              style: TextStyle(
                color: onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 32),

          // Check Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _checkSentence,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC779D0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Check Sentence",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWheel(
    List<String> items,
    Function(int) onChanged,
    Color onSurface,
  ) {
    if (items.isEmpty) return const Expanded(child: SizedBox());
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        itemExtent: 50,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: items.length,
          builder: (context, index) {
            return Center(
              child: Text(
                items[index],
                style: TextStyle(
                  color: onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ),
    );
  }
}
