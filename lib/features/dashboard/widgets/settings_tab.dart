import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/screens/sound_settings_screen.dart';
import 'package:gravity_app/services/app_theme_service.dart';
import 'package:gravity_app/services/analytics_service.dart';
import 'package:lottie/lottie.dart';

class SettingsTab extends StatefulWidget {
  final Function() onLogout;
  final ValueChanged<String>? onLanguageChanged;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  const SettingsTab({
    super.key,
    required this.onLogout,
    this.onLanguageChanged,
    this.currentThemeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab>
    with SingleTickerProviderStateMixin {
  final DataService _dataService = DataService();

  String _preferredLanguage = 'Tamil';
  bool _autoPlayAudio = true;
  bool _sfxEnabled = true;
  bool _notificationsEnabled = true;
  late ThemeMode _themeMode;
  late final VoidCallback _themeModeListener;
  late final AnimationController _themeToggleController;

  @override
  void initState() {
    super.initState();
    _themeMode = AppThemeService.themeModeNotifier.value;
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _themeToggleController = AnimationController(
      vsync: this,
      value: _lottieProgressForTheme(
        _resolveIsDarkForMode(_themeMode, platformBrightness),
      ),
    );
    _themeModeListener = () {
      if (!mounted) return;
      setState(() {
        _themeMode = AppThemeService.themeModeNotifier.value;
      });
      _syncThemeToggleProgress(animate: true);
    };
    AppThemeService.themeModeNotifier.addListener(_themeModeListener);
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncThemeToggleProgress(animate: false);
  }

  @override
  void didUpdateWidget(covariant SettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentThemeMode != widget.currentThemeMode) {
      _themeMode = widget.currentThemeMode;
      _syncThemeToggleProgress(animate: false);
    }
  }

  @override
  void dispose() {
    AppThemeService.themeModeNotifier.removeListener(_themeModeListener);
    _themeToggleController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await SoundService().reloadSettings();
    if (!mounted) return;
    setState(() {
      _preferredLanguage = prefs.getString('preferred_language') ?? 'Tamil';
      _autoPlayAudio = prefs.getBool('auto_play_audio') ?? true;
      _sfxEnabled = SoundService().isSfxEnabled;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _updateLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_language', language);
    await _dataService.saveProgressToCloud('preferred_language', language);
    AnalyticsService().logEvent('setting_changed_language');
    if (!mounted) return;
    setState(() {
      _preferredLanguage = language;
    });
    widget.onLanguageChanged?.call(language);
  }

  Future<void> _saveAudioSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_play_audio', _autoPlayAudio);
    await _dataService.saveProgressToCloud('auto_play_audio', _autoPlayAudio);
  }

  Future<void> _updateThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    setState(() {
      _themeMode = mode;
    });
    _syncThemeToggleProgress(animate: true);
    await AppThemeService.setThemeMode(mode);
    widget.onThemeModeChanged?.call(mode);
    AnalyticsService().logEvent('setting_changed_theme_${mode.name}');
  }

  bool _resolveIsDarkForMode(ThemeMode mode, Brightness platformBrightness) {
    switch (mode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return platformBrightness == Brightness.dark;
    }
  }

  bool _effectiveIsDark(BuildContext context) {
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    return _resolveIsDarkForMode(_themeMode, platformBrightness);
  }

  double _lottieProgressForTheme(bool isDark) => isDark ? 0.52 : 0.02;

  void _syncThemeToggleProgress({required bool animate}) {
    if (!mounted) return;
    final targetProgress = _lottieProgressForTheme(_effectiveIsDark(context));
    if (animate) {
      _themeToggleController.animateTo(
        targetProgress,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _themeToggleController.value = targetProgress;
  }

  Future<void> _toggleManualThemeWithLottie() async {
    final isDark = _effectiveIsDark(context);
    final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
    await _updateThemeMode(nextMode);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService().logEvent('settings_opened');
    });

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final secondaryText = onSurface.withValues(alpha: 0.68);
    final mutedText = onSurface.withValues(alpha: 0.5);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModernSectionHeader('Appearance', Icons.palette_rounded),
          const SizedBox(height: 16),
          _buildThemeSettingCard(context),
          const SizedBox(height: 32),
          _buildModernSectionHeader('Preferences', Icons.tune_rounded),
          const SizedBox(height: 16),
          _buildModernSettingCard(
            context: context,
            title: 'Language',
            subtitle: 'Select your primary learning language',
            icon: Icons.language_rounded,
            color: Colors.blueAccent,
            content: Column(
              children: [
                _buildModernRadioOption('Tamil', Colors.orange),
                const SizedBox(height: 12),
                _buildModernRadioOption('Hindi', Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildModernSectionHeader('Audio & Haptics', Icons.volume_up_rounded),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _modernCardDecoration(context, Colors.pinkAccent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Auto-play Audio',
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Recommended for better pronunciation',
                    style: TextStyle(color: secondaryText, fontSize: 13),
                  ),
                  value: _autoPlayAudio,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    setState(() => _autoPlayAudio = val);
                    _saveAudioSettings();
                  },
                ),
                Divider(color: onSurface.withValues(alpha: 0.12), height: 32),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Sound Effects',
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Play success and error sounds',
                    style: TextStyle(color: secondaryText, fontSize: 13),
                  ),
                  value: _sfxEnabled,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    setState(() => _sfxEnabled = val);
                    SoundService().setSfxEnabled(val);
                    _dataService.saveProgressToCloud('sfx_enabled', val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SoundSettingsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: _modernCardDecoration(
                context,
                const Color(0xFFFF6B9D),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: onSurface.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Color(0xFFFF6B9D),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sound Themes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Customize sound effects for actions',
                          style: TextStyle(color: secondaryText, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: onSurface.withValues(alpha: 0.3),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildModernSectionHeader(
            'Alerts',
            Icons.notifications_active_rounded,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _modernCardDecoration(context, Colors.cyanAccent),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Notifications',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Announcements and reminders',
                style: TextStyle(color: secondaryText, fontSize: 13),
              ),
              value: _notificationsEnabled,
              activeThumbColor: theme.colorScheme.primary,
              onChanged: (val) async {
                setState(() => _notificationsEnabled = val);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('notifications_enabled', val);
                await _dataService.saveProgressToCloud(
                  'notifications_enabled',
                  val,
                );

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      val
                          ? 'Daily reminders enabled'
                          : 'Daily reminders disabled',
                    ),
                    backgroundColor: val
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF9800),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Version 3.0.0  Gravity App',
              style: TextStyle(color: mutedText, fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildModernSectionHeader(String title, IconData icon) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, color: onSurface.withValues(alpha: 0.7), size: 20),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: onSurface.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSettingCard(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return _buildModernSettingCard(
      context: context,
      title: 'Theme',
      subtitle: 'Use system theme or choose manually',
      icon: Icons.color_lens_rounded,
      color: primary,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildThemeLottieToggle(context)],
      ),
    );
  }

  Widget _buildThemeLottieToggle(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final isSystem = _themeMode == ThemeMode.system;
    final isDark = _effectiveIsDark(context);
    final effectiveThemeLabel = isDark ? 'Dark' : 'Light';
    final subtitle = isSystem
        ? 'Auto from device ($effectiveThemeLabel)'
        : 'Manual mode ($effectiveThemeLabel)';
    final cardColors = isDark
        ? [
            const Color(0xFF0D1422).withValues(alpha: 0.92),
            primary.withValues(alpha: 0.2),
          ]
        : [
            Colors.white.withValues(alpha: 0.95),
            primary.withValues(alpha: 0.1),
          ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSystem
              ? primary.withValues(alpha: 0.52)
              : onSurface.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 18,
            spreadRadius: -9,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Light / Dark Theme',
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.68),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Use device theme',
                child: InkWell(
                  onTap: () => _updateThemeMode(ThemeMode.system),
                  customBorder: const CircleBorder(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSystem
                          ? primary.withValues(alpha: 0.24)
                          : onSurface.withValues(alpha: 0.06),
                      border: Border.all(
                        color: isSystem
                            ? primary
                            : onSurface.withValues(alpha: 0.2),
                      ),
                      boxShadow: isSystem
                          ? [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.34),
                                blurRadius: 14,
                                spreadRadius: -8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.phone_android_rounded,
                      size: 20,
                      color: isSystem
                          ? primary
                          : onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _toggleManualThemeWithLottie,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: ShapeDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.88),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.24)
                        : onSurface.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.light_mode_rounded,
                    size: 17,
                    color: isDark
                        ? onSurface.withValues(alpha: 0.4)
                        : const Color(0xFFF9A825),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 126,
                        height: 64,
                        child: Lottie.asset(
                          'assets/lottie/Toggle dark mode light mode themes.json',
                          controller: _themeToggleController,
                          repeat: false,
                          fit: BoxFit.contain,
                          onLoaded: (composition) {
                            _themeToggleController.duration =
                                composition.duration;
                            _syncThemeToggleProgress(animate: false);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.dark_mode_rounded,
                    size: 17,
                    color: isDark
                        ? const Color(0xFF90CAF9)
                        : onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _modernCardDecoration(BuildContext context, Color accentColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? const Color(0xFF1E1E2C).withValues(alpha: 0.6)
          : Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: accentColor.withValues(alpha: isDark ? 0.08 : 0.04),
          blurRadius: 32,
          spreadRadius: -10,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  Widget _buildModernSettingCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _modernCardDecoration(context, color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.68),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: onSurface.withValues(alpha: 0.12), height: 32),
          content,
        ],
      ),
    );
  }

  Widget _buildModernRadioOption(String language, Color color) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isSelected = _preferredLanguage == language;
    return InkWell(
      onTap: () => _updateLanguage(language),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : onSurface.withValues(alpha: 0.18),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              language,
              style: TextStyle(
                color: onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20)
            else
              Icon(
                Icons.circle_outlined,
                color: onSurface.withValues(alpha: 0.34),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
