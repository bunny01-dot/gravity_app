# Yesterday Quiz Logic Fix

**Date**: 2026-01-23
**Status**: ✅ Applied

## Issue
Existing listeners who missed a day were being treated as "New Users" when tapping "Yesterday's Review & Quiz".
- **Symptom**: Shown "Welcome! Start Here" dialog with only "Got It" button.
- **Cause**: Logic only checked if yesterday's specific tasks were done. If not, it assumed no history.

## Fix
Updated `_handleYesterdayQuizTap` in `dashboard.dart`.
- **Logic Change**: Added checks for `_missedLessonsCount` and `_streakCount`.
- **New Condition**: 
  User is "New" ONLY if:
  1. Not done yesterday's tasks
  2. AND `_missedLessonsCount == 0`
  3. AND `_streakCount == 0`

## Result
- **New Users**: Still see "Welcome! Start Here".
- **Existing Users (Missed Day)**: Now fall through to the "Yesterday's Lesson Available" dialog.
  - Shows: "Yesterday's lesson has been added to your Pending Lessons."
  - Action: **"Go to Pending Lessons"** button (navigates to Mastery Tab).
