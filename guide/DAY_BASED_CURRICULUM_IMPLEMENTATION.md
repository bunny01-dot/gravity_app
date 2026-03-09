# REFACTORED DAY-BASED CURRICULUM SYSTEM

## ✅ REFACTORING COMPLETE

The curriculum system has been refactored to address all critical issues:

### 🎯 Issue 1: Surface Area Reduction

**BEFORE**: 3 separate services with unclear responsibilities
- `LearningDayService` - day tracking
- `DayBasedProgressService` - persistence
- `DayBasedIntegrationService` - API layer

**AFTER**: 1 authoritative service
- `CurriculumProgressService` - **SINGLE SOURCE OF TRUTH**

**New Clean API:**
```dart
CurriculumProgressService service = CurriculumProgressService();

// Initialize ONCE on app startup
await service.initialize();

// Get today's content
List<VocabularyItem> vocab = await service.getTodayVocabulary();
List<VerbItem> verbs = await service.getTodayVerbs();

// Get specific day
List<VocabularyItem> day5Vocab = await service.getItemsForDay(5);

// Mark completion (ONLY way to increment currentLearningDay)
await service.markDayCompleted(currentDay);

// Get learned items (for games)
List<VocabularyItem> gameVocab = await service.getGameVocabulary();

// Yesterday quiz
List<VocabularyItem> yesterdayVocab = await service.getYesterdayVocabulary();
```

---

### 🎯 Issue 2: Dual Source of Truth ELIMINATED

**BEFORE**: Learning day inferred from:
- ❌ Calendar dates
- ❌ Completion records
- ❌ Cloud sync state
→ Could drift and cause inconsistencies

**AFTER**: ONE canonical value
- ✅ `currentLearningDay` - stored in `CurriculumProgressService`
- ✅ Incremented ONLY when `markDayCompleted()` is called
- ✅ NEVER inferred from calendar math
- ✅ Persisted locally (SharedPreferences) and cloud (Firestore)
- ✅ Hydrated from cloud FIRST on app startup
- ✅ All queries reference this value

**Enforcement Rules:**
```dart
// ✅ CORRECT: Getting current day
int day = service.getCurrentLearningDay(); // Single source

// ❌ WRONG: Inferring from calendar
DateTime start = ...;
int day = DateTime.now().difference(start).inDays; // NEVER DO THIS

// ✅ CORRECT: Advancing day
await service.markDayCompleted(day); // Only way to increment

// ❌ WRONG: Manual increment
currentDay++; // FORBIDDEN - not accessible
```

---

### 🎯 Issue 3: CSV Format Normalized

**BEFORE**: "Clever" parsing
- ❌ "Day X" marker rows for vocabulary
- ❌ Implicit grouping (every 5 rows = 1 day) for verbs
- ❌ Fragile - breaks if CSV edited casually

**AFTER**: Explicit column preferred
- ✅ Parser PREFERS explicit `dayNumber` column
- ✅ Falls back to legacy parsing if missing
- ⚠️ Logs DEPRECATION WARNING when legacy parsing used
- 🎯 Goal: Remove legacy parsing entirely within one iteration

**CSV Format Requirements (FUTURE):**

### Vocabulary CSV
```csv
Serial,English Word,Part of Speech,Tamil,Hindi,Example,dayNumber
1,Ignorance,Noun,அறியாமை,अज्ञान,Ignorance can be dangerous.,1
2,Jocose,Adjective,வேடிக்கையான,मज़ाकिया,His jocose comments...,1
...
```

### Verbs CSV
```csv
Serial,English (V1/V2/V3),Tamil,Hindi,dayNumber
1,Speak / Spoke / Spoken,பேசு / பேசினேன் / பேசியுள்ளேன்,बोलना / बोला / बोल चुका,1
2,Write / Wrote / Written,எழுது / எழுதினேன் / எழுதியுள்ளேன்,लिखना / लिखा / लिख चुका,1
...
```

**Migration Path:**
1. **Now**: Legacy parsing works, but logs warnings
2. **Next iteration**: Add `dayNumber` column to both CSVs
3. **Final**: Remove legacy parsing code entirely

**Current Behavior:**
```
⚠️  DEPRECATION WARNING: Vocabulary CSV uses legacy "Day X" markers
⚠️  Please add explicit "dayNumber" column to CSV

⚠️  DEPRECATION WARNING: Verbs CSV uses legacy sequential grouping
⚠️  Please add explicit "dayNumber" column to CSV
```

---

### 🎯 Issue 4: Boundary Checks VERIFIED

All boundary conditions are now enforced and validated:

