import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class AIService {
  // Configure at build time:
  // flutter run --dart-define=GEMINI_API_KEY=your_key
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  late GenerativeModel _model;
  bool _initialized = false;
  bool get _isConfigured => _apiKey.trim().isNotEmpty;

  void init() {
    if (_initialized) return;
    if (!_isConfigured) return;
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
    _initialized = true;
  }

  Future<List<Map<String, dynamic>>> generateStudentQuiz(String topic) async {
    if (!_isConfigured) {
      debugPrint(
        'AIService: GEMINI_API_KEY not configured. Using local fallback quiz.',
      );
      return _fallbackQuiz();
    }
    if (!_initialized) init();

    final prompt =
        '''
    Generate a quiz with exactly 10 multiple-choice questions for the English grammar topic: "$topic".
    The difficulty should be appropriate for an intermediate English learner.
    Return the response ONLY as a raw JSON array. Do not include markdown formatting like ```json or any other text.
    Each question object must have:
    - "question": String
    - "options": List<String> (4 options)
    - "answerIndex": int (index of correct option, 0-3)

    Example JSON structure:
    [
      {
        "question": "Which sentence is correct?",
        "options": ["She go to school.", "She goes to school.", "She going to school.", "She gone to school."],
        "answerIndex": 1
      }
    ]
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) {
        throw Exception("Empty response from AI");
      }

      String cleanJson = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final List<dynamic> jsonList = json.decode(cleanJson);

      return jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint("Error generating quiz: $e");
      return _fallbackQuiz();
    }
  }

  List<Map<String, dynamic>> _fallbackQuiz() {
    return [
      {
        "question": "What is the past tense of 'run'?",
        "options": ["Runned", "Ran", "Running", "Run"],
        "answerIndex": 1,
      },
      {
        "question": "Identify the noun: 'The cat sleeps.'",
        "options": ["The", "Cat", "Sleeps", "None"],
        "answerIndex": 1,
      },
    ];
  }
}
