# How to Access the Past Perfect Lesson

## Navigation Path

### Step 1: Open Curriculum (Mission Map)
Tap on the **"Curriculum"** or **"Mission Map"** tab in your app.

### Step 2: Find "Lesson 4 - Tense - Past"
Look for the mission map node labeled:
```
📍 Lesson 4 - Tense - Past
```

**Important**: This node shows in the Mission Map as a planet/level node.

### Step 3: Tap on "Lesson 4 - Tense - Past"
When you tap this node, a **bottom sheet menu** will appear with 4 options:

```
┌─────────────────────────────────────┐
│   Past Tense Master Class           │
│   Select a branch to master         │
├─────────────────────────────────────┤
│ ✓ 1. Simple Past                    │  ← Unlocked
│   Finished actions & yesterday      │
├─────────────────────────────────────┤
│ ✓ 2. Past Continuous                │  ← Unlocked
│   Was happening when...             │
├─────────────────────────────────────┤
│ ✓ 3. Past Perfect                   │  ← SHOULD BE UNLOCKED
│   Had happened before...            │
├─────────────────────────────────────┤
│ 🔒 4. Past Perfect Continuous       │  ← Locked (Coming Soon)
│   Had been happening...             │
└─────────────────────────────────────┘
```

### Step 4: Tap "3. Past Perfect"
This will open the Past Perfect lesson with all 10 slides and images.

---

## 🔍 Troubleshooting

### If "3. Past Perfect" Still Shows LOCKED (🔒):

This means the hot reload didn't apply the code changes. Try these solutions:

#### Solution 1: Hot Restart (Fastest)
1. Go to your Flutter terminal/console
2. Press **"R"** (capital R) for hot restart
3. Wait for app to reload
4. Try accessing the lesson again

#### Solution 2: Full Rebuild
1. Stop the running app
2. Run these commands:
```bash
flutter clean
flutter pub get
flutter run
```

#### Solution 3: Check Import Statement
The file `curriculum_screen.dart` should have this import at the top:
```dart
import 'package:gravity_app/screens/lesson_past_perfect_screen.dart';
```

---

## 🐛 If It's Still Grey/Locked After Restart:

### Check the _buildTenseOption call:
In `lib/screens/curriculum_screen.dart` around line 892-911, verify:

```dart
_buildTenseOption(
  "3. Past Perfect",
  "Had happened before...",
  Icons.check_circle_outline,  // ← Should be this, NOT Icons.lock_outline
  true,                         // ← Should be true, NOT false
  () async {
    Navigator.pop(context);
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LessonPastPerfectScreen(),
      ),
    );
    // ... rest of the code
  },
),
```

**Key values:**
- 4th parameter: `Icons.check_circle_outline` (unlocked icon)
- 5th parameter: `true` (unlocked state)

---

## 📱 What to Look For

### When Menu Opens Successfully:
- ✅ Option 1 (Simple Past): **Unlocked** - checkmark icon ✓
- ✅ Option 2 (Past Continuous): **Unlocked** - checkmark icon ✓
- ✅ **Option 3 (Past Perfect)**: **UNLOCKED** - checkmark icon ✓
- ❌ Option 4 (Past Perfect Continuous): **Locked** - lock icon 🔒

### Icon & Color Differences:
- **Unlocked items**: 
  - White text (bright)
  - Checkmark icon (✓)
  - Orange/coral border glow
  - Tappable (responds to touch)

- **Locked items**:
  - Grey text (dimmed)
  - Lock icon (🔒)
  - No border glow
  - Not tappable

---

## 🔄 Quick Fix Script

If you want to manually verify and fix, run this in your terminal:

```bash
# Go to your app directory
cd e:/Apps/gravity_app

# Check if the file has the correct changes
grep -A 5 "3. Past Perfect" lib/screens/curriculum_screen.dart

# You should see:
# "3. Past Perfect",
# "Had happened before...",
# Icons.check_circle_outline,
# true,
```

---

## 🎯 Expected Behavior After Fix

1. **Tap** "Lesson 4 - Tense - Past" in Mission Map
2. **Bottom sheet opens** with 4 tense options
3. **Options 1, 2, 3** are **bright/unlocked**
4. **Option 4** is **grey/locked**
5. **Tap "3. Past Perfect"**
6. **Lesson opens** with Slide 1 (Ravi thinking)

---

## 💡 Alternative: Navigate Directly (Debug)

If you want to test the lesson without going through the menu, you can temporarily add a debug button:

In `dashboard.dart` or any screen, add:
```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LessonPastPerfectScreen(),
      ),
    );
  },
  child: const Text('Test Past Perfect Lesson'),
)
```

This will let you test the lesson directly while troubleshooting the menu issue.

---

## ✅ Confirmation Checklist

Once working, you should be able to:
- [ ] Open Curriculum/Mission Map
- [ ] Tap "Lesson 4 - Tense - Past"
- [ ] See bottom sheet menu with 4 options
- [ ] See "3. Past Perfect" with **checkmark icon** (not lock)
- [ ] Tap it and lesson opens
- [ ] See all 10 slides with images
- [ ] Complete the quiz
- [ ] See completion screen

---

**Current Status Check:**
- Code changes: ✅ Applied correctly in curriculum_screen.dart
- Import statement: ✅ Added
- Images: ✅ All 10 in place
- Lesson screen: ✅ Created

**Issue**: Hot reload may not have applied the changes to the running app.

**Next Step**: Press "R" in the Flutter terminal for a hot restart, or stop and restart the app completely.