#### ✅ CHECK 1: Games Query Correctly
```dart
// Games query learned items up to YESTERDAY only
List<VocabularyItem> gameVocab = await service.getGameVocabulary();
// Returns items from days 1 to (currentLearningDay - 1)

// Today's items NEVER appear in games
List<VocabularyItem> todayVocab = await service.getTodayVocabulary();
// Assertion: todayVocab ∩ gameVocab = ∅ (no overlap)
```

**Validation:**
- Current day 5 → Game vocab = 20 items (days 1-4)
- Current day 1 → Game vocab = 0 items (no games yet)

#### ✅ CHECK 2: New Users (Day 1) See Zero "Yesterday Quiz"
```dart
if (currentLearningDay == 1) {
  List<VocabularyItem> yesterdayVocab = await service.getYesterdayVocabulary();
  assert(yesterdayVocab.isEmpty); // ✅ Must be empty
}
```

**Validation:**
- Day 1: Yesterday quiz = 0 items
- Day 2+: Yesterday quiz = 5 vocab + 5 verbs from previous day

#### ✅ CHECK 3: Reinforcement Mode Triggers Only After Day 90
```dart
bool isEligible = service.isReinforcementModeEligible();
// Returns true ONLY if currentLearningDay > 90
```

**Validation:**
- Day 1-90: `isEligible = false`
- Day 91+: `isEligible = true`

#### ✅ CHECK 4: Today's Items Excluded from Games
```dart
// Enforced by getGameVocabulary()
int maxDay = currentLearningDay - 1;
return getLearnedVocabularyUpToDay(maxDay);
```

**Validation:**
- Games can only access days 1 to (currentDay - 1)
- Today's content (currentDay) is NEVER available to games

---

## 📁 REFACTORED FILE STRUCTURE

### Core Service (Single Source of Truth)
- ✅ `curriculum_progress_service.dart` - **AUTHORITATIVE SERVICE**
  - Manages `currentLearningDay`
  - Provides all daily content APIs
  - Handles persistence and cloud sync
  - Enforces all business rules

### Supporting Services
- ✅ `day_based_curriculum_service.dart` - CSV loading and parsing only
  - Loads CSVs and validates structure
  - Prefers explicit `dayNumber` column
  - Falls back to legacy parsing with warnings
  - Provides item lookup by day number

### Validation & Testing
- ✅ `curriculum_validator.dart` - Comprehensive validation suite
  - Boundary checks for all edge cases
  - Day 1 user validation
  - Game content validation
  - Reinforcement mode validation

### Deprecated/Removed
- ❌ ~~`learning_day_service.dart`~~ - MERGED into CurriculumProgressService
- ❌ ~~`day_based_progress_service.dart`~~ - MERGED into CurriculumProgressService
- ❌ ~~`day_based_integration_service.dart`~~ - MERGED into CurriculumProgressService
- ⚠️ `csv_validator.dart` - Kept for reference, but not actively used
- ⚠️ `day_based_curriculum_tester.dart` - Replaced by CurriculumValidator

---

## 🚀 INTEGRATION GUIDE

### Step 1: Initialize on App Startup

```dart
import 'package:gravity_app/services/curriculum_progress_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize curriculum system
  CurriculumProgressService curriculum = CurriculumProgressService();
  bool success = await curriculum.initialize();
  
  if (!success) {
    // Handle initialization failure
    debugPrint('❌ Failed to initialize curriculum');
  }
  
  runApp(MyApp());
}
```

### Step 2: Get Daily Content

```dart
// In your Daily Task screen
CurriculumProgressService curriculum = CurriculumProgressService();

int currentDay = curriculum.getCurrentLearningDay();
List<VocabularyItem> todayVocab = await curriculum.getTodayVocabulary();
List<VerbItem> todayVerbs = await curriculum.getTodayVerbs();
```

### Step 3: Mark Day Completed

```dart
// When user completes ALL daily tasks
CurriculumProgressService curriculum = CurriculumProgressService();
int currentDay = curriculum.getCurrentLearningDay();

await curriculum.markDayCompleted(currentDay);
// currentLearningDay automatically increments to currentDay + 1
```

### Step 4: Get Game Content

```dart
// In your games
CurriculumProgressService curriculum = CurriculumProgressService();

// Get vocab/verbs from days 1 to (currentDay - 1)
List<VocabularyItem> gameVocab = await curriculum.getGameVocabulary();
List<VerbItem> gameVerbs = await curriculum.getGameVerbs();

// Today's items will NEVER appear here
```

### Step 5: Get Yesterday Quiz

```dart
// In Yesterday Quiz screen
CurriculumProgressService curriculum = CurriculumProgressService();

List<VocabularyItem> yesterdayVocab = await curriculum.getYesterdayVocabulary();
List<VerbItem> yesterdayVerbs = await curriculum.getYesterdayVerbs();

// Returns empty list if currentDay == 1
```

