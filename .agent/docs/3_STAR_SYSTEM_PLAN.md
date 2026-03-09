# 🌟 Canonical 3-Star System Implementation Plan

**Objective:** Implement a deterministic, additive 3-star system per lesson and integrate strictly defined level-unlock gates (Level 6 & Level 11).

---

## 🏗️ Phase 1: Data Model Unification
**Goal:** Establish a single source of truth for "Stars" by aggregating existing dispersed flags.

### 1. New Usage of Existing Data
We will map existing persistence keys to the new 3-Star definition without deleting user data.

| Star | Definition | Source Logic (Mental Map) |
|------|------------|---------------------------|
| ⭐ **1** | Lesson Complete | `prefs.getBool('lessonX_storybook_completed')` OR Firestore `storybook_completed` |
| ⭐ **2** | Immediate Quiz | `prefs.getBool('lessonX_quiz_completed')` (Score >= 6) |
| ⭐ **3** | Master Quiz | `prefs.containsKey('lessonX')` (Menu/Curriculum Quiz) |

### 2. Helper Class
Create a `LessonProgress` helper in `curriculum_screen.dart` or a separate service to encapsulate this logic:
```dart
int calculateStars(String lessonId) {
  int stars = 0;
  if (isStoryCompleted(lessonId)) stars++;
  if (isImmediateQuizPassed(lessonId)) stars++;
  if (isMasterQuizPassed(lessonId)) stars++;
  return stars;
}
```

---

## 🎨 Phase 2: UI & Visualization
**Goal:** Update `MasteryLevelMap` to display the new 3-star status accurately.

### 1. Update `_buildNode`
- **Current:** Checks `hasStorybook` (1 star) or `hasQuiz` (2 stars).
- **New:**
  - Visualize 3 star slots (hollow/filled).
  - Use `calculateStars()` result.
  - Distinct colors/icons for 1 vs 2 vs 3 stars.

---

## 🔒 Phase 3: Gating & Unlock Logic (The Hard Gates)
**Goal:** Enforce progress requirements for Level 6 and Level 11.

### 1. Gate Definitions
| Gate | Condition | User Message |
|------|-----------|--------------|
| **Standard** | Previous Level ≥ 1 Star | "Complete previous lesson." |
| **Gate 1** (L6) | Levels 1-5 ≥ **2 Stars** | "Earn 2 stars in all previous levels to unlock Level 6." |
| **Gate 2** (L11) | Levels 1-10 ≥ **3 Stars** | "Master every previous level (3 stars) to unlock Level 11." |

### 2. Implementation in `_buildMap`
Refactor the simple `isLocked = index > currentLevelIndex` loop into a robust `checkLockStatus(index)` function that validates the specific history for that index.

---

## 📅 Execution Steps (Iterative)

1.  **Step 1: Data Logic (Safe)**
    - Modify `curriculum_screen.dart` to calculate the 3 distinct flags.
    - Log the calculated stars for verification.

2.  **Step 2: Map UI (Visual)**
    - Modify `mastery_level_map.dart` to show 3 star icons.
    - Ensure existing user progress maps correctly (e.g. existing users might jump to 2 or 3 stars instantly).

3.  **Step 3: Gates (Enforcement)**
    - Implement the `isLocked` logic updates.
    - Add the specific "Locked Reason" Snackbar messages.

---

## ✅ Verification Checklist
- [ ] User with Story only → 1 Star
- [ ] User with Story + Quiz → 2 Stars
- [ ] User with Story + Master Quiz → 2 Stars (Additive)
- [ ] User with ALL → 3 Stars
- [ ] Try to open Level 6 with only 1 star in Level 1 → **LOCKED**
- [ ] Try to open Level 11 with 2 stars in Level 1 → **LOCKED**
