import 'package:flutter/material.dart';

class StoryChoiceScreen extends StatefulWidget {
  const StoryChoiceScreen({super.key});

  @override
  State<StoryChoiceScreen> createState() => _StoryChoiceScreenState();
}

class _StoryChoiceScreenState extends State<StoryChoiceScreen> {
  // Simple Graph
  // Node 0 -> Start
  final List<Map<String, dynamic>> _storyNodes = [
    {
      'id': 0,
      'text':
          "You wake up in a mysterious forest. The trees are glowing with a faint blue light. You see a path to your left and a cave to your right.",
      'choices': [
        {'text': "Take the path", 'next': 1},
        {'text': "Enter the cave", 'next': 2},
      ],
    },
    {
      'id': 1,
      'text':
          "You follow the path and find a small cottage made of candy. An old lady is waving at you from the window.",
      'choices': [
        {'text': "Wave back", 'next': 3},
        {'text': "Run away", 'next': 4},
      ],
    },
    {
      'id': 2,
      'text':
          "The cave is dark and damp. Suddenly, you hear a loud roar echoing from deep inside.",
      'choices': [
        {'text': "Investigate the roar", 'next': 5},
        {'text': "Leave immediately", 'next': 0}, // Back to start
      ],
    },
    {
      'id': 3,
      'text':
          "She smiles and invites you in for tea. It was the best tea you ever had. You made a new friend! The End.",
      'choices': [],
    },
    {
      'id': 4,
      'text':
          "You run back to the forest entrance, breathless but safe. Maybe another day. The End.",
      'choices': [],
    },
    {
      'id': 5,
      'text':
          "Ideally you'd fight a dragon, but we are out of budget. You found a sleeping bear. He snores loudly. You sneak out. The End.",
      'choices': [],
    },
  ];

  int _currentNodeId = 0;

  void _makeChoice(int nextId) {
    setState(() {
      _currentNodeId = nextId;
    });
  }

  void _restart() {
    setState(() => _currentNodeId = 0);
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

    // Find node by ID
    final node = _storyNodes.firstWhere(
      (n) => n['id'] == _currentNodeId,
      orElse: () => _storyNodes[0],
    );
    final choices = node['choices'] as List;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Story Adventure"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : onSurface.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.5 : 0.12,
                        ),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      node['text'],
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 20,
                        height: 1.6,
                        fontFamily: 'serif',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            if (choices.isEmpty)
              ElevatedButton(
                onPressed: _restart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                ),
                child: const Text(
                  "Play Again",
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              ...choices.map((choice) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _makeChoice(choice['next']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        choice['text'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
