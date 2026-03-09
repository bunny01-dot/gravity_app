# Critical Bug Fixes Implementation Plan

**Created:** 2026-01-13T20:36:54+05:30  
**Priority:** CRITICAL  
**Total Issues:** 6

---

## 🎯 Overview

This document outlines the implementation plan for 6 critical bugs affecting core learning functionality, user trust, and language integrity.

### Priority Order
1. ✅ **Issue 3** - Daily Task Regression (Shows "Day 1", "Day 2" instead of words) - **CRITICAL**
2. ✅ **Issue 4** - Language & Localization Integrity (Mixed languages)
3. ✅ **Issue 1** - Game Access for Old/Returning Users
4. ✅ **Issue 2** - Listening Mastery "No lesson found"
5. ✅ **Issue 5** - Progress Bar Overuse
6. ✅ **Issue 6** - Black Hole Vocab Cards Enhancement

---

## 🚨 Issue 3: Daily Task Regression (CRITICAL)

### Problem
Daily vocabulary shows "Day 1", "Day 2" placeholders instead of actual vocabulary words. This was working before → indicates regression.

### Root Cause Analysis
The `DayBasedCurriculumService` parses CSV data and looks for "Day X" markers in column 1 to group words by day. However, the UI might be displaying the day marker itself instead of the actual word.

**Key Files:**
- `lib/services/day_based_curriculum_service.dart` - Parses CSV with day markers
- `lib/dashboard.dart` - Daily tasks UI (line 1563-1574: Daily Vocabulary card)
- Need to find the actual vocabulary lesson screen that displays words

### Investigation Needed
1. Find where Daily Vocabulary launches and what screen it shows
2. Check if the screen is displaying the `dayNumber` field instead of the `word` field
3. Verify CSV parsing is extracting words correctly from column 2

### Fix Strategy
1. Locate the vocabulary lesson/learning screen
2. Ensure it displays `VocabularyItem.word` not day markers
3. Add debug logging to verify parsed vocabulary items
4. Test with actual user flow

---

## 🌐 Issue 4: Language & Localization Integrity

### Problem
Language setting shows "Tamil" but content is mixed:
- Pronunciation: Hindi words
- Verb forms: English
- Tamil examples: Missing

### Root Cause
No language-aware content filtering. All content is loaded regardless of selected language.

### Files to Fix
- `lib/services/data_service.dart` - Content loading logic
- `lib/mastery/speaking_screen.dart` - Pronunciation exercises
- Verb forms screen (need to locate)
- Need language field in CSV data or separate CSV files per language

### Fix Strategy
1. **Check CSV Structure:** Do CSVs have a language column?
2. **Add Language Filtering:** Filter content by `_preferredLanguage` setting
3. **Fallback Strategy:** If no content for selected language, show clear message
4. **Content Audit:** Verify Tamil content exists in CSVs

### Implementation
```dart
// In DataService or curriculum service
List<VocabularyItem> getLanguageFilteredVocabulary(String language) {
  return _vocabularyItems.where((item) {
    return item.language == null || // If no language field, include all
           item.language == language || 
           item.language == 'universal';
  }).toList();
}
```

---

## 🎮 Issue 1: Game Access for Old/Returning Users

### Problem
Games are blocked based on daily task completion, not learned word count. Old users with existing learned words can't play.

### Current Logic (WRONG)
```
Games unlock IF daily_tasks_complete_today
```

### Correct Logic (REQUIRED)
```
Games unlock IF learned_words_count > minimum_threshold
Daily tasks are for progression, NOT a gate
```

### Files to Fix
- `lib/services/game_availability_service.dart` (line 74 mentions daily task counting)
- `lib/widgets/games_hub_card.dart` (line 368, 551)
- `lib/widgets/locked_games_view.dart`

### Fix Strategy
1. Change game unlock logic to check total learned words (all-time)
2. Keep daily task tracking separate (for streak/progression)
3. Only show "learn first" for brand new users (zero learned words)

