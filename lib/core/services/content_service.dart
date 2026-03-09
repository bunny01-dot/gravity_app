import 'package:flutter/foundation.dart';
// Assuming existing models or generic maps

class ContentService {
  // Singleton pattern
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  // Cache
  final Map<String, dynamic> _cache = {};

  Future<List<dynamic>> loadGameContent(String gameId) async {
    if (_cache.containsKey(gameId)) {
      return _cache[gameId];
    }

    try {
      // In a real app, you would load this from assets/data/games.json
      // For now, we return structured data here to replace hardcoded widgets
      final data = await _fetchFromSource(gameId);
      _cache[gameId] = data;
      return data;
    } catch (e) {
      debugPrint("Error loading content for $gameId: $e");
      return [];
    }
  }

  Future<List<dynamic>> _fetchFromSource(String gameId) async {
    // Simulate JSON load or Firestore fetch
    // To support the migration, we define the data here.

    switch (gameId) {
      case 'pronunciation_match':
        return [
          {
            'options': ['Sheep', 'Ship', 'Cheap', 'Chip'],
          },
          {
            'options': ['Bat', 'Bet', 'Bit', 'But'],
          },
          {
            'options': ['Cat', 'Cut', 'Cot', 'Coat'],
          },
          {
            'options': ['Walk', 'Work', 'Woke', 'Week'],
          },
          {
            'options': ['Pen', 'Pan', 'Pin', 'Pain'],
          },
        ];

      case 'emoji_sentence':
        return [
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

      default:
        return [];
    }
  }
}
