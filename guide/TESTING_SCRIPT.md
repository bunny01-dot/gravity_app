# TESTING SCRIPT
## Systematic QA Validation After Fixes

---

## 🔒 SECURITY TESTS

### Test 1: Firestore Rules - XP Protection
```
1. Login as Student A
2. Open Firebase Console → Firestore
3. Try to manually update Student B's XP
   Expected: Permission denied
4. Try to decrease own XP from 100 to 50
   Expected: Permission denied
5. Try to increase own XP from 100 to 150
   Expected: Success
```

### Test 2: Firestore Rules - Role Protection
```
1. Login as Student
2. Try to update own role to 'teacher'
   Expected: Permission denied
3. Try to create announcement
   Expected: Permission denied
4. Login as Teacher
5. Create announcement
   Expected: Success
```

### Test 3: Firestore Rules - Leaderboard
```
1. Open leaderboard
2. Check network tab for Firestore reads
   Expected: Maximum 50 documents read
3. Try to update another user's score
   Expected: Permission denied
```

---

## 📡 OFFLINE TESTS

### Test 4: Offline Login
```
1. Turn off WiFi/Mobile data
2. Open app
3. Login with valid credentials
   Expected: Login succeeds with orange snackbar "Logged in offline"
4. Check that dashboard loads with cached data
5. Turn on internet
   Expected: Data syncs automatically
```

### Test 5: Offline XP Earning
```
1. Turn off internet
2. Complete a game (e.g., Word Match)
3. Earn 100 XP
   Expected: XP updates locally
4. Close app
5. Reopen app (still offline)
   Expected: XP persists
6. Turn on internet
   Expected: XP syncs to Firestore
```

---

## 📝 QUIZ TESTS

### Test 6: Quiz Exit Prevention
```
1. Start daily quiz
2. Answer 2 questions
3. Press device back button
   Expected: Confirmation dialog appears
4. Press "Cancel"
   Expected: Quiz continues
5. Press back again → "Exit"
   Expected: Returns to dashboard, progress lost
```

### Test 7: Empty Vocabulary Handling
```
1. Clear all vocabulary data (or use fresh install)
2. Navigate to Daily Quiz
   Expected: Shows "No vocabulary loaded. Please sync data in Settings."
   Expected: Back button visible in AppBar
3. Press back
   Expected: Returns to dashboard
```

### Test 8: Quiz Scoring - Mastered (80%+)
```
1. Start quiz with 10 questions
2. Answer 9 correctly (90%)
   Expected: "Excellent! 🎉" dialog
   Expected: "You have truly mastered this lesson"
   Expected: Confetti animation plays
3. Press "Done"
   Expected: Returns to dashboard
   Expected: Quiz marked as passed
```

### Test 9: Quiz Scoring - Passed (70-79%)
```
1. Start quiz with 10 questions
2. Answer 7-8 correctly (70-80%)
   Expected: "Good Job! 👍" dialog
   Expected: "You passed, but reviewing the material again will help"
   Expected: "Review" button visible
3. Press "Done"
   Expected: Returns to dashboard
```

### Test 10: Quiz Scoring - Failed (<70%)
```
1. Start quiz with 10 questions
2. Answer 6 or fewer correctly (<70%)
   Expected: Navigates to Assignment Screen
   Expected: Shows vocabulary/verbs to review
```

### Test 11: Answer Explanations
```
1. Start quiz
2. Select WRONG answer
   Expected: Card turns red
   Expected: Correct answer turns green
   Expected: Orange snackbar shows explanation
   Expected: Wait 2 seconds, auto-advances to next question
```

### Test 12: TTS in Quiz
```
1. Start quiz
2. Press speaker icon next to question
   Expected: Word is spoken aloud
3. Change TTS speed in settings
4. Return to quiz, press speaker again
   Expected: Word spoken at new speed
```

---

## 🎮 GAME TESTS

### Test 13: Word Match - Long Definitions
```
1. Open Word Match game
2. Find a definition card with long text
3. Tap the card
   Expected: Card flips and shows truncated text
4. Tap again (if implemented)
   Expected: Full text visible or scrollable
```

### Test 14: Rapid Button Tapping
```
1. Start daily quiz
2. Rapidly tap multiple answer options
   Expected: Only first tap registers
   Expected: No duplicate answers recorded
```

### Test 15: Timer Management
```
1. Start daily quiz
2. Note the timer
3. Complete quiz (pass or fail)
   Expected: Timer stops immediately
   Expected: Timer value saved correctly
```

---

## 🔄 ROTATION TESTS

