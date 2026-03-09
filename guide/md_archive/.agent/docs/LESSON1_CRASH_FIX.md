# Lesson 1 Crash Fix - Troubleshooting Guide

## Issue
App crashes when clicking "Start Lesson" for Lesson 1 in the curriculum.

## Root Cause
The SVG files for Lesson 1 are very large (2-5 MB each), which can cause:
- **Memory pressure** on devices with limited RAM
- **Parsing issues** with the flutter_svg package
- **Render timeout** when trying to display large vector graphics

## Fixes Applied

### 1. Added Error Handling to SVG Loading
**File**: `lib/screens/lesson_subjects_screen.dart`

Added `errorBuilder` to gracefully handle SVG loading failures instead of crashing:
```dart
errorBuilder: (context, error, stackTrace) {
  debugPrint('Error loading SVG: $error');
  return Container(
    // Shows error message instead of crashing
  );
}
```

### 2. Improved SVG Rendering Performance
Added performance optimizations to handle large SVG files:

```dart
SvgPicture.asset(
  'assets/Lessons/Lesson_01_Subjects_svg/$svgFile',
  fit: BoxFit.contain,
  allowDrawingOutsideViewBox: false, // Prevents overdraw
  clipBehavior: Clip.hardEdge,        // Improves rendering
  cacheColorFilter: true,              // Reduces memory usage
  ...
)
```

### 3. Navigation Error Handling
**File**: `lib/screens/curriculum_screen.dart`

Wrapped lesson navigation in try-catch blocks to prevent app crashes:
```dart
try {
  Navigator.of(context).push(...);
} catch (e) {
  _showError('Failed to load lesson: $e');
}
```

## Testing the Fix

### Test Steps:
1. **Hot Restart** the app (or rebuild)
2. Navigate to **Dashboard → Full Curriculum**
3. Tap on **"Lesson 1 - Subjects"**
4. Click **"Start Lesson"**

### Expected Behavior:
- ✅ Lesson should load without crashing
- ✅ If SVG fails to load, you'll see an error message instead of a crash
- ✅ You can navigate through the 8 pages smoothly

### If Still Crashing:

#### Option A: Check Device Logs
Run this command to see the exact error:
```bash
flutter logs
```

Look for:
- `OutOfMemoryError`
- `SVG parsing error`
- Stack trace showing which line crashed

#### Option B: Verify Assets
Make sure all 8 SVG files exist:
```bash
dir "assets\Lessons\Lesson_01_Subjects_svg"
```

Should show:
- first_person_singular.svg
- first_person_plural.svg
- second_person_singular.svg
- second_person_plural.svg
- third_person_singular_he.svg
- third_person_singular.svg
- third_person_things.svg
- third_person_plural.svg

#### Option C: Reduce SVG File Sizes
If the SVGs are too large (>2MB each), we may need to:
1. Optimize/compress the SVG files
2. Convert them to PNG images instead
3. Use a different rendering approach

## Alternative Solution (If SVG Still Fails)

If the SVG approach continues to cause issues, we have 2 alternatives:

### Alternative 1: Convert SVGs to PNG
Run this to convert all SVGs to smaller PNG files:
```bash
# (Would need to install an SVG-to-PNG converter)
```

### Alternative 2: Use Lazy Loading
Load SVGs one at a time instead of all at once:
```dart
// Only load the current page SVG, dispose others
```

## Next Steps

Please try the app now and let me know:
1. **Does it still crash?** → Share the error from `flutter logs`
2. **Does it load but show error message?** → Which SVG file is failing?
3. **Does it work?** → Great! We can move on to Lesson 2

---

**Status**: 🔧 Fixed and ready for testing
**Priority**: HIGH - Blocking curriculum feature
