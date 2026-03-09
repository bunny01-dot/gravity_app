import 'package:gravity_app/services/sfx/sfx_manager.dart';
import 'package:gravity_app/services/sfx/sfx_models.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // Bridge to SfxManager

  bool get isSfxEnabled => SfxManager().isEnabled;

  Future<void> setSfxEnabled(bool enabled) async {
    await SfxManager().setEnabled(enabled);
  }

  Future<void> reloadSettings() async {
    await SfxManager().init();
  }

  // Different sounds for different actions

  /// Light tap/click sound for button presses
  Future<void> playTap() async {
    await SfxManager().play(SfxAction.buttonTap);
  }

  /// Sound when user submits an answer (neutral)
  Future<void> playAnswer() async {
    await SfxManager().play(SfxAction.minimalClick);
  }

  /// Positive sound for correct answer
  Future<void> playCorrect() async {
    await SfxManager().play(SfxAction.answerCorrect);
  }

  /// Gentle sound for wrong answer (not harsh)
  Future<void> playWrong() async {
    await SfxManager().play(SfxAction.answerWrong);
  }

  /// Success/completion sound for finishing a task
  Future<void> playCompletion() async {
    await SfxManager().play(SfxAction.levelComplete);
  }

  /// Special celebratory sound for level up or achievements
  Future<void> playLevelUp() async {
    await SfxManager().play(SfxAction.xpGain);
  }

  /// Error sound for critical errors
  Future<void> playError() async {
    await SfxManager().play(SfxAction.validationError);
  }

  /// Mic Start Sound
  Future<void> playMicStart() async {
    await SfxManager().play(SfxAction.toggleOn);
  }

  /// Mic Stop/Processing Sound
  Future<void> playMicStop() async {
    await SfxManager().play(SfxAction.selectionMade);
  }

  /// Bookmark/Black Hole Add sound
  Future<void> playBookmarkAdd() async {
    await SfxManager().play(SfxAction.bookmarkAdd);
  }

  /// Bookmark/Black Hole Remove sound
  Future<void> playBookmarkRemove() async {
    await SfxManager().play(SfxAction.bookmarkRemove);
  }

  // Legacy methods for backward compatibility
  @Deprecated('Use playCorrect() instead')
  Future<void> playSuccess() async => playCorrect();
}
