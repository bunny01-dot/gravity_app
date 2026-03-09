import 'package:flutter/material.dart';
import 'package:gravity_app/models/verb_item.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/services/day_based_curriculum_service.dart';
import 'package:gravity_app/services/tts_service.dart';
import 'package:gravity_app/widgets/daily_verb_card.dart';

class BlackholeItemDetailScreen extends StatefulWidget {
  final Map<String, String> item;
  final String preferredLanguage;

  const BlackholeItemDetailScreen({
    super.key,
    required this.item,
    required this.preferredLanguage,
  });

  @override
  State<BlackholeItemDetailScreen> createState() =>
      _BlackholeItemDetailScreenState();
}

class _BlackholeItemDetailScreenState extends State<BlackholeItemDetailScreen> {
  final TtsService _ttsService = TtsService();
  VocabularyItem? _vocabItem;
  VerbItem? _verbItem;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final word = (widget.item['word'] ?? widget.item['title'] ?? '').trim();
    final type = widget.item['type'] ?? '';
    final isVerb =
        type == 'verb' ||
        widget.item.containsKey('v1') ||
        widget.item.containsKey('v2');

    if (word.isNotEmpty) {
      final curriculum = DayBasedCurriculumService();
      await curriculum.initialize();

      if (isVerb) {
        _verbItem = _findVerb(curriculum.getAllVerbs(), word);
      } else {
        _vocabItem = _findVocab(curriculum.getAllVocabulary(), word);
      }
    }

    // Fallback to minimal data when not found in curriculum
    if (_vocabItem == null && _verbItem == null && word.isNotEmpty) {
      if (isVerb) {
        _verbItem = _fallbackVerb(word);
      } else {
        _vocabItem = _fallbackVocab(word);
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  VocabularyItem? _findVocab(List<VocabularyItem> items, String word) {
    for (final item in items) {
      if (item.word.toLowerCase() == word.toLowerCase()) {
        return item;
      }
    }
    return null;
  }

  VerbItem? _findVerb(List<VerbItem> items, String word) {
    for (final item in items) {
      if (item.base.toLowerCase() == word.toLowerCase()) {
        return item;
      }
    }
    return null;
  }

  VocabularyItem _fallbackVocab(String word) {
    return VocabularyItem(
      id: widget.item['id'] ?? word,
      word: word,
      definition: widget.item['meaning'] ?? '',
      tamilMeaning: widget.item['tamil_meaning'] ?? '',
      hindiMeaning: widget.item['hindi_meaning'] ?? '',
      exampleSentence: widget.item['english_example'] ?? '',
      englishExample: widget.item['english_example'] ?? '',
      tamilExample: widget.item['tamil_example'] ?? '',
      hindiExample: widget.item['hindi_example'] ?? '',
      synonyms: _splitCsv(widget.item['synonyms'] ?? ''),
      localizedSynonyms: _splitCsv(widget.item['tamil_synonyms'] ?? ''),
      pos: widget.item['pos'] ?? '',
    );
  }

  VerbItem _fallbackVerb(String word) {
    return VerbItem(
      id: widget.item['id'] ?? word,
      base: word,
      past: widget.item['v2'] ?? '',
      pastParticiple: widget.item['v3'] ?? '',
      present3rd: widget.item['v4'] ?? '',
      gerund: widget.item['v5'] ?? '',
      tamilMeaning:
          widget.item['tamil_meaning'] ?? widget.item['meaning'] ?? '',
      hindiMeaning:
          widget.item['hindi_meaning'] ?? widget.item['meaning'] ?? '',
      exampleSentences: {
        'english': widget.item['english_example'] ?? '',
        'tamil': widget.item['tamil_example'] ?? '',
        'hindi': widget.item['hindi_example'] ?? '',
      },
    );
  }

  List<String> _splitCsv(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Word Detail"),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _buildDetail(),
    );
  }

  Widget _buildDetail() {
    if (_verbItem != null) {
      final meaning = _getVerbMeaning(_verbItem!);
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          DailyVerbCard(
            verb: _verbItem!,
            meaning: meaning,
            preferredLanguage: widget.preferredLanguage,
            onRead: () {},
          ),
        ],
      );
    }