---

## 🧪 VALIDATION & TESTING

### Run Full Validation Suite

```dart
import 'package:gravity_app/services/curriculum_validator.dart';

CurriculumValidator validator = CurriculumValidator();
String report = await validator.runAllValidations();
debugPrint(report);
```

**Output includes:**
- ✅ Game boundary checks
- ✅ New user (day 1) validation
- ✅ Reinforcement mode eligibility
- ✅ Today's items exclusion from games
- ✅ Day completion logic
- ✅ Single source of truth verification

### Quick Validation

```dart
String quickReport = await validator.runQuickValidation();
debugPrint(quickReport);
```

### Test Day Progression

```dart
String progressionReport = await validator.testDayProgression();
debugPrint(progressionReport);
```

---

## 📊 SINGLE SOURCE OF TRUTH FLOWCHART

```
┌─────────────────────────────────────────┐
│  CurriculumProgressService              │
│  ┌───────────────────────────────────┐  │
│  │  _currentLearningDay (private)    │  │
│  │  Single Source of Truth           │  │
│  └───────────────────────────────────┘  │
│                  ↓                       │
│  ┌───────────────────────────────────┐  │
│  │  Initialize:                      │  │
│  │  1. Load CSVs                     │  │
│  │  2. Hydrate from cloud FIRST      │  │
│  │  3. Fall back to local            │  │
│  │  4. Default to 1 if new user      │  │
│  └───────────────────────────────────┘  │
│                  ↓                       │
│  ┌───────────────────────────────────┐  │
│  │  All queries reference this:      │  │
│  │  • getTodayVocabulary()           │  │
│  │  • getGameVocabulary()            │  │
│  │  • getYesterdayVocabulary()       │  │
│  │  • isReinforcementModeEligible()  │  │
│  └───────────────────────────────────┘  │
│                  ↓                       │
│  ┌───────────────────────────────────┐  │
│  │  Increment ONLY via:              │  │
│  │  markDayCompleted(day)            │  │
│  │  → ++_currentLearningDay          │  │
│  │  → Persist local & cloud          │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘

❌ NEVER:
  - Infer from calendar math
  - Compute from active dates
  - Calculate from completion records
  
✅ ALWAYS:
  - Reference _currentLearningDay
  - Increment via markDayCompleted()
  - Persist on every change
```

---

## 🔒 CRITICAL RULES

### Rule 1: currentLearningDay is Read-Only (except markDayCompleted)
```dart
// ✅ CORRECT
int day = curriculum.getCurrentLearningDay();

// ❌ WRONG - not possible (private field)
curriculum._currentLearningDay = 5;
```

### Rule 2: Increment Only on Completion
```dart
// ✅ CORRECT
await curriculum.markDayCompleted(currentDay);

// ❌ WRONG - no manual manipulation
currentDay++; // This won't work
```

### Rule 3: Never Infer from Calendar
```dart
// ❌ WRONG - calendar math forbidden
int daysActive = activeDates.length;
int currentDay = daysActive + 1;

// ✅ CORRECT - single source of truth
int currentDay = curriculum.getCurrentLearningDay();
```

### Rule 4: Games Use Yesterday and Before
```dart
// ✅ CORRECT
List<VocabularyItem> gameVocab = await curriculum.getGameVocabulary();
// Returns days 1 to (currentDay - 1)

// ❌ WRONG - never include today
List<VocabularyItem> allLearned = await curriculum.getLearnedVocabularyUpToDay(currentDay);
// This includes today - DON'T use for games
```

---

## 📈 STATUS & NEXT STEPS

### ✅ Completed
- [x] Merged 3 services into 1 authoritative service
- [x] Established currentLearningDay as single source of truth
- [x] Updated CSV parser to prefer explicit dayNumber column
- [x] Added deprecation warnings for legacy parsing
- [x] Implemented boundary checks for all edge cases
- [x] Created comprehensive validation suite
- [x] Documented migration path

### ⏳ Pending
- [ ] Add explicit `dayNumber` column to vocabulary CSV
- [ ] Add explicit `dayNumber` column to verbs CSV
- [ ] Remove legacy "Day X" marker parsing
- [ ] Remove sequential grouping logic
- [ ] Update existing DataService calls to use new API
- [ ] Integrate with Daily Task screens
- [ ] Integrate with Quiz screens
- [ ] Integrate with Games Hub
- [ ] Test cloud sync on new device

### 🎯 Immediate Next Action
**Add `dayNumber` column to both CSVs to eliminate legacy parsing**

---

*Refactoring completed: 2026-01-08*  
*New architecture: 1 service, 1 source of truth, zero ambiguity*
