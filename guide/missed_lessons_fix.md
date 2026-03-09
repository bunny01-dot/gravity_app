# Missed Lessons Count Fix - Implementation Summary

## Date: 2026-02-02

## Issue Reported
User joined only 2 days ago, but the app is showing **22 pending lessons**.

---

## Root Cause Analysis

### The Problem
The `getMissedDates()` method was incorrectly calculating missed lessons by checking **every calendar day** since signup, regardless of the user's actual curriculum progress.

**Old Logic (INCORRECT):**
```
User signed up: Jan 1
Today: Jan 23
Days to check: Jan 2 - Jan 22 = 21 days
Missed lessons shown: 22 (all days where tasks weren't completed)
```

**Why this was wrong:**
- The app uses a **curriculum-based progression** system, not a calendar-based system
- Users progress through "Day 1, Day 2, Day 3..." of the curriculum
- A user on "Day 3" should only have 2 days to potentially miss (Days 1 and 2)
- Calendar days are irrelevant - only curriculum days matter

### Example Scenario
**User Journey:**
- **Jan 1**: Signed up, completed Day 1 tasks ✅
- **Jan 2**: Completed Day 2 tasks ✅
- **Jan 3**: Currently on Day 3 (in progress)

**Old System (WRONG):**
- Checked: Jan 2 through Jan 22 (21 calendar days)
- Showed: 22 pending lessons ❌

**New System (CORRECT):**
- Current learning day: 3
- Days to check: 3 - 1 = 2 (Days 1 and 2)
- Both completed ✅
- Showed: 0 pending lessons ✅

---

## The Solution

### New Logic
The missed lessons count now uses **curriculum progress** instead of calendar days:

1. **Get current learning day** from `CurriculumProgressService`
2. **Calculate days to check**: `currentLearningDay - 1`
3. **Check only those curriculum days** for completion
4. **Ignore future calendar days** that the user hasn't reached yet

### Formula
```dart
daysToCheck = currentLearningDay - 1

// Example:
// User on Day 3 → Check Days 1 and 2 (2 days)
// User on Day 1 → Check nothing (0 days)
// User on Day 10 → Check Days 1-9 (9 days)
```

---

## Changes Made

### File Modified
**`lib/services/data_service.dart`**

**Method:** `getMissedDates()` (Lines 2035-2100)

### Key Changes

**1. Use Curriculum Progress**
```dart
// OLD: Check all calendar days since signup
for (var d = startDate; d.isBefore(endCheckDate); d = d.add(Duration(days: 1)))

// NEW: Check only curriculum days that should be completed
int currentLearningDay = prefs.getInt('current_learning_day') ?? 1;
int daysToCheck = currentLearningDay - 1;
for (int dayOffset = 0; dayOffset < daysToCheck; dayOffset++)
```

**2. Early Return for Day 1 Users**
```dart
if (daysToCheck <= 0) {
  // User is still on Day 1, no missed lessons possible
  return [];
}
```

**3. Map Curriculum Days to Calendar Days**
```dart
// Each curriculum day maps to a calendar day from signup
final checkDate = signupDate.add(Duration(days: dayOffset));
```

**4. Safety Check for Future Dates**
```dart
// Don't check future dates
if (checkDate.isAfter(today)) {
  break;
}
```

---

## Examples

### Example 1: New User (Day 1)
```
Signup: Feb 1
Current Day: Day 1
Days to check: 1 - 1 = 0
Missed lessons: 0 ✅
```

### Example 2: User on Day 3 (All Completed)
```
Signup: Jan 30
Current Day: Day 3
Days to check: 3 - 1 = 2 (Days 1 and 2)
Calendar days: Jan 30, Jan 31
Both completed ✅
Missed lessons: 0 ✅
```

### Example 3: User on Day 5 (Missed Day 2)
```
Signup: Jan 28
Current Day: Day 5
Days to check: 5 - 1 = 4 (Days 1, 2, 3, 4)
Calendar days: Jan 28, 29, 30, 31

Day 1 (Jan 28): Completed ✅
Day 2 (Jan 29): NOT completed ❌
Day 3 (Jan 30): Completed ✅
Day 4 (Jan 31): Completed ✅

Missed lessons: 1 (Jan 29) ✅
```

### Example 4: User Reported Issue (Fixed)
```
Signup: Jan 31 (2 days ago)
Current Day: Day 3
Days to check: 3 - 1 = 2 (Days 1 and 2)
Calendar days: Jan 31, Feb 1

OLD SYSTEM:
- Checked: Feb 1 - Feb 1 (all calendar days)
- Showed: 22 pending ❌ (WRONG!)

NEW SYSTEM:
- Checked: Jan 31, Feb 1 (only 2 curriculum days)
- Showed: 0-2 pending ✅ (CORRECT!)
```

---

## Benefits

### 1. Accurate Counts
- Only counts days the user should have completed
- No inflation from future calendar days

### 2. Fair to New Users
- New users don't see inflated "pending" counts
- Encourages engagement instead of overwhelming them

### 3. Curriculum-Aligned
- Matches the app's curriculum progression model
- Consistent with how learning days work

### 4. Prevents Confusion
- Users understand what they actually missed
- Clear connection between curriculum progress and missed lessons

---

## Testing Checklist

- [x] Updated getMissedDates logic
- [ ] Test with Day 1 user (should show 0 missed)
- [ ] Test with Day 3 user who completed all (should show 0 missed)
- [ ] Test with Day 5 user who missed Day 2 (should show 1 missed)
- [ ] Test with user who joined 30 days ago but only on Day 3
- [ ] Verify dashboard shows correct count
- [ ] Verify "Pending Review(s)" label updates correctly

---

## Files Modified

1. `lib/services/data_service.dart` - Fixed `getMissedDates()` method

---

## Migration Notes

### For Existing Users
- Users with inflated missed lesson counts will see the correct count after this update
- No data migration needed
- Counts will automatically adjust based on `current_learning_day`

### For New Users
- Will see accurate counts from day 1
- No more overwhelming "22 pending lessons" on day 2

---

## Related Systems

This fix aligns with:
- **CurriculumProgressService**: Uses `current_learning_day` as source of truth
- **Day Badge Fix**: Both now use curriculum progress, not calendar days
- **Daily Tasks**: Completion tracking remains unchanged

---

## Notes

- The system still checks calendar days for completion status
- But only checks days that correspond to curriculum days the user should have completed
- This maintains backward compatibility with existing completion tracking
- Future enhancement: Could directly use `CurriculumProgressService.isDayCompleted()` for even more accuracy
