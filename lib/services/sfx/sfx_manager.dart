import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sfx_models.dart';
import 'sfx_library.dart';
import '../data_service.dart';

/// Centralized SFX Manager for the entire app
class SfxManager {
  static final SfxManager _instance = SfxManager._internal();
  factory SfxManager() => _instance;
  SfxManager._internal();

  final AudioPlayer _player = AudioPlayer();
  SfxPreferences _preferences = const SfxPreferences();
  bool _isInitialized = false;

  /// Initialize the SFX system
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _loadPreferences();

      // Configure audio context for optimal playback
      // This ensures sounds play even if switch is on silent (on iOS) or mixes properly
      // Configure audio context for optimal playback
      // Using defaults to avoid platform interface assertions
      // final AudioContext audioContext = AudioContext(
      //   iOS: AudioContextIOS(
      //     category: AVAudioSessionCategory.ambient,
      //     options: {
      //       AVAudioSessionOptions.defaultToSpeaker,
      //       AVAudioSessionOptions.mixWithOthers,
      //     },
      //   ),
      //   android: AudioContextAndroid(
      //     isSpeakerphoneOn: true,
      //     stayAwake: false,
      //     contentType: AndroidContentType.sonification,
      //     usageType: AndroidUsageType.assistanceSonification,
      //     audioFocus: AndroidAudioFocus.none,
      //   ),
      // );
      // await AudioPlayer.global.setAudioContext(audioContext);

