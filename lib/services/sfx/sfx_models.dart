/// Comprehensive action types for SFX mapping
enum SfxAction {
  // ===== UI & Navigation =====
  buttonTap,
  screenOpen,
  screenClose,
  backAction,
  toggleOn,
  toggleOff,
  tabSwitch,
  menuOpen,
  menuClose,
  drawerSlide,
  modalOpen,
  modalClose,

  // ===== Learning Interactions =====
  answerCorrect,
  answerWrong,
  answerPartial,
  hintUsed,
  flashcardFlip,
  dragStart,
  dragDrop,
  dragCancel,
  typingFeedback,
  selectionMade,
  bookmarkAdd,
  bookmarkRemove,

  // ===== Progress & Rewards =====
  levelComplete,
  lessonComplete,
  quizPass,
  quizFail,
  xpGain,
  badgeEarned,
  achievementUnlocked,
  streakContinued,
  streakBroken,
  milestoneReached,

  // ===== Errors & Warnings =====
  validationError,
  networkError,
  actionDenied,
  timeout,
  warning,

  // ===== System Feedback =====
  saveSuccess,
  syncStart,
  syncComplete,
  syncFailed,
  notificationReceived,
  loadingComplete,
  refreshComplete,
  uploadSuccess,
  downloadComplete,

  // ===== Minimal / Accessibility =====
  minimalClick,
  minimalConfirm,
  minimalError,
  minimalSuccess,
}

/// Sound categories for organization
enum SfxCategory {
  ui('UI & Navigation'),
  learn('Learning'),
  progress('Progress & Rewards'),
  error('Errors & Warnings'),
  system('System'),
  minimal('Minimal');

  final String label;
  const SfxCategory(this.label);
}

/// Individual sound file definition
class SfxSound {
  final String id;
  final String name;
  final String filePath;
  final SfxCategory category;
  final int durationMs;
  final String description;

  const SfxSound({
    required this.id,
    required this.name,
    required this.filePath,
    required this.category,
    required this.durationMs,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filePath': filePath,
    'category': category.name,
    'durationMs': durationMs,
    'description': description,
  };

  factory SfxSound.fromJson(Map<String, dynamic> json) => SfxSound(
    id: json['id'],
    name: json['name'],
    filePath: json['filePath'],
    category: SfxCategory.values.firstWhere((c) => c.name == json['category']),
    durationMs: json['durationMs'],
    description: json['description'],
  );
}

/// User SFX preferences
class SfxPreferences {
  final bool enabled;
  final double masterVolume;
  final Map<SfxAction, String> actionToSoundMap; // Maps action to sound ID
  final bool focusMode; // Minimal sounds only
  final Map<SfxCategory, double> categoryVolumes;
  final bool nightMode; // Quieter sounds

  const SfxPreferences({
    this.enabled = true,
    this.masterVolume = 0.7,
    this.actionToSoundMap = const {},
    this.focusMode = false,
    this.categoryVolumes = const {},
    this.nightMode = false,
  });

  SfxPreferences copyWith({
    bool? enabled,
    double? masterVolume,
    Map<SfxAction, String>? actionToSoundMap,
    bool? focusMode,
    Map<SfxCategory, double>? categoryVolumes,
    bool? nightMode,
  }) {
    return SfxPreferences(
      enabled: enabled ?? this.enabled,
      masterVolume: masterVolume ?? this.masterVolume,
      actionToSoundMap: actionToSoundMap ?? this.actionToSoundMap,
      focusMode: focusMode ?? this.focusMode,
      categoryVolumes: categoryVolumes ?? this.categoryVolumes,
      nightMode: nightMode ?? this.nightMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'masterVolume': masterVolume,
    'actionToSoundMap': actionToSoundMap.map((k, v) => MapEntry(k.name, v)),
    'focusMode': focusMode,
    'categoryVolumes': categoryVolumes.map((k, v) => MapEntry(k.name, v)),
    'nightMode': nightMode,
  };

  factory SfxPreferences.fromJson(Map<String, dynamic> json) {
    return SfxPreferences(
      enabled: json['enabled'] ?? true,
      masterVolume: (json['masterVolume'] ?? 0.7).toDouble(),
      actionToSoundMap:
          (json['actionToSoundMap'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              SfxAction.values.firstWhere((a) => a.name == k),
              v as String,
            ),
          ) ??
          {},
      focusMode: json['focusMode'] ?? false,
      categoryVolumes:
          (json['categoryVolumes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              SfxCategory.values.firstWhere((c) => c.name == k),
              (v as num).toDouble(),
            ),
          ) ??
          {},
      nightMode: json['nightMode'] ?? false,
    );
  }
}
