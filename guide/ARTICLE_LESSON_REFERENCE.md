# Article Lesson - Storybook UI V2 Pattern (REFERENCE IMPLEMENTATION)

## Overview
The Articles lesson (`lesson_articles_screen.dart`) represents the **gold standard** for the Storybook UI V2 pattern. All new lessons should follow this structure.

---

## LESSON FLOW

### Phase 1: Story Pages (Learning)
```
PageView Controller → Slide 1 → Slide 2 → ... → Final Slide
```

**User Actions:**
- Swipes left/right to navigate
- Taps translate button to toggle Tamil/Hindi
- Interacts with inline quiz/highlight exercises

**Features:**
1. **First-time Swipe Hint Animation**
   - Slides content 15% left on first lesson entry
   - Saved to `SharedPreferences` so only shows once
   - Uses `AnimationController` with `Tween<Offset>`

2. **Progress Bar**
   - Shows `(currentIndex + 1) / totalSlides`
   - Cyan accent color
   - Located in header

3. **Language Toggle**
   - Icon button (translate icon)
   - Shows native text: "தமிழ்" for Tamil
   - Displays `tamilContent` or `hindiContent` in overlay box

---

### Phase 2: Story Complete Screen
```
✓ All slides viewed → Auto-transition → Story Complete Screen
```

**UI Elements:**
- **Icon:** Check circle outline (size 80, cyan)
- **Title:** "Story Completed!"
- **Message:** "Take the Mastery Quiz to earn 2 Stars..."
- **Buttons:**
  1. **Primary (Cyan):** "Take Mastery Quiz" → Starts quiz
  2. **Secondary (Outlined):** "Review Story" → Returns to slide 1

**Trigger Logic:**
```dart
if (index == _slides.length - 1) {
  Future.delayed(Duration(milliseconds: 800), () {
    setState(() => _storyComplete = true);
  });
}
```

---

### Phase 3: Mastery Quiz
```
Question 1 → Question 2 → ... → Final Question → Results
```

**Quiz Screen Structure:**

#### Header
- **Close Button** (X icon)
- **Question Counter:** "Quiz 1/5"
- **Score Display:** "Score: 3" (cyan accent)
- **Progress Bar:** Linear indicator

#### Question Area
- **Question Card:**
  - White background (opacity 0.1)
  - 20px padding
  - Centered text
  - Border: Cyan accent (opacity 0.3)

#### Answer Options
- **Layout:** Vertical list of buttons
- **States:**
  1. **Unselected:** White10 background, White24 border
  2. **Selected (Before Answer):** Cyan accent background + border
  3. **Correct Answer:** Green accent background + border + check icon
  4. **Wrong Answer:** Red accent background + border + X icon

- **Option Format:**
  ```
  [A] → Option Text → [Icon if answered]
  ```

#### Explanation Box (After Answer)
- **Background:** Green/Red based on correctness
- **Icon:** Check circle (correct) / Info (incorrect)
- **Text:** Explanation from question data

#### Footer Button
- **"Next Question"** → Goes to next
- **"See Results"** (on last question) → Goes to results

**Data Structure:**
```dart
{
  'question': 'I saw ___ elephant.',
  'options': ['a', 'an', 'the'],
  'correct': 1, // Index of correct option
}
```

---

### Phase 4: Results Screen
```
Final Score → Pass/Fail → Retake or Exit
```

**UI Elements:**

1. **Icon:**
   - **Passed (≥60%):** Celebration icon (amber)
   - **Failed (<60%):** Trophy icon (orange)
   - Animated: `.animate().scale()`

2. **Title:**
   - Passed: "Congratulations!"
   - Failed: "Good Effort!"

3. **Message:**
   - Passed: "You've mastered Active & Passive Voice!"
   - Failed: "Keep practicing to improve!"

4. **Score Card:**
   - Container with white10 background
   - Label: "Your Score"
   - Fraction: "4/5" (cyan, size 48)
   - Percentage: "80%" (green if passed, orange if failed)

5. **Action Buttons:**
   - **"Retake Quiz"** (outlined, white)
   - **"Complete"** (filled, cyan) → Exits to curriculum

**Save Logic:**
```dart
// SharedPreferences
prefs.setBool('lesson_articles_completed', true);

// Firestore
users/{uid}/lessons/lesson_articles {
  completed: true,
  timestamp: serverTimestamp
}
```

