# MIGRATION TEMPLATE: Active & Passive Voice Lesson

## Purpose
This document serves as the **EXACT TEMPLATE** for migrating old card-based lessons to Storybook UI V2.

---

## COMPLETE CODE STRUCTURE

### 1. IMPORTS (Required)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
```

**DO NOT IMPORT:**
- ❌ `lesson_speaking_card.dart` (not needed in V2)

---

### 2. DATA MODELS

```dart
abstract class LessonUnit {}

class LessonSlide extends LessonUnit {
  final String title;
  final String content;
  final String imagePath;
  final String? soundPath;
  final String hindiContent;
  final String tamilContent;
  final String? formula;
  final BoxFit? imageFit;

  LessonSlide({
    required this.title,
    required this.content,
    required this.imagePath,
    this.soundPath,
    this.hindiContent = "",
    this.tamilContent = "",
    this.formula,
    this.imageFit,
  });
}

class LessonQuizInteraction extends LessonUnit {
  final String title;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String imagePath;
  final BoxFit? imageFit;

  LessonQuizInteraction({
    required this.title,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.imagePath,
    this.imageFit,
  });
}

class LessonSpeakingPractice extends LessonUnit {
  final String title;
  final String? micIconPath;
  final String imagePath;
  final List<String> prompts;
  final List<String> summaryPoints;
  final BoxFit? imageFit;

