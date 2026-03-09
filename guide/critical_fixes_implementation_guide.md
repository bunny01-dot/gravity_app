# Critical Fixes Implementation Guide
**Date:** 2026-02-03  
**Status:** Ready for Implementation

---

## 🎯 Overview

This document outlines the implementation plan for 7 critical bug fixes that address data persistence, UI consistency, and user experience issues in the Gravity App.

---

## 1️⃣ Daily Verb Forms - Switch from Popup to Full Page

### Problem
Daily Verb Forms currently opens in a popup/bottom sheet, causing:
- Content hidden due to scroll issues
- Awkward navigation
- Poor UX for large content

### Solution
Create dedicated full-screen page with proper scroll behavior.

#### Files to Create:
**`lib/screens/daily_verb_detail_screen.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/tts_service.dart';

class DailyVerbDetailScreen extends StatefulWidget {
  final Map<String, dynamic> verb;
  final String preferredLanguage;
  
  const DailyVerbDetailScreen({
    Key? key,
    required this.verb,
    required this.preferredLanguage,
  }) : super(key: key);

  @override
  State<DailyVerbDetailScreen> createState() => _DailyVerbDetailScreenState();
}

class _DailyVerbDetailScreenState extends State<DailyVerbDetailScreen> {
  final TtsService _ttsService = TtsService();

  @override
  Widget build(BuildContext context) {
    final verb = widget.verb;
    final meaning = widget.preferredLanguage == 'Tamil' 
        ? verb['Tamil'] ?? verb['Meaning']
        : verb['Hindi'] ?? verb['Meaning'];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
     appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verb Forms',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Meaning Card
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.translate, color: Color(0xFF4FACFE), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Meaning',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    meaning ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Verb Forms Card
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.change_circle, color: Color(0xFFC779D0), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Three Forms',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildVerbRow('V1 (Base)', verb['V1'] ?? 'N/A'),
                  const Divider(height: 24, color: Colors.white10),
                  _buildVerbRow('V2 (Past)', verb['V2'] ?? 'N/A'),
                  const Divider(height: 24, color: Colors.white10),
                  _buildVerbRow('V3 (Participle)', verb['V3'] ?? 'N/A'),
                ],
              ),
            ),
            
            // Examples (if present)
            if (verb['Example'] != null && verb['Example'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Color(0xFFFFC107), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Example',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      verb['Example'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildVerbRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.volume_up, color: Color(0xFF4FACFE), size: 20),
              onPressed: () => _ttsService.speak(value),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }
}
```

#### Files to Modify:
**`lib/dashboard.dart`** - Replace bottom sheet with Navigator.push:
```dart
// FIND the onVerbsTap callback (around line 1570-1571)
// REPLACE:
onVerbsTap: () => _handleTaskTap("Daily Verb Forms", 'verbs', 'task_verbs'),

// WITH:
onVerbsTap: () async {
  SoundService().playTap();
  AnalyticsService().logEvent('daily_verb_tapped');
  
  // Fetch today's verb
  final verb = await _dataService.getTodaysVerb();
  if (verb != null && mounted) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyVerbDetailScreen(
          verb: verb,
          preferredLanguage: _preferredLanguage,
        ),
      ),
    );
    // Refresh progress
    await _checkDailyProgress();
  }
},
```

**Add import at top of dashboard.dart:**
```dart
import 'package:gravity_app/screens/daily_verb_detail_screen.dart';
```

---

## 2️⃣ Blackhole Icon Consistency

### Problem
Blackhole icon inconsistent across Dashboard, Mastery Page, and Daily Task cards.

### Solution
Create centralized icon widget.

#### Files to Create:
**`lib/widgets/blackhole_icon.dart`**
```dart
import 'package:flutter/material.dart';

class BlackholeIcon extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final bool showGlow;

  const BlackholeIcon({
    Key? key,
    this.size = 24,
    this.onTap,
    this.showGlow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.blur_on,
      color: Colors.white,
      size: size,
    );

    if (!showGlow) {
      return onTap != null
          ? IconButton(
              icon: icon,
              onPressed: onTap,
              tooltip: 'Black Hole (Difficult Words)',
            )
          : icon;
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9E86FF).withOpacity(0.6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: onTap != null
          ? IconButton(
              icon: icon,
              onPressed: onTap,
              tooltip: 'Black Hole (Difficult Words)',
            )
          : icon,
    );
  }
}
```

