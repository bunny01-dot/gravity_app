import 'package:flutter/material.dart';
import 'package:gravity_app/services/data_service.dart';

class LibraryCategoryScreen extends StatefulWidget {
  final String categoryType;
  final String title;
  final Color themeColor;

  const LibraryCategoryScreen({
    super.key,
    required this.categoryType,
    required this.title,
    required this.themeColor,
  });

  @override
  State<LibraryCategoryScreen> createState() => _LibraryCategoryScreenState();
}

class _LibraryCategoryScreenState extends State<LibraryCategoryScreen> {
  final DataService _dataService = DataService();
  List<Map<String, String>> _items = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await _dataService.getAllItems(widget.categoryType);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading ${widget.categoryType}: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Filter logic
    final filteredItems = _items.where((item) {
      final searchContent = item.values.join(' ').toLowerCase();
      return searchContent.contains(_searchQuery.toLowerCase());
    }).toList();
    final entries = _buildEntries(filteredItems);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "Search ${widget.title}...",
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: isDark
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: widget.themeColor),
                  )
                : filteredItems.isEmpty
                ? Center(
                    child: Text(
                      "No items found.",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      if (entry.isHeader) {
                        return _buildLevelHeader(entry.header!);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildItemCard(entry.item!),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Add/Edit feature coming soon!"),
              backgroundColor: widget.themeColor,
            ),
          );
        },
        backgroundColor: widget.themeColor, // Use theme color
        foregroundColor: colorScheme.onPrimary, // Dark icon for contrast
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildItemCard(Map<String, String> item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Determine Title and Subtitle based on category
    String title = "Unknown Item";
    String subtitle = "";

    switch (widget.categoryType) {
      case 'vocabulary':
        title = item['word'] ?? "-";
        subtitle = "${item['type'] ?? ''} | ${item['meaning'] ?? ''}";
        break;
      case 'verbs':
        title = item['word'] ?? "-";
        subtitle = item['meaning'] ?? "";
        break;
      case 'reading':
        title = item['title'] ?? "Passage ${item['id']}";
        subtitle = "Level: ${item['level'] ?? '-'}";
        break;
      case 'writing':
        title = item['focus'] ?? "Writing Task";
        subtitle = item['instruction'] ?? "";
        break;
      case 'speaking':
        title = item['text'] ?? item['prompt'] ?? "Speaking Task";
        subtitle = item['category'] ?? item['task_type'] ?? "";
        break;
      case 'listening':
        title = item['title'] ?? "Listening Task";
        subtitle = item['question'] ?? "";
        break;
      case 'quiz':
        title = item['question'] ?? "Quiz Question";
        subtitle = "Ans: ${item['answer']}";
        break;
      default:
        title = item.values.firstOrNull ?? "-";
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.themeColor.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.themeColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            item['_index'] ?? '#',
            style: TextStyle(
              color: widget.themeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
      ),
    );
  }

  Widget _buildLevelHeader(String level) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6, left: 4),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  List<_LibraryListEntry> _buildEntries(List<Map<String, String>> items) {
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

    final entries = <_LibraryListEntry>[];
    for (final level in levels) {
      entries.add(_LibraryListEntry.header(level));
      final sectionItems = grouped[level] ?? const [];
      for (final item in sectionItems) {
        entries.add(_LibraryListEntry.item(item));
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
}

class _LibraryListEntry {
  final String? header;
  final Map<String, String>? item;

  const _LibraryListEntry._({this.header, this.item});

  factory _LibraryListEntry.header(String title) {
    return _LibraryListEntry._(header: title);
  }

  factory _LibraryListEntry.item(Map<String, String> item) {
    return _LibraryListEntry._(item: item);
  }

  bool get isHeader => header != null;
}
