import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/services/tts_service.dart';
import 'package:gravity_app/services/daily_task_completion_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/utils/safe_navigation.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyVocabularyListScreen extends StatefulWidget {
  final List<VocabularyItem> vocabulary;
  final String preferredLanguage;
  final int stageNumber;

  const DailyVocabularyListScreen({
    super.key,
    required this.vocabulary,
    required this.preferredLanguage,
    required this.stageNumber,
  });

  @override
  State<DailyVocabularyListScreen> createState() =>
      _DailyVocabularyListScreenState();
}

class _DailyVocabularyListScreenState extends State<DailyVocabularyListScreen> {
  static const String _expandHintSeenKey = 'vocab_expand_hint_seen';
  final TtsService _ttsService = TtsService();
  final DataService _dataService = DataService();
  final DailyTaskCompletionService _completionService =
      DailyTaskCompletionService();
  final ScrollController _scrollController = ScrollController();
  final Map<int, double> _blackHoleIconTurns = <int, double>{};
  List<GlobalKey> _cardKeys = [];
  List<ExpansibleController> _expansionControllers = [];
  int _focusRequestToken = 0;
  int? _expandedCardIndex;
  int _readCount = 0;
  bool _isSubmitting = false;
  bool _showExpandHint = false;

  @override
  void initState() {
    super.initState();
    unawaited(_maybeShowExpandHint());
  }

  void _ensureCardState(int count) {
    if (_cardKeys.length == count && _expansionControllers.length == count) {
      return;
    }
    for (final controller in _expansionControllers) {
      controller.dispose();
    }
    _cardKeys = List.generate(count, (_) => GlobalKey());
    _expansionControllers = List.generate(count, (_) => ExpansibleController());
    if (_expandedCardIndex != null && _expandedCardIndex! >= count) {
      _expandedCardIndex = null;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in _expansionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _maybeShowExpandHint() async {
    if (widget.vocabulary.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_expandHintSeenKey) ?? false;
    if (!mounted || seen) return;
    await prefs.setBool(_expandHintSeenKey, true);
    setState(() => _showExpandHint = true);
  }

  Future<void> _dismissExpandHint({bool persist = true}) async {
    if (!_showExpandHint) return;
    if (mounted) {
      setState(() => _showExpandHint = false);
    }
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_expandHintSeenKey, true);
    }
  }

