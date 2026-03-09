# Gravity App - Curriculum Feature Implementation Plan

## Overview
We will implement a structured learning path called "Curriculum" for students. This involves a new dashboard card, a dedicated Curriculum page with 15 hardcoded lessons, PPTX slide viewing, AI-generated quizzes, and progress tracking using Firebase Firestore.

## 1. Dashboard Update
- **File**: `lib/dashboard.dart`
- **Action**: Add a new "Curriculum" card to the Student Dashboard grid/list.
- **Design**: Use the existing premium aesthetics (glassmorphism/gradients).
- **Navigation**: Tapping the card opens the `CurriculumScreen`.

## 2. Curriculum Screen (`lib/screens/curriculum_screen.dart`)
- **Structure**: A scrollable list of 15 Lesson Cards.
- **Data Model**:
  ```dart
  class Lesson {
    final int id;
    final String title;
    final String topic; // For AI generation
    final String pptxUrl; // Firebase Storage URL
    // ...
  }
  ```
- **Lesson Display**:
  - Show Title.
  - **Status**: Show "Completed" badge if score >= 90%.
  - **Actions** (if not completed):
    - "View Slides": Opens a Dialog with a WebView showing the Google Docs Viewer URL for the PPTX.
    - "Take a Quiz": Triggers the AI Quiz flow.

## 3. Slide Viewer
- **Tech**: `webview_flutter` (if mobile) or direct widget.
- **Implementation**: A Dialog containing a `WebViewWidget`.
- **URL**: `https://docs.google.com/gview?embedded=true&url=<PPTX_URL>`

## 4. AI Quiz Generation
- **Service**: Create/Update `GenAIService` (or `AIService`).
- **Function**: `generateStudentQuiz(String topic)`
- **Logic**:
  - Call Google Gemini API (via `google_generative_ai` package).
  - Prompt: "Generate 10 multiple-choice questions for English grammar topic: [Topic]. Return JSON."
  - Parse JSON to `List<Question>`.
- **Fallback**: If AI fails, handle gracefully (retry or show error).

## 5. Quiz Interface & Progress
- **UI**: A Dialog showing one question at a time.
- **Flow**:
  1. User selects answer -> Immediate feedback (Green/Red).
  2. Next question.
  3. End -> Show Score %.
- **Progress Saving**:
  - **Firestore Path**: `users/{userId}/curriculum_progress/{lessonId}`
  - **Data**: `{ score: 90, completed: true, timestamp: ... }`
  - If score >= 90%, update local state to show "Completed".

## 6. Dependencies
- `webview_flutter` (for viewing slides in app).
- `google_generative_ai` (for quiz generation).
- `cloud_firestore` (for saving progress).

## 7. Next Steps
Once approved:
1.  Setup `CurriculumScreen` skeleton.
2.  Implement `AIService` for quiz generation.
3.  Integrate Firestore for progress.
4.  Connect everything in `Dashboard`.
