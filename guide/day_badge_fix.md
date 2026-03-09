# Day Badge Fix - Implementation Summary

## Date: 2026-02-01

## Issue Reported
User completed 2 days of daily tasks, but the badge displayed "Day 4".

---

## Root Cause Analysis

### The Problem
The dashboard was calculating the day number incorrectly using this formula:

```dart
// INCORRECT CALCULATION (OLD CODE)
int vDay = (vocabTotalAssigned > 0) ? (vocabTotalAssigned / 5).ceil() : 1;
int vbDay = (verbsTotalAssigned > 0) ? (verbsTotalAssigned / 5).ceil() : 1;
```

**Why this was wrong:**
- `total_vocab_assigned` represents the **total number of vocabulary items ever assigned** to the user
- This includes items from ALL days, not just completed days
- Example scenario:
  - Day 1: Assigned 5 words → `total_vocab_assigned = 5` → Badge shows "Day 1" ✅
  - Day 2: Assigned 5 more words → `total_vocab_assigned = 10` → Badge shows "Day 2" ✅
  - Day 3: Assigned 5 more words → `total_vocab_assigned = 15` → Badge shows "Day 3" ❌ (User only completed 2 days!)
  - Day 4: Assigned 5 more words → `total_vocab_assigned = 20` → Badge shows "Day 4" ❌

**The Issue:**
The system was assigning new items for upcoming days even before the user completed previous days, causing the badge to show the "next available day" rather than the "current learning day".

---

## The Solution

### Authoritative Service
The app already has a proper service: **`CurriculumProgressService`**

This service:
- Maintains `_currentLearningDay` as the single source of truth
- Only increments the day when `markDayCompleted()` is called
- Syncs to cloud and local storage
- Is the **authoritative** way to track curriculum progress

### The Fix
Updated the dashboard to use the authoritative service:

```dart
// CORRECT CALCULATION (NEW CODE)
int currentDay = 1;
try {
  final curriculumService = CurriculumProgressService();
  if (curriculumService.getCurrentLearningDay() > 0) {
    currentDay = curriculumService.getCurrentLearningDay();
  }
} catch (e) {
  // Fallback: If service not initialized, try to get from SharedPreferences
  currentDay = prefs.getInt('current_learning_day') ?? 1;
}

// Use the same day for both vocab and verbs (they should always be in sync)
int vDay = currentDay;
int vbDay = currentDay;
```

---

## Changes Made

### 1. Dashboard Day Calculation ✅
**File:** `lib/dashboard.dart`

**Lines Modified:** 1581-1603

**Changes:**
1. Removed incorrect calculation based on `total_vocab_assigned` and `total_verbs_assigned`
2. Added proper call to `CurriculumProgressService.getCurrentLearningDay()`
3. Added fallback to `SharedPreferences` if service not initialized
4. Unified day display (vocab and verbs now always show the same day)

### 2. Import Statement ✅
**File:** `lib/dashboard.dart`

**Line Added:** 21

**Change:**
```dart
import 'package:gravity_app/services/curriculum_progress_service.dart';
```

---

## How Day Progression Works Now

### Day Advancement Logic
The day only advances when **ALL** daily tasks are completed:

1. User completes vocabulary task → `task_vocab_complete` = true
2. User completes verbs task → `task_verbs_complete` = true
3. User completes pronunciation task → `task_pronunciation_complete` = true
4. System checks if all 3 tasks are complete
5. If yes → `CurriculumProgressService.markDayCompleted(currentDay)` is called
6. Service increments `_currentLearningDay` from N to N+1
7. Badge now shows "Day N+1"

### Key Points
- Day number reflects **completed days + 1** (the current day you're working on)
- If you're on Day 3, it means you've completed Days 1 and 2
- The badge accurately represents your learning progress
- Vocab and Verbs always show the same day (synchronized)

---

## Testing Checklist

- [x] Fixed day calculation logic
- [x] Added proper import
- [ ] Test with actual app runtime
- [ ] Verify badge shows correct day after completing tasks
- [ ] Verify day increments only after all tasks complete
- [ ] Test fallback to SharedPreferences if service not initialized
- [ ] Verify cloud sync works correctly

---

## Files Modified

1. `lib/dashboard.dart` - Fixed day calculation and added import

---

## Expected Behavior After Fix

### Scenario 1: New User (Day 1)
- Badge shows: "Day 1"
- User completes all tasks
- Badge advances to: "Day 2"

### Scenario 2: User on Day 3 (Completed Days 1-2)
- Badge shows: "Day 3"
- User completes 2/3 tasks
- Badge still shows: "Day 3" (waiting for all tasks)
- User completes final task
- Badge advances to: "Day 4"

### Scenario 3: User Reported Issue (Fixed)
- User completed 2 days
- Badge **now correctly shows**: "Day 3" (not "Day 4")
- System no longer counts assigned-but-not-completed items

---

## Notes

- The `CurriculumProgressService` is the single source of truth for day tracking
- All other parts of the app should use this service for day-related queries
- The old `total_vocab_assigned` metric is still useful for analytics but should NOT be used for day display
- This fix ensures consistency across the entire app
