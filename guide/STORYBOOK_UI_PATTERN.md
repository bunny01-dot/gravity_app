# Storybook Lesson UI Pattern Guide (Latest - Articles Based)

**Reference Implementation**: `lib/screens/lesson_articles_screen.dart`  
**Last Updated**: 2026-01-21  
**Pattern Version**: 3.0 (Latest)

---

## 🎯 Pattern Overview

All storybook lessons (EXCEPT Subjects/Lesson 1) MUST follow this standardized pattern based on the Articles lesson implementation.

### ✅ **Applies To**:
- Simple Present Tense
- Simple Past Tense
- Simple Future Tense
- Present Continuous
- Present Perfect
- Past Continuous
- Past Perfect
- Future Continuous
- Future Perfect
- Modal Verbs
- Sentence Patterns
- Types of Sentences
- Articles
- Question Types
- Irregular Verbs
- Reported Questions
- All other grammar/lesson storybooks

### ❌ **Does NOT Apply To**:
- **Subjects (Lesson 1)** - This uses a special SVG-based image storybook pattern

---

## 📋 Core Components (Mandatory)

### 1. **Data Models**

```dart
abstract class LessonUnit {}

class LessonSlide extends LessonUnit {
  final String title;
  final String content;
  final String imagePath;
  final String? soundPath;
  final String hindiContent;      // ✅ Required for translation
  final String tamilContent;      // ✅ Required for translation
  final String? formula;
  final BoxFit? imageFit;
}

class LessonHighlightInteraction extends LessonUnit {
  final String title;
  final String introText;
  final List<String> highlightItems;
  final String exampleText;
  final String imagePath;
  final String hindiContent;      // ✅ Required
  final String tamilContent;      // ✅ Required
  final BoxFit? imageFit;
}

class LessonQuizInteraction extends LessonUnit {
  final String title;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String imagePath;
  final BoxFit? imageFit;
}

class LessonSpeakingPractice extends LessonUnit {
  final String title;
  final String? micIconPath;
  final String imagePath;
  final List<String> prompts;
  final List<String> summaryPoints;
  final BoxFit? imageFit;
}
```

---

### 2. **State Variables** (Required)

```dart
class _LessonXxxScreenState extends State<LessonXxxScreen> {
  // ✅ Navigation & Paging
  bool _isLoading = true;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // ✅ Phase Management
  bool _showCompletion = false;
  bool _storyCompleted = false;
  bool _showQuiz = false;
  bool _showResults = false;
  bool _isReEntryLanding = false;
  bool _showTutorial = true; // Swipe tutorial for first-time users

  // ✅ Language & Translation (MANDATORY!)
  String _preferredLanguage = 'Tamil'; // Default
  bool _showTranslation = false;

  // ✅ Quiz State
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answerSelected = false;
  int? _selectedOptionIndex;
  bool _quizCompleted = false;

  // ✅ Lesson Content
  late List<LessonUnit> _slides;
  
  // ✅ Asset Path (specific to lesson)
  final String _assetPath = 'assets/Lessons/Lesson_XX_YourLesson/';

  // ✅ Quiz Questions (end-of-lesson quiz)
  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'Question text?',
      'options': ['Option 1', 'Option 2', 'Option 3'],
      'correct': 0, // Index of correct answer
    },
    // ... more questions
  ];
}
```

---

### 3. **UI Structure** (Complete Layout)

