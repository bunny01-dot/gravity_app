# Games Hub Fix Plan
**Created:** February 3, 2026 - 00:03 IST  
**Priority:** HIGH

---

## 🎯 Phase 1: Critical Fixes (Can Do NOW - 2-3 hours)

### ✅ Fix #1: Add Difficulty Level Filtering to SafeGameContentProvider
**Priority:** 🔥 CRITICAL  
**Impact:** Makes all games adaptive to student proficiency level  
**Effort:** ~30 minutes

#### Current Problem:
```dart
// SafeGameContentProvider pulls from ALL learned vocabulary
// regardless of user's effective_difficulty_level
final allLearned = await dataService.getLearnedVocabularyItems();
```

#### Solution:
Update `SafeGameContentProvider` to:
1. Read user's `effective_difficulty_level` from SharedPreferences
2. Filter vocabulary/verbs by level before returning
3. Add optional parameter to override level if needed

#### Implementation Steps:
```dart
// 1. Add to SafeGameContentProvider class:
Future<String> _getUserDifficultyLevel() async {
  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    return prefs.getString('effective_difficulty_level') ??
           prefs.getString('english_proficiency_level_${user.uid}') ??
           'Beginner';
  }
  return 'Beginner';
}

// 2. Update getEligibleVocabulary:
Future<List<VocabularyItem>> getEligibleVocabulary({
  required int minCount,
  String? forceLevel, // Optional override
}) async {
  final level = forceLevel ?? await _getUserDifficultyLevel();
  
  // Get level-specific learned items
  final allLearned = await dataService.getLearnedVocabularyItemsByLevel(level);
  
  // Rest of the logic stays the same...
}

// 3. Add new DataService method:
Future<List<VocabularyItem>> getLearnedVocabularyItemsByLevel(String level) async {
  // Filter learned items by difficulty level
  final learnedIds = await getLearnedVocabularyIds();
  final levelItems = await getVocabularyByLevel(level); // Beginner/Intermediate/Advanced
  
  return levelItems.where((item) => learnedIds.contains(item.id)).toList();
}
```

#### Files to Modify:
- `lib/services/safe_game_content_provider.dart` (add level filtering)
- `lib/services/data_service.dart` (add `getLearnedVocabularyItemsByLevel`, `getVocabularyByLevel`)

#### Testing:
1. Change user level to "Beginner" → Games should show beginner words
2. Change to "Advanced" → Games should show advanced words
3. Teacher override should propagate to games

---

### ✅ Fix #2: Verify and Document Audio Asset Status
**Priority:** 🔥 CRITICAL  
**Impact:** Prevents crashes in listening games  
**Effort:** ~15 minutes

#### Current Status:
- No dedicated `assets/audio/` folder found
- Listening games reference audio files that may not exist
- TTS (Text-to-Speech) integration unclear

#### Action Items:
1. **Audit listening game screens:**
   - Check `audio_guess_screen.dart`
   - Check `dictation_game_screen.dart`
   - Check `listen_and_tap_screen.dart`
   - Check `conversation_catch_screen.dart`

2. **Document findings:**
   - List expected audio file paths
   - Check if files exist
   - Note which games use TTS vs pre-recorded audio

3. **Quick Fix Options:**
   - **Option A:** Use Flutter TTS package (fast, no assets needed)
   - **Option B:** Record/generate audio files (higher quality, more work)
   - **Option C:** Disable audio games until assets ready (temporary)

#### Implementation (Option A - TTS):
```dart
// Add to pubspec.yaml:
dependencies:
  flutter_tts: ^3.8.5

// Create lib/services/tts_service.dart:
class TTSService {
  static final FlutterTts _tts = FlutterTts();
  
  static Future<void> speak(String text) async {
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }
  
  static Future<void> stop() async {
    await _tts.stop();
  }
}

// Update listening games to use TTS instead of audio files
```

---

### ✅ Fix #3: Standardize Speech Recognition Across Speaking Games
**Priority:** ⚠️ HIGH  
**Impact:** Improves speaking game reliability  
**Effort:** ~45 minutes

#### Current Problem:
- Each speaking game implements speech recognition differently
- Inconsistent error handling
- Different permission request flows

#### Solution:
Create a unified `SpeechRecognitionService` wrapper.

#### Implementation:
```dart
// lib/services/speech_recognition_service.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechRecognitionService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _isInitialized = false;
  
  /// Initialize speech recognition (call once at app start)
  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
    return _isInitialized;
  }
  
  /// Request microphone permission
  static Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
  
  /// Start listening for speech
  static Future<String?> listen({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return null;
    }
    
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;
    
    String result = '';
    await _speech.listen(
      onResult: (val) => result = val.recognizedWords,
      listenFor: timeout,
      pauseFor: const Duration(seconds: 3),
    );
    
    // Wait for result
    await Future.delayed(timeout);
    return result.isNotEmpty ? result : null;
  }
  
  /// Stop listening
  static Future<void> stop() async {
    await _speech.stop();
  }
  
  /// Check if currently listening
  static bool get isListening => _speech.isListening;
}
```

