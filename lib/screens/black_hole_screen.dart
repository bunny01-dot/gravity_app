import 'package:flutter/material.dart';
import 'package:gravity_app/models/verb_item.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/day_based_curriculum_service.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/screens/focused_quiz_screen.dart';
import 'package:gravity_app/screens/blackhole_item_detail_screen.dart';
import 'package:lottie/lottie.dart';

class BlackHoleScreen extends StatefulWidget {
  const BlackHoleScreen({super.key});

  @override
  State<BlackHoleScreen> createState() => _BlackHoleScreenState();
}

class _BlackHoleScreenState extends State<BlackHoleScreen> {
  final DataService _dataService = DataService();
  final DayBasedCurriculumService _curriculumService =
      DayBasedCurriculumService();
  List<Map<String, String>> _items = [];
  Map<String, VerbItem> _verbLookupByBase = {};
  bool _isLoading = true;
  String _preferredLanguage = 'Tamil';
  static const int _heavyThreshold = 10;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final preferredLanguage = await _dataService.getUserLanguage();

    // 1. Load Local Cache First (Fast)
    var items = await _dataService.getBlackHoleItems();
    items = await _enrichVerbItems(items);
    if (mounted) {
      setState(() {
        _preferredLanguage = preferredLanguage;
        _items = items;
        // Only stop loading if we actually have data.
        // If empty, keep loading until sync finishes to avoid flickering "Empty" state
        // if the user actually has data in cloud.
        if (items.isNotEmpty) _isLoading = false;
      });
    }

    // 2. Force Cloud Sync (Fresh Data)
    // This solves the issue where mobile doesn't see updates from other devices
    // if the app was in background or didn't sync on launch.
    await _dataService.syncProgressFromCloud();

    // 3. Reload from Local Cache (Updated)
    items = await _dataService.getBlackHoleItems();
    items = await _enrichVerbItems(items);
    if (mounted) {
      setState(() {
        _preferredLanguage = preferredLanguage;
        _items = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _ensureVerbLookup() async {
    if (_verbLookupByBase.isNotEmpty) return;

    try {
      await _curriculumService.initialize();
      final map = <String, VerbItem>{};
      for (final verb in _curriculumService.getAllVerbs()) {
        final key = verb.base.trim().toLowerCase();
        if (key.isEmpty) continue;
        map[key] = verb;
      }
      _verbLookupByBase = map;
    } catch (_) {
      _verbLookupByBase = {};
    }
  }

  Future<List<Map<String, String>>> _enrichVerbItems(
    List<Map<String, String>> items,
  ) async {
    final hasVerbItems = items.any(
      (item) => (item['type'] ?? '').toLowerCase() == 'verb',
    );
    if (!hasVerbItems) return items;

    await _ensureVerbLookup();
    if (_verbLookupByBase.isEmpty) return items;

    return items.map((item) {
      final type = (item['type'] ?? '').toLowerCase();
      if (type != 'verb') return item;

      final base = (item['word'] ?? item['title'] ?? '').trim().toLowerCase();
      if (base.isEmpty) return item;

      final verb = _verbLookupByBase[base];
      if (verb == null) return item;

      final enriched = Map<String, String>.from(item);
      enriched['v1'] = verb.base;
      enriched['v2'] = verb.past;
      enriched['v3'] = verb.pastParticiple;
      if ((enriched['tamil_meaning'] ?? '').trim().isEmpty) {
        enriched['tamil_meaning'] = verb.tamilMeaning;
      }
      if ((enriched['hindi_meaning'] ?? '').trim().isEmpty) {
        enriched['hindi_meaning'] = verb.hindiMeaning;
      }

      return enriched;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(
                  alpha: isDark ? 0.16 : 0.1,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                if (!_isLoading &&
                    _items.isNotEmpty &&
                    _items.length >= _heavyThreshold)
                  _buildHeavyTopPrompt(),
                if (_isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_items.isEmpty)
                  _buildEmptyState()
                else
                  Expanded(child: _buildItemList()),
                if (!_isLoading && _items.isNotEmpty) _buildQuizCtaSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeavyTopPrompt() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child:
          Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 62,
                      height: 62,
                      child: Lottie.asset(
                        'assets/lottie/Body Builder.json',
                        repeat: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Blackhole is getting heavy. Time to take a quiz?",
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.08, end: 0, duration: 350.ms),
    );
  }

  Widget _buildQuizCtaSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final ctaGradient = isDark
        ? const [Color(0xFF4FACFE), Color(0xFFA18CD1), Color(0xFFFE5196)]
        : const [Color(0xFF4FACFE), Color(0xFF00D3FF), Color(0xFF5B8CFF)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: ctaGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.45 : 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _startQuiz,
            child: SizedBox(
              width: double.infinity,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  "Start Focused Quiz",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().scale(delay: 120.ms, curve: Curves.easeOutBack);
  }

  Widget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.cyclone_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Black Hole",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  "Words to review with meaning and context",
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.blur_on,
              size: 80,
              color: colorScheme.onSurface.withValues(alpha: 0.14),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 5.seconds),
            const SizedBox(height: 24),
            Text(
              "The Black Hole is empty.",
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                "Add words you find difficult from your daily tasks to review them here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _itemIdentity(Map<String, String> item, [String fallback = '']) {
    return (item['id'] ?? item['word'] ?? item['title'] ?? fallback).trim();
  }

  Widget _buildItemList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final itemKey = _itemIdentity(item, 'unknown_$index');

        return Dismissible(
          key: ValueKey('blackhole_${itemKey}_$index'),
          direction: DismissDirection.endToStart,
          background: _buildDismissBackground(),
          onDismissed: (_) => _removeItem(item),
          child: _BlackHoleVocabCard(
            item: item,
            preferredLanguage: _preferredLanguage,
            onTap: () => _openItemDetail(item),
            onDelete: () => _removeItem(item),
          ),
        ).animate().fadeIn(delay: (index * 35).ms).slideX(begin: 0.08, end: 0);
      },
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.55)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          SizedBox(width: 6),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeItem(Map<String, String> item) async {
    final itemId = _itemIdentity(item);
    if (itemId.isEmpty) return;

    final previousItems = List<Map<String, String>>.from(_items);
    setState(() {
      final index = _items.indexWhere((e) => _itemIdentity(e) == itemId);
      if (index >= 0) _items.removeAt(index);
    });

    try {
      await _dataService.toggleBlackHoleItem(item);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = previousItems);
    }
  }

  void _startQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FocusedQuizScreen()),
    );
  }

  void _openItemDetail(Map<String, String> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlackholeItemDetailScreen(
          item: item,
          preferredLanguage: _preferredLanguage,
        ),
      ),
    );
  }
}