#### **Main Build Method**:

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

  return WillPopScope(
    onWillPop: _onWillPop,
    child: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(),          // ✅ Header with close button
            if (!_showResults &&
                !_showQuiz &&
                !_showCompletion &&
                !_isReEntryLanding)
              _buildProgressBar(),         // ✅ Progress bar
            Expanded(
              child: _showResults
                  ? _buildResultsScreen()
                  : _showQuiz
                  ? _buildQuizScreen()
                  : (_showCompletion || _isReEntryLanding)
                  ? _buildStoryCompleteScreen()
                  : PageView.builder(     // ✅ PageView slider
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _slides.length + 1, // +1 for completion
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                        if (_showTutorial) {
                          setState(() => _showTutorial = false);
                        }
                        if (index == _slides.length) {
                          if (!_storyCompleted) {
                            _saveProgress(storyCompleted: true);
                            SoundService().playCompletion();
                            setState(() => _storyCompleted = true);
                          }
                        }
                      },
                      itemBuilder: (context, index) {
                        if (index == _slides.length) {
                          return _buildStoryCompleteScreen();
                        }
                        return Stack(
                          children: [
                            _buildUnitAtIndex(index),
                            if (_showTutorial && index == 0)
                              _buildSwipeTutorial(),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

---

#### **Header** (Standard):

```dart
Widget _buildModernHeader() {
  return Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: const BoxDecoration(color: Color(0xFF1E293B)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ✅ Close button (left)
        IconButton(
          onPressed: () async {
            if (await _onWillPop() && mounted) Navigator.pop(context);
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 20,
          icon: const Icon(Icons.close, color: Colors.white70),
        ),
        
        // ✅ Lesson title (center)
        const Text(
          "Your Lesson Title",  // Change per lesson
          style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // ✅ Progress indicator (right)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            (_showResults || _showQuiz || _showCompletion || _isReEntryLanding)
                ? "Quiz"
                : _currentIndex == _slides.length
                ? "Success"
                : "${_currentIndex + 1}/${_slides.length}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}
```

---

#### **Progress Bar**:

```dart
Widget _buildProgressBar() {
  final progress = ((_currentIndex + 1) / _slides.length).clamp(0.0, 1.0);
  return Container(
    height: 2,
    decoration: const BoxDecoration(color: Color(0xFF1E293B)),
    child: FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: progress,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyanAccent, Colors.cyan.shade300],
          ),
        ),
      ),
    ),
  );
}
```

---

### 4. **Slide Layouts** (Standard Templates)

#### **Basic Slide Layout** (Most Common):

```dart
Widget _buildSlideLayout(LessonSlide slide) {
  return Column(
    children: [
      // ✅ Image Area (flex: 4)
      Expanded(
        flex: 4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              '$_assetPath${slide.imagePath}',
              fit: slide.imageFit ?? BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image, size: 50, color: Colors.white24),
            ).animate(key: ValueKey(slide.imagePath)).fadeIn(),
          ),
        ),
      ),
      
      // ✅ Content Card (flex: 5)
      Expanded(
        flex: 5,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ✅ Title Row with Translation Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        slide.title,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    
                    // ✅ MANDATORY: Tamil/Hindi Toggle Button
                    if (slide.tamilContent.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showTranslation = !_showTranslation;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _showTranslation
                                ? Colors.cyanAccent.withOpacity(0.2)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _showTranslation
                                  ? Colors.cyanAccent
                                  : Colors.white24,
                            ),
                          ),
                          child: Text(
                            _preferredLanguage == 'Hindi' ? 'हिंदी' : 'தமிழ்',
                            style: TextStyle(
                              color: _showTranslation
                                  ? Colors.cyanAccent
                                  : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // ✅ Main Content (English)
                Text(
                  slide.content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                // ✅ Translation (Tamil/Hindi)
                if (_showTranslation)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      _preferredLanguage == 'Hindi'
                          ? slide.hindiContent
                          : slide.tamilContent,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ).animate().fadeIn(),
                  ),
                
                // ✅ Optional Formula Box
                if (slide.formula != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyan),
                    ),
                    child: Text(
                      slide.formula!,
                      style: TextStyle(
                        color: Colors.cyan[200],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
```

---

### 5. **Language & Translation** (MANDATORY)

#### **Load Language Preference**:

```dart
Future<void> _loadProgress() async {
  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;

  // ✅ Load preferred language (from SharedPreferences or Firebase)
  String? lang = prefs.getString('preferred_language');
  if (user != null) {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (userDoc.exists && userDoc.data()!.containsKey('language')) {
      lang = userDoc.get('language');
      await prefs.setString('preferred_language', lang!);
    }
  }
  _preferredLanguage = lang ?? 'Tamil';  // Default to Tamil

  // ... load other progress (story completed, quiz completed, etc.)
  
  if (mounted) {
    setState(() {
      _isLoading = false;
      // ... set other state
    });
  }
}
```

---

### 6. **Swipe Hint Animation** (First-Time Users)

**OLD PATTERN** ❌: Static overlay with swipe icon (blocking, intrusive)

**NEW PATTERN** ✅: Subtle card animation (non-blocking, intuitive)

#### **Implementation**:

```dart
class _LessonXxxScreenState extends State<LessonXxxScreen> 
    with SingleTickerProviderStateMixin {  // ✅ Add mixin
  
  late AnimationController _hintAnimationController;
  late Animation<Offset> _slideAnimation;
  bool _hasShownHint = false;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeLessonContent();
    _loadProgress();
    
    // ✅ Initialize hint animation
    _hintAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,           // Original position
      end: const Offset(-0.15, 0),  // Slide 15% left
    ).animate(CurvedAnimation(
      parent: _hintAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // ✅ Play hint animation once
    _checkAndPlayHint();
  }
  
  Future<void> _checkAndPlayHint() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenHint = prefs.getBool('has_seen_swipe_hint_lesson_xxx') ?? false;
    
    if (!hasSeenHint && mounted) {
      setState(() => _hasShownHint = false);
      
      // Wait a bit for layout to settle
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted && !_hasShownHint) {
        // Play animation: slide out and back
        await _hintAnimationController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        await _hintAnimationController.reverse();
        
        // Mark as seen
        await prefs.setBool('has_seen_swipe_hint_lesson_xxx', true);
        setState(() => _hasShownHint = true);
      }
    } else {
      setState(() => _hasShownHint = true);
    }
  }
  
  @override
  void dispose() {
    _hintAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
```

#### **Apply Animation to PageView**:

```dart
PageView.builder(
  controller: _pageController,
  physics: const BouncingScrollPhysics(),
  itemCount: _slides.length + 1,
  onPageChanged: (index) {
    setState(() => _currentIndex = index);
    // ... other logic
  },
  itemBuilder: (context, index) {
    if (index == _slides.length) {
      return _buildStoryCompleteScreen();
    }
    
    // ✅ Wrap current slide with SlideTransition for hint
    Widget slideWidget = _buildUnitAtIndex(index);
    
    // Apply hint animation only to first slide, only if not shown yet
    if (index == 0 && !_hasShownHint) {
      slideWidget = SlideTransition(
        position: _slideAnimation,
        child: slideWidget,
      );
    }
    
    return slideWidget;
  },
)
```

#### **Enhanced Version: Show Background Cards**

To make the next card partially visible during hint animation:

```dart
PageView.builder(
  controller: _pageController,
  physics: const BouncingScrollPhysics(),
  itemCount: _slides.length + 1,
  
  // ✅ Make pages slightly visible on sides
  padEnds: false,  
  clipBehavior: Clip.none,
  
  // ✅ Show part of next page (10% on each side)
  viewportFraction: 0.9,
  
  onPageChanged: (index) {
    setState(() => _currentIndex = index);
  },
  itemBuilder: (context, index) {
    if (index == _slides.length) {
      return _buildStoryCompleteScreen();
    }
    
    Widget slideWidget = _buildUnitAtIndex(index);
    
    // Add hint animation to first slide
    if (index == 0 && !_hasShownHint) {
      slideWidget = SlideTransition(
        position: _slideAnimation,
        child: slideWidget,
      );
    }
    
    // ✅ Add padding to create gap between cards
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: slideWidget,
    );
  },
)
```

#### **Alternative: Card Peek Animation**

For a more subtle effect without changing viewport:

```dart
// In itemBuilder:
return AnimatedBuilder(
  animation: index == 0 ? _slideAnimation : const AlwaysStoppedAnimation(Offset.zero),
  builder: (context, child) {
    final offset = index == 0 && !_hasShownHint 
        ? _slideAnimation.value 
        : Offset.zero;
    
    return Transform.translate(
      offset: Offset(offset.dx * MediaQuery.of(context).size.width, 0),
      child: child,
    );
  },
  child: _buildUnitAtIndex(index),
);
```

---

### **Design Principles**:

1. **✅ Subtle, Not Intrusive**: 15% slide (not full swipe)
2. **✅ Quick**: 1.5 seconds total (750ms out, 750ms back)
3. **✅ Once Per Lesson**: Stored in SharedPreferences
4. **✅ Non-Blocking**: Doesn't prevent interaction
5. **✅ Intuitive**: Shows the swipe direction naturally

### **Animation Timing**:

```
t=0s:    Card at original position (100%)
  ↓
t=0.75s: Card slides left to 85% position
  ↓
t=0.95s: Brief pause (200ms)
  ↓
t=1.7s:  Card returns to 100% position
  ↓
t=1.7s+: User can swipe (hint complete)
```

### **Storage Key Pattern**:

```dart
// Use lesson-specific keys
'has_seen_swipe_hint_lesson_simple_past'
'has_seen_swipe_hint_lesson_articles'
'has_seen_swipe_hint_lesson_present_perfect'

// Or global (all lessons share same hint)
'has_seen_swipe_hint_global'
```

### **Visual Effect**:

```
Before hint:
┌─────────────┐
│             │
│   Card 1    │  ← Current slide (100% visible)
│             │
└─────────────┘

During hint (slides left 15%):
      ┌─────────────┐
┌─────│─────┐       │
│ Card│  1  │ Card 2│  ← Card 1 moves left, Card 2 peek visible
│     │     │       │
└─────│─────┘       │
      └─────────────┘

After hint (returns):
┌─────────────┐
│             │
│   Card 1    │  ← Back to original position
│             │
└─────────────┘
```

---

### **Comparison: Old vs New**

| Feature | Old (Overlay) | New (Animation) |
|---------|--------------|-----------------|
| Visual | Static swipe icon | Card movement |
| Blocking | Yes (overlay covers content) | No (can still interact) |
| Intrusive | High (dark overlay) | Low (subtle motion) |
| Intuitive | Icon requires interpretation | Motion shows action |
| Dismissal | Tap to dismiss | Auto-completes |
| Duration | Until user taps | 1.7 seconds |

---

---

## 🎨 Layout Specifications

### **Image to Content Ratio**:
- Image Area: `flex: 4` (44.4%)
- Content Area: `flex: 5` (55.6%)

### **Colors**:
- Background: `Color(0xFF0F172A)` (dark blue)
- Header: `Color(0xFF1E293B)` (slightly lighter blue)
- Card: `Color(0xFF1E293B)`
- Accent: `Colors.cyanAccent`
- Translation: `Colors.amberAccent`

### **Spacing**:
- Card margins: `EdgeInsets.fromLTRB(16, 0, 16, 16)`
- Card padding: `EdgeInsets.all(20)`
- Image padding: `EdgeInsets.symmetric(horizontal: 16, vertical: 4)`

### **Border Radius**:
- Cards: `16`
- Header badge: `10`
- Toggle button: `20`
- Images: `16`

---

## 🔄 Complete Flow

### **1. First Visit**:
```
Loading Screen
  ↓
Swipe Tutorial (overlay on first slide)
  ↓
Slide 1 → Slide 2 → ... → Slide N
  ↓
  ⭐ LESSON SUMMARY (mandatory)
  ↓
  (If user tries to skip interactive quiz without attempting)
  ↓
  Show gentle reminder → Allow skip after confirmation
  ↓
Story Complete Screen
  ↓
Final Quiz
  ↓
Results Screen
```

### **2. Return Visit (Story Completed)**:
```
Story Complete Screen (shows immediately)
  ↓
Option: Review Story OR Take Quiz
```

---

## 🚪 Exit Dialog (Strict Standard)

All lessons MUST use this exact exit dialog style. DO NOT use default system dialogs.

### **Implementation**:

```dart
Future<bool> _onWillPop() async {
  final shouldPop = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Dismiss",
    pageBuilder: (context, a1, a2) => Container(),
    transitionBuilder: (context, a1, a2, child) {
      return Transform.scale(
        scale: a1.value,
        child: Dialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Leave Lesson?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Progress will be lost.",
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        child: const Text("Exit"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("Stay"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return shouldPop ?? false;
}
```

### **Usage in Build Method**:

```dart
@override
Widget build(BuildContext context) {
  // ... loading check ...
  return PopScope(
    canPop: false,
    onPopInvoked: (didPop) async {
      if (didPop) return;
      final shouldPop = await _onWillPop();
      if (shouldPop && context.mounted) Navigator.of(context).pop(true);
    },
    child: Scaffold(
      // ...
    ),
  );
}
```

### **Usage in Close Button**:

```dart
IconButton(
  icon: const Icon(Icons.close, color: Colors.white70),
  onPressed: () async {
    if (await _onWillPop() && mounted) Navigator.pop(context, true);
  },
),
```

### **3. Return Visit (Quiz Completed)**:
```
Re-Entry Landing (shows immediately)
  ↓
Option: Review Story OR Retake Quiz
```

---

## 📝 Lesson Summary Slide (MANDATORY)

### **Purpose**: 
- Reinforce key learning points
- Prepare learner for final quiz
- Provide a mental review checkpoint

### **Placement**:
- **AFTER**: All content slides (last instructional slide)
- **BEFORE**: Story completion screen and final quiz

### **Structure**:

```dart
// Add as the LAST slide in your _slides list (before completion screen)
LessonSlide(
  title: "Lesson Summary",  // ✅ Standard title
  content:
      "Great job! Remember:\n"
      "• Key Point 1 (main concept)\n"
      "• Key Point 2 (important rule)\n"
      "• Key Point 3 (common mistake to avoid)\n"
      "• Key Point 4 (practical tip)",
  imagePath: 'lesson_summary_image.png',  // Use a summary/recap style image
  hindiContent:
      "बढ़िया काम! याद रखें:\n"
      "• मुख्य बिंदु 1\n"
      "• मुख्य बिंदु 2\n"
      "• मुख्य बिंदु 3",
  tamilContent:
      "சிறப்பு! நினைவில் கொள்ளுங்கள்:\n"
      "• முக்கிய புள்ளி 1\n"
      "• முக்கிய புள்ளி 2\n"
      "• முக்கிய புள்ளி 3",
),
```

### **Content Guidelines**:

#### ✅ **DO**:
1. **Start with encouragement**: "Great job!", "Well done!", "Excellent work!"
2. **Use bullet points**: Easy to scan, clear structure
3. **Limit to 3-5 key points**: Don't overwhelm
4. **Focus on actionable takeaways**: What they should remember
5. **Connect to quiz**: Hint at what they'll be tested on
6. **Use simple language**: Should be a quick review

#### ❌ **DON'T**:
1. **Don't introduce new concepts**: This is review only
2. **Don't make it too long**: Should fit on one screen
3. **Don't be vague**: Be specific about what to remember
4. **Don't skip translation**: Include Tamil & Hindi content

### **Examples by Lesson Type**:

#### **Grammar Lesson (Simple Past)**:
```dart
content:
    "Great job! Remember:\n"
    "• Use Simple Past for finished actions.\n"
    "• Watch out for irregular verbs (go → went).\n"
    "• Use 'didn't' + base verb for negatives.",
```

#### **Tense Lesson (Present Perfect)**:
```dart
content:
    "Excellent! Key points:\n"
    "• Present Perfect connects past to now.\n"
    "• Formula: have/has + V3 (past participle).\n"
    "• Use for experience, results, recent actions.\n"
    "• Time words: just, already, yet, never, ever.",
```

#### **Parts of Speech**:
```dart
content:
    "Well done! Remember:\n"
    "• Noun = Person, Place, Thing, Idea.\n"
    "• Verb = Action or State.\n"
    "• Adjective = Describes nouns.\n"
    "• Adverb = Describes verbs, adjectives, other adverbs.",
```

#### **Articles**:
```dart
content:
    "Great work! Key rules:\n"
    "• A/An = New or general (first mention).\n"
    "• The = Specific or known.\n"
    "• A + consonant sound, An + vowel sound.\n"
    "• No article for general plurals or uncountables.",
```

### **Image Recommendations**:

- Use a **summary-style image**: checklist, recap visual, or achievement badge
- OR reuse the lesson's main visual (e.g., Ravi celebrating)
- Should feel **conclusive** and **positive**

### **Standard Format**:

```dart
// Template for all lessons
LessonSlide(
  title: "Lesson Summary",  // ✅ Keep consistent across all lessons
  content:
      "[Encouraging opening]! Remember:\n"
      "• [Key Point 1]\n"
      "• [Key Point 2]\n"
      "• [Key Point 3]\n"
      "• [Key Point 4 - optional]",
  imagePath: '[lesson_name]_summary.png',
  hindiContent: "[Hindi translation with bullets]",
  tamilContent: "[Tamil translation with bullets]",
)
```

---

## 🎯 Interactive Quiz Skip Prevention (NEW)

### **Problem**: Users can swipe past interactive quizzes without attempting them

### **Solution**: Gentle reminder with explicit confirmation

### **Implementation**:

#### **1. Add State Variable for Each Quiz**:

```dart
// Track which quizzes have been attempted
Map<int, bool> _quizAttempted = {};  // key = slide index, value = attempted
```

#### **2. Mark Quiz as Attempted When Answer Selected**:

```dart
Widget _buildQuizLayout(LessonQuizInteraction unit) {
  return Column(
    children: [
      // ... image area
      
      // Options
      ...List.generate(unit.options.length, (index) {
        return ElevatedButton(
          onPressed: () {
            // ✅ Mark this quiz as attempted
            setState(() {
              _quizAttempted[_currentIndex] = true;
            });
            
            // Handle answer...
            if (index == unit.correctIndex) {
              SoundService().playCorrect();
              // Show success message
            } else {
              SoundService().playWrong();
              // Show try again
            }
          },
          child: Text(unit.options[index]),
        );
      }),
    ],
  );
}
```

#### **3. Check Before Allowing Page Change**:

```dart
PageView.builder(
  controller: _pageController,
  physics: const NeverScrollableScrollPhysics(),  // ✅ Disable swipe
  onPageChanged: (index) async {
    // Check if previous page was unattempted quiz
    if (_currentIndex < _slides.length) {
      final prevUnit = _slides[_currentIndex];
      if (prevUnit is LessonQuizInteraction) {
        if (_quizAttempted[_currentIndex] != true) {
          // ✅ Show gentle reminder
          final shouldSkip = await _showQuizSkipDialog();
          if (!shouldSkip) {
            // Go back to quiz
            _pageController.jumpToPage(_currentIndex);
            return;
          }
        }
      }
    }
    
    setState(() => _currentIndex = index);
  },
  itemBuilder: (context, index) {
    // ... build slides
  },
)
```

#### **4. Gentle Reminder Dialog**:

```dart
Future<bool> _showQuizSkipDialog() async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                color: Colors.amber,
                size: 48,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Title
            const Text(
              "Quick Quiz!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Message
            const Text(
              "Try the quiz to reinforce your learning.\nIt only takes a moment!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                // Skip button (secondary)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, true), // ✅ Allow skip
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Skip"),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Try Quiz button (primary)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, false), // ✅ Go back
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Try Quiz",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  
  return result ?? false;  // Default: don't skip
}
```

#### **5. Alternative: Use Swipe Gestures with Interception**

If you want to keep swipe physics but intercept:

```dart
PageView.builder(
  controller: _pageController,
  physics: const BouncingScrollPhysics(),  // Keep swipe
  onPageChanged: (index) {
    // Will be called, but we can revert
  },
  // Use listener instead
)

// In initState:
_pageController.addListener(() {
  // Detect page change attempt
  if (_pageController.page != null) {
    final targetPage = _pageController.page!.round();
    if (targetPage != _currentIndex) {
      _handlePageChangeAttempt(targetPage);
    }
  }
});

void _handlePageChangeAttempt(int targetPage) async {
  // Check if leaving unattempted quiz
  final currentUnit = _slides[_currentIndex];
  if (currentUnit is LessonQuizInteraction) {
    if (_quizAttempted[_currentIndex] != true) {
      // Show dialog
      final shouldSkip = await _showQuizSkipDialog();
      if (!shouldSkip) {
        // Jump back to current page
        _pageController.jumpToPage(_currentIndex);
        return;
      }
    }
  }
}
```

### **Design Principles**:

1. **✅ Gentle, Not Blocking**: Use warm colors (amber) and friendly language
2. **✅ Educational**: "Reinforce your learning" not "You must do this"
3. **✅ Explicit Confirmation**: User must actively choose to skip
4. **✅ Easy to Try**: "Try Quiz" button is primary (cyan, larger emphasis)
5. **✅ Allows Skip**: Don't force - respect user choice after confirmation

### **When to Show**:

- ✅ **Show**: User swipes away from quiz without selecting any answer
- ❌ **Don't Show**: User has attempted the quiz (even if wrong answer)
- ❌ **Don't Show**: User is reviewing lesson (already completed before)
- ❌ **Don't Show**: On Speaking Practice slides (no right/wrong answers)

---

## ✅ Checklist for New Lessons

When creating a new storybook lesson, ensure:

- [ ] Uses `PageView.builder` with `PageController`
- [ ] Has `_showTranslation` and `_preferredLanguage` state variables
- [ ] Loads language preference from SharedPreferences/Firebase
- [ ] Has Tamil (தமிழ்) toggle button on every slide
- [ ] **NEW**: Uses subtle swipe hint animation (card slides left & back)
- [ ] **NEW**: Implements `SingleTickerProviderStateMixin` for hint animation
- [ ] **NEW**: Hint plays once per lesson (stored in SharedPreferences)
- [ ] Has `_buildProgressBar()` below header
- [ ] Uses standard header with close button + progress counter
- [ ] Image area is `flex: 4`, content area is `flex: 5`
- [ ] All `LessonSlide` objects have `tamilContent` and `hindiContent`
- [ ] Card uses `Color(0xFF1E293B)` background
- [ ] Progress saves to SharedPreferences AND Firebase
- [ ] Has end-of-lesson quiz (`_quizQuestions`)
- [ ] Has `_buildStoryCompleteScreen()` for re-entry
- [ ] No navigation buttons (pure swipe gestures)
- [ ] Uses `BouncingScrollPhysics()` for PageView
- [ ] **NEW**: Has Lesson Summary slide as LAST content slide
- [ ] **NEW**: Summary has 3-5 bullet points reinforcing key concepts
- [ ] **NEW**: Summary prepares learner for final quiz
- [ ] **NEW**: Implements interactive quiz skip prevention with gentle reminder
- [ ] **NEW**: Tracks quiz attempts with `Map<int, bool> _quizAttempted`
- [ ] **NEW**: Shows dialog when user tries to skip unattempted quiz

---

## 🚫 What NOT to Do

### ❌ **Don't Use**:
- Navigation arrow buttons (removed in latest pattern)
- GestureDetector with manual swipe detection
- Direct `setState()` page changes
- FadeIn animations for page transitions (causes blackout)
- Manual slide-in animations
- Center-aligned images (use flex ratio instead)
- **Static swipe overlay tutorial** (use subtle hint animation instead)
- **Blocking swipe tutorials** (use non-blocking card movement)

### ❌ **Don't Skip**:
- Tamil/Hindi toggle button
- **Swipe hint animation** for first-time users (card slides left & back)
- Progress bar
- Translation content (`tamilContent`, `hindiContent`)
- Save to Firebase (not just SharedPreferences)
- Re-entry landing screen logic
- Lesson Summary slide (mandatory as last content slide)
- Interactive quiz skip prevention dialog

---

## 📦 Required Packages

```yaml
dependencies:
  flutter_animate: ^4.5.2
  shared_preferences: ^2.5.4
  cloud_firestore: ^6.1.1
  firebase_auth: ^6.1.2
```

---

## 📂 File Structure Template

```
lib/screens/lesson_xxx_screen.dart
├── Data Models (LessonSlide, etc.)
├── Screen State Class
│   ├── State Variables
│   ├── initState() → _initializeLessonContent() + _loadProgress()
│   ├── _loadProgress() → Load language & completion status
│   ├── _saveProgress() → Save to SharedPreferences + Firebase
│   ├── Quiz Logic (_handleAnswer, _nextQuestion, _finishQuiz)
│   ├── build() → Main UI structure
│   ├── _buildModernHeader()
│   ├── _buildProgressBar()
│   ├── _buildSwipeTutorial()
│   ├── _buildUnitAtIndex() → Route to correct layout
│   ├── _buildSlideLayout()
│   ├── _buildHighlightLayout()
│   ├── _buildQuizLayout()
│   ├── _buildSpeakingLayout()
│   ├── _buildStoryCompleteScreen()
│   ├── _buildQuizScreen()
│   └── _buildResultsScreen()
```

---

## 🎯 Key Principles

1. **Consistency**: All storybooks look and feel the same
2. **Tamil Support**: MANDATORY language toggle on every slide
3. **Swipe Navigation**: Pure gesture-based, no buttons
4. **Progress Tracking**: Save story completion + quiz completion separately
5. **Re-entry Handling**: Different screens for different completion states
6. **Tutorial**: Show swipe tutorial to new users
7. **Smooth UX**: Use PageView's built-in physics, no custom animations

---

## 📝 Example: Minimal Implementation

See `lib/screens/lesson_articles_screen.dart` for the complete, working reference implementation.

---

**Last Updated**: 2026-01-21  
**Based On**: Articles Lesson (lesson_articles_screen.dart)  
**Pattern Version**: 3.0 - Latest and Final

This is the **single source of truth** for all storybook lesson UI patterns.

---

### 6. **Re-Entry / Lesson Mastered Screen** (New Standard)

This screen is shown when a user re-enters a completed lesson or finishes the quiz successfully.
Based on `lesson_subjects_screen.dart`.

```dart
  Widget _buildReEntryLanding() {
    // Map your state variables to 'isMastered'
    // _quizCompleted is usually the flag for Mastery
    final bool isMastered = _quizCompleted; 

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isMastered
                  ? Icons.emoji_events_rounded
                  : Icons.check_circle_outline,
              size: 100,
              color: isMastered
                  ? const Color(0xFFFFD700)
                  : const Color(0xFF4FACFE),
            )
                .animate()
                .fade(duration: 400.ms)
                .scale(
                  delay: 100.ms,
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 32),
            Text(
              isMastered ? 'Lesson Mastered!' : 'Lesson Completed',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            Text(
              isMastered
                  ? 'You have earned 2 Stars! ⭐⭐'
                  : 'You have earned 1 Star! ⭐\nTake the quiz to earn Mastery.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 48),
            
            // Buttons
            if (isMastered) ...[
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: () {
                     // RESET LOGIC
                     setState(() {
                       _currentIndex = 0;
                       _isReEntryLanding = false;
                       // Do NOT reset completion flags if you want to keep progress
                     });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Review Story"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: () {
                     // SHOW QUIZ
                     setState(() {
                       _showResult = false;
                       _showQuiz = true;
                       _isReEntryLanding = false;
                       // reset quiz vars
                     });
                  },
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text("Retake Quiz"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FACFE).withOpacity(0.2),
                    foregroundColor: const Color(0xFF4FACFE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  "Go Back",
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ] else ...[
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () {
                     // SHOW QUIZ
                     setState(() {
                        _showQuiz = true;
                        _isReEntryLanding = false;
                     });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FACFE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    "Take Quiz",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  "Continue to Next Lesson",
                  style: TextStyle(color: Colors.white54),
                ),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ],
        ),
      ),
    );
  }
```
