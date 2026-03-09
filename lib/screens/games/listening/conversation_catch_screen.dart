import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gravity_app/services/sound_service.dart';

class ConversationCatchScreen extends StatefulWidget {
  const ConversationCatchScreen({super.key});

  @override
  State<ConversationCatchScreen> createState() =>
      _ConversationCatchScreenState();
}

class _ConversationCatchScreenState extends State<ConversationCatchScreen> {
  late FlutterTts _flutterTts;
  int _currentIndex = 0;
  bool _answered = false;
  bool _isPlaying = false;

  final List<Map<String, dynamic>> _conversations = [
    {
      'dialogue': [
        "Hi, how are you today?",
        "I am fine, thanks. I am going to the library.",
        "Oh, have fun reading!",
      ],
      'question': "Where is the second person going?",
      'options': ["School", "Market", "Library", "Park"],
      'correctIndex': 2,
    },
    {
      'dialogue': [
        "Did you see my red pen?",
        "No, I only saw a blue one on the table.",
        "Okay, I will keep looking.",
      ],
      'question': "What color pen is the person looking for?",
      'options': ["Blue", "Red", "Green", "Black"],
      'correctIndex': 1,
    },
    {
      'dialogue': [
        "What time does the movie start?",
        "It starts at 7 o'clock.",
        "We should hurry then!",
      ],
      'question': "When does the movie start?",
      'options': ["6:00", "7:00", "8:00", "9:00"],
      'correctIndex': 1,
    },
  ];

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  void _playDialogue() async {
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isPlaying = true);

    List<String> lines = _conversations[_currentIndex]['dialogue'];
    for (int i = 0; i < lines.length; i++) {
      if (!mounted || !_isPlaying) break;
      // Simply changing rate/pitch to simulate voices roughly
      if (i % 2 == 0) {
        await _flutterTts.setPitch(1.0); // Viewer A
        await _flutterTts.setSpeechRate(0.5);
      } else {
        await _flutterTts.setPitch(1.2); // Viewer B (higher pitch)
        await _flutterTts.setSpeechRate(0.55);
      }
      await _flutterTts.speak(lines[i]);
      await _flutterTts.awaitSpeakCompletion(true);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (mounted) setState(() => _isPlaying = false);
  }

  void _onOptionTap(int index) {
    if (_answered) return;
    setState(() => _answered = true);

    int correct = _conversations[_currentIndex]['correctIndex'];
    if (index == correct) {
      SoundService().playSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Correct!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      SoundService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incorrect."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _next() {
    if (_currentIndex < _conversations.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _isPlaying = false;
      });
      _flutterTts.stop();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final convo = _conversations[_currentIndex];
    final options = convo['options'] as List<String>;
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
        title: const Text("Conversation Catch"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Audio Player
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Listen to the dialogue",
                    style: TextStyle(color: onSurface.withValues(alpha: 0.54)),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _playDialogue,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: _isPlaying
                          ? Colors.redAccent
                          : const Color(0xFF00E5FF),
                      child: Icon(
                        _isPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_isPlaying)
                    Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Playing...",
                        style: TextStyle(color: onSurface),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Question
            Text(
              convo['question'],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 32),

            // Options
            Expanded(
              child: ListView.separated(
                itemCount: options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  bool isCorrect = index == convo['correctIndex'];
                  Color color = isDark
                      ? const Color(0xFF2A2A35)
                      : Colors.white.withValues(alpha: 0.96);
                  if (_answered) {
                    if (isCorrect) color = Colors.green.withValues(alpha: 0.3);
                    // highlight incorrect selected? requires state tracking index.
                    // Keeping simple: Show correct always if answered.
                  }

                  return GestureDetector(
                    onTap: () => _onOptionTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _answered && isCorrect
                              ? Colors.green
                              : (isDark
                                    ? Colors.white10
                                    : onSurface.withValues(alpha: 0.1)),
                        ),
                      ),
                      child: Text(
                        options[index],
                        style: TextStyle(color: onSurface, fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_answered)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _next,
                  child: const Text("Next Conversation"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
