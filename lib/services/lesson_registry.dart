import 'package:flutter/material.dart';
import '../models/lesson_config.dart';
import '../screens/lesson_subjects_screen.dart';
import '../screens/lesson_parts_of_speech_screen.dart';
import '../screens/lesson_present_tense_screen.dart';
import '../screens/lesson_present_continuous_screen.dart';
import '../screens/lesson_present_perfect_screen.dart';
import '../screens/lesson_present_perfect_continuous_screen.dart';
import '../screens/lesson_simple_past_screen.dart';
import '../screens/lesson_past_continuous_screen.dart';
import '../screens/lesson_past_perfect_screen.dart';
import '../screens/lesson_past_perfect_continuous_screen.dart';

import '../screens/lesson_simple_future_screen.dart';
import '../screens/lesson_future_continuous_screen.dart';
import '../screens/lesson_future_perfect_screen.dart';
import '../screens/lesson_future_perfect_continuous_screen.dart';
import '../screens/lesson_articles_screen.dart';

/// Centralized registry for all lessons in the curriculum
class LessonRegistry {
  // Singleton pattern
  static final LessonRegistry _instance = LessonRegistry._internal();
  factory LessonRegistry() => _instance;
  LessonRegistry._internal();

  /// Get all lesson groups
  List<LessonGroup> getAllLessonGroups() {
    return [
      _getPresentTenseGroup(),
      _getPastTenseGroup(),
      _getFutureTenseGroup(),
    ];
  }

  /// Get a specific lesson group by ID
  LessonGroup? getLessonGroup(String groupId) {
    try {
      return getAllLessonGroups().firstWhere((group) => group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  /// Present Tense Lesson Group
  LessonGroup _getPresentTenseGroup() {
    return LessonGroup(
      id: 'lesson_3_present',
      title: 'Lesson 3 - Tense - Present',
      subtitle: 'Select a branch to master',
      themeColor: const Color(0xFFFF9966), // Orange
      lessons: [
        LessonConfig(
          id: 'simple_present',
          title: '1. Simple Present',
          subtitle: 'Daily habits & facts',
          icon: Icons.check_circle_outline,
          isUnlocked: true,
          screenBuilder: () => const LessonPresentTenseScreen(),
          progressKey: 'lesson_3_simple_present_completed',
        ),
        LessonConfig(
          id: 'present_continuous',
          title: '2. Present Continuous',
          subtitle: 'Happening now',
          icon: Icons.check_circle_outline,
          isUnlocked: true,
          screenBuilder: () => const LessonPresentContinuousScreen(),
          progressKey: 'lesson_3_present_continuous_completed',
        ),
        LessonConfig(
          id: 'present_perfect',
          title: '3. Present Perfect',
          subtitle: 'Past connecting to now',
          icon: Icons.check_circle_outline,
          isUnlocked: true,
          screenBuilder: () => const LessonPresentPerfectScreen(),
          progressKey: 'lesson_3_present_perfect_completed',
        ),
        LessonConfig(
          id: 'present_perfect_continuous',
          title: '4. Present Perfect Continuous',
          subtitle: 'Duration of recent past',
          icon: Icons.check_circle_outline,
          isUnlocked: true,
          screenBuilder: () => const LessonPresentPerfectContinuousScreen(),
          progressKey: 'lesson_3_present_perfect_continuous_completed',
        ),
      ],
    );
  }

  /// Past Tense Lesson Group
  LessonGroup _getPastTenseGroup() {
    return LessonGroup(
      id: 'lesson_4_past',
      title: 'Lesson 4 - Tense - Past',
      subtitle: 'Select a branch to master',
      themeColor: const Color(0xFF00E676), // Green
      lessons: [
        LessonConfig(
          id: 'simple_past',
          title: '1. Simple Past',
          subtitle: 'Finished actions & yesterday',
          icon: Icons.check_circle_outline,
          isUnlocked: true,
          screenBuilder: () => const LessonSimplePastScreen(),
          progressKey: 'lesson_4_simple_past_completed',
        ),
        LessonConfig(
          id: 'past_continuous',
          title: '2. Past Continuous',
          subtitle: 'Was happening when...',
          icon: Icons.check_circle_outline,
          isUnlocked: true,
          screenBuilder: () => const LessonPastContinuousScreen(),
          progressKey: 'lesson_4_past_continuous_completed',
        ),
        LessonConfig(
          id: 'past_perfect',
          title: '3. Past Perfect',
          subtitle: 'Had happened before...',
          icon: Icons.check_circle_outline,
          isUnlocked: true,
          screenBuilder: () => const LessonPastPerfectScreen(),
          progressKey: 'lesson_4_past_perfect_completed',
        ),
        LessonConfig(
          id: 'past_perfect_continuous',
          title: '4. Past Perfect Continuous',
          subtitle: 'Had been happening...',
          icon: Icons.check_circle_outline,
          isUnlocked: true,
          screenBuilder: () => const LessonPastPerfectContinuousScreen(),
          progressKey: 'lesson_4_past_perfect_continuous_completed',
        ),
      ],
    );
  }

  /// Future Tense Lesson Group
  LessonGroup _getFutureTenseGroup() {
    return LessonGroup(
      id: 'lesson_5_future',
      title: 'Lesson 5 - Tense - Future',
      subtitle: 'Select a branch to master',
      themeColor: Colors.cyanAccent,
      lessons: [
        LessonConfig(
          id: 'simple_future',
          title: '1. Simple Future',
          subtitle: 'Predictions & Plans',
          icon: Icons.rocket_launch,
          isUnlocked: true,
          screenBuilder: () => const LessonSimpleFutureScreen(),
          progressKey: 'lesson_5_simple_future_completed',
        ),
        LessonConfig(
          id: 'future_continuous',
          title: '2. Future Continuous',
          subtitle: 'Will be doing...',
          icon: Icons.rocket_launch, // Unlocked visually or just icon
          isUnlocked: true, // Unlocked for viewing placehoder
          screenBuilder: () => const LessonFutureContinuousScreen(),
          progressKey: 'lesson_5_future_continuous_completed',
        ),
        LessonConfig(
          id: 'future_perfect',
          title: '3. Future Perfect',
          subtitle: 'Will have done...',
          icon: Icons.rocket_launch,
          isUnlocked: true,
          screenBuilder: () => const LessonFuturePerfectScreen(),
          progressKey: 'lesson_5_future_perfect_completed',
        ),
        LessonConfig(
          id: 'future_perfect_continuous',
          title: '4. Future Perf. Continuous',
          subtitle: 'Will have been doing...',
          icon: Icons.rocket_launch,
          isUnlocked: true,
          screenBuilder: () => const LessonFuturePerfectContinuousScreen(),
          progressKey: 'lesson_5_future_perfect_continuous_completed',
        ),
      ],
    );
  }

  /// Get standalone lessons (Lesson 1, 2, etc.)
  List<Map<String, dynamic>> getStandaloneLessons() {
    return [
      {
        'id': 'lesson_1_subjects',
        'title': 'Lesson 1 - Subjects',
        'hasStoryBook': true,
        'screenBuilder': () => const LessonSubjectsScreen(),
      },
      {
        'id': 'lesson_2_parts_of_speech',
        'title': 'Lesson 2 - Parts of Speech',
        'hasStoryBook': true,
        'screenBuilder': () => const LessonPartsOfSpeechScreen(),
      },
      {
        'id': 'lesson_2_articles',
        'title': 'Lesson 3 - Articles',
        'hasStoryBook': true,
        'screenBuilder': () => const LessonArticlesScreen(),
      },
    ];
  }
}