  LessonSpeakingPractice({
    required this.title,
    this.micIconPath,
    required this.imagePath,
    required this.prompts,
    required this.summaryPoints,
    this.imageFit,
  });
}
```

---

### 3. STATE VARIABLES (EXACT ORDER)

```dart
class _LessonXXXScreenState extends State<LessonXXXScreen>
    with SingleTickerProviderStateMixin {
  
  // NAVIGATION & PAGE CONTROL
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isLoading = true;
  late List<LessonUnit> _slides;

  // VIEW STATE
  bool _showTranslation = false;
  String _preferredLanguage = 'Tamil';

  // INLINE QUIZ STATE (for quizzes within story)
  int? _selectedQuizIndex;
  bool _isQuizCorrect = false;
  bool _showQuizFeedback = false;

  // FINAL QUIZ STATE (mastery quiz)
  bool _storyComplete = false;
  bool _showFinalQuiz = false;
  int _finalQuizIndex = 0;
  int _finalQuizScore = 0;
  int? _selectedFinalQuizOption;
  bool _showFinalQuizFeedback = false;
  bool _lessonCompleted = false;

  // ANIMATION
  late AnimationController _progressController;

  // DATA
  final String _assetPath = 'assets/Lessons/Lesson_XX_Name/';
  
  // FINAL QUIZ QUESTIONS (6 questions minimum)
  final List<Map<String, dynamic>> _finalQuizQuestions = [
    // ... questions
  ];
```

---

### 4. LIFECYCLE METHODS

```dart
@override
void initState() {
  super.initState();
  _initializeContent();
  _loadProgress();
  _progressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
}

@override
void dispose() {
  _pageController.dispose();
  _progressController.dispose();
  super.dispose();
}
```

---

### 5. CONTENT INITIALIZATION

```dart
void _initializeContent() {
  final String assetPath = 'assets/Lessons/Lesson_XX_Name/';

  _slides = [
    // Slide 1: Hook (REQUIRED)
    LessonSlide(
      title: "Hook Title",
      content: "Engaging opening question or scenario",
      imagePath: "${assetPath}hook_square.png",
      tamilContent: "தமிழ் மொழிபெயர்ப்பு",
      hindiContent: "हिंदी अनुवाद",
    ),

    // Slide 2-8: Teaching Content
    // Mix of LessonSlide, LessonQuizInteraction

    // Slide 9: Summary/Chart
    
    // Slide 10: Speaking Practice (REQUIRED)
    LessonSpeakingPractice(
      title: "Speaking Practice",
      imagePath: "${assetPath}chart_square.png",
      prompts: ["Example 1", "Example 2"],
      summaryPoints: ["Key point 1", "Key point 2"],
    ),
  ];
}
```

---

### 6. PROGRESS LOADING

```dart
Future<void> _loadProgress() async {
  final prefs = await SharedPreferences.getInstance();
  final lang = prefs.getString('preferred_language') ?? 'Tamil';
  if (mounted) {
    setState(() {
      _preferredLanguage = lang;
      _isLoading = false;
    });
  }
}
```

---

### 7. COMPLETION LOGIC

```dart
Future<void> _completeLesson() async {
  SoundService().playCompletion();

  // Save locally
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('lesson_xx_name_completed', true);

  // Save to Firestore
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lessons')
        .doc('lesson_xx_name')
        .set({
      'completed': true,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
```

---

### 8. BUILD METHOD (EXACT STRUCTURE)

```dart
@override
Widget build(BuildContext context) {
  if (_isLoading) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      ),
    );
  }

  // Story complete screen
  if (_storyComplete) {
    return _buildStoryCompleteScreen();
  }

  // Final quiz
  if (_showFinalQuiz) {
    return _buildFinalQuizPage();
  }

  // Completion page
  if (_lessonCompleted) {
    return _buildCompletionPage();
  }

  // Normal slides
  final progress = (_currentIndex + 1) / _slides.length;

  return Scaffold(
    backgroundColor: const Color(0xFF0F172A),
    body: SafeArea(
      child: Column(
        children: [
          _buildHeader(progress),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _selectedQuizIndex = null;
                  _isQuizCorrect = false;
                  _showQuizFeedback = false;
                });
                
                if (index == _slides.length - 1) {
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) {
                      setState(() => _storyComplete = true);
                    }
                  });
                }
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: _buildSlideContent(_slides[index]),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

### 9. HEADER (_buildHeader)

```dart
Widget _buildHeader(double progress) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(
      color: Color(0xFF1E293B),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              "Lesson Name (${_currentIndex + 1}/${_slides.length})",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() => _showTranslation = !_showTranslation);
              },
              icon: Icon(
                _showTranslation ? Icons.translate : Icons.translate_outlined,
                color: Colors.cyanAccent,
                size: 20,
              ),
              label: Text(
                _preferredLanguage == 'Tamil' ? 'தமிழ்' : _preferredLanguage,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            color: Colors.cyanAccent,
            minHeight: 6,
          ),
        ),
      ],
    ),
  );
}
```

---

### 10. STORY COMPLETE SCREEN

```dart
Widget _buildStoryCompleteScreen() {
  return Scaffold(
    backgroundColor: const Color(0xFF0F172A),
    body: SafeArea(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.cyanAccent,
              ).animate().scale(),
              const SizedBox(height: 24),
              const Text(
                "Story Completed!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Take the Mastery Quiz to test your knowledge!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _storyComplete = false;
                      _showFinalQuiz = true;
                    });
                    SoundService().playTap();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Take Mastery Quiz",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _storyComplete = false;
                      _currentIndex = 0;
                    });
                    _pageController.jumpToPage(0);
                    SoundService().playTap();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("Review Story"),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

---

### 11. SLIDE CONTENT ROUTER

```dart
Widget _buildSlideContent(LessonUnit slide) {
  Key key = ValueKey(_currentIndex);
  if (slide is LessonSlide) {
    return _buildStandardSlide(slide, key);
  } else if (slide is LessonQuizInteraction) {
    return _buildQuizSlide(slide, key);
  } else if (slide is LessonSpeakingPractice) {
    return _buildSpeakingSlide(slide, key);
  }
  return const SizedBox.shrink();
}
```

---

### 12. STANDARD SLIDE

```dart
Widget _buildStandardSlide(LessonSlide slide, Key key) {
  return Column(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        flex: 4,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            slide.imagePath,
            fit: slide.imageFit ?? BoxFit.contain,
            errorBuilder: (c, e, s) => const Center(
              child: Icon(Icons.image_not_supported,
                  color: Colors.white24, size: 60),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Expanded(
        flex: 6,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.title,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                slide.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
              if (_showTranslation) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.amberAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    _preferredLanguage == 'Hindi'
                        ? slide.hindiContent
                        : slide.tamilContent,
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ).animate().fadeIn(),
              ],
              if (slide.formula != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent),
                  ),
                  child: Text(
                    "Rule: ${slide.formula}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}
```

---

### 13. QUIZ SLIDE (Inline)

```dart
Widget _buildQuizSlide(LessonQuizInteraction slide, Key key) {
  return Column(
    key: key,
    children: [
      Expanded(
        flex: 3,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Image.asset(
            slide.imagePath,
            fit: slide.imageFit ?? BoxFit.contain,
            errorBuilder: (c, e, s) => const Center(
                child: Icon(Icons.quiz, color: Colors.white24, size: 60)),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        slide.title,
        style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 22,
            fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      Text(
        slide.question,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 20),
      ...List.generate(slide.options.length, (index) {
        final isSelected = _selectedQuizIndex == index;
        final isCorrect = index == slide.correctIndex;
        Color bgColor = Colors.white10;
        Color borderColor = Colors.white24;

        if (_showQuizFeedback) {
          if (isCorrect) {
            bgColor = Colors.greenAccent.withOpacity(0.2);
            borderColor = Colors.greenAccent;
          } else if (isSelected && !isCorrect) {
            bgColor = Colors.redAccent.withOpacity(0.2);
            borderColor = Colors.redAccent;
          }
        } else if (isSelected) {
          bgColor = Colors.cyanAccent.withOpacity(0.2);
          borderColor = Colors.cyanAccent;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: _showQuizFeedback
                ? null
                : () {
                    setState(() {
                      _selectedQuizIndex = index;
                      _showQuizFeedback = true;
                      _isQuizCorrect = (index == slide.correctIndex);
                      if (_isQuizCorrect) {
                        SoundService().playCorrect();
                      } else {
                        SoundService().playWrong();
                      }
                    });
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      color: borderColor == Colors.white24
                          ? Colors.white54
                          : borderColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      slide.options[index],
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16),
                    ),
                  ),
                  if (_showQuizFeedback && isCorrect)
                    const Icon(Icons.check_circle, color: Colors.greenAccent),
                  if (_showQuizFeedback && isSelected && !isCorrect)
                    const Icon(Icons.cancel, color: Colors.redAccent),
                ],
              ),
            ),
          ),
        );
      }),
      if (_showQuizFeedback)
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isQuizCorrect
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _isQuizCorrect
                ? "Correct! ${slide.explanation}"
                : "Incorrect. ${slide.explanation}",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isQuizCorrect ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ).animate().fadeIn(),
    ],
  );
}
```

---

### 14. SPEAKING PRACTICE SLIDE

```dart
Widget _buildSpeakingSlide(LessonSpeakingPractice slide, Key key) {
  return SingleChildScrollView(
    key: key,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Image.asset(
            slide.imagePath,
            fit: slide.imageFit ?? BoxFit.contain,
            errorBuilder: (c, e, s) => const Center(
              child: Icon(
                Icons.image_not_supported,
                color: Colors.white24,
                size: 60,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          slide.title,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Practice Speaking:",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...slide.prompts.map((prompt) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.cyanAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prompt,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Key Points:",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...slide.summaryPoints.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rate_rounded,
                        size: 16,
                        color: Colors.amberAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}
```

---

### 15. FINAL QUIZ PAGE (See ARTICLE_LESSON_REFERENCE.md for full code)
### 16. COMPLETION PAGE (See ARTICLE_LESSON_REFERENCE.md for full code)

---

## MIGRATION CHECKLIST

For EACH old lesson, follow these steps IN ORDER:

### Step 1: Backup
- [ ] Create backup of original file

### Step 2: Update Imports
- [ ] Remove old imports (LessonContent, etc.)
- [ ] Add required imports (see section 1)

### Step 3: Replace Data Models
- [ ] Replace `LessonContent` with `LessonSlide`
- [ ] Add `LessonQuizInteraction` if inline quizzes exist
- [ ] Add `Lesson SpeakingPractice` for final slide

### Step 4: Update State Variables
- [ ] Copy exact state structure from section 3
- [ ] Update `_assetPath` to match lesson
- [ ] Update `_finalQuizQuestions` with lesson-specific questions

### Step 5: Rewrite _initializeContent()
- [ ] Convert old content to `LessonSlide` objects
- [ ] Ensure 10 total slides (minimum)
- [ ] Last slide MUST be `LessonSpeakingPractice`
- [ ] Add Tamil/Hindi translations

### Step 6: Replace build() Method
- [ ] Copy exact build structure from section 8
- [ ] Update lesson name in header

### Step 7: Add Missing Methods
- [ ] `_buildStoryCompleteScreen()` (section 10)
- [ ] `_buildHeader()` (section 9)
- [ ] `_buildSlideContent()` (section 11)
- [ ] `_buildStandardSlide()` (section 12)
- [ ] `_buildQuizSlide()` (section 13)
- [ ] `_buildSpeakingSlide()` (section 14)
- [ ] `_buildFinalQuizPage()` (from articles reference)
- [ ] `_buildCompletionPage()` (from articles reference)

### Step 8: Update _completeLesson()
- [ ] Change keys to match lesson name
- [ ] Update Firestore document path

### Step 9: Test
- [ ] Run flutter analyze
- [ ] Test all 4 phases
- [ ] Verify swipe navigation
- [ ] Check translation toggle
- [ ] Confirm Firebase save

### Step 10: Mark Complete
- [ ] Update TODO.md
- [ ] Commit changes

---

## STRICT RULES

1. **NEVER** skip the Story Complete Screen
2. **ALWAYS** use PageView (no manual scroll)
3. **ALWAYS** include 6+ quiz questions
4. **ALWAYS** provide Tamil and Hindi translations
5. **ALWAYS** use native language names (தமிழ் not "Tamil")
6. **NEVER** use navigation buttons (gesture only)
7. **ALWAYS** save to both SharedPreferences AND Firestore
8. **ALWAYS** use 60% pass threshold
9. **ALWAYS** dispose PageController
10. **ALWAYS** test before marking complete

---

This template is LAW. Follow it exactly for every migration.