### Test 16: Orientation Lock
```
1. Open app
2. Rotate device to landscape
   Expected: App stays in portrait mode
3. Try all screens (quiz, games, dashboard)
   Expected: All stay portrait
```

---

## 🌐 NETWORK TESTS

### Test 17: Slow Network Login
```
1. Enable network throttling (2G speed)
2. Login
   Expected: Shows loading indicator
   Expected: Timeout after 30 seconds with error message
   Expected: Allows retry
```

### Test 18: Network Loss During Quiz
```
1. Start quiz with internet on
2. Turn off internet mid-quiz
3. Complete quiz
   Expected: Quiz completes normally
   Expected: Results saved locally
4. Turn on internet
   Expected: Results sync to cloud
```

---

## 👥 USER FLOW TESTS

### Test 19: First-Time User (if onboarding implemented)
```
1. Fresh install
2. Open app
   Expected: Onboarding screens appear
3. Swipe through 3 screens
4. Press "Get Started"
   Expected: Navigates to login screen
5. Reopen app
   Expected: Skips onboarding, goes to login
```

### Test 20: Student Daily Flow
```
1. Login as student
2. Check daily tasks
3. Complete daily quiz (pass)
   Expected: Checkmark appears
   Expected: XP awarded
4. Complete vocabulary game
   Expected: High score saved
5. Check leaderboard
   Expected: Rank updated
```

### Test 21: Teacher Flow
```
1. Login as teacher
2. View students tab
   Expected: All students visible
3. View attendance
   Expected: Today's attendance shown
4. Create announcement
   Expected: Announcement appears for all students
5. Check student progress
   Expected: Radar charts show accurate data
```

---

## 🐛 EDGE CASE TESTS

### Test 22: Missed Lessons Filter
```
1. Login as student
2. Navigate to Missed Lessons
3. Check that ONLY failed/incomplete lessons appear
   Expected: Passed lessons NOT shown
4. Retry a missed lesson and pass
5. Return to Missed Lessons
   Expected: Lesson removed from list
```

### Test 23: Duplicate Quiz Attempt
```
1. Complete today's quiz (pass)
2. Try to start quiz again
   Expected: "Great Job! You have already mastered this lesson"
   Expected: Cannot retake today's quiz
```

### Test 24: Low Memory Device
```
1. Test on device with <2GB RAM
2. Open app
3. Navigate through all screens
   Expected: No crashes
   Expected: Smooth performance
4. Play multiple games
   Expected: No memory warnings
```

---

## 📊 ANALYTICS TESTS

### Test 25: XP Transaction Safety
```
1. Complete 2 games simultaneously (if possible)
2. Check Firestore
   Expected: Both XP updates recorded correctly
   Expected: No lost XP
3. Check local SharedPreferences
   Expected: Matches Firestore
```

### Test 26: Streak Calculation
```
1. Login on Day 1
2. Complete quiz
3. Login on Day 2
4. Complete quiz
   Expected: Streak = 2
5. Skip Day 3
6. Login on Day 4
   Expected: Streak reset to 1
```

---

## ✅ ACCEPTANCE CRITERIA

**All tests must pass before production deployment:**

- [ ] All security tests pass (1-3)
- [ ] All offline tests pass (4-5)
- [ ] All quiz tests pass (6-12)
- [ ] All game tests pass (13-15)
- [ ] Orientation lock works (16)
- [ ] Network handling works (17-18)
- [ ] User flows work (19-21)
- [ ] Edge cases handled (22-24)
- [ ] Analytics accurate (25-26)

---

## 🚨 FAILURE PROTOCOL

If any test fails:
1. Document the failure
2. Check `COMPREHENSIVE_FIXES.md` for solution
3. Apply fix
4. Re-run failed test
5. Run full test suite again

---

## 📝 TEST REPORT TEMPLATE

```
Test Date: ___________
Tester: ___________
Device: ___________
OS Version: ___________

RESULTS:
- Security Tests: ___/3 passed
- Offline Tests: ___/2 passed
- Quiz Tests: ___/7 passed
- Game Tests: ___/3 passed
- Rotation Tests: ___/1 passed
- Network Tests: ___/2 passed
- User Flow Tests: ___/3 passed
- Edge Case Tests: ___/3 passed
- Analytics Tests: ___/2 passed

TOTAL: ___/26 passed

CRITICAL FAILURES:
(List any critical test failures)

NOTES:
(Additional observations)
```

---

**Estimated Testing Time**: 2-3 hours for complete test suite
**Recommended**: Run tests after each major fix, then full suite before deployment
