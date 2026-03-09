# UI MIGRATION AUDIT - OLD DATASERVICE TO NEW CURRICULUM SYSTEM

## 🔍 AUDIT RESULTS

### ❌ **CRITICAL: Files Still Using Old DataService**

The following files are still calling legacy DataService methods and MUST be updated:

#### 1. **`safe_game_content_provider.dart`** - Lines 69, 123
```dart
// ❌ OLD CODE (REMOVE):
final dailyMaps = await dataService.getDailyVocabulary();
final dailyMaps = await dataService.getDailyVerbs();

// ✅ NEW CODE (USE THIS):
import 'package:gravity_app/services/curriculum_progress_service.dart';

final curriculum = CurriculumProgressService();
final todayVocab = await curriculum.getGameVocabulary();  // Auto-excludes today
final todayVerbs = await curriculum.getGameVerbs();       // Auto-excludes today
```

**CRITICAL**: Games must use `getGameVocabulary()` NOT `getTodayVocabulary()` to ensure today's items never appear in games.

---

#### 2. **`word_match_screen.dart`** - Line 112
```dart
// ❌ OLD CODE (REMOVE):
final dynamicDocs = await DataService().getRandomVocabulary(_totalPairs);

// ✅ NEW CODE (USE THIS):
import 'package:gravity_app/services/curriculum_progress_service.dart';

final curriculum = CurriculumProgressService();
final gameVocab = await curriculum.getGameVocabulary();

// Shuffle and take needed pairs
gameVocab.shuffle();
final dynamicDocs = gameVocab.take(_totalPairs).map((item) => {
  'id': item.id,
  'word': item.word,
  'tamil_meaning': item.translation,
  'definition': item.definition,
}).toList();
```

---

### ⚠️ **Files with Deprecated Service References (Can Delete)**

These files reference old services that have been merged:

- `day_based_integration_service.dart` - Delete this file
- `day_based_progress_service.dart` - Delete this file
- `learning_day_service.dart` - Delete this file

---

## 🔧 ISSUE B: ATOMIC TASK COMPLETION

### ✅ **NEW SERVICE CREATED: `DailyTaskCompletionService`**

This service ensures atomic completion of all 3 daily tasks before advancing the day.

### **Integration Steps:**

#### 1. **Vocabulary Task Screen**
```dart
import 'package:gravity_app/services/daily_task_completion_service.dart';

// When user completes all vocabulary for the day:
final taskCompletion = DailyTaskCompletionService();
await taskCompletion.markVocabularyComplete();
// ↑ This automatically checks if all 3 tasks done and advances day
```

#### 2. **Verbs Task Screen**
```dart
import 'package:gravity_app/services/daily_task_completion_service.dart';

// When user completes all verbs for the day:
final taskCompletion = DailyTaskCompletionService();
await taskCompletion.markVerbsComplete();
```

#### 3. **Pronunciation Task Screen**
```dart
import 'package:gravity_app/services/daily_task_completion_service.dart';

// When user completes pronunciation:
final taskCompletion = DailyTaskCompletionService();
await taskCompletion.markPronunciationComplete();
```

### **Daily Progress Display**
```dart
import 'package:gravity_app/services/daily_task_completion_service.dart';

final taskCompletion = DailyTaskCompletionService();

// Get completion status
Map<String, bool> status = await taskCompletion.getCurrentDayStatus();
// Returns: {'vocab': true, 'verbs': false, 'pronunciation': false}

// Get progress percentage (0-100)
int progress = await taskCompletion.getCurrentDayProgress();
// Returns: 33 (1 out of 3 tasks complete)

// Check if all done
bool isDayComplete = await taskCompletion.isCurrentDayComplete();
```

### **Critical Rule:**
❌ **NEVER call `curriculum.markDayCompleted()` directly from UI**
✅ **ALWAYS use `taskCompletion.markVocabularyComplete()` etc.**

The `DailyTaskCompletionService` is the ONLY code that should call `markDayCompleted()`.

---

## 🎊 ISSUE C: REINFORCEMENT MODE DIALOG

### ✅ **NEW WIDGET CREATED: `ReinforcementModeDialog`**

This dialog shows ONCE when user completes day 90 and enters reinforcement mode.

### **Integration in Main App or Dashboard:**

```dart
import 'package:gravity_app/services/daily_task_completion_service.dart';
import 'package:gravity_app/widgets/reinforcement_mode_dialog.dart';

class DashboardScreen extends StatefulWidget {
  // ...
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DailyTaskCompletionService _taskCompletion = DailyTaskCompletionService();

  @override
  void initState() {
    super.initState();
    _checkReinforcementMode();
  }

  Future<void> _checkReinforcementMode() async {
    bool shouldShow = await _taskCompletion.shouldShowReinforcementIntro();
    
    if (shouldShow && mounted) {
      // Wait a moment for UI to settle
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        await ReinforcementModeDialog.show(context);
        await _taskCompletion.markReinforcementIntroShown();
      }
    }
  }

  // ... rest of dashboard
}
```

