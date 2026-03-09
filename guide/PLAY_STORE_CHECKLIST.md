# Gravity App - Play Store Assets Checklist

## 📱 Required Graphics

### 1. App Icon (High Res)
- **Size:** 512 x 512 px
- **Format:** PNG (32-bit)
- **Location:** `assets/images/app_logo.png` ✅ (Already exists)
- **Action:** Verify it's 512x512, if not, upscale it

### 2. Feature Graphic
- **Size:** 1024 x 500 px
- **Format:** PNG or JPG
- **Purpose:** Top banner on Play Store listing
- **Suggestion:** Create using Canva or Figma
  - Background: Dark gradient (#6C63FF to #02AABD)
  - Text: "Master English with Gravity App"
  - Include app icon and mockup

### 3. Screenshots (Minimum 2, Recommended 4-8)
- **Phone:** 1080 x 2400 px (9:16 aspect ratio)
- **Tablet (optional):** 1200 x 1920 px
- **Required screens:**
  1. Login/Splash Screen
  2. Dashboard/Home
  3. Mastery/Learning Module
  4. Progress/Profile

**How to capture:**
```bash
# Run app on emulator or device
flutter run --release
# Use Android Studio > Logcat > Camera icon to capture
```

---

## 📝 Store Listing Copy

### Short Description (80 chars max)
```
Master English: Vocabulary, Grammar, Reading, Speaking & Writing
```

### Full Description (4000 chars max)
```
🚀 Transform Your English Learning Journey

Gravity App is your complete English learning companion designed for students and professionals who want to master the English language effectively.

📚 COMPREHENSIVE LEARNING MODULES

• Vocabulary Building - Daily words with meanings, examples, and pronunciation
• Grammar Mastery - Interactive grammar exercises and verb forms
• Reading Comprehension - Engaging passages with comprehension tests
• Writing Practice - Structured writing exercises with feedback
• Speaking Practice - Pronunciation guides and dictation exercises
• Listening Skills - Audio-based learning activities

🎯 KEY FEATURES

✓ Personalized Learning Path - Progress tracking tailored to your level
✓ Daily Practice - Get daily words, quizzes, and reminders
✓ Offline Access - Learn anytime, anywhere without internet
✓ Progress Sync - Cloud backup keeps your progress safe
✓ Teacher Dashboard - For educators managing classrooms
✓ Gamified Learning - Earn achievements and track milestones

🏆 WHAT MAKES US DIFFERENT

• Curriculum-based learning aligned with educational standards
• Interactive games: Word Builder, Synonym Swap, Antonym Attack
• Real-time notifications for announcements and updates
• Beautiful, intuitive dark-mode interface
• Completely FREE with no ads

👥 PERFECT FOR

✓ Students preparing for competitive exams
✓ Professionals improving communication skills
✓ Teachers managing classrooms
✓ Anyone wanting to improve their English

📊 TRACK YOUR PROGRESS

Monitor your learning journey with detailed analytics:
- Daily streak tracking
- Quiz performance metrics
- Module completion progress
- Mastery level indicators

🔒 PRIVACY & SECURITY

Your data is protected with Firebase security. We never share your personal information.

📞 SUPPORT

Need help? Contact us at: support@gravityapp.example.com

⭐ Join thousands of learners improving their English daily!

Download Gravity App now and start your English mastery journey today!
```

---

## 🔐 Privacy & Compliance

### Privacy Policy URL
**URL:** https://bunny01-dot.github.io/gravity-privacy-policy/privacy_policy.html ✅ **LIVE**
**File:** `privacy_policy.html` ✅ Created & Hosted

> Use this URL when uploading to Play Store Console


---

## 🏷️ App Categorization

- **Category:** Education
- **Tags:** English Learning, Vocabulary, Grammar, Education, Language
- **Content Rating:** Everyone (or Teen if app has user-generated content)
- **Target Audience:** Ages 13+

---

## ✅ Pre-Submission Checklist

- [ ] App signed with production keystore (not debug)
- [ ] Version code incremented in `pubspec.yaml`
- [ ] All Firebase indexes created
- [ ] Privacy policy URL live and accessible
- [ ] App tested on multiple devices (phone + tablet)
- [ ] All permissions justified in manifest
- [ ] Feature graphic created (1024x500)
- [ ] Minimum 2 screenshots captured
- [ ] Store listing description written
- [ ] Contact email set up
- [ ] App bundle built: `flutter build appbundle --release`

---

## 🚀 Build Commands

### For Testing (APK)
```bash
flutter build apk --release
```

### For Play Store (App Bundle)
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

---

## 📧 Contact & Support

Set up a dedicated email for:
- User support requests
- Privacy/data deletion requests
- App feedback

**Suggested:** `support@bfsbc.edu.in` or `gravityapp@outlook.com`

---

## 🎨 Asset Creation Tools

- **Canva** - Feature graphics and promotional images
- **Figma** - UI mockups and screenshots
- **Remove.bg** - Remove backgrounds from screenshots
- **Photopea** - Free online Photoshop alternative