class _BlackHoleVocabCard extends StatelessWidget {
  final Map<String, String> item;
  final String preferredLanguage;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BlackHoleVocabCard({
    required this.item,
    required this.preferredLanguage,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final word = (item['word'] ?? item['title'] ?? 'Unknown').trim();
    final type = (item['type'] ?? 'vocab').toLowerCase();
    final isVerb = type == 'verb';
    final formsLine = _verbFormsLine(item);
    final primaryMeaning = isVerb
        ? _primaryVerbMeaning(item, preferredLanguage)
        : _primaryMeaning(item, preferredLanguage);
    final example = _primaryExample(item, preferredLanguage);
    final labelLanguage = preferredLanguage == 'Hindi' ? 'Hindi' : 'Tamil';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.24 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              word,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Text(
                              type == 'verb' ? 'verb' : 'vocab',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                if (isVerb && formsLine.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    formsLine,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ],
                if (primaryMeaning.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    primaryMeaning,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
                if (example.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '$labelLanguage example: $example',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.92,
                      ),
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _primaryMeaning(
    Map<String, String> item,
    String preferredLanguage,
  ) {
    final tamil = (item['tamil_meaning'] ?? '').trim();
    final hindi = (item['hindi_meaning'] ?? '').trim();
    final english = (item['meaning'] ?? '').trim();

    if (preferredLanguage == 'Hindi') {
      if (hindi.isNotEmpty) return hindi;
      if (english.isNotEmpty) return english;
      return tamil;
    }

    if (tamil.isNotEmpty) return tamil;
    if (english.isNotEmpty) return english;
    return hindi;
  }

  static String _primaryVerbMeaning(
    Map<String, String> item,
    String preferredLanguage,
  ) {
    final tamil = (item['tamil_meaning'] ?? '').trim();
    final hindi = (item['hindi_meaning'] ?? '').trim();
    final english = (item['meaning'] ?? '').trim();

    if (preferredLanguage == 'Hindi') {
      if (hindi.isNotEmpty) return hindi;
      if (tamil.isNotEmpty) return tamil;
      return english;
    }

    if (tamil.isNotEmpty) return tamil;
    if (hindi.isNotEmpty) return hindi;
    return english;
  }

  static String _verbFormsLine(Map<String, String> item) {
    final v1 = (item['v1'] ?? item['word'] ?? '').trim();
    final v2 = (item['v2'] ?? '').trim();
    final v3 = (item['v3'] ?? '').trim();

    final forms = <String>[];
    if (v1.isNotEmpty) forms.add(v1);
    if (v2.isNotEmpty && !forms.contains(v2)) forms.add(v2);
    if (v3.isNotEmpty && !forms.contains(v3)) forms.add(v3);

    if (forms.length > 1) {
      return forms.join(' / ');
    }

    final rawForms = (item['forms'] ?? '').trim();
    if (rawForms.isNotEmpty) {
      final parsed = rawForms
          .split('/')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parsed.length > 1) return parsed.join(' / ');
    }

    return forms.join(' / ');
  }

  static String _primaryExample(
    Map<String, String> item,
    String preferredLanguage,
  ) {
    final tamil = (item['tamil_example'] ?? '').trim();
    final hindi = (item['hindi_example'] ?? '').trim();
    final english = (item['english_example'] ?? '').trim();

    if (preferredLanguage == 'Hindi') {
      if (hindi.isNotEmpty) return hindi;
      if (english.isNotEmpty) return english;
      return tamil;
    }

    if (tamil.isNotEmpty) return tamil;
    if (english.isNotEmpty) return english;
    return hindi;
  }
}
