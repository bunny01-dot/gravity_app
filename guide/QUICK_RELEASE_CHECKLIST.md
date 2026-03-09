# 🚀 PLAY STORE RELEASE - QUICK ACTION CHECKLIST

**CRITICAL:** Complete ALL items before submission

---

## ✅ IMMEDIATE ACTIONS (DO NOW)

### **1. Verify Games Use Safe Content (2-4 hours)**

```bash
# Run this command to check each game:
grep -l "SafeGameContentProvider" lib/screens/games/*.dart
grep -l "InsufficientContentException" lib/screens/games/*.dart

# For each game file, verify it has:
# ✅ SafeGameContentProvider import
# ✅ getEligibleVocabulary() or getEligibleVerbs() call
# ✅ InsufficientContentException catch block
# ✅ Insufficient content UI
# ❌ NO static CSV data
# ❌ NO hardcoded word lists
```

**Games to Check:**
- [ ] Word Builder (**✅ ALREADY VERIFIED SAFE**)
- [ ] Synonym Swap
- [ ] Antonym Attack
- [ ] Word Match
- [ ] Picture Guess
- [ ] Word Search
- [ ] Fill the Gap
- [ ] Speed Vocabulary
- [ ] Hangman
- [ ] Typing Defense
- [ ] Flashcard Flip
- [ ] Grammar Choice
- [ ] Sentence Scramble
- [ ] Tense Trainer
- [ ] Error Hunt

---

### **2. Fix LoremFlickr (5 minutes - Option A)**

**File:** `lib/widgets/games_hub_card.dart`

**Quick Fix:**
```dart
// Find the line that creates Picture Guess card
// Comment it out:
// _buildGameCard('Picture Guess', Icons.image, () => PictureGuessScreen()),

// OR add above it:
// TODO: Re-enable after adding local image assets
```

✅ DONE when: Picture Guess no longer appears in games hub

---

### **3. Physical Device Testing (2-4 hours) - CRITICAL**

```bash
# Build release APK
flutter build apk --release

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk

# OR use:
flutter run --release
```

**Test Checklist:**
- [ ] App launches without crash
- [ ] Onboarding works
- [ ] Daily Tasks complete correctly
- [ ] Games unlock after tasks
- [ ] Play at least 3 different games
- [ ] Test locked games message
- [ ] Minimize → Resume (NO crash)
- [ ] Rotate screen (NO crash)
- [ ] Back button navigation
- [ ] Audio playback works

**Device Info:**
- Model: _________________________
- Android: _______________________
- Result: [ ] ✅ PASS [ ] ❌ FAIL

---

### **4. CSV Content Review (1-2 hours)**

**Files to Check:**
```bash
# Find CSV files:
find assets/data -name "*.csv"

# Review each for:
# ✅ No offensive words
# ✅ Spelling correct
# ✅ Age-appropriate
# ✅ No placeholder text
```

- [ ] Vocabulary CSV reviewed
- [ ] Verbs CSV reviewed
- [ ] Reading CSV reviewed
- [ ] Audio references valid
- [ ] Image references valid

---

## 🏁 FINAL BUILD (After ALL Above Complete)

### **Step 1: Set Version**

**File:** `pubspec.yaml`

```yaml
version: 1.0.0+1  # Update this
```

---

### **Step 2: Build Release**

```bash
# For Play Store (AAB - preferred):
flutter build appbundle --release

# For direct APK:
flutter build apk --release
```

---

### **Step 3: Sign Build**

```bash
# Ensure you have keystore configured in:
# android/key.properties

# Build will automatically sign if configured
```

---

### **Step 4: Verify AppConfig**

**File:** `lib/config/app_config.dart`

```dart
class AppConfig {
  static const bool isProduction = true;  // ✅ MUST BE TRUE
  // ...
}
```

---

## ✅ RELEASE CONFIRMATION

**Sign this ONLY when ALL items above are complete:**

```
RELEASE READINESS CONFIRMATION

I confirm that:

✅ All 15 games verified to use SafeGameContentProvider
✅ LoremFlickr removed/disabled
✅ Device tested on: _____________________ (model)
✅ Android version: _____________________ 
✅ NO crashes observed
✅ CSV content reviewed and appropriate
✅ Version set: _____________________
✅ Built in RELEASE mode
✅ AppConfig.isProduction = true

The app is SAFE and READY for Play Store.

Signed: _________________________
Date: ___________________________
```

---

## 🚨 BLOCKER RESOLUTION STATUS

| Blocker | Status |
|---------|--------|
| Games use unlearned content | ⚠️ Verify all 15 games |
| No device testing | ❌ TEST NOW |
| LoremFlickr copyright risk | ❌ FIX NOW |
| CSV content not reviewed | ❌ REVIEW NOW |

**Current:** 70% Complete  
**Target:** 100% Complete  
**ETA:** 6-13 hours of work

---

## 📞 QUICK HELP

**If game doesn't use SafeGameContentProvider:**
→ See `BLOCKER_FIX_GUIDE.md` for implementation pattern

**If device crashes:**
→ Get stack trace: `adb logcat`
→ Fix issue before proceeding

**If unsure:**
→ Review `BLOCKER_FIX_STATUS.md` for complete details

---

**Last Updated:** 2026-01-06  
**Status:** ACTION REQUIRED  
**Priority:** CRITICAL
