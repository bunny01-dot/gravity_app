# Lesson 12 - Active & Passive Voice - Implementation Notes

## Date: 2026-01-23
## Author: Antigravity AI

## Pattern Used
Following the **Storybook UI V2** pattern as implemented in `lesson_articles_screen.dart`.

## Structure
The lesson follows this flow:
1. **Teaching Slides** (10 slides) - PageView-based learning content
2. **Story Complete Screen** - Transition screen with "Take Mastery Quiz" option
3. **Mastery Quiz** (6 questions) - Final evaluation
4. **Results Screen** - Score, percentage, retake option

## Key Components

### State Variables
- `_showFinalQuiz`: Controls quiz display
- `_lessonCompleted`: Controls results page  
- `_storyComplete`: Controls story completion screen
- `_finalQuizIndex`: Current quiz question
- `_finalQuizScore`: Running score
- `_selectedFinalQuizOption`: User's answer
- `_showFinalQuizFeedback`: Shows explanation

### UI Flow Methods
1. `build()` - Main router showing current screen
2. `_buildStoryCompleteScreen()` - Intermediate completion screen
3. `_buildFinalQuizPage()` - Quiz UI with questions
4. `_buildCompletionPage()` - Final results screen

### Content Structure
- **Slides**: 10 teaching slides using `LessonSlide` model
- **Quiz**: 6 multiple-choice questions testing comprehension
- **Interactivity**: Inline quiz slides within teaching content

## Features Implemented
✅ PageView with swipe navigation
✅ Language toggle (தமிழ்/Hindi)
✅ No navigation buttons (gesture-based)
✅ Story completion checkpoint
✅ Mastery quiz with scoring
✅ Results screen with pass/fail (60% threshold)
✅ Retake quiz option

## Deviations from Standard
- Used PageView instead of PageController with manual navigation
- Removed footer navigation buttons per user request
- Added horizontal drag support for previous slide

## Assets Required
Location: `assets/Lessons/Lesson_12_Active_Passive/`

Required images (10 total):
1. active_passive_hook_square.png
2. active_passive_structure_square.png
3. tense_present_square.png  
4. tense_past_square.png
5. tense_future_square.png
6. tense_continuous_square.png
7. voice_quiz_square.png
8. active_passive_conversion_square.png
9. (reused) tense_continuous_square.png
10. active_passive_chart_square.png

**Note**: Images not yet generated due to quota limit. Placeholders show "Image Not Supported" icon.

## Firebase Integration
- Saves completion status to Firestore
- Path: `users/{uid}/lessons/lesson_12_active_passive`
- Fields: `completed`, `timestamp`

## Sound Effects
- `SoundService().playCorrect()` - Correct quiz answer
- `SoundService().playWrong()` - Incorrect answer
- `SoundService().playCompletion()` - Lesson completion
- `SoundService().playTap()` - Page navigation

## Testing Notes
- Test swipe left/right navigation
- Verify quiz scoring logic
- Check Firebase save on completion
- Validate 60% pass threshold
- Test retake functionality

## Known Issues
- Unused methods `_nextSlide` and `_prevSlide` (kept for potential future use)
- Image generation quota exhausted - images pending
