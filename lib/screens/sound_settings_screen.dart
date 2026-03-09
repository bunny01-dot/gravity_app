import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sfx/sfx_manager.dart';
import 'package:gravity_app/services/sfx/sfx_models.dart';
import 'package:gravity_app/services/sfx/sfx_library.dart';

class SoundSettingsScreen extends StatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  final SfxManager _sfxManager = SfxManager();
  late SfxPreferences _prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await _sfxManager.init();
    setState(() {
      _prefs = _sfxManager.preferences;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sound Themes',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await _sfxManager.resetToDefaults();
              await _loadPreferences();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Reset to default sounds'),
                  backgroundColor: Color(0xFFFF6B9D),
                ),
              );
            },
            icon: Icon(
              Icons.refresh_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            label: Text(
              'Reset',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildMasterControls(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Action Sounds'),
                  const SizedBox(height: 16),
                  ..._buildActionSoundCards(),
                  const SizedBox(height: 32),
                  _buildModeSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.music_note_rounded,
                color: colorScheme.onPrimary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Customize Your Sounds',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Choose different sound effects for each action to personalize your learning experience.',
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.92),
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildMasterControls() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Master Volume',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.volume_down_rounded,
                color: Color(0xFFFF6B9D),
                size: 20,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFFF6B9D),
                    inactiveTrackColor: colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                    thumbColor: colorScheme.onPrimary,
                    overlayColor: const Color(
                      0xFFFF6B9D,
                    ).withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _prefs.masterVolume,
                    onChanged: (val) async {
                      await _sfxManager.setMasterVolume(val);
                      setState(() => _prefs = _sfxManager.preferences);
                    },
                  ),
                ),
              ),
              const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFFFF6B9D),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                '${(_prefs.masterVolume * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFFFF6B9D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          Icons.audiotrack_rounded,
          color: colorScheme.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActionSoundCards() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final actions = [
      (SfxAction.buttonTap, 'Button Tap', Icons.touch_app_rounded),
      (SfxAction.answerCorrect, 'Correct Answer', Icons.check_circle_rounded),
      (SfxAction.answerWrong, 'Wrong Answer', Icons.cancel_rounded),
      (SfxAction.levelComplete, 'Task Complete', Icons.flag_rounded),
      (SfxAction.xpGain, 'XP Gained', Icons.star_rounded),
    ];

    return actions.map((tuple) {
      final action = tuple.$1;
      final label = tuple.$2;
      final icon = tuple.$3;
      final currentSoundId = _prefs.actionToSoundMap[action] ?? '';
      final currentSound = SfxLibrary.getSound(currentSoundId);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _showSoundPicker(action, label),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B9D).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFFFF6B9D), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentSound?.name ?? 'Select Sound',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildModeSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Focus Mode',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Minimal, non-distracting sounds',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            value: _prefs.focusMode,
            activeThumbColor: const Color(0xFFFF6B9D),
            onChanged: (val) async {
              await _sfxManager.setFocusMode(val);
              setState(() => _prefs = _sfxManager.preferences);
            },
          ),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Night Mode',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Softer volume (50% quieter)',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            value: _prefs.nightMode,
            activeThumbColor: const Color(0xFFFF6B9D),
            onChanged: (val) async {
              await _sfxManager.setNightMode(val);
              setState(() => _prefs = _sfxManager.preferences);
            },
          ),
        ],
      ),
    );
  }

  void _showSoundPicker(SfxAction action, String actionLabel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Get all available sounds from the library
    final availableSounds = SfxLibrary.sounds
        .where(
          (s) => s.category != SfxCategory.minimal,
        ) // Exclude minimal category sounds from selection
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Sound for $actionLabel',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableSounds.length,
                itemBuilder: (context, index) {
                  final sound = availableSounds[index];
                  final isSelected =
                      _prefs.actionToSoundMap[action] == sound.id;

                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? const Color(0xFFFF6B9D)
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    title: Text(
                      sound.name,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      sound.description,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        color: Color(0xFF4FACFE),
                      ),
                      onPressed: () => _sfxManager.previewSound(sound.id),
                    ),
                    onTap: () async {
                      await _sfxManager.mapActionToSound(action, sound.id);
                      setState(() => _prefs = _sfxManager.preferences);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
