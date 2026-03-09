import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/data_service.dart';

class DifficultySettingsScreen extends StatefulWidget {
  const DifficultySettingsScreen({super.key});

  @override
  State<DifficultySettingsScreen> createState() =>
      _DifficultySettingsScreenState();
}

class _DifficultySettingsScreenState extends State<DifficultySettingsScreen> {
  final Map<String, String> _difficulties = {
    'reading': 'Beginner',
    'writing': 'Beginner',
    'listening': 'Beginner',
    'speaking': 'Beginner',
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _difficulties['reading'] =
          prefs.getString('difficulty_reading') ?? 'Beginner';
      _difficulties['writing'] =
          prefs.getString('difficulty_writing') ?? 'Beginner';
      _difficulties['listening'] =
          prefs.getString('difficulty_listening') ?? 'Beginner';
      _difficulties['speaking'] =
          prefs.getString('difficulty_speaking') ?? 'Beginner';
      _isLoading = false;
    });
  }

  Future<void> _updateDifficulty(String type, String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('difficulty_$type', level);
    // Sync to cloud
    await DataService().saveProgressToCloud('difficulty_$type', level);
    setState(() {
      _difficulties[type] = level;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Difficulty Levels"),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  "Customize Your Learning",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Set your proficiency level for each mastery section.",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                _buildDifficultyCard(
                  "Writing Mastery",
                  Icons.edit_note_rounded,
                  const Color(0xFFFEAC5E),
                  'writing',
                ),
                const SizedBox(height: 16),
                _buildDifficultyCard(
                  "Reading Mastery",
                  Icons.auto_stories_rounded,
                  const Color(0xFFC779D0),
                  'reading',
                ),
                const SizedBox(height: 16),
                _buildDifficultyCard(
                  "Listening Mastery",
                  Icons.headphones_rounded,
                  const Color(0xFFFE5196),
                  'listening',
                ),
                const SizedBox(height: 16),
                _buildDifficultyCard(
                  "Speaking Mastery",
                  Icons.record_voice_over_rounded,
                  const Color(0xFF4BC0C8),
                  'speaking',
                ),
              ],
            ),
    );
  }

  Widget _buildDifficultyCard(
    String title,
    IconData icon,
    Color color,
    String key,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: ['Beginner', 'Intermediate', 'Advanced'].map((level) {
              final isSelected = _difficulties[key] == level;
              Color activeColor;
              if (level == 'Beginner') {
                activeColor = Colors.greenAccent;
              } else if (level == 'Intermediate') {
                activeColor = Colors.orangeAccent;
              } else {
                activeColor = Colors.redAccent;
              }

              return InkWell(
                onTap: () => _updateDifficulty(key, level),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12, // Increased for better tap target
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? activeColor
                          : colorScheme.outlineVariant.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: isSelected
                          ? activeColor
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14, // Slightly scale up font
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