#### Files to Modify:
**`lib/dashboard.dart`** (around line 690-720):
```dart
// REPLACE:
IconButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BlackHoleScreen(),
      ),
    );
  },
  icon: Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF9E86FF).withOpacity(0.6),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ],
    ),
    child: const Icon(
      Icons.blur_on,
      color: Colors.white,
    ),
  ),
  tooltip: "Black Hole (Difficult Words)",
),

// WITH:
BlackholeIcon(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BlackHoleScreen(),
      ),
    );
  },
),
```

**Add import:**
```dart
import 'package:gravity_app/widgets/blackhole_icon.dart';
```

**Repeat for:**
- `lib/widgets/mastery_page.dart` or mastery screens
- `lib/features/dashboard/widgets/daily_task_card.dart`

---

## 3️⃣ Vocabulary History Reset Bug

### Problem
Vocabulary history resets and doesn't respect join date.

### Solution
Fix history loading to strictly use join date and persist properly.

#### Files to Modify:
**`lib/screens/vocabulary_history_screen.dart`**

FIND the history loading logic and ADD join date validation:
```dart
Future<void> _loadHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;
  
  if (user== null) return;

  // Get join date
  String? startDateStr = prefs.getString('progress_start_date') ??
      prefs.getString('learning_start_date');
  
  if (startDateStr == null) {
    // Fetch from Firestore if not in prefs
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    startDateStr = userDoc.data()?['progress_start_date'] as String?;
    
    if (startDateStr != null) {
      await prefs.setString('progress_start_date', startDateStr);
    }
  }
  
  final startDate = startDateStr != null 
      ? DateTime.parse(startDateStr)
      : DateTime.now();

  // Load history from Firebase/local
  // Filter to only show dates >= startDate
  // ...existing history load logic...
  
  setState(() {
    _joinDate = startDate;
    _historyData = historyData.where((entry) {
      final entryDate = DateTime.parse(entry['date']);
      return entryDate.isAfter(startDate) || entryDate.isAtSameMomentAs(startDate);
    }).toList();
  });
}
```

---

## 4️⃣ Mastery Page Content Empty

### Problem
- Mastery page loads empty on first open
- Loads only after app minimize/resume  
- Writing mastery always empty

### Solution
Fix lifecycle loading and CSV validation.

#### Files to Modify:
**`lib/widgets/mastery_card.dart` or mastery page file:**

```dart
@override
void initState() {
  super.initState();
  // Load immediately, don't wait for lifecycle
  _loadMasteryContent();
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Reload if dependencies change (e.g., difficulty sync)
  _loadMasteryContent();
}

Future<void> _loadMasteryContent() async {
  if (_isLoading) return; // Prevent duplicate loads
  
  setState(() => _isLoading = true);
  
  try {
    // Force refresh from DataService
    await _dataService.clearMemoryCache();
    
    final content = await _dataService.getMasteryContent(
      type: widget.masteryType,
      difficulty: await _dataService.getUserDifficulty(),
      language: await _dataService.getPreferredLanguage(),
    );
    
    if (mounted) {
      setState(() {
        _content = content;
        _isEmpty = content == null || content.isEmpty;
        _isLoading = false;
      });
    }
  } catch (e) {
    debugPrint('Mastery load error: $e');
    if (mounted) {
      setState(() {
        _isEmpty = true;
        _isLoading = false;
      });
    }
  }
}
```

**For Writing Mastery CSV check in `lib/services/data_service.dart`:**
```dart
Future<List<Map<String, dynamic>>> getWritingMastery() async {
  // Check if CSV exists
  final csvPath = 'assets/data/writing_mastery_${difficulty}.csv';
  
  try {
    final data = await rootBundle.loadString(csvPath);
    // Parse and return
  } catch (e) {
    debugPrint('Writing mastery CSV not found: $csvPath');
    // Return empty list with proper flag
    return [];
  }
}
```

---

## 5️⃣ Blackhole Quiz - Word Removal Logic

### Problems
1. Word not removed after "Remove" button
2. Hindi words appearing as options
3. Old-style notice cards

### Solution
Fix persistence, language filtering, and UI.