  Future<void> _markAllComplete() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final completion = await _completionService.completeVocabularyListTask(
        learnedWords: widget.vocabulary.map((item) => item.word),
      );
      if (mounted) {
        await SafeNavigation.maybePop(
          context,
          result: DailyTaskCompletionService.completionResultPayload(
            completion,
          ),
          source: 'DailyVocabularyListScreen._markAllComplete',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Duration _focusDurationForDistance(double distancePx) {
    final ms = (220 + (distancePx * 0.7)).round().clamp(260, 760);
    return Duration(milliseconds: ms);
  }

  Future<void> _animateTargetIntoView(BuildContext targetContext) async {
    if (!_scrollController.hasClients) return;

    final renderObject = targetContext.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    final viewport = RenderAbstractViewport.of(renderObject);
    // Keep some top breathing room instead of pinning exactly to the top.
    final target = viewport.getOffsetToReveal(renderObject, 0.08).offset - 8;
    final position = _scrollController.position;
    final clamped = target
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    final delta = (position.pixels - clamped).abs();
    if (delta < 1) return;

    await _scrollController.animateTo(
      clamped,
      duration: _focusDurationForDistance(delta),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _smoothScrollCardIntoFocus(
    int index, {
    required int token,
  }) async {
    // Pass 1: bring the tapped card area into view quickly.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted || token != _focusRequestToken) return;

    final firstContext = _cardKeys[index].currentContext;
    if (firstContext != null && firstContext.mounted) {
      await _animateTargetIntoView(firstContext);
    }

    // Pass 2: after expansion settles, refine to the full card position.
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted || token != _focusRequestToken) return;

    final cardContext = _cardKeys[index].currentContext;
    if (cardContext == null || !cardContext.mounted) return;

    await _animateTargetIntoView(cardContext);
  }

  void _collapseOtherCards(int expandedIndex) {
    for (var i = 0; i < _expansionControllers.length; i++) {
      if (i == expandedIndex) continue;
      final controller = _expansionControllers[i];
      if (controller.isExpanded) {
        controller.collapse();
      }
    }
  }

  void _handleCardExpansion(int index) {
    if (!mounted) return;
    if (_showExpandHint) {
      unawaited(_dismissExpandHint());
    }
    final token = ++_focusRequestToken;
    unawaited(_smoothScrollCardIntoFocus(index, token: token));
  }

  void _collapseCard(int index) {
    if (index < 0 || index >= _expansionControllers.length) return;
    final controller = _expansionControllers[index];
    if (!controller.isExpanded) return;
    _focusRequestToken++;
    controller.collapse();
    if (_expandedCardIndex == index && mounted) {
      setState(() {
        _expandedCardIndex = null;
      });
    }
  }

  void _expandCard(int index) {
    if (index < 0 || index >= _expansionControllers.length) return;
    final controller = _expansionControllers[index];
    if (controller.isExpanded) return;

    if (_showExpandHint) {
      unawaited(_dismissExpandHint());
    }
    _collapseOtherCards(index);
    controller.expand();
    if (mounted) {
      setState(() {
        _expandedCardIndex = index;
      });
    }
  }

  bool _isPointInsideCard(int index, Offset globalPosition) {
    if (index < 0 || index >= _cardKeys.length) return false;
    final context = _cardKeys[index].currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return false;
    final cardTopLeft = renderObject.localToGlobal(Offset.zero);
    final cardRect = cardTopLeft & renderObject.size;
    return cardRect.contains(globalPosition);
  }

  void _handleOutsidePointerDown(Offset globalPosition) {
    if (_showExpandHint) {
      unawaited(_dismissExpandHint());
    }
    final expandedIndex = _expandedCardIndex;
    if (expandedIndex == null) return;
    if (_isPointInsideCard(expandedIndex, globalPosition)) return;
    _collapseCard(expandedIndex);
  }

  void _spinBlackHoleIcon(int index) {
    setState(() {
      _blackHoleIconTurns[index] = (_blackHoleIconTurns[index] ?? 0) + 1.0;
    });
  }

  Widget _buildExpandedBody({required _VocabCardDetails details}) {
    final englishSynonymsText = details.englishSynonyms.join(', ');
    final localizedSynonymsText = details.localizedSynonyms.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailSection(
          icon: Icons.lightbulb_outline,
          title: 'English Example',
          content: details.englishExample,
          emptyText: 'No English example available.',
          italicContent: true,
        ),
        _buildDetailSection(
          icon: Icons.translate_rounded,
          title: '${details.localizedLabel} Example',
          content: details.localizedExample,
          emptyText: 'No ${details.localizedLabel} example available.',
          italicContent: true,
        ),
        _buildDetailSection(
          icon: Icons.sync_alt_rounded,
          title: 'English Synonyms',
          content: englishSynonymsText,
          emptyText: 'No English synonyms available.',
          italicContent: false,
        ),
        _buildDetailSection(
          icon: Icons.translate_rounded,
          title: '${details.localizedLabel} Synonyms',
          content: localizedSynonymsText,
          emptyText: 'No ${details.localizedLabel} synonyms available.',
          italicContent: false,
        ),
      ],
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
    required String emptyText,
    required bool italicContent,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.amber.withValues(alpha: 0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (content.trim().isNotEmpty)
            Text(
              content,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
                height: 1.4,
                fontStyle: italicContent ? FontStyle.italic : FontStyle.normal,
              ),
            )
          else
            Text(
              emptyText,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureCardState(widget.vocabulary.length);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: Container(),
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vocabulary Practice',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Level ${widget.stageNumber} Plan',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) =>
                      _handleOutsidePointerDown(event.position),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    itemCount: widget.vocabulary.length,
                    itemBuilder: (context, index) {
                      final item = widget.vocabulary[index];
                      return _buildVocabCard(item, index);
                    },
                  ),
                ),
                if (_showExpandHint) _buildExpandHintOverlay(),
              ],
            ),
          ),
          _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildExpandHintOverlay() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      left: 22,
      right: 22,
      top: 6,
      child: Align(
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => unawaited(_dismissExpandHint()),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(54, 10, 12, 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.96,
                        )
                      : colorScheme.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  "Tap a card to expand",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 4,
                child:
                    SizedBox(
                          width: 34,
                          height: 34,
                          child: Lottie.asset(
                            'assets/lottie/Touch To Screen.json',
                            repeat: true,
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .scaleXY(begin: 0.9, end: 1.1, duration: 850.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVocabCard(VocabularyItem item, int index) {
    final isExpanded =
        _expandedCardIndex == index || _expansionControllers[index].isExpanded;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const cardRadius = BorderRadius.all(Radius.circular(24));
    final tileShape = RoundedRectangleBorder(borderRadius: cardRadius);
    final meaning = _getMeaning(item);
    final englishExample = _getEnglishExample(item);
    final localizedExample = _getLocalizedExample(item);
    final localizedLabel = widget.preferredLanguage == 'Hindi'
        ? 'Hindi'
        : 'Tamil';
    final englishSynonyms = _filterEnglishSynonyms(item.synonyms);
    final localizedFromColumn = _filterLocalizedSynonyms(
      item.localizedSynonyms,
      widget.preferredLanguage,
    );
    final localizedFromMain = _filterLocalizedSynonyms(
      item.synonyms,
      widget.preferredLanguage,
    );
    final localizedSynonyms = _mergeUniqueSynonyms(
      localizedFromColumn,
      localizedFromMain,
    );
    final details = _VocabCardDetails(
      item: item,
      meaning: meaning,
      englishExample: englishExample,
      localizedExample: localizedExample,
      localizedLabel: localizedLabel,
      englishSynonyms: englishSynonyms,
      localizedSynonyms: localizedSynonyms,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeInOutCubic,
      key: _cardKeys[index],
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: cardRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isExpanded ? 0.48 : 0.3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: isDark
                  ? (isExpanded ? 0.26 : 0.2)
                  : (isExpanded ? 0.12 : 0.08),
            ),
            blurRadius: isExpanded ? 14 : 10,
            offset: Offset(0, isExpanded ? 5 : 4),
          ),
        ],
      ),
      child: ExpansionTile(
        controller: _expansionControllers[index],
        enabled: true,
        clipBehavior: Clip.antiAlias,
        maintainState: true,
        shape: tileShape,
        collapsedShape: tileShape,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        splashColor: colorScheme.primary.withValues(alpha: 0.08),
        tilePadding: const EdgeInsets.all(20),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        iconColor: colorScheme.primary,
        collapsedIconColor: colorScheme.onSurfaceVariant,
        showTrailingIcon: false,
        expansionAnimationStyle: const AnimationStyle(
          duration: Duration(milliseconds: 540),
          reverseDuration: Duration(milliseconds: 460),
          curve: Curves.easeInOutCubic,
          reverseCurve: Curves.easeInOutCubic,
        ),
        trailing: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isExpanded ? null : () => _expandCard(index),
          child: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isExpanded
                    ? colorScheme.primary.withValues(
                        alpha: isDark ? 0.22 : 0.16,
                      )
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: isDark ? 0.8 : 0.66,
                      ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isExpanded
                      ? colorScheme.primary.withValues(alpha: 0.58)
                      : colorScheme.outlineVariant.withValues(alpha: 0.48),
                ),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isExpanded
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
        ),
        onExpansionChanged: (expanded) {
          if (!expanded) {
            _focusRequestToken++;
            if (_expandedCardIndex == index) {
              setState(() {
                _expandedCardIndex = null;
              });
            } else {
              setState(() {});
            }
            return;
          }

          setState(() {
            _expandedCardIndex = index;
          });
          _handleCardExpansion(index);
        },
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
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                Row(
                  children: [
                    FutureBuilder<bool>(
                      future: _dataService.isInBlackHole(item.id),
                      builder: (context, snapshot) {
                        final isSaved = snapshot.data ?? false;
                        return GestureDetector(
                          onTap: () async {
                            _spinBlackHoleIcon(index);
                            final map = {
                              'id': item.id,
                              'word': item.word,
                              'meaning': meaning,
                              'tamil_meaning': item.tamilMeaning,
                              'hindi_meaning': item.hindiMeaning,
                              'english_example': _getEnglishExample(item),
                              'tamil_example': item.tamilExample,
                              'hindi_example': item.hindiExample,
                              'type': 'vocab',
                              'source': 'daily_vocab',
                            };
                            await _dataService.toggleBlackHoleItem(map);
                            if (mounted) {
                              setState(() {});
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: AnimatedRotation(
                              turns: _blackHoleIconTurns[index] ?? 0,
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeInOut,
                              child: Icon(
                                isSaved
                                    ? Icons.cyclone
                                    : Icons.cyclone_outlined,
                                color: isSaved
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                size: 22,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.volume_up,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        _ttsService.speak(item.word);
                        setState(() => _readCount++);
                      },
                    ),
                  ],
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
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Close card',
              icon: Icon(
                Icons.close_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: () => _collapseCard(index),
            ),
          ),
          Divider(
            color: colorScheme.outlineVariant.withValues(alpha: 0.48),
            height: 32,
          ),
          _buildExpandedBody(details: details),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX();
  }

  String _getMeaning(VocabularyItem item) {
    switch (widget.preferredLanguage) {
      case 'Tamil':
        return item.tamilMeaning;
      case 'Hindi':
        return item.hindiMeaning;
      default:
        return '';
    }
  }

  String _getExample(VocabularyItem item) {
    switch (widget.preferredLanguage) {
      case 'Hindi':
        return item.hindiExample;
      case 'Tamil':
      default:
        return item.tamilExample;
    }
  }

  String _getLocalizedExample(VocabularyItem item) {
    return _getExample(item);
  }

  String _getEnglishExample(VocabularyItem item) {
    if (item.englishExample.isNotEmpty) return item.englishExample;
    return item.exampleSentence;
  }

  static final RegExp _tamilRegex = RegExp(r'[\u0B80-\u0BFF]');
  static final RegExp _devanagariRegex = RegExp(r'[\u0900-\u097F]');

  List<String> _filterEnglishSynonyms(List<String> synonyms) {
    return synonyms
        .where((s) => s.trim().isNotEmpty)
        .where((s) => !_tamilRegex.hasMatch(s) && !_devanagariRegex.hasMatch(s))
        .toList();
  }

  List<String> _filterLocalizedSynonyms(
    List<String> synonyms,
    String preferredLanguage,
  ) {
    return synonyms
        .where((s) => s.trim().isNotEmpty)
        .where(
          (s) => preferredLanguage == 'Hindi'
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

  Widget _buildCompleteButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.96)
            : colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _markAllComplete,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isSubmitting
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Complete Vocabulary Practice',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}

class _VocabCardDetails {
  final VocabularyItem item;
  final String meaning;
  final String englishExample;
  final String localizedExample;
  final String localizedLabel;
  final List<String> englishSynonyms;
  final List<String> localizedSynonyms;

  const _VocabCardDetails({
    required this.item,
    required this.meaning,
    required this.englishExample,
    required this.localizedExample,
    required this.localizedLabel,
    required this.englishSynonyms,
    required this.localizedSynonyms,
  });
}
