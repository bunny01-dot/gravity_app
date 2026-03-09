import 'package:gravity_app/services/sfx/sfx_models.dart';

/// Default sound library with all available SFX
class SfxLibrary {
  static const List<SfxSound> sounds = [
    // ===== UI & Navigation =====
    SfxSound(
      id: 'soft_tap',
      name: 'Soft Tap',
      filePath: 'assets/sfx/ui/ui-click-43196.mp3',
      category: SfxCategory.ui,
      durationMs: 50,
      description: 'Gentle button tap',
    ),
    SfxSound(
      id: 'crisp_click',
      name: 'Crisp Click',
      filePath: 'assets/sfx/ui/ding-sound-246413.mp3',
      category: SfxCategory.ui,
      durationMs: 80,
      description: 'Sharp, clear click',
    ),
    SfxSound(
      id: 'slide_open',
      name: 'Slide Open',
      filePath: 'assets/sfx/ui/ui-sounds-pack-2-sound-1-358893.mp3',
      category: SfxCategory.ui,
      durationMs: 150,
      description: 'Smooth slide transition',
    ),
    SfxSound(
      id: 'slide_close',
      name: 'Slide Close',
      filePath: 'assets/sfx/ui/ui-sounds-pack-2-sound-8-358892.mp3',
      category: SfxCategory.ui,
      durationMs: 120,
      description: 'Gentle close sound',
    ),
    SfxSound(
      id: 'toggle_on',
      name: 'Toggle On',
      filePath: 'assets/sfx/ui/bubblepop-254773.mp3',
      category: SfxCategory.ui,
      durationMs: 100,
      description: 'Positive toggle activation',
    ),
    SfxSound(
      id: 'toggle_off',
      name: 'Toggle Off',
      filePath: 'assets/sfx/ui/ui-sound-off-270300.mp3',
      category: SfxCategory.ui,
      durationMs: 90,
      description: 'Soft toggle deactivation',
    ),
    SfxSound(
      id: 'tab_switch',
      name: 'Tab Switch',
      filePath: 'assets/sfx/ui/ui-pop-sound-316482.mp3',
      category: SfxCategory.ui,
      durationMs: 70,
      description: 'Quick tab change',
    ),

    // ===== Learning Interactions =====
    SfxSound(
      id: 'correct_short',
      name: 'Correct (Short)',
      filePath: 'assets/sfx/learn/button-4-214382.mp3',
      category: SfxCategory.learn,
      durationMs: 200,
      description: 'Brief success tone',
    ),
    SfxSound(
      id: 'correct_chime',
      name: 'Correct Chime',
      filePath: 'assets/sfx/learn/achive-sound-132273.mp3',
      category: SfxCategory.learn,
      durationMs: 250,
      description: 'Pleasant chime for correct answer',
    ),
    SfxSound(
      id: 'wrong_soft',
      name: 'Wrong (Soft)',
      filePath: 'assets/sfx/learn/button-press-382713.mp3',
      category: SfxCategory.learn,
      durationMs: 120,
      description: 'Gentle negative feedback',
    ),
    SfxSound(
      id: 'hint_pop',
      name: 'Hint Pop',
      filePath: 'assets/sfx/learn/hint_pop.mp3',
      category: SfxCategory.learn,
      durationMs: 80,
      description: 'Light hint reveal',
    ),
    SfxSound(
      id: 'flip_card',
      name: 'Card Flip',
      filePath: 'assets/sfx/learn/flip_card.mp3',
      category: SfxCategory.learn,
      durationMs: 100,
      description: 'Quick flip sound',
    ),
    SfxSound(
      id: 'drag_pickup',
      name: 'Drag Pickup',
      filePath: 'assets/sfx/learn/drag_pickup.mp3',
      category: SfxCategory.learn,
      durationMs: 60,
      description: 'Subtle lift sound',
    ),
    SfxSound(
      id: 'drag_drop',
      name: 'Drag Drop',
      filePath: 'assets/sfx/learn/drag_drop.mp3',
      category: SfxCategory.learn,
      durationMs: 90,
      description: 'Soft placement sound',
    ),

    // ===== Progress & Rewards =====
    SfxSound(
      id: 'level_complete',
      name: 'Level Complete',
      filePath: 'assets/sfx/progress/level-up-06-370051.mp3',
      category: SfxCategory.progress,
      durationMs: 250,
      description: 'Triumphant completion',
    ),
    SfxSound(
      id: 'xp_gain',
      name: 'XP Gain',
      filePath: 'assets/sfx/progress/xp-gain-magic-tone-453274.mp3',
      category: SfxCategory.progress,
      durationMs: 150,
      description: 'Experience points earned',
    ),
    SfxSound(
      id: 'badge_unlock',
      name: 'Badge Unlock',
      filePath: 'assets/sfx/progress/badge_unlock.mp3',
      category: SfxCategory.progress,
      durationMs: 200,
      description: 'Achievement unlocked',
    ),
    SfxSound(
      id: 'streak_continue',
      name: 'Streak Continue',
      filePath: 'assets/sfx/progress/streak_continue.mp3',
      category: SfxCategory.progress,
      durationMs: 120,
      description: 'Streak maintained',
    ),
    SfxSound(
      id: 'streak_broken',
      name: 'Streak Broken',
      filePath: 'assets/sfx/progress/streak_broken.mp3',
      category: SfxCategory.progress,
      durationMs: 180,
      description: 'Streak lost (empathetic)',
    ),

    // ===== Errors & Warnings =====
    SfxSound(
      id: 'error_soft',
      name: 'Error (Soft)',
      filePath: 'assets/sfx/error/error-09-206494.mp3',
      category: SfxCategory.error,
      durationMs: 100,
      description: 'Gentle error notification',
    ),
    SfxSound(
      id: 'error_beep',
      name: 'Error Beep',
      filePath: 'assets/sfx/error/error_beep.mp3',
      category: SfxCategory.error,
      durationMs: 80,
      description: 'Brief error tone',
    ),
    SfxSound(
      id: 'warning',
      name: 'Warning',
      filePath: 'assets/sfx/error/ui-8-warning-sound-effect-336254.mp3',
      category: SfxCategory.error,
      durationMs: 120,
      description: 'Attention needed',
    ),

    // ===== System Feedback =====
    SfxSound(
      id: 'save_success',
      name: 'Save Success',
      filePath: 'assets/sfx/system/servant-bell-ring-1-211684.mp3',
      category: SfxCategory.system,
      durationMs: 90,
      description: 'Data saved confirmation',
    ),
    SfxSound(
      id: 'sync_complete',
      name: 'Sync Complete',
      filePath: 'assets/sfx/system/sync_complete.mp3',
      category: SfxCategory.system,
      durationMs: 150,
      description: 'Synchronization finished',
    ),
    SfxSound(
      id: 'notification_soft',
      name: 'Notification',
      filePath: 'assets/sfx/system/new-notification-022-370046.mp3',
      category: SfxCategory.system,
      durationMs: 130,
      description: 'Gentle notification',
    ),

    // ===== Minimal / Accessibility =====
    SfxSound(
      id: 'minimal_click',
      name: 'Minimal Click',
      filePath: 'assets/sfx/minimal/click.mp3',
      category: SfxCategory.minimal,
      durationMs: 40,
      description: 'Ultra-short click',
    ),
    SfxSound(
      id: 'minimal_confirm',
      name: 'Minimal Confirm',
      filePath: 'assets/sfx/minimal/confirm.mp3',
      category: SfxCategory.minimal,
      durationMs: 50,
      description: 'Brief confirmation',
    ),
    SfxSound(
      id: 'minimal_error',
      name: 'Minimal Error',
      filePath: 'assets/sfx/minimal/error.mp3',
      category: SfxCategory.minimal,
      durationMs: 60,
      description: 'Quick error tone',
    ),
    SfxSound(
      id: 'minimal_success',
      name: 'Minimal Success',
      filePath: 'assets/sfx/minimal/success.mp3',
      category: SfxCategory.minimal,
      durationMs: 70,
      description: 'Quick success tone',
    ),
  ];