      await _player.setReleaseMode(ReleaseMode.stop);
      _isInitialized = true;
      debugPrint('OK: SfxManager initialized');
    } catch (e) {
      debugPrint('Error: SfxManager init failed: $e');
    }
  }

  /// Load user preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Load Local Immediately (Fast startup)
      final json = prefs.getString('sfx_preferences');

      if (json != null) {
        _preferences = SfxPreferences.fromJson(jsonDecode(json));
        debugPrint('OK: Loaded SFX preferences from local storage');
      } else {
        // First time - use defaults
        _preferences = SfxPreferences(
          actionToSoundMap: SfxLibrary.defaultMappings,
          categoryVolumes: {for (var cat in SfxCategory.values) cat: 1.0},
        );
        await _savePreferences();
        debugPrint('OK: Created default SFX preferences');
      }

      // 2. Sync from cloud in background (Don't await to prevent splash screen hang)
      _syncFromCloud();
    } catch (e) {
      debugPrint('Error loading SFX preferences: $e');
    }
  }

  /// Save preferences to storage and cloud
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_preferences.toJson());

      // Save locally first (immediate)
      await prefs.setString('sfx_preferences', jsonString);
      debugPrint('OK: Saved SFX preferences locally');

      // Sync to cloud (fire & forget to prevent UI blocking)
      _syncToCloud(jsonString);
    } catch (e) {
      debugPrint('Error saving SFX preferences: $e');
    }
  }

  /// Sync preferences to Firestore
  Future<void> _syncToCloud(String jsonString) async {
    try {
      final dataService = DataService();
      await dataService.saveProgressToCloud('sfx_preferences', jsonString);
      debugPrint(' Synced SFX preferences to cloud');
    } catch (e) {
      debugPrint('[WARN] Cloud sync failed (non-critical): $e');
      // Don't fail - local save is enough
    }
  }

  /// Sync preferences from Firestore
  Future<void> _syncFromCloud() async {
    try {
      // Sync all progress from cloud (includes sfx_preferences)
      final dataService = DataService();
      await dataService.syncProgressFromCloud();

      // Refresh memory from prefs after sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Ensure we see latest changes
      final json = prefs.getString('sfx_preferences');

      if (json != null) {
        final newPrefs = SfxPreferences.fromJson(jsonDecode(json));
        // Only update if changed prevents unnecessary object creation
        if (jsonEncode(newPrefs.toJson()) !=
            jsonEncode(_preferences.toJson())) {
          _preferences = newPrefs;
          debugPrint(' Updated in-memory SFX prefs from cloud sync');
        }
      }
      debugPrint(' Synced all progress from cloud (including SFX)');
    } catch (e) {
      debugPrint('[WARN] Cloud sync failed (using local): $e');
      // Don't fail - will use local version
    }
  }

  /// Play sound for a specific action
  Future<void> play(SfxAction action) async {
    if (!_isInitialized) await init();
    if (!_preferences.enabled) return;

    try {
      // Get mapped sound ID
      String? soundId;
      if (_preferences.focusMode) {
        soundId = SfxLibrary.focusModeMappings[action];
      } else {
        soundId = _preferences.actionToSoundMap[action];
      }

      if (soundId == null) return;

      // Get sound details
      final sound = SfxLibrary.getSound(soundId);
      if (sound == null) return;

      // Calculate final volume
      final categoryVolume =
          _preferences.categoryVolumes[sound.category] ?? 1.0;
      final nightModeMultiplier = _preferences.nightMode ? 0.5 : 1.0;
      final finalVolume =
          _preferences.masterVolume * categoryVolume * nightModeMultiplier;

      // Play sound (non-blocking)
      await _player.stop(); // Stop any previous sound
      await _player.setVolume(finalVolume);
      await _player.play(
        AssetSource(sound.filePath.replaceFirst('assets/', '')),
      );

      debugPrint(
        'SFX: $action -> ${sound.name} (vol: ${(finalVolume * 100).toInt()}%)',
      );
    } catch (e) {
      debugPrint('Error: Error playing SFX for $action: $e');
    }
  }

  /// Preview a specific sound (for settings UI)
  Future<void> previewSound(String soundId) async {
    if (!_isInitialized) await init();

    try {
      final sound = SfxLibrary.getSound(soundId);
      if (sound == null) return;

      await _player.stop();
      await _player.setVolume(_preferences.masterVolume);
      await _player.play(
        AssetSource(sound.filePath.replaceFirst('assets/', '')),
      );
    } catch (e) {
      debugPrint('Error previewing sound: $e');
    }
  }

  /// Update master enabled/disabled
  Future<void> setEnabled(bool enabled) async {
    _preferences = _preferences.copyWith(enabled: enabled);
    await _savePreferences();
  }

  /// Update master volume (0.0 - 1.0)
  Future<void> setMasterVolume(double volume) async {
    _preferences = _preferences.copyWith(masterVolume: volume.clamp(0.0, 1.0));
    await _savePreferences();
  }

  /// Update category volume
  Future<void> setCategoryVolume(SfxCategory category, double volume) async {
    final newVolumes = Map<SfxCategory, double>.from(
      _preferences.categoryVolumes,
    );
    newVolumes[category] = volume.clamp(0.0, 1.0);
    _preferences = _preferences.copyWith(categoryVolumes: newVolumes);
    await _savePreferences();
  }

  /// Update focus mode
  Future<void> setFocusMode(bool enabled) async {
    _preferences = _preferences.copyWith(focusMode: enabled);
    await _savePreferences();
  }

  /// Update night mode
  Future<void> setNightMode(bool enabled) async {
    _preferences = _preferences.copyWith(nightMode: enabled);
    await _savePreferences();
  }

  /// Map action to specific sound
  Future<void> mapActionToSound(SfxAction action, String soundId) async {
    final newMap = Map<SfxAction, String>.from(_preferences.actionToSoundMap);
    newMap[action] = soundId;
    _preferences = _preferences.copyWith(actionToSoundMap: newMap);
    await _savePreferences();
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    _preferences = SfxPreferences(
      actionToSoundMap: SfxLibrary.defaultMappings,
      categoryVolumes: {for (var cat in SfxCategory.values) cat: 1.0},
    );
    await _savePreferences();
  }

  // ===== Getters =====
  bool get isEnabled => _preferences.enabled;
  double get masterVolume => _preferences.masterVolume;
  bool get focusMode => _preferences.focusMode;
  bool get nightMode => _preferences.nightMode;
  SfxPreferences get preferences => _preferences;

  /// Dispose resources
  void dispose() {
    _player.dispose();
  }
}

