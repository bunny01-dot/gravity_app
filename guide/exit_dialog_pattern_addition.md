# Storybook UI Pattern - Exit Dialog & Re-Entry Addition

**IMPORTANT**: Add this section to `STORYBOOK_UI_PATTERN.md` at line 769 (before "## 🔄 Complete Flow")

---

## 🚪 Exit Dialog & Re-Entry Pattern (MANDATORY)

### **Problem**: 
Users can exit lessons without warning, losing progress and creating confusion

### **Solution**: 
Modern exit confirmation dialog + smart re-entry landing screens

---

### **1. Exit Dialog (Prevent Accidental Exits)**

#### **Implementation**:

```dart
// Wrap Scaffold with PopScope (Flutter 3.12+) or WillPopScope (older)
return PopScope(
  canPop: false,  // Prevent immediate back navigation
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;  // Already popped, do nothing
    
    // Show exit confirmation
    final shouldExit = await _showExitDialog();
    if (shouldExit && context.mounted) {
      Navigator.of(context).pop();
    }
  },
  child: Scaffold(
    // ... your lesson UI
  ),
);
```

#### **Modern Exit Dialog**:

```dart
Future<bool> _showExitDialog() async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,  // Must choose an option
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
            // Warning Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.exit_to_app_rounded,
                color: Colors.orange,
                size: 48,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Title
            const Text(
              "Leave Lesson?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Message
            const Text(
              "Your progress will be saved, but you'll need to\nrestart this lesson from where you left off.",
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
                // Stay button (primary)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, false),  // Stay
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Stay",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Leave button (secondary)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, true),  // Leave
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Leave"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  
  return result ?? false;  // Default: don't exit
}
```

---

### **2. Re-Entry Landing Pattern**

#### **Problem**: 
Users who return to completed lessons see confusing screens

#### **Solution**: 
Smart landing screens based on completion state

#### **State Management**:

```dart
// Load progress in initState
Future<void> _loadProgress() async {
  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;
  
  // Check story completion
  bool storyDone = prefs.getBool('lesson_xxx_story_completed') ?? false;
  
  // Check quiz completion
  bool quizDone = false;
  if (user != null) {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lesson_progress')
        .doc('lesson_xxx')
        .get();
    
    if (doc.exists) {
      storyDone = doc.get('story_completed') ?? false;
      quizDone = doc.get('quiz_completed') ?? false;
    }
  }
  
  // Set re-entry state
  setState(() {
    _storyCompleted = storyDone;
    _quizCompleted = quizDone;
    
    // Show landing screen if returning user
    if (quizDone) {
      _isReEntryLanding = true;  // Both completed
      _showCompletion = true;
    } else if (storyDone) {
      _showCompletion = true;  // Only story completed
    }
    
    _isLoading = false;
  });
}
```

#### **Re-Entry Landing Screen**:

```dart
Widget _buildStoryCompleteScreen() {
  // Different UI based on state
  final bool bothCompleted = _storyCompleted && _quizCompleted;
  
  return Container(
    color: const Color(0xFF0F172A),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon (different based on state)
            Icon(
              bothCompleted ? Icons.emoji_events : Icons.check_circle_outline,
              color: bothCompleted ? Colors.amber : Colors.cyanAccent,
              size: 80,
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              bothCompleted ? "Lesson Complete!" : "Story Complete!",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              bothCompleted
                  ? "Great job! You've mastered this lesson."
                  : "Ready to test your knowledge?",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            // Options
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showCompletion = false;
                    _isReEntryLanding = false;
                    _currentIndex = 0;
                    _pageController.jumpToPage(0);
                  });
                },
                icon: const Icon(Icons.replay_rounded),
                label: const Text("Review Story"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Quiz button (different text based on state)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showCompletion = false;
                    _showQuiz = true;
                    _currentQuestionIndex = 0;
                    _score = 0;
                  });
                },
                icon: Icon(bothCompleted ? Icons.refresh : Icons.quiz_outlined),
                label: Text(bothCompleted ? "Retake Quiz" : "Take Quiz"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.cyanAccent,
                  side: const BorderSide(color: Colors.cyanAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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

### **Design Principles**:

1. **✅ Always Ask Before Exiting**: Never let users accidentally leave
2. **✅ Save Progress**: Always save before showing exit dialog
3. **✅ Clear Messaging**: Tell users what will happen
4. **✅ Smart Re-Entry**: Show different screens based on completion state
5. **✅ Primary Action Highlighted**: "Stay" is primary, "Leave" is secondary

---

### **When to Show**:

#### **Exit Dialog**:
- ✅ **Show**: User presses back button or close button
- ✅ **Show**: User swipes down to dismiss (if applicable)
- ❌ **Don't Show**: User completed quiz and clicked "Return to Dashboard"
- ❌ **Don't Show**: Programmatic navigation (deep links, etc.)

#### **Re-Entry Landing**:
- ✅ **Show**: Story completed, quiz not taken
- ✅ **Show**: Both story and quiz completed
- ❌ **Don't Show**: First-time visitor
- ❌ **Don't Show**: User clicked "Review Story" from landing

---

### **Flow Diagram**:

```
User presses Back
       ↓
  Exit Dialog
       ↓
   ┌───┴───┐
   │       │
 Stay    Leave
   │       │
Continue   Save progress
 Lesson    & Exit
```

```
User returns to lesson
       ↓
  Check completion state
       ↓
   ┌────┴────┐
   │         │
Story done  Both done
Quiz not    │
   │        │
Show "Take  Show "Retake
Quiz"       Quiz"
```

---

### **Testing Checklist**:

- [ ] Back button shows exit dialog
- [ ] Close button shows exit dialog
- [ ] "Stay" keeps user in lesson
- [ ] "Leave" exits and saves progress
- [ ] Re-entry shows correct landing screen
- [ ] "Review Story" goes to slide 1
- [ ] "Take Quiz" starts quiz
- [ ] "Retake Quiz" resets quiz state

---

