# MIGRATION GUIDE: Old Services → CurriculumProgressService

## Quick Reference

| Old Code | New Code |
|----------|----------|
| `DayBasedIntegrationService().getDailyVocabulary()` | `CurriculumProgressService().getTodayVocabulary()` |
| `DayBasedIntegrationService().getDailyVerbs()` | `CurriculumProgressService().getTodayVerbs()` |
| `LearningDayService().getCurrentLearningDay()` | `CurriculumProgressService().getCurrentLearningDay()` |
| `DayBasedIntegrationService().getYesterdayVocabulary()` | `CurriculumProgressService().getYesterdayVocabulary()` |
| `DayBasedProgressService().markVocabularyAsLearned()` | `CurriculumProgressService().markDayCompleted()` |
| `DayBasedIntegrationService().getVocabularyForDateRange()` | Use `getLearnedVocabularyUpToDay()` + custom logic |

## Step-by-Step Migration

### 1. Replace Imports

**Old:**
```dart
import 'package:gravity_app/services/day_based_integration_service.dart';
import 'package:gravity_app/services/learning_day_service.dart';
import 'package:gravity_app/services/day_based_progress_service.dart';
```

**New:**
```dart
import 'package:gravity_app/services/curriculum_progress_service.dart';
```

### 2. Replace Service Instances

**Old:**
```dart
DayBasedIntegrationService integrationService = DayBasedIntegrationService();
LearningDayService learningDayService = LearningDayService();
DayBasedProgressService progressService = DayBasedProgressService();
```

**New:**
```dart
CurriculumProgressService curriculum = CurriculumProgressService();
```

### 3. Replace Method Calls

#### Getting Daily Content

**Old:**
```dart
List<VocabularyItem> vocab = await integrationService.getDailyVocabulary();
List<VerbItem> verbs = await integrationService.getDailyVerbs();
```

**New:**
```dart
List<VocabularyItem> vocab = await curriculum.getTodayVocabulary();
List<VerbItem> verbs = await curriculum.getTodayVerbs();
```

#### Getting Current Day

**Old:**
```dart
int currentDay = await learningDayService.getCurrentLearningDay();
```

**New:**
```dart
int currentDay = curriculum.getCurrentLearningDay(); // No await needed
```

#### Marking Progress

**Old:**
```dart
await progressService.markVocabularyAsLearned(date, learnedIds);
await progressService.markVerbsAsLearned(date, learnedIds);
```

**New:**
```dart
// Mark entire day complete when ALL tasks done
await curriculum.markDayCompleted(currentDay);
```

#### Getting Game Content

**Old:**
```dart
// Had to manually calculate up to yesterday
int yesterday = currentDay - 1;
List<VocabularyItem> gameVocab = await integrationService.getLearnedVocabularyUpToDay(yesterday);
```

**New:**
```dart
// Automatic yesterday boundary
List<VocabularyItem> gameVocab = await curriculum.getGameVocabulary();
List<VerbItem> gameVerbs = await curriculum.getGameVerbs();
```

### 4. Replace Initialization

**Old:**
```dart
DayBasedIntegrationService service = DayBasedIntegrationService();
bool success = await service.initialize();
```

**New:**
```dart
CurriculumProgressService curriculum = CurriculumProgressService();
bool success = await curriculum.initialize();
```

### 5. Files to Delete After Migration

Once you've replaced all references, you can safely delete:
- `lib/services/learning_day_service.dart`
- `lib/services/day_based_progress_service.dart`
- `lib/services/day_based_integration_service.dart`
- `lib/services/day_based_curriculum_tester.dart` (replaced by curriculum_validator.dart)

## Example: Daily Task Screen Migration

### Before
```dart
class DailyTaskScreen extends StatefulWidget {
  @override
  _DailyTaskScreenState createState() => _DailyTaskScreenState();
}

class _DailyTaskScreenState extends State<DailyTaskScreen> {
  final DayBasedIntegrationService _integrationService = DayBasedIntegrationService();
  final DayBasedProgressService _progressService = DayBasedProgressService();
  
  List<VocabularyItem> _todayVocab = [];
  List<VerbItem> _todayVerbs = [];
  int _currentDay = 1;

  @override
  void initState() {
    super.initState();
    _loadDailyContent();
  }

  Future<void> _loadDailyContent() async {
    _currentDay = await LearningDayService().getCurrentLearningDay();
    _todayVocab = await _integrationService.getDailyVocabulary();
    _todayVerbs = await _integrationService.getDailyVerbs();
    setState(() {});
  }

  Future<void> _markCompleted() async {
    DateTime today = DateTime.now();
    List<String> vocabIds = _todayVocab.map((v) => v.id).toList();
    List<String> verbIds = _todayVerbs.map((v) => v.id).toList();
    
    await _progressService.markVocabularyAsLearned(today, vocabIds);
    await _progressService.markVerbsAsLearned(today, verbIds);
  }
}
```

### After
```dart
class DailyTaskScreen extends StatefulWidget {
  @override
  _DailyTaskScreenState createState() => _DailyTaskScreenState();
}

class _DailyTaskScreenState extends State<DailyTaskScreen> {
  final CurriculumProgressService _curriculum = CurriculumProgressService();
  
  List<VocabularyItem> _todayVocab = [];
  List<VerbItem> _todayVerbs = [];
  int _currentDay = 1;

  @override
  void initState() {
    super.initState();
    _loadDailyContent();
  }

  Future<void> _loadDailyContent() async {
    _currentDay = _curriculum.getCurrentLearningDay();
    _todayVocab = await _curriculum.getTodayVocabulary();
    _todayVerbs = await _curriculum.getTodayVerbs();
    setState(() {});
  }

  Future<void> _markCompleted() async {
    // Simply mark the day complete
    await _curriculum.markDayCompleted(_currentDay);
    
    // Day automatically increments to _currentDay + 1
    setState(() {
      _currentDay = _curriculum.getCurrentLearningDay();
    });
  }
}
```

## Key Differences

### Simpler API
- **Old**: Multiple services with overlapping responsibilities
- **New**: Single service with clear, focused API

### Clearer Intent
- **Old**: `markVocabularyAsLearned()` + `markVerbsAsLearned()`
- **New**: `markDayCompleted()` - clearer that entire day is done

### No Date Management
- **Old**: Pass `DateTime.now()` to every method
- **New**: Service manages dates internally based on `currentLearningDay`

### Automatic Yesterday Boundary
- **Old**: Manually calculate `currentDay - 1` for games
- **New**: `getGameVocabulary()` automatically uses correct boundary

### Single Source of Truth
- **Old**: Day could be inferred from multiple sources
- **New**: `getCurrentLearningDay()` is the ONLY source

## Testing After Migration

```dart
import 'package:gravity_app/services/curriculum_validator.dart';

// Run validation to ensure everything works
CurriculumValidator validator = CurriculumValidator();
String report = await validator.runAllValidations();
debugPrint(report);
```

This will verify:
- ✅ Games use correct day range
-✅ New users (day 1) handled correctly
- ✅ Reinforcement mode triggers at right time
- ✅ Today's items excluded from games
- ✅ Day completion increments correctly