### **Alternative: Show After Day Completion**

```dart
// In your task completion handler:
await taskCompletion.markVocabularyComplete();  // Or verbs/pronunciation

// Check if this triggered reinforcement mode
bool shouldShow = await taskCompletion.shouldShowReinforcementIntro();
if (shouldShow && mounted) {
  await ReinforcementModeDialog.show(context);
  await taskCompletion.markReinforcementIntroShown();
}
```

---

## 📋 MIGRATION CHECKLIST

### Phase 1: Update Game Screens
- [ ] Update `safe_game_content_provider.dart` to use `getGameVocabulary()`
- [ ] Update `word_match_screen.dart` to use `getGameVocabulary()`
- [ ] Search for any other game screens using old DataService
- [ ] Test games to ensure today's items NEVER appear

### Phase 2: Update Daily Task Screens
- [ ] Update vocabulary task screen to call `markVocabularyComplete()`
- [ ] Update verbs task screen to call `markVerbsComplete()`
- [ ] Update pronunciation screen to call `markPronunciationComplete()`
- [ ] Remove any direct calls to `curriculum.markDayCompleted()`

### Phase 3: Update Dashboard/Progress Display
- [ ] Show daily task completion status (vocab/verbs/pronunciation)
- [ ] Display overall progress percentage
- [ ] Add reinforcement mode check on app startup
- [ ] Test that 100% badge appears when all tasks done

### Phase 4: Add Reinforcement Dialog
- [ ] Integrate `ReinforcementModeDialog` in main app or dashboard
- [ ] Test by manually completing 90 days
- [ ] Verify dialog shows ONCE and never again

### Phase 5: Delete Old Services
- [ ] Delete `day_based_integration_service.dart`
- [ ] Delete `day_based_progress_service.dart`
- [ ] Delete `learning_day_service.dart`
- [ ] Delete `csv_validator.dart` (not actively used)

### Phase 6: Add Deprecation Warnings (Optional)
```dart
// In DataService.getDailyVocabulary():
@Deprecated('Use CurriculumProgressService.getTodayVocabulary() instead')
Future<List<Map<String, String>>> getDailyVocabulary() async {
  debugPrint('⚠️  DEPRECATED: getDailyVocabulary() called. Use CurriculumProgressService instead.');
  // ... old code
}
```

---

## 🚨 CRITICAL ASSERTIONS TO ADD

### In DataService (Temporary During Migration):

```dart
import 'package:gravity_app/services/curriculum_progress_service.dart';

class DataService {
  bool _warnedAboutDeprecation = false;

  Future<List<Map<String, String>>> getDailyVocabulary() async {
    if (!_warnedAboutDeprecation) {
      debugPrint('');
      debugPrint('🚨🚨🚨 CRITICAL WARNING 🚨🚨🚨');
      debugPrint('Legacy DataService.getDailyVocabulary() was called!');
      debugPrint('This should use CurriculumProgressService.getTodayVocabulary()');
      debugPrint('Update the calling code immediately.');
      debugPrint('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');
      debugPrint('');
      _warnedAboutDeprecation = true;
    }
    
    // ... existing code
  }
}
```

---

## ✅ VERIFICATION TESTS

After migration, run these tests:

### Test 1: Games Boundary
```dart
import 'package:gravity_app/services/curriculum_validator.dart';

CurriculumValidator validator = CurriculumValidator();
String report = await validator.runAllValidations();
debugPrint(report);
// Should show: "✅ PASS: Today's items excluded from games"
```

### Test 2: Atomic Completion
1. Complete vocabulary task → Check progress = 33%
2. Complete verbs task → Check progress = 67%
3. Complete pronunciation → Check progress = 100% AND day increments
4. Verify day incremented ONLY after step 3

### Test 3: Reinforcement Dialog
1. Manually set day to 90: `curriculum.setCurrentDay(90);`
2. Complete all 3 tasks for day 90
3. Verify dialog appears
4. Restart app
5. Verify dialog does NOT appear again

---

## 📊 FINAL ARCHITECTURE

```
UI Screens
    ↓
DailyTaskCompletionService (atomic completion)
    ↓
CurriculumProgressService (single source of truth)
    ↓
DayBasedCurriculumService (CSV parsing only)
```

**NEVER:**
- ❌ Call DataService.getDailyVocabulary()
- ❌ Call curriculum.markDayCompleted() from UI
- ❌ Calculate learned counts in widgets

**ALWAYS:**
- ✅ Use CurriculumProgressService for all content
- ✅ Use DailyTaskCompletionService for completion
- ✅ Use getGameVocabulary() for games (not getTodayVocabulary())

---

*Migration Guide Created: 2026-01-08*  
*Priority: CRITICAL - Complete before production deployment*