---

## STATE MANAGEMENT

### Boolean Flags
```dart
bool _isLoading = true;           // Initial load
bool _showCompletion = false;     // Story complete screen
bool _storyCompleted = false;     // Story phase done
bool _showQuiz = false;           // Quiz active
bool _showResults = false;        // Results screen
bool _isReEntryLanding = false;   // User returns to lesson
bool _quizCompleted = false;      // Quiz finished once
```

### Navigation
```dart
int _currentIndex = 0;              // Current slide
PageController _pageController;     // Slide navigation
```

### Quiz State
```dart
int _currentQuestionIndex = 0;      // Current Q
int _score = 0;                     // Running score
bool _answerSelected = false;       // User picked answer
int? _selectedOptionIndex;          // Which option
```

---

## UI COMPONENTS

### 1. Header (_buildModernHeader)
```
[Close Icon] [Title + Progress] [Translate Icon (தமிழ்)]
[━━━━━━━━━━ Progress Bar ━━━━━━━━━━]
```

**Code:**
- Container with `Color(0xFF1E293B)` background
- Rounded bottom corners (24px radius)
- Padding: 16 horizontal, 12 vertical

### 2. Slide Layouts

#### Standard Slide (_buildSlideLayout)
```
┌───────────────────────┐
│   [Image 40% height]  │
├───────────────────────┤
│   Title (Cyan, 24px)  │
│                       │
│   Content (White)     │
│                       │
│  [Translation Box]    │ (if toggled)
│  [Formula Box]        │ (if exists)
└───────────────────────┘
```

#### Highlight Interaction (_buildHighlightLayout)
```
┌─────────────────────────┐
│    Instruction Text     │
├─────────────────────────┤
│  "Ravi ate [a] dosa."   │ ← Tappable words
├─────────────────────────┤
│  [Check Answer Button]  │
│  [Feedback Box]         │
└─────────────────────────┘
```

#### Quiz Interaction (_buildQuizLayout)
```
┌─────────────────────────┐
│   Question Title        │
├─────────────────────────┤
│   Question Text         │
│   [A] Option 1          │
│   [B] Option 2          │
│   [C] Option 3          │
│   [Feedback]            │
└─────────────────────────┘
```

#### Speaking Practice (_buildSpeakingLayout)
```
┌─────────────────────────┐
│   [Chart Image]         │
├─────────────────────────┤
│   Speaking Prompts:     │
│   🎤 "Say: I saw an..."│
│   🎤 "Say: The dog..." │
├─────────────────────────┤
│   Key Points:           │
│   ⭐ Use 'a' before... │
│   ⭐ Use 'the' when... │
└─────────────────────────┘
```

---

## ANIMATIONS

### 1. Page Transitions
- **Default PageView:** Horizontal scroll with physics
- **No custom transitions** on slides (PageView handles it)

### 2. Swipe Hint (First Time)
```dart
Tween<Offset>(
  begin: Offset.zero,
  end: Offset(-0.15, 0),  // 15% left
).animate(CurvedAnimation(
  parent: controller,
  curve: Curves.easeInOut,
))
```

### 3. Answer Feedback
```dart
Container(...).animate().fadeIn()
```

### 4. Result Screen Icons
```dart
Icon(...).animate().scale(duration: 500ms)
```

---

## COLOR SCHEME

### Primary Colors
- **Background:** `Color(0xFF0F172A)` (dark navy)
- **Card/Panel:** `Color(0xFF1E293B)` (slate)
- **Accent:** `Colors.cyanAccent`

### Feedback Colors
- **Correct:** `Colors.greenAccent`
- **Wrong:** `Colors.redAccent`
- **Warning:** `Colors.amberAccent`

### Text Colors
- **Primary:** `Colors.white`
- **Secondary:** `Colors.white70` (opacity 70%)
- **Disabled:** `Colors.white24`

---

## SOUND EFFECTS

```dart
SoundService().playTap();        // Navigation
SoundService().playCorrect();    // Right answer
SoundService().playWrong();      // Wrong answer
SoundService().playCompletion(); // Lesson done
```

---

## DATA MODELS

### LessonUnit (Abstract)
Base class for all slide types.

