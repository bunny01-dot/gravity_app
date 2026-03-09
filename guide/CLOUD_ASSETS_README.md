
# ☁️ Cloud Asset Strategy: Implementation Guide

## 1. The Strategy
We are moving away from a giant app download.
- **Old Way:** Application (200MB) = Code + All Assets
- **New Way:** Application (30MB) = Code. Assets download as you play.

## 2. How it works
1.  **User opens Lesson 1.**
2.  App checks: "Do I have images for Lesson 1?"
    - No? Use bundled fallback (safe).
    - Yes? Use beautiful cloud images.
3.  **Magic happens:** Background downloader wakes up.
    - "User is on Lesson 1... I should get Lesson 2 and Lesson 3 ready!"
    - Starts downloading them silently.
4.  **User finishes Lesson 1.**
5.  **User opens Lesson 2.**
    - Boom! It's already there. Instant load.

## 3. How to add new lessons
For every lesson you want to move to the cloud:

### A. Prepare the Zip
1.  Go to `assets/Lessons/`.
2.  Zip the lesson folder (e.g., `Lesson_02_PartsOfSpeech` -> `lesson_2.zip`).
3.  Upload to OneDrive.
4.  Get the **Direct Link** (change `embed` to `download`).

### B. Update the Code
Open `lib/services/lesson_content_service.dart`.
Add your link to the `_lessonManifest`:

```dart
final Map<String, String> _lessonManifest = {
  'lesson_1_subjects': 'https://onedrive...',
  'lesson_2_parts_of_speech': 'YOUR_NEW_LINK_HERE',
  // ...
};
```

### C. Update the Screen
Open the screen file (e.g., `lesson_parts_of_speech_screen.dart`).

1. **Imports:**
   ```dart
   import 'package:gravity_app/services/lesson_content_service.dart';
   import 'package:gravity_app/widgets/lesson_image.dart';
   ```

2. **Init State (Trigger Next Downloads):**
   ```dart
   @override
   void initState() {
     super.initState();
     // ...
     LessonContentService().preloadNextLessons('lesson_2_parts_of_speech');
   }
   ```

3. **Replace Images:**
   Change `Image.asset(...)` to:
   ```dart
   LessonImage(
     lessonId: 'lesson_2_parts_of_speech',
     imageName: '01_intro.png', // Just the filename
     fallbackAssetPath: 'assets/Lessons/Lesson_02_PartsOfSpeech/01_intro.png',
   )
   ```

## 4. Verification
Watch your Debug Console when you run the app.
You will see:
- `🚀 Triggering preload for: lesson_2_parts_of_speech`
- `📦 Download complete`
