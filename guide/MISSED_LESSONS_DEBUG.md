# Missed Lessons Count Bug - Fix Guide

## 🐛 Problem

**User Report:** "Missed lesson card says 0 pending. Inside it has 2 days tasks"

**Root Cause Options:**
1. Count is calculated before data loads (race condition)
2. `getMissedDates()` returns data but count doesn't update
3. State not refreshing after viewing MissedLessonsScreen

---

## 🔍 Debug Steps Added

Added logging to `dashboard.dart` line 210-220:
```dart
Future<void> _fetchMissedLessonsCount() async {
  final missed = await _dataService.getMissedDates();
  debugPrint('📋 Missed Lessons: ${missed.length} days found');
  for (var date in missed) {
    debugPrint('   - ${date.toIso8601String().split('T')[0]}');
  }
  // ... rest of method
}
```

---

## 🔧 Potential Fixes

### Fix 1: Force Refresh After Returning from MissedLessonsScreen

**In `home_tab.dart` line 107-113:**

**CURRENT:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const MissedLessonsScreen(),
  ),
).then((_) => onRefresh());
```

**CHANGE TO:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const MissedLessonsScreen(),
  ),
).then((_) async {
  await onRefresh(); // Ensure refresh completes
});
```

---

### Fix 2: Ensure Initial Load Completes

**In `dashboard.dart`, check when `_fetchMissedLessonsCount()` is called:**

Should be called in `initState()` or `_loadDashboard()`.

If it's not being awaited properly:

**Find where it's called (likely in initState or a load method):**
```dart
// WRONG (fire and forget)
_fetchMissedLessonsCount();

// CORRECT (await completion)
await _fetchMissedLessonsCount();
```

---

### Fix 3: Check SharedPreferences Data

The`getMissedDates()` method checks SharedPreferences for:
- `quiz_passed_$dateKey`
- `task_vocab_$dateKey`  
- `task_verbs_$dateKey`

**Test if data exists:**

```dart
// Add to getMissedDates() for debugging
final dateKey = d.toIso8601String().split('T')[0];
bool passedQuiz = prefs.getBool('quiz_passed_$dateKey') ?? false;
bool completedVocab = prefs.getBool('task_vocab_$dateKey') ?? false;
bool completedVerbs = prefs.getBool('task_verbs_$dateKey') ?? false;

debugPrint('$dateKey: quiz=$passedQuiz, vocab=$completedVocab, verbs=$completedVerbs');

if (!passedQuiz && !completedVocab && !completedVerbs) {
  debugPrint('  ❌ MISSED!');
  missed.add(d);
}
```

---

### Fix 4: Check Date Range Logic

The `getMissedDates()` uses a global reset date:
```dart
final globalResetDate = DateTime(2025, 12, 22);
```

**Current date:** January 2, 2026

**Days between Dec 22, 2025 and Jan 2, 2026:** ~11 days

If user hasn't completed tasks for 2 of those days, those should show up.

**Verify:**
1. Run app and check console for debug output
2. Look for: `📋 Missed Lessons: X days found`
3. Check if dates are listed

---

## 🧪 Testing Steps

1. **Run the app** with logging enabled
2. **Check console** for:
   ```
   📋 Missed Lessons: 2 days found
      - 2025-12-30
      - 2025-12-31
   ✅ Missed lessons count updated to: 2
   ```

3. **If count shows 0 but screen has content:**
   - There's a state synchronization issue
   - The screen is using cached data but count refresh failed

4. **If count is correct but shows wrong number:**
   - UI might be using stale state
   - Add `key: UniqueKey()` to HomeTab to force rebuild

---

## 🎯 Quick Fix (Most Likely Solution)

The issue is probably a **timing/refresh issue**. Apply this fix:

**In `dashboard.dart`, find `_refreshDashboard()` method:**

```dart
Future<void> _refreshDashboard() async {
  setState(() {
    _isLoading = true;
  });

  await Future.wait([
    _loadInitialData(),
    _fetchStreakCount(),
    _fetchOverallProgress(),
    _fetchMissedLessonsCount(), // ENSURE THIS IS CALLED
  ]);

  setState(() {
    _isLoading = false;
  });
}
```

**And ensure it's called after returning from MissedLessonsScreen.**

---

## 📊 Expected Behavior

**Card Should Show:**
```
Missed Lessons
2 Pending Review(s)  ← This should match number of dates in the screen
```

**Inside Screen:**
- Lesson: December 30, 2025
- Lesson: December 31, 2025

= 2 cards = 2 count ✅

---

## 🔍 Next Steps

1. Run app and capture console output
2. Check what the debug logs show
3. If count is 0 in logs → Issue is in `getMissedDates()`
4. If count is 2 in logs but UI shows 0 → Issue is in state refresh

Let me know what the console shows!