  /// Default action-to-sound mappings
  static Map<SfxAction, String> get defaultMappings => {
    // UI & Navigation
    SfxAction.buttonTap: 'soft_tap',
    SfxAction.screenOpen: 'slide_open',
    SfxAction.screenClose: 'slide_close',
    SfxAction.backAction: 'slide_close',
    SfxAction.toggleOn: 'toggle_on',
    SfxAction.toggleOff: 'toggle_off',
    SfxAction.tabSwitch: 'tab_switch',
    SfxAction.menuOpen: 'slide_open',
    SfxAction.menuClose: 'slide_close',
    SfxAction.modalOpen: 'slide_open',
    SfxAction.modalClose: 'slide_close',

    // Learning
    SfxAction.answerCorrect: 'crisp_click',
    SfxAction.answerWrong: 'wrong_soft',
    SfxAction.hintUsed: 'hint_pop',
    SfxAction.flashcardFlip: 'flip_card',
    SfxAction.dragStart: 'drag_pickup',
    SfxAction.dragDrop: 'drag_drop',
    SfxAction.selectionMade: 'soft_tap',

    // Progress
    SfxAction.levelComplete: 'level_complete',
    SfxAction.xpGain: 'xp_gain',
    SfxAction.badgeEarned: 'badge_unlock',
    SfxAction.streakContinued: 'streak_continue',
    SfxAction.streakBroken: 'streak_broken',

    // Errors
    SfxAction.validationError: 'error_soft',
    SfxAction.networkError: 'error_beep',
    SfxAction.actionDenied: 'warning',

    // System
    SfxAction.saveSuccess: 'save_success',
    SfxAction.syncComplete: 'sync_complete',
    SfxAction.notificationReceived: 'notification_soft',
    SfxAction.bookmarkAdd: 'toggle_on',
    SfxAction.bookmarkRemove: 'toggle_off',

    // Minimal
    SfxAction.minimalClick: 'minimal_click',
    SfxAction.minimalConfirm: 'minimal_confirm',
    SfxAction.minimalError: 'minimal_error',
    SfxAction.minimalSuccess: 'minimal_success',
  };

  /// Focus mode mappings (minimal sounds only)
  static Map<SfxAction, String> get focusModeMappings => {
    SfxAction.buttonTap: 'minimal_click',
    SfxAction.answerCorrect: 'minimal_confirm',
    SfxAction.answerWrong: 'minimal_error',
    SfxAction.levelComplete: 'minimal_success',
    SfxAction.validationError: 'minimal_error',
    // All others map to minimal_click or nothing
  };

  /// Get sound by ID
  static SfxSound? getSound(String id) {
    try {
      return sounds.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get sounds by category
  static List<SfxSound> getSoundsByCategory(SfxCategory category) {
    return sounds.where((s) => s.category == category).toList();
  }
}