    if (_vocabItem != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [_buildVocabCard(_vocabItem!)],
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        "No details available for this word.",
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildVocabCard(VocabularyItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF4FACFE) : colorScheme.primary;
    final highlight = isDark
        ? Colors.amber
        : colorScheme.secondary.withValues(alpha: 0.9);

    final meaning = _getVocabMeaning(item);
    final englishExample = _getEnglishExample(item);
    final localizedExample = _getLocalizedExample(item);
    final localizedLabel = widget.preferredLanguage == 'Hindi'
        ? 'Hindi'
        : 'Tamil';
    final englishSynonyms = _filterEnglishSynonyms(item.synonyms);
    final localizedFromColumn = _filterLocalizedSynonyms(
      item.localizedSynonyms,
    );
    final localizedFromMain = _filterLocalizedSynonyms(item.synonyms);
    final localizedSynonyms = _mergeUniqueSynonyms(
      localizedFromColumn,
      localizedFromMain,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.all(20),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        iconColor: accent,
        collapsedIconColor: colorScheme.onSurfaceVariant,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.word,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.volume_up,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    _ttsService.speak(item.word);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.pos.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (meaning.isNotEmpty)
              Text(
                meaning,
                style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        children: [
          Divider(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            height: 32,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: highlight),
                  const SizedBox(width: 8),
                  Text(
                    "English Example",
                    style: TextStyle(
                      color: highlight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (englishExample.isNotEmpty)
                Text(
                  englishExample,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                const Text(
                  "No English example available.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.translate_rounded, size: 16, color: highlight),
                  const SizedBox(width: 8),
                  Text(
                    "$localizedLabel Example",
                    style: TextStyle(
                      color: highlight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (localizedExample.isNotEmpty)
                Text(
                  localizedExample,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Text(
                  "No $localizedLabel example available.",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.sync_alt_rounded, size: 16, color: highlight),
                  const SizedBox(width: 8),
                  Text(
                    "English Synonyms",
                    style: TextStyle(
                      color: highlight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (englishSynonyms.isNotEmpty)
                Text(
                  englishSynonyms.join(', '),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                    height: 1.4,
                  ),
                )
              else
                Text(
                  "No English synonyms available.",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.translate_rounded, size: 16, color: highlight),
                  const SizedBox(width: 8),
                  Text(
                    "$localizedLabel Synonyms",
                    style: TextStyle(
                      color: highlight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (localizedSynonyms.isNotEmpty)
                Text(
                  localizedSynonyms.join(', '),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                    height: 1.4,
                  ),
                )
              else
                Text(
                  "No $localizedLabel synonyms available.",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getVocabMeaning(VocabularyItem item) {
    switch (widget.preferredLanguage) {
      case 'Hindi':
        return item.hindiMeaning;
      case 'Tamil':
      default:
        return item.tamilMeaning;
    }
  }

  String _getVerbMeaning(VerbItem item) {
    switch (widget.preferredLanguage) {
      case 'Hindi':
        return item.hindiMeaning;
      case 'Tamil':
      default:
        return item.tamilMeaning;
    }
  }

  String _getEnglishExample(VocabularyItem item) {
    if (item.englishExample.isNotEmpty) return item.englishExample;
    return item.exampleSentence;
  }

  String _getLocalizedExample(VocabularyItem item) {
    switch (widget.preferredLanguage) {
      case 'Hindi':
        return item.hindiExample;
      case 'Tamil':
      default:
        return item.tamilExample;
    }
  }

  static final RegExp _tamilRegex = RegExp(r'[\u0B80-\u0BFF]');
  static final RegExp _devanagariRegex = RegExp(r'[\u0900-\u097F]');

  List<String> _filterEnglishSynonyms(List<String> synonyms) {
    return synonyms
        .where((s) => s.trim().isNotEmpty)
        .where((s) => !_tamilRegex.hasMatch(s) && !_devanagariRegex.hasMatch(s))
        .toList();
  }

  List<String> _filterLocalizedSynonyms(List<String> synonyms) {
    return synonyms
        .where((s) => s.trim().isNotEmpty)
        .where(
          (s) => widget.preferredLanguage == 'Hindi'
              ? _devanagariRegex.hasMatch(s)
              : _tamilRegex.hasMatch(s),
        )
        .toList();
  }

  List<String> _mergeUniqueSynonyms(
    List<String> primary,
    List<String> secondary,
  ) {
    final seen = <String>{};
    final result = <String>[];

    for (final s in [...primary, ...secondary]) {
      final trimmed = s.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed)) {
        result.add(trimmed);
      }
    }

    return result;
  }
}
