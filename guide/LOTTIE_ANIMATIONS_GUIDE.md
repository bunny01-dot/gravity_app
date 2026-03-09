# LOTTIE ANIMATIONS GUIDE FOR GRAVITY APP

## 📁 Required Animation Files

All Lottie JSON files must be placed in: `assets/lottie/`

**File Size Limit:** ≤ 150 KB per animation  
**Format:** JSON (vector animations)  
**Performance:** Must run smoothly on low-end devices

---

## 🎯 PART 1 — BOTTOM NAVIGATION ICONS

### Files Needed:

| File Name | Description | Animation Type |
|-----------|-------------|----------------|
| `nav_home_selected.json` | Dashboard icon with soft pulse/glow | Play once on select |
| `nav_tasks_selected.json` | Checklist tick/bounce | Play once on select |
| `nav_mastery_selected.json` | Gentle loop/rotate | Play once on select |
| `nav_settings_selected.json` | Slow gear turn | Play once on select |

**Animation Duration:** 400-600ms  
**Behavior:** Play ONCE when tab becomes selected, then freeze at end frame

---

## 🏠 PART 2 — DASHBOARD PAGE

### Files Needed:

| File Name | Description | Trigger |
|-----------|-------------|---------|
| `sparkle_welcome.json` | Subtle sparkle/wave behind "Welcome Back!" | First page load |
| `fire_streak.json` | Fire flicker for streak badge | On load, or when streak increases |
| `progress_fill.json` | Progress bar fill animation | When progress value changes |

**Behavior:**
- Welcome sparkle: Play once on mount, optional
- Fire: Play once per session OR when streak changes
- Progress: Animate fill only when value increases

---

## ✅ PART 3 — DAILY TASKS PAGE

### Files Needed:

| File Name | Description | Trigger |
|-----------|-------------|---------|
| `check_success.json` | Checkmark animation when task completes | Task completion |
| `progress_ring.json` | Circular progress animation | Progress % increases |

**Animation Pattern:**
```dart
// Example for completed task icon
if (isDone) {
  return Lottie.asset(
    'assets/lottie/check_success.json',
    repeat: false,
    width: 40,
    height: 40,
  );
} else {
  return Icon(taskIcon, size: 40); // Static
}
```

**Behavior:**
- Check animation plays ONCE when task becomes complete
- Then freezes at final frame
- Progress ring animates only on value change

---

## 🎮 PART 4 — GAMES UNLOCK MOMENT

### Files Needed:

| File Name | Description | Trigger |
|-----------|-------------|---------|
| `lock_unlock.json` | Lock → unlock transformation | All daily tasks completed |
| `confetti_subtle.json` | Small confetti burst | Games unlock moment |

**Behavior:**
- **Critical:** Play ONCE per day when games unlock
- Must not replay on screen rebuild
- Store state: `games_unlock_animation_played_YYYY-MM-DD`

**Animation Duration:** 1-1.5 seconds max

---

## 🕹️ PART 5 — GAMES HUB CARD

### Files Needed:

| File Name | Description | Trigger |
|-----------|-------------|---------|
| `games_hub_unlock.json` | Lock fading out, card lifting | First unlock of the day |

**Behavior:**
- Locked state: Static lock icon (NO animation)
- On first daily unlock: Play lock-to-unlock animation ONCE
- Store flag: `games_hub_unlocked_YYYY-MM-DD`

---

## 📚 PART 6 — MASTERY PAGE

### Files Needed:

| File Name | Description | Trigger |
|-----------|-------------|---------|
| `mastery_intro_reading.json` | Book opening | First visit |
| `mastery_intro_listening.json` | Headphones pulse | First visit |
| `mastery_intro_speaking.json` | Microphone wave | First visit |
| `mastery_intro_writing.json` | Pen writing | First visit |
| `mastery_tap_feedback.json` | Scale/glow on tap | User tap |

**Behavior:**
- Intro animations: Play ONCE on first page visit
- Store flag: `mastery_intro_seen`
- Tap feedback: Very subtle, 200-300ms

