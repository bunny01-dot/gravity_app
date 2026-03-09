# CRITICAL FIX NEEDED - Lesson Screen Errors

## Problem
Three lesson files have syntax errors due to condensed formatting:
1. `lib\screens\lesson_parts_of_speech_screen.dart`
2. `lib\screens\lesson_reported_questions_screen.dart`
3. `lib\screens\lesson_verbal_nouns_screen.dart`

## Root Cause
Extra closing brackets in the `_buildContentCard` method causing parse errors.

## SOLUTION: Use Working Templates

### Step 1: Delete Broken Files
```powershell
Remove-Item lib\screens\lesson_parts_of_speech_screen.dart
Remove-Item lib\screens\lesson_reported_questions_screen.dart  
Remove-Item lib\screens\lesson_verbal_nouns_screen.dart
```

### Step 2: Copy from Working Templates

**For Lesson 2 - Parts of Speech:**
```powershell
Copy-Item lib\screens\lesson_idioms_screen.dart lib\screens\lesson_parts_of_speech_screen.dart
```
Then update:
- Class name: `LessonPartsOfSpeechScreen`
- Title: "Parts of Speech"
- Asset path: `'assets/Lessons/Lesson_02_PartsOfSpeech/'`
- Lesson content: 8 slides for noun, verb, adjective, adverb, pronoun, preposition, conjunction, interjection

**For Lesson - Verbal Nouns:**
```powershell
Copy-Item lib\screens\lesson_idioms_screen.dart lib\screens\lesson_verbal_nouns_screen.dart
```
Then update:
- Class name: `LessonVerbalNounsScreen`
- Title: "Verbal Nouns"
- Asset path: `'assets/Lessons/Lesson_Verbal_Nouns/'`
- Lesson content: 10 slides for gerunds

**For Lesson 25 - Reported Questions:**
```powershell
Copy-Item lib\screens\lesson_direct_indirect_speech_screen.dart lib\screens\lesson_reported_questions_screen.dart
```
Then update:
- Class name: `LessonReportedQuestionsScreen`
- Title: "Reported Questions"
- Asset path: `'assets/Lessons/Lesson_Reported_Questions/'`
- Lesson content: 10 slides for reported questions

## Quick Alternative

If you want me to regenerate these files properly, I can do so one at a time with proper formatting. Just let me know which one to start with.

## Files That Work Correctly (Use as Templates)
- ✅ lesson_idioms_screen.dart
- ✅ lesson_direct_indirect_speech_screen.dart
- ✅ lesson_conditionals_screen.dart
- ✅ lesson_prepositions_screen.dart

All these files have the same structure and are properly formatted.
