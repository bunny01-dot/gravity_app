# Improved Settings & SFX System

## Current Issues
1. ❌ Same SFX for all actions (monotonous)
2. ❌ SFX "tone" setting just changes playback speed (useless)
3. ❌ No per-task difficulty preferences
4. ❌ "Low/Normal/High" difficulty only affects audio speed, not content difficulty

## Solution

### 1. Sound Effects (SFX) System ✅
**Implemented:**
- `playTap()` - Light click for buttons (volume: 0.3)
- `playAnswer()` - Neutral sound when submitting answer (volume: 0.4)
- `playCorrect()` - Positive chime for correct answers (volume: 0.6)
- `playWrong()` - Gentle buzz for wrong answers (volume: 0.4)  
- `playCompletion()` - Success sound for task completion (volume: 0.7)
- `playLevelUp()` - Achievement fanfare (volume: 0.8)
- `playError()` - Error sound for critical issues (volume: 0.5)

**Removed:**
- ❌ `setSfxTone()` - pointless pitch adjustment
- ❌ SFX Tone setting from UI

### 2. Difficulty Settings System (TODO)
**New Approach:**
Each skill type has independent difficulty preference:
- Vocabulary Mastery: Beginner/Intermediate/Advanced
- Reading Mastery: Beginner/Intermediate/Advanced  
- Writing Mastery: Beginner/Intermediate/Advanced
- Listening Mastery: Beginner/Intermediate/Advanced
- Speaking Mastery: Beginner/Intermediate/Advanced
- Daily Tasks: Beginner/Intermediate/Advanced (affects vocab + verb count)

**Storage:**
```dart
SharedPreferences keys:
- 'difficulty_vocabulary': 'Beginner'|'Intermediate'|'Advanced'
- 'difficulty_reading': ...
- 'difficulty_writing': ...
- 'difficulty_listening': ...
- 'difficulty_speaking': ...
- 'difficulty_daily': ...
```

**UI Location:**
Settings Tab → "Difficulty Preferences" section

### 3. Implementation Steps
1. ✅ Update SoundService with varied sounds
2. ⏳ Remove setSfxTone calls from dashboard.dart (3 locations)
3. ⏳ Remove setSfxTone UI from settings_tab.dart
4. ⏳ Create DifficultyPreferencesSection widget
5. ⏳ Add difficulty filtering logic to DataService
6. ⏳ Update each mastery screen to load difficulty preference

---
**Priority:** High - Improves UX significantly
**Effort:** Medium - ~2 hours