---

## ⚙️ PART 7 — SETTINGS PAGE (MINIMAL)

### Files Needed:

| File Name | Description | Trigger |
|-----------|-------------|---------|
| `settings_tap_feedback.json` | Ultra-subtle scale | On option tap |

**Behavior:**
- **NO idle animations**
- Only micro-feedback on tap
- Must feel calm, not playful

---

## 🎓 PART 8 — TUTORIAL/ONBOARDING

### Files Needed:

| File Name | Description | Use |
|-----------|-------------|-----|
| `onboarding_welcome.json` | Gentle dashboard preview | Onboarding screen 1 |
| `onboarding_tasks.json` | Checklist filling | Onboarding screen 2 |
| `onboarding_games_unlock.json` | Lock → unlock | Onboarding screen 3 |
| `coachmark_arrow.json` | Pointing arrow | Contextual hints |
| `coachmark_pulse_ring.json` | Pulsing circle around target | Hint emphasis |

**Behavior:**
- Onboarding animations: Play in loop during onboarding screens
- Coach marks: Gentle loop, can repeat
- Must not block UI interaction

---

## 🔧 IMPLEMENTATION RULES

### 1. Controller Management

```dart
late final AnimationController _animationController;

@override
void initState() {
  super.initState();
  _animationController = AnimationController(vsync: this);
}

@override
void dispose() {
  _animationController.dispose();
  super.dispose();
}
```

### 2. Play Once Pattern

```dart
Lottie.asset(
  'assets/lottie/animation.json',
  controller: _animationController,
  onLoaded: (composition) {
    _animationController.duration = composition.duration;
    _animationController.forward(); // Play once
  },
)
```

### 3. Conditional Animation

```dart
// Only animate on state change
if (shouldAnimate) {
  Lottie.asset(
    'assets/lottie/animation.json',
    repeat: false,
    animate: true,
  );
} else {
  // Show static icon
  Icon(Icons.example);
}
```

### 4. Accessibility Support

```dart
import 'package:flutter/foundation.dart';

bool get _reduceMotion {
  return MediaQuery.of(context).disableAnimations;
}

Widget _buildAnimatedIcon() {
  if (_reduceMotion) {
    return Icon(Icons.static_icon); // No animation
  }
  return Lottie.asset('assets/lottie/animation.json');
}
```

---

## 📊 PERFORMANCE CHECKLIST

✅ Animations only play on state change, not constantly  
✅ Controllers properly disposed  
✅ File sizes ≤ 150 KB  
✅ Fallback to static icons if Lottie fails to load  
✅ Respects accessibility "reduce motion"  
✅ No animations in release mode if performance is poor  

---

## 🎨 RECOMMENDED LOTTIE SOURCES

**Free Resources:**
- LottieFiles.com (search for "minimal", "subtle", "micro-interaction")
- IconScout Lottie
- Rive.app (can export to Lottie)

**Search Keywords:**
- "minimal check"
- "subtle pulse"
- "lock unlock"
- "fire flicker"
- "progress fill"
- "confetti small"

**Design Tips:**
- Choose monochrome or 2-color animations
- Avoid overly complex/busy animations
- Test on low-end devices
- Prefer < 60 frames for smooth playback

---

## 🚫 WHAT NOT TO DO

❌ Infinite fast loops  
❌ Animations triggering on every `setState`  
❌ Large file sizes (> 150 KB)  
❌ Complex 3D/particle effects  
❌ Animations that don't reinforce meaning  
❌ Distracting motion during learning tasks  

---

## ✅ IMPLEMENTATION STATUS

Once Lottie files are added to `assets/lottie/`, the app will:
1. Automatically detect and use them
2. Fall back to static icons if files are missing
3. Respect performance and accessibility settings
4. Provide delightful micro-interactions without distraction

**Next Steps:**
1. Download/create Lottie JSON files (use guide above)
2. Place in `assets/lottie/` directory
3. Run `flutter pub get`
4. Test on physical device
5. Adjust animation speeds if needed