#### Usage in Games:
```dart
// OLD (inconsistent):
final newSpeech = Speech();
await newSpeech.initialize();
// ... lots of boilerplate

// NEW (standardized):
final result = await SpeechRecognitionService.listen();
if (result != null) {
  // Process recognized text
}
```

#### Files to Update:
- `lib/screens/games/speaking/repeat_after_me_screen.dart`
- `lib/screens/games/speaking/pronunciation_match_screen.dart`
- `lib/screens/games/speaking/tongue_twister_screen.dart`
- `lib/screens/games/speaking/read_aloud_screen.dart`

---

## 🎯 Phase 2: Data Standardization (Next Week - 4-6 hours)

### Fix #4: Migrate Hardcoded Game Data to CSV Files
**Priority:** ⚠️ MEDIUM  
**Impact:** Easier content updates, difficulty level support  
**Effort:** ~4 hours

#### Games Currently Using Hardcoded Data:
1. **Grammar Games** (all 6): Error Hunt, Sentence Scramble, Grammar Choice, Tense Trainer, Parts of Speech, Sentence Builder
2. **Casual Games** (most): Word Puzzle, Quiz Battle, Story Choice, Word Race
3. **Listening Games** (all 4): Need CSV with sentences/words
4. **Speaking Games** (all 5): Need CSV with target phrases

#### CSV Structure (Example for Grammar Games):
```csv
ID,Type,Question,Correct_Answer,Wrong_Option_1,Wrong_Option_2,Wrong_Option_3,Level,Explanation
1,tense,"I ___ to school yesterday.","went","go","goes","going","Beginner","Past tense for yesterday"
2,error,"She don't like pizza.","doesn't","don't","don't not","don't never","Beginner","Use 'doesn't' for third person singular"
```

#### Implementation Steps:
1. Create CSV files:
   - `assets/Master Sheets/Grammar Questions - Sheet.csv`
   - `assets/Master Sheets/Speaking Phrases - Sheet.csv`
   - `assets/Master Sheets/Listening Sentences - Sheet.csv`
   
2. Update DataService to load these CSVs with difficulty filtering

3. Update each game to use `dataService.getGrammarQuestions(level: userLevel)`

---

### Fix #5: Add Progress Tracking to Non-Level Games
**Priority:** ⚠️ MEDIUM  
**Impact:** Better engagement, user satisfaction  
**Effort:** ~2 hours

#### Current Issue:
Games without 30-level systems don't track any progress (e.g., Word Categories, Speed Vocabulary, all grammar/speaking games).

#### Solution:
Add simple "High Score" or "Times Played" tracking.

#### Implementation:
```dart
// Already exists in DataService:
await DataService().saveHighScore(gameId, score);
final highScore = await DataService().getHighScore(gameId);

// Add "Times Played" counter:
await DataService().incrementPlayCount(gameId);
final playCount = await DataService().getPlayCount(gameId);

// Show in UI:
Text('High Score: $highScore')
Text('Played $playCount times')
```

---

## 🎯 Phase 3: Advanced Features (Next Month)

### Fix #6: Adaptive Difficulty
Make games adjust based on performance

### Fix #7: Multiplayer Implementation
Build real-time game matching

### Fix #8: Analytics Dashboard
Teacher view of student game performance

---

## 📋 Quick Reference: File Locations

### Services to Modify:
- `lib/services/safe_game_content_provider.dart` - Add level filtering
- `lib/services/data_service.dart` - Add level-specific methods
- `lib/services/speech_recognition_service.dart` - NEW (create this)
- `lib/services/tts_service.dart` - NEW (create this)

### Game Categories:
- **Vocabulary:** `lib/screens/games/*.dart` (11 files)
- **Grammar:** `lib/screens/games/grammar/*.dart` (6 files)
- **Speaking:** `lib/screens/games/speaking/*.dart` (5 files)
- **Listening:** `lib/screens/games/listening/*.dart` (4 files)
- **Casual:** `lib/screens/games/casual/*.dart` (6 files)
- **Reading:** `lib/screens/games/reading/*.dart` (4 files)

---

## ✅ What Can We Do RIGHT NOW?

**I recommend starting with Fix #1 (Difficulty Level Filtering) because:**
1. ✅ Affects the MOST games (all vocabulary games)
2. ✅ High user impact (personalized experience)
3. ✅ Quick to implement (~30-45 minutes)
4. ✅ No external dependencies needed

**Would you like me to:**
- **A) Implement Fix #1** (difficulty level filtering) now?
- **B) Audit audio assets** (Fix #2) first to assess the situation?
- **C) Create the SpeechRecognitionService wrapper** (Fix #3)?
- **D) Something else?**

Let me know and I'll get started immediately!
