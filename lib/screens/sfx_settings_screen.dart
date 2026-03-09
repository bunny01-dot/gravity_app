import 'package:flutter/material.dart';
import 'package:gravity_app/services/sfx/sfx_manager.dart';
import 'package:gravity_app/services/sfx/sfx_models.dart';
import 'package:gravity_app/services/sfx/sfx_library.dart';

class SfxSettingsScreen extends StatefulWidget {
  const SfxSettingsScreen({super.key});

  @override
  State<SfxSettingsScreen> createState() => _SfxSettingsScreenState();
}

class _SfxSettingsScreenState extends State<SfxSettingsScreen> {
  final SfxManager _sfxManager = SfxManager();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _sfxManager.init();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sound Effects'),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Defaults',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await _sfxManager.resetToDefaults();
              setState(() {});
              messenger.showSnackBar(
                const SnackBar(content: Text('Reset to default settings')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMasterControls(),
          const SizedBox(height: 24),
          _buildQuickModes(),
          const SizedBox(height: 24),
          _buildCategoryVolumes(),
          const SizedBox(height: 24),
          _buildActionMappings(),
        ],
      ),
    );
  }

  Widget _buildMasterControls() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Master Controls',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Enable/Disable Toggle
            SwitchListTile(
              title: Text(
                'Enable Sound Effects',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              subtitle: Text(
                _sfxManager.isEnabled ? 'Sounds are ON' : 'Sounds are OFF',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              value: _sfxManager.isEnabled,
              onChanged: (value) async {
                await _sfxManager.setEnabled(value);
                if (value) await _sfxManager.play(SfxAction.toggleOn);
                setState(() {});
              },
              activeThumbColor: const Color(0xFF4FACFE),
            ),

            Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),

            // Master Volume
            Text(
              'Master Volume',
              style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
            ),
            Row(
              children: [
                Icon(Icons.volume_down, color: colorScheme.onSurfaceVariant),
                Expanded(
                  child: Slider(
                    value: _sfxManager.masterVolume,
                    onChanged: _sfxManager.isEnabled
                        ? (value) async {
                            await _sfxManager.setMasterVolume(value);
                            setState(() {});
                          }
                        : null,
                    onChangeEnd: (value) {
                      _sfxManager.play(SfxAction.minimalConfirm);
                    },
                    activeColor: const Color(0xFF4FACFE),
                  ),
                ),
                Icon(Icons.volume_up, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  '${(_sfxManager.masterVolume * 100).toInt()}%',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickModes() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Modes',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              title: Text(
                'Focus Mode',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              subtitle: Text(
                'Minimal, non-distracting sounds only',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              value: _sfxManager.focusMode,
              onChanged: (value) async {
                await _sfxManager.setFocusMode(value);
                if (value) await _sfxManager.play(SfxAction.minimalConfirm);
                setState(() {});
              },
              activeThumbColor: Colors.greenAccent,
            ),

            SwitchListTile(
              title: Text(
                'Night Mode',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              subtitle: Text(
                'Quieter sounds (50% volume)',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              value: _sfxManager.nightMode,
              onChanged: (value) async {
                await _sfxManager.setNightMode(value);
                if (value) await _sfxManager.play(SfxAction.minimalConfirm);
                setState(() {});
              },
              activeThumbColor: Colors.deepPurpleAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryVolumes() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Volumes',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...SfxCategory.values.map((category) {
              final volume =
                  _sfxManager.preferences.categoryVolumes[category] ?? 1.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: volume,
                            onChanged: _sfxManager.isEnabled
                                ? (value) async {
                                    await _sfxManager.setCategoryVolume(
                                      category,
                                      value,
                                    );
                                    setState(() {});
                                  }
                                : null,
                            activeColor: _getCategoryColor(category),
                          ),
                        ),
                        Text(
                          '${(volume * 100).toInt()}%',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMappings() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customize Sounds (Advanced)',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap any action to change its sound',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),

            // Show a few key actions for customization
            ..._getKeyActions().map((action) => _buildActionRow(action)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(SfxAction action) {
    final colorScheme = Theme.of(context).colorScheme;
    final soundId = _sfxManager.preferences.actionToSoundMap[action];
    final sound = soundId != null ? SfxLibrary.getSound(soundId) : null;

    return ListTile(
      title: Text(
        _formatActionName(action),
        style: TextStyle(color: colorScheme.onSurface),
      ),
      subtitle: Text(
        sound?.name ?? 'Not assigned',
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Color(0xFF4FACFE)),
            onPressed: () {
              if (soundId != null) _sfxManager.previewSound(soundId);
            },
          ),
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ],
      ),
      onTap: () => _showSoundPicker(action),
    );
  }

  void _showSoundPicker(SfxAction action) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surface,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Select Sound',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...SfxLibrary.sounds.map(
            (sound) => ListTile(
              title: Text(
                sound.name,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              subtitle: Text(
                '${sound.category.label}  ${sound.durationMs}ms',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow, color: Color(0xFF4FACFE)),
                onPressed: () => _sfxManager.previewSound(sound.id),
              ),
              onTap: () async {
                await _sfxManager.mapActionToSound(action, sound.id);
                setState(() {});
                if (!context.mounted) return;
                Navigator.pop(context);
                _sfxManager.play(action);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<SfxAction> _getKeyActions() {
    return [
      SfxAction.buttonTap,
      SfxAction.answerCorrect,
      SfxAction.answerWrong,
      SfxAction.levelComplete,
      SfxAction.validationError,
      SfxAction.notificationReceived,
    ];
  }

  String _formatActionName(SfxAction action) {
    return action.name
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getCategoryColor(SfxCategory category) {
    switch (category) {
      case SfxCategory.ui:
        return const Color(0xFF4FACFE);
      case SfxCategory.learn:
        return Colors.greenAccent;
      case SfxCategory.progress:
        return Colors.amber;
      case SfxCategory.error:
        return Colors.redAccent;
      case SfxCategory.system:
        return Colors.purpleAccent;
      case SfxCategory.minimal:
        return Colors.grey;
    }
  }
}