### LessonSlide
```dart
{
  title: String,
  content: String,
  imagePath: String,
  hindiContent: String,
  tamilContent: String,
  formula: String? (optional),
  imageFit: BoxFit? (optional),
}
```

### LessonHighlightInteraction
```dart
{
  instruction: String,
  sentence: String,
  correctIndices: List<int>,
  options: List<String>,
  explanation: String,
}
```

### LessonQuizInteraction
```dart
{
  title: String,
  question: String,
  options: List<String>,
  correctIndex: int,
  explanation: String,
}
```

### LessonSpeakingPractice
```dart
{
  title: String,
  imagePath: String,
  prompts: List<String>,
  summaryPoints: List<String>,
}
```

---

## BUILD METHOD FLOW

```dart
build(BuildContext context) {
  if (_isLoading) return LoadingScreen;
  
  if (_isReEntryLanding) return ReEntryScreen;
  if (_showResults) return _buildResultsScreen();
  if (_showQuiz) return _buildQuizScreen();
  if (_showCompletion) return _buildStoryCompleteScreen();
  
  // Default: Story Mode
  return Scaffold(
    body: SafeArea(
      child: Column([
        _buildModernHeader(),
        _buildProgressBar(),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) {
              // Update index, reset quiz states
              if (index == lastSlide) showCompletion();
            },
            itemBuilder: (ctx, idx) => _buildUnitAtIndex(idx),
          ),
        ),
      ]),
    ),
  );
}
```

---

## KEY DIFFERENCES FROM OLD PATTERN

### What Changed:
1. ❌ **Removed:** Card-based `LessonContent` model
2. ❌ **Removed:** Column with manual ScrollController
3. ❌ **Removed:** Bottom navigation buttons
4. ✅ **Added:** PageView with swipe navigation
5. ✅ **Added:** Story Complete checkpoint screen
6. ✅ **Added:** Swipe hint animation
7. ✅ **Added:** Native language labels (தமிழ்)
8. ✅ **Added:** Inline interactive elements

### Architecture:
- **Old:** Linear scroll with cards
- **New:** Paginated slides with interactions

---

## BEST PRACTICES

### DO:
✅ Use `PageView.builder` for slides
✅ Add story complete screen before quiz
✅ Show native language names (தமிழ், हिंदी)
✅ Use gesture-based navigation (swipe)
✅ Play sounds for feedback
✅ Save progress to both SharedPreferences + Firestore
✅ Show pass/fail threshold (60%)
✅ Provide retake option

### DON'T:
❌ Don't use navigation buttons (removed)
❌ Don't skip story complete screen
❌ Don't use plain English for language names
❌ Don't assume user language (load from prefs)
❌ Don't auto-advance slides (user controls)
❌ Don't save incomplete progress

---

## ASSETS STRUCTURE

```
assets/Lessons/Lesson_XX_Name/
├── slide_1_square.png
├── slide_2_square.png
├── interaction_1_square.png
├── quiz_question_square.png
└── summary_chart_square.png
```

**Naming:**
- All lowercase with underscores
- End with `_square.png` (1:1 aspect ratio)
- Descriptive names matching content

---

## TESTING CHECKLIST

- [ ] Swipe left/right works
- [ ] Language toggle shows correct translation
- [ ] Progress bar updates accurately
- [ ] Story complete screen appears after last slide
- [ ] Quiz questions display correctly
- [ ] Answer feedback shows (green/red)
- [ ] Score calculates correctly
- [ ] Results screen shows pass/fail
- [ ] Retake quiz resets state
- [ ] Firebase save triggers on completion
- [ ] Swipe hint only shows once
- [ ] Close button exits to curriculum

---

## Common Pitfalls

1. **Forgetting Story Complete Screen**
   - Always add intermediate screen before quiz
   
2. **Wrong Flow Order**
   - Correct: Story → Complete → Quiz → Results
   - Wrong: Story → Quiz → Results

3. **Translation Box Logic**
   - Must check `_showTranslation` AND have content
   - Use `if (_showTranslation && slide.tamilContent.isNotEmpty)`

4. **PageController Disposal**
   - Always dispose in `dispose()` method

5. **Quiz State Reset**
   - Reset all quiz variables when retaking

---

This is the **definitive reference** for Storybook UI V2. Follow this pattern exactly for all new lessons.
