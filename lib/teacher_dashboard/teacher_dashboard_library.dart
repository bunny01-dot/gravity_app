// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api

part of 'teacher_dashboard_screen.dart';

extension TeacherDashboardLibrary on _TeacherDashboardState {
  Widget _buildLevelHeader(String title) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: onSurface.withValues(alpha: 0.42),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  List<_LibraryEntry> _buildLibraryEntries(List<Map<String, String>> items) {
    final grouped = <String, List<Map<String, String>>>{};
    for (final item in items) {
      final level = _resolveLevel(item);
      grouped.putIfAbsent(level, () => []).add(item);
    }

    final levels = grouped.keys.toList()
      ..sort((a, b) {
        final weightA = _levelWeight(a);
        final weightB = _levelWeight(b);
        if (weightA != weightB) return weightA.compareTo(weightB);
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    final entries = <_LibraryEntry>[];
    for (final level in levels) {
      entries.add(_LibraryEntry.header(level));
      final sectionItems = grouped[level] ?? const [];
      for (final item in sectionItems) {
        entries.add(_LibraryEntry.item(item));
      }
    }
    return entries;
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

  Widget _buildItemCard(Map<String, String> item, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    String title =
        item['word'] ??
        item['title'] ??
        item['focus'] ??
        item['id'] ??
        'Unknown';
    String subtitle =
        item['meaning'] ??
        item['passage'] ??
        item['instruction'] ??
        item['prompt'] ??
        item['question'] ??
        item['input'] ?? // Added for Writing
        '';

    // Truncate subtitle
    if (subtitle.length > 50) subtitle = "${subtitle.substring(0, 50)}...";

    return Dismissible(
      key: Key("${_selectedCategory}_$index"),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) =>
          _confirmDeleteLibraryItem(item: item, title: title),
      onDismissed: (direction) => _handleLibraryItemDismissed(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E2C)
              : Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.62),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF4FACFE)),
              onPressed: () => _handleEditItemTap(item, index),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, String> item, int index) {
    // Dynamically build text controllers for each key/value
    final Map<String, TextEditingController> controllers = {};
    item.forEach((key, value) {
      if (key != '_index') {
        controllers[key] = TextEditingController(text: value);
      }
    });

    showModernDialog(
      context,
      title: "Edit Item",
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: controllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                controller: entry.value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: entry.key.toUpperCase(),
                  labelStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.62),
                    fontSize: 10,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines:
                    entry.key == 'meaning' ||
                        entry.key == 'passage' ||
                        entry.key == 'instruction' ||
                        entry.key == 'hindi' || // Multiline for translations
                        entry.key == 'tamil' ||
                        entry.key == 'input' || // Multiline for prompts
                        entry.key == 'answer'
                    ? 3
                    : 1,
              ),
            );
          }).toList(),
        ),
      ),
      primaryButtonText: "Save",
      onPrimaryPressed: () => _handleSaveEditedItem(controllers, index),
      secondaryButtonText: "Cancel",
      onSecondaryPressed: () => _handleCloseRootDialog(context),
      icon: Icons.edit_note_rounded,
      accentColor: const Color(0xFF4FACFE),
    );
  }

  void _showImportCsvDialog() {
    final urlController = TextEditingController();
    String selectedType = _selectedCategory;

    showModernDialog(
      context,
      title: "Import CSV Data",
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "CSV URL",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.72),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: "https://example.com/data.csv",
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Data Type",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.72),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: selectedType,
                  dropdownColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2C2C3E)
                      : Colors.white,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => _handleImportTypeChanged(
                    setState,
                    (val) => selectedType = val,
                    value,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      primaryButtonText: "Import",
      onPrimaryPressed: () =>
          _handleImportCsvSubmit(urlController, selectedType),
      secondaryButtonText: "Cancel",
      onSecondaryPressed: () => _handleCloseDialog(context),
      icon: Icons.cloud_download_rounded,
      accentColor: const Color(0xFFFFD700),
    );
  }
}
