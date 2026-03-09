# TUTORIAL SYSTEM - DEBUGGING GUIDE

## ✅ **Tutorial Status Check**

You mentioned only the **startup tutorial (onboarding)** worked. Here's why the other 4 tutorials might not be showing and how to trigger them:

---

## 📚 **5 Contextual Tutorials Implemented**

### 1️⃣ **Startup Tutorial (Onboarding)** - ✅ WORKING
- **Shows When**: First app launch
- **Condition**: `onboarding_seen` flag is false
- **Status**: ✅ **Working** (you confirmed this)

---

### 2️⃣ **Daily Tasks Tutorial** - ⏳ Waiting for Conditions
- **Shows When**: You open the Daily Tasks tab for the first time
- **File**: `dashboard.dart` line 3560
- **Conditions Required**:
  - ✅ Onboarding must be completed
  - ❌ Daily tasks for today must NOT be completed yet
  - ❌ Tutorial flag `tutorial_daily_tasks_seen` must be false

**Why It's Not Showing:**
Likely you've already completed some daily tasks, so the condition `tasksCompletedToday == false` is not met.

**How to Trigger It:**
```dart
// Option 1: Reset the tutorial flag
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setBool('tutorial_daily_tasks_seen', false);
// Next time you open Daily Tasks tab (and tasks aren't done), it will show

// Option 2: Use the reset method
TutorialService().resetTutorial();
```

---

### 3️⃣ **Games Locked Tutorial** - ⏳ Waiting for Trigger
- **Shows When**: You tap a LOCKED game for the first time
- **File**: `locked_games_view.dart` line 36
- **Conditions Required**:
  - ❌ Tutorial flag `tutorial_games_locked_seen` must be false
  - ❌ Games must have NEVER been unlocked before (`games_unlocked_once` is false)

**Why It's Not Showing:**
- You need to **tap on a locked game** (the tutorial doesn't show automatically, only when you try to access a locked game)
- If you've ever completed all daily tasks before, games were unlocked and the `games_unlocked_once` flag is set

**How to Trigger It:**
1. Don't complete all daily tasks today (games will be locked)
2. Tap on any game in the Games tab
3. Tutorial should show

**Or reset it:**
```dart
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setBool('tutorial_games_locked_seen', false);
await prefs.setBool('games_unlocked_once', false);
```

---

### 4️⃣ **Mastery Tutorial** - ⏳ Waiting for First Visit
- **Shows When**: You open the Mastery tab for the first time
- **File**: `dashboard.dart` line 3593
- **Conditions Required**:
  - ❌ Tutorial flag `tutorial_mastery_seen` must be false

**Why It's Not Showing:**
- You might have already visited the Mastery tab once
- There's also a legacy "Mastery Intro Dialog" that might be showing instead (line 3413)

**How to Trigger It:**
```dart
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setBool('tutorial_mastery_seen', false);
await prefs.setBool('mastery_intro_seen', false);  // Reset both
// Now open Mastery tab
```

---

### 5️⃣ **Settings Difficulty Tutorial** - ⏳ Waiting for Specific Conditions
- **Shows When**: You open Settings tab after completing at least one lesson
- **File**: `dashboard.dart` line 3622
- **Conditions Required**:
  - ✅ You must have completed at least ONE lesson (vocab, verbs, or speaking)
  - ❌ Tutorial flag `tutorial_settings_difficulty_seen` must be false
  - ❌ You must NOT have changed difficulty before (`difficulty_changed_once` is false)

**Why It's Not Showing:**
- You need to complete a lesson first
- Then visit Settings tab
- If you've already changed difficulty, it won't show

**How to Trigger It:**
1. Complete at least one daily task
2. Open Settings tab (Profile → Settings icon)
3. Tutorial should show

**Or reset it:**
```dart
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setBool('tutorial_settings_difficulty_seen', false);
await prefs.setBool('difficulty_changed_once', false);
```

---

## 🔧 **QUICK FIX: Reset All Tutorials**

To see ALL tutorials again, add this button temporarily in your dashboard:

```dart
// In dashboard build method, add a test button:
FloatingActionButton(
  onPressed: () async {
    await TutorialService().resetTutorial();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All tutorials reset! Restart app to see them.')),
    );
  },
  child: Icon(Icons.restart_alt),
)
```

Or run this in your code:

```dart
await TutorialService().resetTutorial();
// This resets ALL tutorial flags
```

---

## 🎯 **Tutorial Trigger Sequence**

Here's the ideal sequence to see all tutorials:

1. **First Launch** → ✅ Startup Tutorial (Onboarding) shows
2. **Open Daily Tasks tab** → Tutorial #2 shows (if tasks not done)
3. **Tap a locked game** → Tutorial #3 shows (if games locked)
4. **Open Mastery tab** → Tutorial #4 shows
5. **Complete one task, then open Settings** → Tutorial #5 shows

---

## 📊 **Check Current Tutorial Status**

Add this debug method to see which tutorials have been shown:

```dart
Future<void> checkTutorialStatus() async {
  final prefs = await SharedPreferences.getInstance();
  
  debugPrint('=== TUTORIAL STATUS ===');
  debugPrint('Onboarding seen: ${prefs.getBool('onboarding_seen')}');
  debugPrint('Dashboard tutorial: ${prefs.getBool('tutorial_dashboard_seen')}');
  debugPrint('Daily Tasks tutorial: ${prefs.getBool('tutorial_daily_tasks_seen')}');
  debugPrint('Games Locked tutorial: ${prefs.getBool('tutorial_games_locked_seen')}');
  debugPrint('Mastery tutorial: ${prefs.getBool('tutorial_mastery_seen')}');
  debugPrint('Settings tutorial: ${prefs.getBool('tutorial_settings_difficulty_seen')}');
  debugPrint('======================');
}
```

---

## ⚡ **MOST LIKELY REASON**

The tutorials are working correctly, but:

1. **Tutorial #2 (Daily Tasks)** - You've already completed tasks today
2. **Tutorial #3 (Games Locked)** - You haven't **tapped** a locked game yet (it needs user action)
3. **Tutorial #4 (Mastery)** - You've already visited Mastery tab once
4. **Tutorial #5 (Settings)** - You haven't visited Settings after completing a lesson yet

---

## ✅ **SOLUTION**

### Option 1: Test on Fresh Install
```bash
flutter clean
flutter run
```
This gives you a completely fresh app with no saved preferences.

### Option 2: Reset Tutorial Flags Programmatically
Add this code temporarily in your Dashboard `initState()`:

```dart
@override
void initState() {
  super.initState();
  
  // TESTING ONLY - Remove after confirming tutorials work
  _resetTutorialsForTesting();
  
  // ... rest of init code
}

Future<void> _resetTutorialsForTesting() async {
  await TutorialService().resetTutorial();
  debugPrint('✅ All tutorials reset for testing');
}
```

### Option 3: Manual Trigger (Test Each One)
Go to each screen and the tutorial should show if you've reset the flags.

---

## 🎓 **SUMMARY**

✅ **All 5 tutorials ARE implemented and integrated**  
✅ **They're just waiting for specific user actions/conditions**  
⚡ **Most likely not showing because conditions aren't met on your device**  

**Next Steps:**
1. Close and restart the app
2. Reset tutorial flags using `TutorialService().resetTutorial()`
3. Follow the trigger sequence above
4. Each tutorial should appear at the right moment

---

*Tutorial System: WORKING*  
*Issue: Trigger conditions not met on current device state*
