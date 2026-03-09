import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/tutorial_service.dart';
import 'package:gravity_app/services/analytics_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logEvent('tutorial_started');
  }

  void _skip() {
    AnalyticsService().logEvent('tutorial_skipped');
    TutorialService().markOnboardingSeen();
    Navigator.of(context).pop();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      AnalyticsService().logEvent('tutorial_completed');
      TutorialService().markOnboardingSeen();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF030305)
          : theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.62),
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomeScreen(),
                  _buildDailyTasksScreen(isDark: isDark, onSurface: onSurface),
                  _buildGamesAndMasteryScreen(
                    isDark: isDark,
                    onSurface: onSurface,
                  ),
                ],
              ),
            ),

            // Page Indicator
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? primary
                              : onSurface.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next/Get Started Button
                  FilledButton(
                    onPressed: _nextPage,
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage == 2 ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation: Dashboard cards
          Container(
                width: 280,
                height: 180,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.black87,
                              size: 48,
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.1, 1.1),
                              duration: 1.seconds,
                            ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your Progress',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.2, end: 0, duration: 600.ms),

          const SizedBox(height: 48),

          // Text
          Text(
            'Welcome back!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : onSurface,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

          const SizedBox(height: 16),

          Text(
            'Let\'s improve your English every day.',
            style: TextStyle(
              fontSize: 18,
              color: isDark
                  ? Colors.white70
                  : onSurface.withValues(alpha: 0.78),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

          const SizedBox(height: 8),

          Text(
            'Learn a little daily. Progress steadily.',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white38
                  : onSurface.withValues(alpha: 0.56),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildDailyTasksScreen({
    required bool isDark,
    required Color onSurface,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation: Checklist with ticking icons
          Container(
            width: 280,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E2C)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
                    : onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                _buildChecklistItem(
                  Icons.history_edu_rounded,
                  'Quiz',
                  0,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildChecklistItem(
                  Icons.menu_book_rounded,
                  'Vocabulary',
                  1,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildChecklistItem(
                  Icons.change_circle_rounded,
                  'Verbs',
                  2,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildChecklistItem(
                  Icons.mic_rounded,
                  'Speak',
                  3,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms),

          const SizedBox(height: 48),

          // Text
          Text(
            'Daily Tasks are your main goal.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : onSurface,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

          const SizedBox(height: 16),

          Text(
            'Learn vocabulary, verb forms, and pronunciation every day.',
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? Colors.white70
                  : onSurface.withValues(alpha: 0.78),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
    IconData icon,
    String label,
    int index, {
    required bool isDark,
    required Color onSurface,
  }) {
    return Row(
      children: [
        Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: Colors.black87, size: 20),
            )
            .animate(delay: (index * 400).ms)
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(),
        const SizedBox(width: 16),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ).animate(delay: (index * 400).ms).fadeIn(),
      ],
    );
  }

  Widget _buildGamesAndMasteryScreen({
    required bool isDark,
    required Color onSurface,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation: Lock  Unlock
          Stack(
            alignment: Alignment.center,
            children: [
              // Games Card
              Container(
                width: 280,
                height: 140,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4FACFE)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sports_esports_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Games Arcade',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms),

              // Lock icon that disappears
              Icon(Icons.lock_rounded, size: 64, color: Colors.black87)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .then(delay: 1.seconds)
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(0, 0),
                    duration: 400.ms,
                  )
                  .fadeOut(),
            ],
          ),

          const SizedBox(height: 32),

          // Mastery Cards Preview
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniMasteryCard(
                Icons.book_rounded,
                'Reading',
                0,
                isDark: isDark,
                onSurface: onSurface,
              ),
              const SizedBox(width: 12),
              _buildMiniMasteryCard(
                Icons.headphones_rounded,
                'Listening',
                1,
                isDark: isDark,
                onSurface: onSurface,
              ),
              const SizedBox(width: 12),
              _buildMiniMasteryCard(
                Icons.mic_rounded,
                'Speaking',
                2,
                isDark: isDark,
                onSurface: onSurface,
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Text
          Text(
            'Games unlock after learning.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : onSurface,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

          const SizedBox(height: 16),

          Text(
            'Mastery helps you build real skills over time.',
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? Colors.white70
                  : onSurface.withValues(alpha: 0.78),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildMiniMasteryCard(
    IconData icon,
    String label,
    int index, {
    required bool isDark,
    required Color onSurface,
  }) {
    return Container(
          width: 72,
          height: 80,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E2C)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF4FACFE), size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? Colors.white70
                      : onSurface.withValues(alpha: 0.74),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
        .animate(delay: (1500 + index * 200).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.3, end: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
