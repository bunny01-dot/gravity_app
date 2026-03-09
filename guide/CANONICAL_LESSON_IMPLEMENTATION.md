# Canonical Lesson Implementation Guide

This guide defines the standard pattern for implementing all new Lessons in the Gravity App. Following this pattern ensures consistency in **State Management**, **Persistence**, **Star Rewards**, and **UI Layouts**.

## 1. Lesson State Model

Every Lesson screen must implement the following `LessonState` enum and loading logic to handle the lesson lifecycle.

### Enum Definition
```dart
enum LessonState { notStarted, storyCompleted, quizMastered }
```

### Loading State (Strict Score Check)
Crucial: You must check the `quiz_score` (>= 6) to grant Mastery status. Do NOT rely solely on the `quiz_completed` flag.

```dart
  Future<void> _loadValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storyDone = prefs.getBool('lessonX_storybook_completed') ?? false;
      final quizDone = prefs.getBool('lessonX_quiz_completed') ?? false;
      final quizScore = prefs.getInt('lessonX_quiz_score') ?? 0;

      setState(() {
        // Strict Mastery Check: Must have flag AND passing score (>=6)
        if (quizDone && quizScore >= 6) {
          _lessonState = LessonState.quizMastered;
          _isReEntryLanding = true;
        } else if (storyDone) {
          _lessonState = LessonState.storyCompleted;
          _isReEntryLanding = true;
        } else {
          _lessonState = LessonState.notStarted;
          _isReEntryLanding = false;
        }
        _isLoading = false;
      });
      // ... Analytics log
    } catch (e) { ... }
  }
```

## 2. Persistence & Completion Logic

### Storybook Completion (1 Star)
```dart
  Future<void> _saveStoryBookCompletion() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lessonX_storybook_completed', true);

      if (_lessonState != LessonState.quizMastered) {
        setState(() => _lessonState = LessonState.storyCompleted);
      }
      
      // ... Firestore sync 'storybook_completed': true
  }
```

### Quiz Completion (2 Stars + Mastery)
Crucial: You MUST save the `quiz_score` to SharedPreferences.

```dart
  Future<void> _saveQuizCompletion() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lessonX_quiz_completed', true);
      await prefs.setInt('lessonX_quiz_score', _correctAnswers); // CRITICAL
      await prefs.setBool('lessonX_storybook_completed', true);

      setState(() => _lessonState = LessonState.quizMastered);

      // ... Firestore sync { 'quiz_completed': true, 'quiz_score': _correctAnswers }
  }
```

## 3. UI Layout Standards (Polished)

All success/landing screens must be **Centered** and use **SingleChildScrollView** to prevent overflows.

### Re-Entry Landing Screen
Provides specific options based on state.
- **1 Star (Story Completed)**: Show "Take Quiz" (Primary) + "Continue" (Secondary).
- **2 Stars (Mastered)**: Show "Review Story" + "Retake Quiz" + "Go Back".

```dart
  Widget _buildReEntryLanding() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             // Icon (Yellow/Purple based on Lesson Theme)
             // Title "Lesson Mastered!" / "Lesson Completed"
             // Subtitle "You have earned X Stars!"
             // Buttons (SizedBox width: 220)
          ]
        )
      )
    );
  }
```

### Buttons
Buttons should have a consistent width of `220` and use `RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))`.

## 4. Curriculum Screen Integration

When adding a new lesson to `curriculum_screen.dart`, you must use the updated `syncItem` signature that includes the Score Key.

```dart
      await syncItem(
        'Lesson Name',
        'firestore_doc_id',
        'lessonX_storybook_completed',
        'lessonX_quiz_completed',
        'lessonX_quiz_score', // SCORE KEY IS MANDATORY
      );
```

## 5. Map & Rewards
- **1 Star**: Awarded for Story completion.
- **2 Stars**: Awarded ONLY if Quiz is passed (Score >= 6).
- **UI**: The Map Node shows corner badges (Left=Story, Right=Quiz) and a central Trophy/Checkmark.

---
**Note to Developers**: Always verify `firestore.rules` allows write access to `users/{uid}/lessons/{lessonId}`.