#### Files to Modify:
**`lib/screens/black_hole_screen.dart` (Quiz section):**

```dart
void _handleWordRemoval(String wordId) async {
  // 1. Remove from Blackhole
  await _dataService.removeFromBlackhole(wordId);
  
  // 2. Mark as learned
  await _dataService.markWordAsLearned(wordId);
  
  // 3. Persist to SharedPreferences AND Firestore
  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;
  
  Set<String> learnedIds = (prefs.getStringList('learned_vocab_ids') ?? []).toSet();
  learnedIds.add(wordId);
  await prefs.setStringList('learned_vocab_ids', learnedIds.toList());
  
  if (user != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'learned_vocab': FieldValue.arrayUnion([wordId]),
      'blackhole_words': FieldValue.arrayRemove([wordId]),
    }, SetOptions(merge: true));
  }
  
  // 4. Refresh quiz pool
  setState(() {
    _quizWords.removeWhere((word) => word['id'] == wordId);
  });
  
  // 5. Show confirmation
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Word removed from Black Hole!')),
  );
}
```

**Language Enforcement in Quiz Options:**
```dart
List<String> _generateQuizOptions(Map<String, dynamic> word) {
  final correctAnswer = _preferredLanguage == 'Tamil'
      ? word['Tamil'] ?? word['Meaning']
      : word['Hindi'] ?? word['Meaning'];
  
  // Get distractors in SAME language only
  final distractors = _allVocab
      .where((v) => v['id'] != word['id'])
      .map((v) => _preferredLanguage == 'Tamil'
          ? v['Tamil'] ?? v['Meaning']
          : v['Hindi'] ?? v['Meaning'])
      .where((meaning) => meaning != null && meaning != correctAnswer)
      .toList()
    ..shuffle();
  
  final options = [correctAnswer, ...distractors.take(3)];
  options.shuffle();
  return options;
}
```

---

## 6️⃣ Announcement Card Navigation Error

### Problem
Tapping announcement shows "All caught up" then "Error loading notification"

### Solution
Fix async loading and state management.

#### Files to Modify:
**`lib/features/dashboard/widgets/announcements_section.dart`:**

```dart
void _handleAnnouncementTap(String notificationId) async {
  if (notificationId.isEmpty) {
    debugPrint('Invalid notification ID');
    return;
  }
  
  // Show loading state
  if (mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  try {
    // Fetch notification data FIRST
    final notification = await FirebaseFirestore.instance
        .collection('announcements')
        .doc(notificationId)
        .get();
    
    if (!mounted) return;
    
    // Close loading
    Navigator.pop(context);
    
    if (!notification.exists) {
      throw Exception('Notification not found');
    }
    
    // Navigate with data
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          initialNotificationId: notificationId,
          notificationData: notification.data(),
        ),
      ),
    );
  } catch (e) {
    if (mounted) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notification: $e')),
      );
    }
  }
}
```

---

## 7️⃣ Final Validation Checklist

After implementing all fixes, verify:

- [ ] No Hindi words appear anywhere for Tamil users
- [ ] Mastery content loads on first open
- [ ] Writing mastery shows proper empty state if no CSV
- [ ] Blackhole quiz removes words permanently
- [ ] Removed words don't appear in games
- [ ] Announcement card opens cleanly without errors
- [ ] Vocabulary history never resets
- [ ] History respects join date
- [ ] Blackhole icon identical everywhere
- [ ] Daily Verb Forms opens as full page
- [ ] All changes persist across app restarts

---

## Implementation Order

1. **Blackhole Icon** (Simplest, affects multiple areas)
2. **Daily Verb Detail Screen** (Self-contained)
3. **Vocabulary History** (Data integrity)
4. **Mastery Page Loading** (User-facing)
5. **Blackhole Quiz Logic** (Complex, multiple parts)
6. **Announcement Navigation** (Async handling)
7. **Final Validation** (Test all changes)

---

## Testing Strategy

For each fix:
1. Test fresh install
2. Test after app restart
3. Test with poor connectivity
4. Test difficulty changes
5. Test language switches
6. Verify Firestore sync
7. Verify SharedPreferences persistence

---

**Status:** Ready for implementation  
**Estimated Time:** 4-6 hours for all fixes  
**Priority:** HIGH - These are critical UX issues
