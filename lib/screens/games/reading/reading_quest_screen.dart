import 'package:flutter/material.dart';
import 'package:gravity_app/services/sound_service.dart';

class ReadingQuestScreen extends StatefulWidget {
  const ReadingQuestScreen({super.key});

  @override
  State<ReadingQuestScreen> createState() => _ReadingQuestScreenState();
}

class _ReadingQuestScreenState extends State<ReadingQuestScreen> {
  // Simple Passage + Questions
  final String _passage =
      "The Giant Panda is a bear native to south central China. "
      "It is easily recognized by the large, distinctive black patches around its eyes, over the ears, and across its round body. "
      "Though belonging to the order Carnivora, the Giant Panda's diet is over 99% bamboo.";

  final List<Map<String, dynamic>> _questions = [
    {
      'q': "Where is the Giant Panda native to?",
      'opts': ["Japan", "South Central China", "India"],
      'ans': 1,
    },
    {
      'q': "What does the Panda mostly eat?",
      'opts': ["Fish", "Meat", "Bamboo"],
      'ans': 2,
    },
    {
      'q': "What family does the Panda belong to?",
      'opts': ["Feline", "Bear", "Reptile"],
      'ans': 1,
    },
  ];

  final Map<int, int> _userAnswers = {}; // questionIndex -> selectedOptionIndex
  bool _submitted = false;
  int _score = 0;

  void _selectAnswer(int qIndex, int oIndex) {
    if (_submitted) return;
    setState(() {
      _userAnswers[qIndex] = oIndex;
    });
  }

  void _submit() {
    if (_userAnswers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please answer all questions.")),
      );
      return;
    }

    int correct = 0;
    _questions.asMap().forEach((idx, q) {
      if (_userAnswers[idx] == q['ans']) correct++;
    });

    setState(() {
      _submitted = true;
      _score = correct;
    });

    if (correct == _questions.length) {
      SoundService().playSuccess();
    } else {
      SoundService().playError();
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
        title: const Text("Reading Quest"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Passage
            Container(
              padding: const EdgeInsets.all(28),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: Colors.orangeAccent),
                      SizedBox(width: 10),
                      Text(
                        "Read Carefully",
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _passage,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Questions
            ...List.generate(_questions.length, (idx) {
              final q = _questions[idx];
              final opts = q['opts'] as List<String>;

              return Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${idx + 1}. ${q['q']}",
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(opts.length, (optIdx) {
                      bool isSelected = _userAnswers[idx] == optIdx;
                      bool isCorrect = q['ans'] == optIdx;
                      Color color = isDark
                          ? const Color(0xFF2A2A35)
                          : Colors.white.withValues(alpha: 0.96);
                      Color textColor = onSurface;

                      if (_submitted) {
                        if (isCorrect) {
                          color = Colors.green.withValues(alpha: 0.2);
                          textColor = isDark
                              ? Colors.greenAccent
                              : Colors.green.shade800;
                        } else if (isSelected) {
                          color = Colors.red.withValues(alpha: 0.2);
                          textColor = isDark
                              ? Colors.redAccent
                              : Colors.red.shade800;
                        }
                      } else if (isSelected) {
                        color = Colors.blueAccent;
                        textColor = Colors.white;
                      }

                      return GestureDetector(
                        onTap: () => _selectAnswer(idx, optIdx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _submitted && isCorrect
                                    ? Icons.check_circle
                                    : (_submitted && isSelected && !isCorrect
                                          ? Icons.cancel
                                          : (isSelected
                                                ? Icons.radio_button_checked
                                                : Icons
                                                      .radio_button_unchecked)),
                                color: textColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                opts[optIdx],
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),

            if (_submitted)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Score: $_score / ${_questions.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FACFE),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    "Submit Answers",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
