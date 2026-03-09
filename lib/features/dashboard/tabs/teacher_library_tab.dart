import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/data_service.dart' as data_service;
import 'package:gravity_app/widgets/modern_glass_dialog.dart';
import 'package:gravity_app/widgets/refresh_lottie_loader.dart';
import 'package:gravity_app/features/daily_sentences/daily_sentence_service.dart';
import 'package:gravity_app/screens/library_category_screen.dart';

class TeacherLibraryTab extends StatefulWidget {
  const TeacherLibraryTab({super.key});

  @override
  State<TeacherLibraryTab> createState() => _TeacherLibraryTabState();
}

class _TeacherLibraryTabState extends State<TeacherLibraryTab> {
  Map<String, int> _itemCounts = {};
  Map<String, Map<String, int>> _itemCountsByLevel = {};
  List<String> _orderedLevels = [];
  bool _isLoadingCounts = true;

  @override
  void initState() {
    super.initState();
    _loadItemCounts();
  }

  Future<void> _loadItemCounts() async {
    final ds = data_service.DataService();
    Map<String, int> newCounts = {};
    Map<String, Map<String, int>> newCountsByLevel = {};
    final baseLevels = ['Beginner', 'Intermediate', 'Advanced'];

    try {
      // Load all data first to ensure cache is populated
      // Note: This might be heavy, but necessary for accurate counts if not already loaded
      // Optimization: DataService could expose just counts, but for now we fetch lists

      final types = [
        'vocabulary',
        'verbs',
        'reading',
        'writing',
        'speaking',
        'listening',
        'quiz',
      ];
      for (var type in types) {
        final items = await ds.getAllItems(type);
        newCounts[type] = items.length;
        for (final item in items) {
          final level = _resolveLevel(item);
          final levelCounts = newCountsByLevel.putIfAbsent(
            level,
            () => <String, int>{},
          );
          levelCounts[type] = (levelCounts[type] ?? 0) + 1;
        }
      }

      // Daily Sentences counts are handled separately in DailySentenceService or hidden
      // We'll skip for now or just generic logic

      for (final level in baseLevels) {
        newCountsByLevel.putIfAbsent(level, () => <String, int>{});
      }

      final orderedLevels = newCountsByLevel.keys.toList()
        ..sort((a, b) {
          final weightA = _levelWeight(a);
          final weightB = _levelWeight(b);
          if (weightA != weightB) return weightA.compareTo(weightB);
          return a.toLowerCase().compareTo(b.toLowerCase());
        });

      if (mounted) {
        setState(() {
          _itemCounts = newCounts;
          _itemCountsByLevel = newCountsByLevel;
          _orderedLevels = orderedLevels;
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading library counts: $e");
      if (mounted) setState(() => _isLoadingCounts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Content Library"),
          const Text(
            "Browse and manage learning materials by category.",
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 16),

          _isLoadingCounts
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: RefreshLottieLoader(
                    message: "Loading library...",
                    subtitle: "Counting synced content by level",
                  ),
                )
              : Column(
                  children: [
                    for (final level in _orderedLevels)
                      _buildLevelSection(level),
                    const SizedBox(height: 16),
                    _buildSectionHeader("External Content"),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.1,
                      children: [
                        _buildCategoryCard(
                          "Sentences",
                          "sentences",
                          Icons.short_text_rounded,
                          Colors.cyanAccent,
                          isExternal: true,
                          countOverride: null,
                        ),
                      ],
                    ),
                  ],
                ),

          const SizedBox(height: 40),
          _buildSectionHeader("Data Management Tools"),
          const Text(
            "Sync and maintenance tools for database administrators.",
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Compact Tools Section
          Container(
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _buildToolTile(
                  "Refresh Cloud Content",
                  "Reloads all data from configured sources.",
                  Icons.refresh_rounded,
                  Colors.orangeAccent,
                  _handleRefreshData,
                ),
                Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                _buildToolTile(
                  "Sync via CSV URL",
                  "Import data from a Google Sheet link.",
                  Icons.link_rounded,
                  Colors.greenAccent,
                  _handleSyncFromSheet,
                ),
                Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                _buildToolTile(
                  "Wipe All Data",
                  "Factory reset all clearable library data.",
                  Icons.delete_forever_rounded,
                  Colors.redAccent,
                  _handleWipeAllData,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader("Daily Sentences Sync"),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _buildDailySentenceSyncRow("Beginner", Colors.greenAccent),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withValues(alpha: 0.05)),
                const SizedBox(height: 8),
                _buildDailySentenceSyncRow("Intermediate", Colors.orangeAccent),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withValues(alpha: 0.05)),
                const SizedBox(height: 8),
                _buildDailySentenceSyncRow("Advanced", Colors.redAccent),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    String type,
    IconData icon,
    Color color, {
    bool isExternal = false,
    int? countOverride,
  }) {
    final count = countOverride ?? (_itemCounts[type] ?? 0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isExternal) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "External content cannot be edited here directly.",
                  ),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LibraryCategoryScreen(
                  categoryType: type,
                  title: title,
                  themeColor: color,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isExternal ? "Managed Externally" : "$count items",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
      onTap: onTap,
    );
  }

  // Helper for UI

  Future<void> _handleSyncFromSheet() async {
    // 1. Get Saved URL
    final prefs = await SharedPreferences.getInstance();
    String currentUrl = prefs.getString('google_sheet_url') ?? '';

    // 2. Show Input Dialog
    if (!mounted) return;
    TextEditingController controller = TextEditingController(text: currentUrl);
    final newUrl = await showModernDialog<String>(
      context,
      title: "Google Sheet CSV Link",
      message: "Enter the 'Published to Web' CSV link of your Google Sheet.",
      content: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "https://docs.google.com/.../pub?output=csv",
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      primaryButtonText: "Sync Now",
      onPrimaryPressed: () => Navigator.pop(context, controller.text.trim()),
      secondaryButtonText: "Cancel",
      onSecondaryPressed: () => Navigator.pop(context),
      icon: Icons.link_rounded,
      accentColor: const Color(0xFF4FACFE),
    );

    if (newUrl == null || newUrl.isEmpty) return;

    // 3. Save URL
    await prefs.setString('google_sheet_url', newUrl);

    // 4. Show Loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (c) => const RefreshLottieLoader(
        message: "Syncing data...",
        subtitle: "Applying latest Google Sheet updates",
      ),
    );

    // 5. Call DataService
    final success = await data_service.DataService().adminSyncFromUrlToCloud(
      newUrl,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cloud synced successfully from Google Sheet!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sync failed. Check the URL and try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleRefreshData() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (c) => const RefreshLottieLoader(
        message: "Refreshing library...",
        subtitle: "Syncing latest content stats",
      ),
    );

    try {
      // Force refresh in DataService
      await data_service.DataService().forceRefreshData();

      // Wait a bit for effect
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data cache cleared and reloaded successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error refreshing data: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleWipeAllData() async {
    // Confirm Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset All Library Data?"),
        content: const Text(
          "This will erase all custom vocabulary, verbs, daily task history, and reset synced URLs. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Wipe Everything"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const RefreshLottieLoader(
        message: "Wiping all data...",
        subtitle: "Cleaning local and cloud library records",
      ),
    );

    try {
      // 1. Wipe Daily Sentence Service Local Data
      await DailySentenceService().resetData();

      // 2. Wipe General Data Service (Memory, Prefs, Cloud)
      await data_service.DataService().wipeAllLibraryData();

      if (mounted) {
        Navigator.pop(context); // Close Loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All Library Data & History Wiped Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close Loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error wiping data: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildDailySentenceSyncRow(String level, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "$level Sentences",
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        TextButton.icon(
          onPressed: () => _handleDailySentenceSync(level),
          icon: const Icon(Icons.sync_rounded, size: 20),
          label: Text("Sync $level"),
          style: TextButton.styleFrom(
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: color.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDailySentenceSync(String level) async {
    final prefs = await SharedPreferences.getInstance();
    String currentUrl = prefs.getString('daily_sentences_url_$level') ?? '';

    if (!mounted) return;
    TextEditingController controller = TextEditingController(text: currentUrl);
    final newUrl = await showModernDialog<String>(
      context,
      title: "Sync $level Sentences",
      message: "Enter the Google Sheet CSV link for $level sentences.",
      content: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "https://docs.google.com/.../pub?output=csv",
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      primaryButtonText: "Sync Now",
      onPrimaryPressed: () => Navigator.pop(context, controller.text.trim()),
      secondaryButtonText: "Cancel",
      onSecondaryPressed: () => Navigator.pop(context),
      icon: Icons.sync_rounded,
      accentColor: Colors.cyanAccent,
    );

    if (newUrl == null || newUrl.isEmpty) return;

    await prefs.setString('daily_sentences_url_$level', newUrl);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => RefreshLottieLoader(
        message: "Syncing $level...",
        subtitle: "Pulling latest daily sentence rows",
      ),
    );

    final success = await DailySentenceService().importCsvFromUrl(
      newUrl,
      level,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? "$level sentences synced successfully!"
                : "Failed to sync $level sentences.",
          ),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  // --- Helpers ---
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF1E1E2C).withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildLevelSection(String level) {
    final counts = _itemCountsByLevel[level] ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLevelHeader(level),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          children: [
            _buildCategoryCard(
              "Vocabulary",
              "vocabulary",
              Icons.menu_book_rounded,
              Colors.purpleAccent,
              countOverride: counts['vocabulary'] ?? 0,
            ),
            _buildCategoryCard(
              "Verbs",
              "verbs",
              Icons.directions_run_rounded,
              Colors.orangeAccent,
              countOverride: counts['verbs'] ?? 0,
            ),
            _buildCategoryCard(
              "Reading",
              "reading",
              Icons.article_rounded,
              Colors.blueAccent,
              countOverride: counts['reading'] ?? 0,
            ),
            _buildCategoryCard(
              "Writing",
              "writing",
              Icons.edit_note_rounded,
              Colors.greenAccent,
              countOverride: counts['writing'] ?? 0,
            ),
            _buildCategoryCard(
              "Speaking",
              "speaking",
              Icons.mic_rounded,
              Colors.redAccent,
              countOverride: counts['speaking'] ?? 0,
            ),
            _buildCategoryCard(
              "Listening",
              "listening",
              Icons.headphones_rounded,
              Colors.tealAccent,
              countOverride: counts['listening'] ?? 0,
            ),
            _buildCategoryCard(
              "Quizzes",
              "quiz",
              Icons.quiz_rounded,
              Colors.amberAccent,
              countOverride: counts['quiz'] ?? 0,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLevelHeader(String level) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        level.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  String _resolveLevel(Map<String, String> item) {
    final level = item['level']?.trim();
    if (level != null && level.isNotEmpty) return level;

    final difficulty = item['difficulty']?.trim();
    if (difficulty != null && difficulty.isNotEmpty) return difficulty;

    final diff = item['diff']?.trim();
    if (diff != null && diff.isNotEmpty) return diff;

    return 'All Levels';
  }

  int _levelWeight(String level) {
    final lower = level.toLowerCase();
    if (lower.contains('beginner') || lower.contains('a1')) return 0;
    if (lower.contains('intermediate') ||
        lower.contains('b1') ||
        lower.contains('b2')) {
      return 1;
    }
    if (lower.contains('advanced') || lower.contains('c1')) return 2;
    return 3;
  }
}
