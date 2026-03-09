import 'package:flutter/material.dart';
import 'package:gravity_app/widgets/lesson_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/analytics_service.dart';

/// Story Book V2 - Alternative lesson presentation mode
///
/// ISOLATED EXPERIMENT - Does NOT modify existing curriculum logic
/// Shows Lesson 1 (Subjects) as 8 sequential image-based pages
///
///  This is additive only - existing lessons remain unchanged
class StoryBookV2Screen extends StatefulWidget {
  const StoryBookV2Screen({super.key});

  @override
  State<StoryBookV2Screen> createState() => _StoryBookV2ScreenState();
}

class _StoryBookV2ScreenState extends State<StoryBookV2Screen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _lessonCompleted = false;

  // Fixed 8 pages in order - using EXACT asset paths from assets/Lessons/lesson_01_subjects/
  final List<LessonPage> _pages = const [
    // Page 1: First Person - Singular
    LessonPage(
      imagePath:
          'assets/Lessons/lesson_01_subjects/first_person/First_person.webp',
      title: 'First Person  Singular',
      subtitle: 'I',
      description: 'When we talk about ourselves',
    ),

    // Page 2: First Person - Plural
    LessonPage(
      imagePath:
          'assets/Lessons/lesson_01_subjects/first_person/First_person_plural.webp',
      title: 'First Person  Plural',
      subtitle: 'We',
      description: 'When we talk about ourselves and others',
    ),

    // Page 3: Second Person - Singular
    LessonPage(
      imagePath:
          'assets/Lessons/lesson_01_subjects/second_person/second_person.webp',
      title: 'Second Person  Singular',
      subtitle: 'You',
      description: 'When we talk to one person',
    ),

    // Page 4: Second Person - Plural
    LessonPage(
      imagePath:
          'assets/Lessons/lesson_01_subjects/second_person/second_person_plural.webp',
      title: 'Second Person  Plural',
      subtitle: 'You (all)',
      description: 'When we talk to multiple people',
    ),

    // Page 5: Third Person - He
    LessonPage(
      imagePath:
          'assets/Lessons/lesson_01_subjects/third_person/third_peron_singluar_he.webp',
      title: 'Third Person  He',
      subtitle: 'He',
      description: 'When we talk about a male person',
    ),

    // Page 6: Third Person - She
    LessonPage(
      imagePath:
          'assets/Lessons/lesson_01_subjects/third_person/third_peron_singluar_she.webp',
      title: 'Third Person  She',
      subtitle: 'She',
      description: 'When we talk about a female person',
    ),

    // Page 7: Third Person - It (things/animals/places)
    LessonPage(
      imagePath:
          'assets/Lessons/lesson_01_subjects/third_person/third_peron_singluar_things.webp',
      title: 'Third Person  It',
      subtitle: 'It',
      description: 'When we talk about things, animals, or places',
    ),

    // Page 8: Third Person - Plural
    LessonPage(
      imagePath:
          'assets/Lessons/lesson_01_subjects/third_person/third_person_plural.webp',
      title: 'Third Person  Plural',
      subtitle: 'They',
      description: 'When we talk about multiple people or things',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCompletion();

    // Analytics - isolated tracking for A/B testing
    AnalyticsService().logEvent('story_book_v2_opened', {
      'lesson_id': 'subjects',
      'format': 'image_based',
    });
  }

  Future<void> _loadCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final completed =
        prefs.getBool('lesson_1_subjects_quiz_completed') ?? false;
    final legacyCompleted = prefs.getBool('lesson1_quiz_completed') ?? false;
    if (mounted) {
      setState(() {
        _lessonCompleted = completed || legacyCompleted;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // OK: REMOVED: Navigation methods - no longer needed with PageView swipe gestures

  Future<bool> _onWillPop() async {
    if (_lessonCompleted) return true;
    if (_currentPage < 1) return true;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shouldExit = await showGeneralDialog<bool>(
      context: context,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: Dialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                    size: 60,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Leave Lesson?",
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Progress will be lost.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.redAccent.withValues(alpha: 0.7),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Exit",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent.withValues(
                              alpha: 0.2,
                            ),
                            foregroundColor: Colors.cyanAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            "Stay",
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
      },
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? const Color(0xFF030305)
        : theme.scaffoldBackgroundColor;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: Stack(
          children: [
            // Background (reusing existing lesson background style)
            _buildBackground(),

            // PageView - OK: UPDATED: Pure swipe navigation (no buttons)
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);

                // Analytics per page
                AnalyticsService().logEvent('story_book_v2_page_view', {
                  'page': (index + 1).toString(),
                  'title': _pages[index].title,
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildPage(_pages[index], index);
              },
            ),

            // Page Indicators (dots)
            _buildPageIndicators(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a237e).withValues(alpha: isDark ? 0.3 : 0.15),
            isDark ? const Color(0xFF030305) : theme.scaffoldBackgroundColor,
          ],
        ),
      ),
    );
  }

  // OK: UPDATED: Removed fadeIn animations for consistency
  Widget _buildPage(LessonPage page, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          // Title overlay (Flutter text) - No fadeIn animation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  page.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  page.subtitle,
                  style: TextStyle(
                    color: const Color(0xFF4FACFE).withValues(alpha: 0.9),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Image (main content) - No fadeIn animation
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4FACFE).withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LessonImage(
                  lessonId: 'subjects',
                  imageName: page.imagePath.split('lesson_01_subjects/').last,
                  fallbackAssetPath: page.imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Description overlay (Flutter text) - No fadeIn animation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              page.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // OK: REMOVED: Navigation buttons - now using pure swipe gestures only

  Widget _buildPageIndicators() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pages.length, (index) {
          final isActive = index == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF4FACFE)
                  : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

/// Data model for a single lesson page
class LessonPage {
  final String imagePath;
  final String title;
  final String subtitle;
  final String description;

  const LessonPage({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}

// OK: REMOVED: _NavButton widget - no longer needed with pure swipe navigation
