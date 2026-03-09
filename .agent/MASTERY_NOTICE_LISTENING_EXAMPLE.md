# 🎤 Example: Listening Screen Integration

## Full Integration Example

Here's how to add mastery notices to the Listening Screen with highlighting:

```dart
import 'package:flutter/material.dart';
import 'package:gravity_app/widgets/mastery_notice_overlay.dart'; // ← Add this import
// ... other imports

class _ListeningScreenState extends State<ListeningScreen> {
  // ... existing fields
  
  // ✅ ADD: GlobalKeys for highlight targets
  final GlobalKey _speedSliderKey = GlobalKey();
  final GlobalKey _hintButtonKey = GlobalKey();
  final GlobalKey _playButtonKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVoices();
    
    // ✅ ADD: Check and show first-time notices
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowWelcomeNotice();
    });
  }
  
  // ✅ ADD: Welcome notice for first-time users
  Future<void> _checkAndShowWelcomeNotice() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('seen_listening_welcome') ?? false;
    
    if (!hasSeenWelcome && mounted) {
      // Wait for dialog to be visible
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        await showMasteryNotice(
          context,
          title: 'Welcome to Listening Mastery!',
          message: 'Listen to the audio conversation and type what you hear. Use the controls below to adjust speed.',
          icon: Icons.headphones_rounded,
          highlightTargetKey: _playButtonKey, // Points to play button
          accentColor: const Color(0xFFFE5196),
          buttonText: 'Got It',
          onDismiss: () async {
            await prefs.setBool('seen_listening_welcome', true);
          },
        );
        
        // After 2 seconds, show speed control notice
        await Future.delayed(const Duration(milliseconds: 2000));
        
        if (mounted) {
          await showMasteryNotice(
            context,
            title: 'Speed Control',
            message: 'Adjust playback speed here. Beginners should start at 0.5x for clearer pronunciation!',
            icon: Icons.speed_rounded,
            highlightTargetKey: _speedSliderKey, // Points to speed slider
            accentColor: const Color(0xFF4FACFE),
            buttonText: 'Thanks!',
          );
        }
      }
    }
  }
  
  Widget _buildListeningCard(...) {
    // ... existing code
    
    return Container(
      child: Column(
        children: [
          // ... header code
          
          // ✅ MODIFY: Add key to play button
          GestureDetector(
            key: _playButtonKey, // ← Add this key
            onTap: () => _playTts(exercise, index, dialogSetState: setDialogState),
            child: Container(
              // ... existing play button UI
            ),
          ),
          
          const SizedBox(height: 24),
          
          // ✅ MODIFY: Add key to speed slider
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.white54, size: 20),
              Expanded(
                child: Slider(
                  key: _speedSliderKey, // ← Add this key
                  value: _speechRate,
                  onChanged: (val) async {
                    // ... existing code
                  },
                ),
              ),
            ],
          ),
          
          // ... question and answer fields
          
          // ✅ MODIFY: Add key to hint button
          Row(
            children: [
              TextButton.icon(
                key: _hintButtonKey, // ← Add this key
                onPressed: () {
                  // ... existing hint logic
                },
                icon: const Icon(Icons.lightbulb_outline, size: 18),
                label: const Text("Hint"),
              ),
              
              FilledButton(
                onPressed: () async {
                  // ✅ ADD: Show hint notice after 2 wrong attempts
                  if (!_isAnswerCorrect(userText, correct)) {
                    _wrongAttempts++;
                    
                    if (_wrongAttempts == 2) {
                      await showMasteryNotice(
                        context,
                        title: 'Need a Hint?',
                        message: 'Tap the Hint button to see the first 3 words of the answer!',
                        icon: Icons.lightbulb_outline_rounded,
                        highlightTargetKey: _hintButtonKey,
                        accentColor: const Color(0xFFFFD700),
                        backgroundEffect: BackgroundEffect.blur,
                      );
                    }
                    
                    // ... show error snackbar
                  } else {
                    // ✅ ADD: Celebration notice on completion
                    await _dataService.saveMasteryProgress('listening', id);
                    
                    await showMasteryNotice(
                      context,
                      title: 'Perfect!',
                      message: 'Great job! You\'ve completed this listening exercise.',
                      customContent: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFE5196).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Progress saved automatically',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      icon: Icons.celebration_rounded,
                      buttonText: 'Next Mission',
                      backgroundEffect: BackgroundEffect.darken,
                    );
                    
                    // ... existing success logic
                  }
                },
                child: const Text("Check Answer"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## Visual Flow Example

### 1. Welcome Notice (First Open)
```
┌─────────────────────────────┐
│  Background: BLURRED        │
│                             │
│  ┌─────────────┐           │
│  │ Play Button │ ← Glowing │
│  └─────────────┘   Ring    │
│                             │
│  ╔═══════════════════╗     │
│  ║ 🎧 Welcome!       ║      │
│  ║                   ║      │
│  ║ Listen to audio   ║      │
│  ║ and type what     ║      │
│  ║ you hear...       ║      │
│  ║                   ║      │
│  ║   [Got It]        ║      │
│  ╚═══════════════════╝      │
└─────────────────────────────┘
```

### 2. Speed Control Notice (After Welcome)
```
┌─────────────────────────────┐
│  Background: BLURRED        │
│                             │
│  Speed: 0.5x                │
│  ┌───────────────┐          │
│  │●─────────────○│ ← Glowing│
│  └───────────────┘   Ring   │
│                             │
│  ╔═══════════════════╗     │
│  ║ 🏃 Speed Control   ║      │
│  ║                   ║      │
│  ║ Adjust speed here.║      │
│  ║ Start at 0.5x!    ║      │
│  ║                   ║      │
│  ║   [Thanks!]       ║      │
│  ╚═══════════════════╝      │
└─────────────────────────────┘
```

### 3. Hint Notice (After 2 Wrong Attempts)
```
┌─────────────────────────────┐
│  Background: DARKENED       │
│                             │
│  [💡 Hint]  ← Glowing       │
│            Ring             │
│                             │
│  ╔═══════════════════╗     │
│  ║ 💡 Need a Hint?    ║      │
│  ║                   ║      │
│  ║ Tap Hint to see   ║      │
│  ║ first 3 words!    ║      │
│  ║                   ║      │
│  ║   [Got It]        ║      │
│  ╚═══════════════════╝      │
└─────────────────────────────┘
```

---

## Tracking User Seen Status

```dart
// SharedPreferences keys for notices
const String KEY_SEEN_LISTENING_WELCOME = 'seen_listening_welcome';
const String KEY_SEEN_SPEED_NOTICE = 'seen_speed_notice';
const String KEY_SEEN_HINT_NOTICE = 'seen_hint_notice';

// Helper to check if notice should show
Future<bool> shouldShowNotice(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(key) ?? false);
}

// Helper to mark notice as seen
Future<void> markNoticeSeen(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, true);
}

// Usage
if (await shouldShowNotice(KEY_SEEN_LISTENING_WELCOME)) {
  await showMasteryNotice(...);
  await markNoticeSeen(KEY_SEEN_LISTENING_WELCOME);
}
```

---

## 🎯 Complete Feature Set

### Notice Triggers:

1. **On First Open** → Welcome + Speed Control
2. **After 2 Wrong Attempts** → Hint Guidance
3. **On Level Complete** → Celebration + Next Level Unlock
4. **On Feature Unlock** → New Feature Introduction
5. **On Setting Change** → Setting Explanation

### All With:
- ✅ Background blur/darken
- ✅ Highlight animation on target
- ✅ One-time display (tracked in SharedPreferences)
- ✅ Smooth animations
- ✅ Professional design

---

**Ready to copy-paste into listening_screen.dart!** 🚀
