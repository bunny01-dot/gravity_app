# Daily Sentences UI Update

**Date**: 2026-01-23
**Status**: ✅ Applied

## Changes

Refactored `DailySentenceCard` to align with the "Daily Tasks" UI pattern.

### 1. UI Consistency
- **Previous**: Custom container with `Row` layout.
- **New**: Uses `DailyTaskCard` widget (same as Vocabulary, Verbs, etc.).
- **Style**: Amber color, Star icon, "Hop" animation.

### 2. Interaction ("Fill the Page")
- **Previous**: Opened a small, center-aligned `Dialog`.
- **New**: Opens a **Modal Bottom Sheet** taking up **85% of screen height**.
- **Styling**: Matches `_showTaskContentSheet` from Dashboard (Dark theme `0xFF161621`, rounded top corners).

### 3. Features
- **Completion Tracking**: Now locally persists completion status (`daily_sentences_completed_YYYY-MM-DD`).
- **Visual Feedback**: Shows "Completed! Great practice." subtitle and checkmark when done.
- **Mark as Done**: Added a dedicated button in the bottom sheet to close and mark as complete.

## File Modified
- `lib/features/daily_sentences/daily_sentence_card.dart`
