# 🎧 SFX Integration Examples for Gravity App

## 🚀 Initialize in main.dart

```dart
// Add at the top
import 'package:gravity_app/services/sfx/sfx_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize SFX System
  await SfxManager().init();

  runApp(const MyApp());
}
```

---

## 📱 Replace in Existing Screens

### **1. Quiz Screens - Answer Feedback**

**Find this pattern:**
```dart
if (isCorrect) {
  // Show success
}
```

**Add SFX:**
```dart
import 'package:gravity_app/services/sfx/sfx_manager.dart';
import 'package:gravity_app/services/sfx/sfx_models.dart';

if (isCorrect) {
  await SfxManager().play(SfxAction.answerCorrect);
  // Show success
} else {
  await SfxManager().play(SfxAction.answerWrong);
  // Show error
}
```

### **2. Level Completion**

**In `_finishQuiz()` or similar:**
```dart
if (percentage >= 80) {
  await SfxManager().play(SfxAction.levelComplete);
  SoundService().playCompletion(); // Keep existing
}
```

### **3. Button Taps in Dashboard**

**In dashboard buttons:**
```dart
IconButton(
  onPressed: () {
    SfxManager().play(SfxAction.buttonTap);
    // Your action
  },
  icon: Icon(Icons.notifications),
)
```

### **4. Tab Navigation**

**In bottom nav bar:**
```dart
BottomNavigationBar(
  onTap: (index) {
    setState(() => _currentIndex = index);
    SfxManager().play(SfxAction.tabSwitch);
  },
  items: [...],
)
```

### **5. Toggle Switches**

```dart
Switch(
  value: _enabled,
  onChanged: (value) {
    setState(() => _enabled = value);
    SfxManager().play(value ? SfxAction.toggleOn : SfxAction.toggleOff);
  },
)
```

### **6. Error Messages**

```dart
if (error) {
  await SfxManager().play(SfxAction.validationError);
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

### **7. Save Success**

```dart
await FirebaseFirestore.instance.collection('users').doc(uid).set({...});
await SfxManager().play(SfxAction.saveSuccess);
```

### **8. XP/Badge Earned**

```dart
if (xpEarned) {
  await SfxManager().play(SfxAction.xpGain);
}

if (badgeUnlocked) {
  await SfxManager().play(SfxAction.badgeEarned);
}
```

---

## ⚙️ Add to Settings Screen

**In your settings tab (dashboard.dart or settings screen):**

```dart
import 'package:gravity_app/screens/sfx_settings_screen.dart';

// Add this ListTile
ListTile(
  leading: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFF4FACFE).withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.volume_up, color: Color(0xFF4FACFE)),
  ),
  title: const Text(
    'Sound Effects',
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
  ),
  subtitle: const Text(
    'Customize app sounds',
    style: TextStyle(color: Colors.white54, fontSize: 12),
  ),
  trailing: const Icon(Icons.chevron_right, color: Colors.white24),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SfxSettingsScreen()),
    );
  },
)
```

---

## 🎯 Common Locations to Add SFX

### **Files to Update:**

1. **`lib/screens/daily_quiz_screen.dart`**
   - Answer feedback: `SfxAction.answerCorrect` / `answerWrong`
   - Quiz complete: `SfxAction.levelComplete`

2. **`lib/screens/curriculum_screen.dart`**
   - Quiz feedback: Same as above
   - Lesson complete: `SfxAction.lessonComplete`

3. **`lib/dashboard.dart`**
   - Tab switches: `SfxAction.tabSwitch`
   - Button taps: `SfxAction.buttonTap`
   - Notification bell: `SfxAction.notificationReceived`

4. **`lib/teacher_dashboard.dart`**
   - Same as dashboard

5. **`lib/screens/daily_review_screen.dart`**
   - Answer feedback
   - Task completion

6. **`lib/features/vocabulary/`**
   - Flashcard flip: `SfxAction.flashcardFlip`
   - Correct/wrong answers

7. **`lib/mastery/`**
   - Level unlocks
   - Progress updates

---

## 🔇 Testing Without Sound Files

The system works even without sound files - it just won't play anything. 

**To test the UI:**
```dart
// Settings screen will work
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const SfxSettingsScreen()
));
```

You can adjust volumes, toggle settings, etc. When you add sound files later, they'll work automatically!

---

## 📊 Migration Checklist

- [ ] Add `await SfxManager().init()` to main.dart
- [ ] Add settings screen link
- [ ] Add SFX to quiz answer feedback
- [ ] Add SFX to level completion
- [ ] Add SFX to button taps (key buttons only)
- [ ] Add SFX to tab navigation
- [ ] Add SFX to toggles
- [ ] Add SFX to errors/warnings
- [ ] Test settings screen UI
- [ ] Download sound files (optional, can do later)

---

## 🎨 Sound File Priority

**Add these first for maximum impact:**
1. ✅ `learn/correct_chime.mp3` - Most satisfying
2. ✅ `learn/wrong_soft.mp3` - Important feedback
3. ✅ `progress/level_complete.mp3` - Celebration
4. ✅ `ui/soft_tap.mp3` - General interaction
5. ✅ `error/error_soft.mp3` - Error feedback

**Add later:**
- Other UI sounds
- System sounds
- Minimal variants

---

**Status:** System ready, just needs sound files! ✅

