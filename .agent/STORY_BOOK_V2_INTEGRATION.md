# 🔗 Story Book V2 - Integration Examples

## Quick Launch Examples

### Example 1: Simple Test Launch

Add a test button anywhere to try Story Book V2:

```dart
import 'package:gravity_app/screens/story_book_v2_screen.dart';

// In any screen:
FilledButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoryBookV2Screen(),
      ),
    );
  },
  child: const Text('Try Story Book V2'),
),
```

---

### Example 2: Add to Curriculum Screen

Modify `curriculum_screen.dart` to offer both lesson formats:

```dart
// In _buildLessonCard method or similar:
Card(
  child: Column(
    children: [
      ListTile(
        title: const Text('Lesson 1 - Subjects'),
        subtitle: const Text('First, Second, Third Person'),
      ),
      
      // Add format selection buttons
      Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                // Original format
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LessonSubjectsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Interactive'),
            ),
          ),
          
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                // NEW: Story Book V2 format
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StoryBookV2Screen(),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book),
              label: const Text('Story Book'),
            ),
          ),
        ],
      ),
    ],
  ),
),
```

---

### Example 3: A/B Testing Integration

Randomly assign users to different formats:

```dart
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/screens/story_book_v2_screen.dart';
import 'package:gravity_app/screens/lesson_subjects_screen.dart';

Future<void> launchLesson1WithABTest(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  
  // Check if user already has an assignment
  bool? useStoryBookV2 = prefs.getBool('ab_test_story_book_v2');
  
  if (useStoryBookV2 == null) {
    // First time - randomly assign (50/50 split)
    useStoryBookV2 = Random().nextBool();
    await prefs.setBool('ab_test_story_book_v2', useStoryBookV2);
    
    // Track assignment
    AnalyticsService().logEvent(
      'ab_test_assigned',
      parameters: {
        'test': 'lesson_format',
        'variant': useStoryBookV2 ? 'story_book_v2' : 'original',
      },
    );
  }
  
  if (useStoryBookV2) {
    // Treatment: Story Book V2
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoryBookV2Screen(),
      ),
    );
  } else {
    // Control: Original lesson
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LessonSubjectsScreen(),
      ),
    );
  }
}

// Usage:
onTap: () => launchLesson1WithABTest(context),
```

---

### Example 4: User Choice with Preferences

Let users choose their preferred format:

```dart
// In settings or lesson menu:
class LessonFormatSetting extends StatefulWidget {
  @override
  State<LessonFormatSetting> createState() => _LessonFormatSettingState();
}

class _LessonFormatSettingState extends State<LessonFormatSetting> {
  String _preferredFormat = 'interactive'; // or 'story_book_v2'
  
  @override
  void initState() {
    super.initState();
    _loadPreference();
  }
  
  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _preferredFormat = prefs.getString('lesson_format') ?? 'interactive';
    });
  }
  
  Future<void> _savePreference(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lesson_format', format);
    setState(() {
      _preferredFormat = format;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Lesson Format'),
      subtitle: Text(_preferredFormat == 'story_book_v2' 
        ? 'Story Book' 
        : 'Interactive'),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Choose Lesson Format'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Interactive'),
                  subtitle: const Text('Character dialogue and scenes'),
                  value: 'interactive',
                  groupValue: _preferredFormat,
                  onChanged: (value) {
                    if (value != null) {
                      _savePreference(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Story Book'),
                  subtitle: const Text('Image-based pages'),
                  value: 'story_book_v2',
                  groupValue: _preferredFormat,
                  onChanged: (value) {
                    if (value != null) {
                      _savePreference(value);
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Then in lesson launch:
Future<void> launchLesson1(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final format = prefs.getString('lesson_format') ?? 'interactive';
  
  if (format == 'story_book_v2') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoryBookV2Screen(),
      ),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LessonSubjectsScreen(),
      ),
    );
  }
}
```

---

### Example 5: Test Mode Toggle (Developer Only)

Add a developer toggle in settings:

```dart
// In settings screen:
if (kDebugMode) {
  SwitchListTile(
    title: const Text('Enable Story Book V2'),
    subtitle: const Text('Use new lesson format (experimental)'),
    value: _useStoryBookV2,
    onChanged: (value) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('force_story_book_v2', value);
      setState(() {
        _useStoryBookV2 = value;
      });
    },
  );
}

// Then check in lesson launch:
Future<void> launchLesson1(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final forceV2 = prefs.getBool('force_story_book_v2') ?? false;
  
  if (forceV2) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoryBookV2Screen(),
      ),
    );
  } else {
    // Use default logic
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LessonSubjectsScreen(),
      ),
    );
  }
}
```

---

## 📊 Analytics Comparison

### Tracking Different Metrics:

```dart
// For Story Book V2:
class StoryBookV2Analytics {
  static void trackPageView(int pageNumber, String pageTitle) {
    AnalyticsService().logEvent(
      'story_book_v2_page_view',
      parameters: {
        'page': pageNumber,
        'title': pageTitle,
        'lesson': 'subjects',
      },
    );
  }
  
  static void trackCompletion() {
    AnalyticsService().logEvent(
      'story_book_v2_completed',
      parameters: {
        'lesson': 'subjects',
        'total_pages': 8,
      },
    );
  }
  
  static void trackTimeSpent(Duration duration) {
    AnalyticsService().logEvent(
      'story_book_v2_time_spent',
      parameters: {
        'lesson': 'subjects',
        'seconds': duration.inSeconds,
      },
    );
  }
}

// Compare with existing lesson tracking:
// - story_book_v2_page_view vs lesson_subjects_step
// - story_book_v2_completed vs lesson_subjects_completed
// - story_book_v2_time_spent vs lesson_subjects_duration
```

---

## 🎯 Recommended Integration

**For Production Launch**, I recommend **Example 3 (A/B Testing)**:

1. **Silent Assignment**: Users automatically assigned to A or B group
2. **Consistent Experience**: Same user always sees same format
3. **Clean Comparison**: 50/50 split for valid statistics
4. **Easy Rollback**: Just flip the percentage if needed

```dart
// Recommended production code:
Future<void> openLesson1(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  
  // Get or assign experiment variant
  bool? isVariantB = prefs.getBool('lesson1_variant_b');
  if (isVariantB == null) {
    // New user - assign randomly (50/50)
    isVariantB = Random().nextBool();
    await prefs.setBool('lesson1_variant_b', isVariantB);
    
    AnalyticsService().logEvent(
      'experiment_assigned',
      parameters: {
        'experiment': 'lesson1_format',
        'variant': isVariantB ? 'B_storybook' : 'A_interactive',
      },
    );
  }
  
  // Launch appropriate format
  if (isVariantB) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoryBookV2Screen(),
      ),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LessonSubjectsScreen(),
      ),
    );
  }
}
```

---

**All integration examples are ready to use!** 🚀

Just choose the one that fits your testing strategy best.
