import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:gravity_app/services/data_service.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _flutterTts = FlutterTts();
  static const String _readWordsKey = 'read_aloud_words';

  TtsService._internal() {
    // Initialize TTS asynchronously
    _initTts();
  }

  double _currentRate = 0.5;
  double get currentRate => _currentRate;

  Future<void> _initTts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentRate = prefs.getDouble('tts_rate') ?? 0.5;

      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(_currentRate);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint("TTS Init Error: $e");
    }
  }

  void setCompletionHandler(Function callback) {
    _flutterTts.setCompletionHandler(() => callback());
  }

  Future<void> setSpeechRate(double rate) async {
    _currentRate = rate;
    await _flutterTts.setSpeechRate(rate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', rate);
    // Sync to cloud
    await DataService().saveProgressToCloud('tts_rate', rate);
  }

  Future<void> speak(String text, {bool tag = true, double? rate}) async {
    if (text.isEmpty) return;
    try {
      // Use provided rate or fallback to global current rate
      await _flutterTts.setSpeechRate(rate ?? _currentRate);

      await _flutterTts.speak(text);
      if (tag) {
        await _tagWordAsRead(text);
      }
    } catch (e) {
      debugPrint("TTS Error: $e");
    }
  }

  Future<List<dynamic>> getVoices() async {
    try {
      return await _flutterTts.getVoices;
    } catch (e) {
      debugPrint("Error getting voices: $e");
      return [];
    }
  }

  Future<void> setVoice(Map<String, String> voice) async {
    try {
      await _flutterTts.setVoice(voice);
    } catch (e) {
      debugPrint("Error setting voice: $e");
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> _tagWordAsRead(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final readWords = await getReadWords();
    if (!readWords.contains(word)) {
      readWords.add(word);
      await prefs.setStringList(_readWordsKey, readWords);
      // Sync list to cloud
      await DataService().saveProgressToCloud(_readWordsKey, readWords);
    }
  }

  Future<List<String>> getReadWords() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_readWordsKey) ?? [];
    return List<String>.from(list);
  }

  Future<bool> isWordRead(String word) async {
    final readWords = await getReadWords();
    return readWords.contains(word);
  }
}