### Implementation
```dart
// In GameAvailabilityService
Future<bool> canPlayGames() async {
  final learnedWordsCount = await _dataService.getTotalLearnedWordsCount();
  return learnedWordsCount >= 5; // Minimum 5 words to start gaming
}
```

---

## 🎧 Issue 2: Listening Mastery - "No lesson found"

### Problem
Listening Mastery displays "No lesson found" error.

### Investigation Needed
1. Check if listening CSV exists and is loaded
2. Verify lesson ID mapping
3. Check skill type filtering logic

### Files to Check
- `lib/mastery/listening_screen.dart`
- `lib/services/data_service.dart` - `getListeningExercises()`method
- Assets: Check for `listening_exercises.csv` or similar

### Fix Strategy
1. Verify CSV file exists in `assets/` folder
2. Check `pubspec.yaml` includes listening CSV
3. Add debug logging to listening data load
4. Verify filtering/mapping logic

---

## ⏳ Issue 5: Progress Bar Overuse

### Problem
"Preparing lesson" progress bar shows even for instant loads (< 1 second).

### Current Behavior
Always shows progress UI, even when unnecessary.

### Desired Behavior
- If load < 500-700ms → No progress bar, instant display
- If load > 700ms → Show progress bar

### Files to Fix
- Locate all lesson loading screens showing progress bars
- Likely in curriculum/lesson navigation code

### Implementation Strategy
```dart
// Pattern to use everywhere
Future<void> loadLesson() async {
  final stopwatch = Stopwatch()..start();
  
  final data = await _loadLessonData();
  
  stopwatch.stop();
  
  if (stopwatch.elapsedMilliseconds > 700) {
    // Show progress was warranted, already displayed
  } else {
    // Too fast, skip progress UI or hide immediately
  }
}

// Alternative: Use FutureBuilder with timeout
```

---

## 🕳️ Issue 6: Black Hole Vocab Cards Enhancement

### Problem
Black Hole cards show only English + Tamil words, missing example sentences that regular vocab cards have.

### Current State
- Collapsed: English word, Tamil translation
- Expanded: Same info, no examples

### Desired State
- Collapsed: English word, Tamil translation (same)
- **Expanded: + Tamil example + English example**

### Files to Fix
- `lib/screens/black_hole_screen.dart` (line 166 references adding difficult words)

### Fix Strategy
1. Find Black Hole card widget implementation
2. Ensure it uses full `VocabularyItem` model with examples
3. Add example sentences to expanded state
4. Style like regular vocab cards

---

## 📋 Implementation Checklist

### Phase 1: Investigation (Current)
- [x] Document all 6 issues
- [x] Locate all affected screen files
- [x] Verify CSV data structure  
- [x] Check current language handling

### Phase 2: Critical Fixes (Priority 1-2)
- [x] ✅ **COMPLETE** - Fix Daily Task regression (Issue 3) - Updated `_parseVocabularyCsv` to calculate days from serial numbers
- [ ] Implement language filtering (Issue 4)

### Phase 3: User Experience Fixes (Priority 3-4)
- [ ] Fix game unlock logic (Issue 1)
- [ ] Fix Listening Mastery (Issue 2)

### Phase 4: Polish (Priority 5-6)
- [ ] Optimize progress bar logic (Issue 5)
- [ ] Enhance Black Hole cards (Issue 6)

### Phase 5: Testing
- [ ] Test old user game access
- [ ] Test new user flows
- [ ] Test language switching
- [ ] Test all daily tasks
- [ ] Verify all mastery sections load

---

## 🔍 Next Steps

1. **Immediate:** Search for vocabulary lesson screen that displays "Day X"
2. **Immediate:** Check CSV files to verify data structure
3. **Immediate:** Add debug logging to curriculum service
4. **Then:** Fix issues in priority order

---

## 📝 Notes

- All fixes must preserve existing progress/data
- Test with both new and returning users
- Ensure backward compatibility with existing SharedPreferences keys
- Add analytics events for critical flows
