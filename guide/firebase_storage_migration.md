# Firebase Cloud Storage Migration Guide

## 1. Why upload to Cloud?
The app now uses a smart `LessonImage` widget that checks 3 places for images, in this order:
1.  **Local Download** (Fastest, latest updates)
2.  **Cloud Storage** (Instant fixes/changes without app updates)
3.  **Local Assets** (Offline safety net)

By uploading your images to Firebase Storage, you gain the ability to **fix mistakes** or **update images** instantly for all users, without releasing a new app update.

## 2. How to Upload

1.  **Go to Firebase Console**: [console.firebase.google.com](https://console.firebase.google.com)
2.  **Select Project**: `gravity-app-f9933`
3.  **Go to Storage**: Click "Storage" in the left Build menu.
4.  **Create "Lessons" Folder**: If it doesn't exist, create a folder named `Lessons`.

## 3. Folder Mapping
Inside the `Lessons` folder on Firebase, you must create sub-folders that match the **Lesson IDs** used in the code.

**⚠️ IMPORTANT**: The folder names must generally follow the format `Lesson_<ID>`, but there are specific mappings.

Here is exactly where to drag-and-drop your folder contents:

| Local Folder (Your Zip)          | Firebase Storage Folder Path              | Lesson ID (In Code) |
| :--- | :--- | :--- |
| `Lesson_01_Subjects` | `Lessons/Lesson_subjects` | `subjects` |
| `Lesson_02_PartsOfSpeech` | `Lessons/Lesson_parts_of_speech` | `parts_of_speech` |
| `Lesson_03_Articles` | `Lessons/Lesson_articles` | `articles` |
| (Simple Present Content) | `Lessons/Lesson_simple_present` | `simple_present` |
| (Present Continuous Content) | `Lessons/Lesson_present_continuous` | `present_continuous` |
| (Present Perfect Content) | `Lessons/Lesson_present_perfect` | `present_perfect` |
| (Simple Past Content) | `Lessons/Lesson_simple_past` | `simple_past` |
| `Lesson_Punctuation` | `Lessons/Lesson_punctuation` | `punctuation` |
| `Lesson_Comparatives` | `Lessons/Lesson_comparatives` | `comparatives` |
| `Lesson_07_Sentence_Patterns` | `Lessons/Lesson_sentence_patterns` | `sentence_patterns` |

### General Rule
The `LessonImage` widget constructs the URL like this:
`.../Lessons/Lesson_{lessonId}/{imageName}`

So if you have a lesson with ID `my_cool_lesson`, you create a folder `Lessons/Lesson_my_cool_lesson` and put the images inside.

## 4. Bulk Upload Tip
You don't need to do this file-by-file!
1.  On your computer, rename your local folders to match the **Firebase Storage Folder Path** above (e.g., rename `Lesson_01_Subjects` to `Lesson_subjects`).
2.  Drag the entire `Lesson_subjects` folder into the `Lessons` folder in the Firebase Console browser window.
3.  It will upload everything and keep the structure!
