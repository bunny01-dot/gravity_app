# 🎧 SFX System - Quick Start Guide

## ⚡ 30-Second Integration

### 1. Add Dependency (if not present)

```yaml
# pubspec.yaml
dependencies:
  audioplayers: ^6.0.0
```

### 2. Initialize in main.dart

```dart
import 'package:gravity_app/services/sfx/sfx_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Add this line
  await SfxManager().init();
  
  runApp(const MyApp());
}
```

### 3. Use Anywhere in Your App

```dart
import 'package:gravity_app/services/sfx/sfx_manager.dart';
import 'package:gravity_app/services/sfx/sfx_models.dart';

// Button tap
SfxManager().play(SfxAction.buttonTap);

// Quiz feedback
SfxManager().play(SfxAction.answerCorrect); // or answerWrong

// Level complete
SfxManager().play(SfxAction.levelComplete);

// Error
SfxManager().play(SfxAction.validationError);
```

---

## 🎯 Most Common Actions

| Use Case | Action |
|----------|--------|
| Button clicked | `SfxAction.buttonTap` |
| Correct answer | `SfxAction.answerCorrect` |
| Wrong answer | `SfxAction.answerWrong` |
| Level finished | `SfxAction.levelComplete` |
| Tab changed | `SfxAction.tabSwitch` |
| Toggle on/off | `SfxAction.toggleOn` / `toggleOff` |
| Screen opened | `SfxAction.screenOpen` |
| Error occurred | `SfxAction.validationError` |
| Badge earned | `SfxAction.badgeEarned` |
| Save success | `SfxAction.saveSuccess` |

---

## 📁 Before Sounds Work - Add Temporary Placeholder

Until you get actual sound files, the system will work but be silent.

**Priority sound files to add first:**
1. `assets/sfx/ui/soft_tap.mp3` - For button taps
2. `assets/sfx/learn/correct_chime.mp3` - For correct answers
3. `assets/sfx/learn/wrong_soft.mp3` - For wrong answers
4. `assets/sfx/progress/level_complete.mp3` - For completions

**Download free sounds from:**
- https://www.zapsplat.com/ (UI Sounds section)
- https://pixabay.com/sound-effects/search/button%20click/

---

## ⚙️ Add Settings Access

In your settings screen, add:

```dart
ListTile(
  leading: const Icon(Icons.volume_up, color: Color(0xFF4FACFE)),
  title: const Text('Sound Effects'),
  subtitle: const Text('Customize app sounds'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SfxSettingsScreen(),
      ),
    );
  },
)
```

---

## 🔇 Quick Disable for Testing

```dart
// Temporarily disable all sounds
await SfxManager().setEnabled(false);

// Re-enable
await SfxManager().setEnabled(true);
```

---

## 📊 What You Get

✅ 60+ action types defined
✅ User-configurable sound mappings
✅ Master volume control
✅ Category-based volumes
✅ Focus mode (minimal sounds)
✅ Night mode (50% quieter)
✅ Per-action customization UI
✅ Sound preview in settings
✅ Non-blocking playback
✅ Persistent preferences

---

## 🚀 Next Steps

1. **Get Sound Files** - See `ADVANCED_SFX_SYSTEM.md` for sources
2. **Add to Assets** - Create `/assets/sfx/` folder structure
3. **Replace Old Sounds** - Migrate from `SoundService` to `SfxManager`
4. **Test** - Run app and verify sounds play
5. **Customize** - Let users configure in settings

---

**Full Documentation:** `ADVANCED_SFX_SYSTEM.md`

**Files Created:**
- `lib/services/sfx/sfx_models.dart`
- `lib/services/sfx/sfx_library.dart`
- `lib/services/sfx/sfx_manager.dart`
- `lib/screens/sfx_settings_screen.dart`

**Ready to Use:** Yes ✅ (once sound files are added)

