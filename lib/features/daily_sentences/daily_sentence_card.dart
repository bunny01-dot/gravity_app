import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gravity_app/features/daily_sentences/daily_sentence_model.dart';
import 'package:gravity_app/features/daily_sentences/daily_sentence_service.dart';
import 'package:gravity_app/services/tts_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/features/dashboard/widgets/daily_task_card.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/services/stage_progress_service.dart';
import 'package:gravity_app/services/offline_xp_service.dart';

class DailySentenceCard extends StatefulWidget {
  final String preferredLanguage;
  final VoidCallback? onCompleted;
  const DailySentenceCard({
    super.key,
    required this.preferredLanguage,
    this.onCompleted,
  });

  @override
  State<DailySentenceCard> createState() => _DailySentenceCardState();
}

class _DailySentenceCardState extends State<DailySentenceCard> {
  final DailySentenceService _service = DailySentenceService();
  final TtsService _ttsService = TtsService();
  final DataService _dataService = DataService();
  final StageProgressService _stageService = StageProgressService();
  static const Duration _expandSettleDuration = Duration(milliseconds: 620);
  int _sentenceFocusRequestToken = 0;

  List<DailySentence> _sentences = [];
  Set<String> _blackHoleWords = {};
  bool _isLoading = true;
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    await _service.init();
    final data = await _service.getDailySentences();

    // Load Black Hole status
    final blackHoleItems = await _dataService.getBlackHoleItems();
    final savedWords = blackHoleItems
        .map((e) => e['word'] ?? e['title'])
        .whereType<String>()
        .toSet();

    if (mounted) {
      setState(() {
        // _userLanguage = userLang; // Handled by widget prop
        _sentences = data;
        _blackHoleWords = savedWords;
        _isLoading = false;
      });

      // Mark these as "seen/assigned" immediately
      _service.markAsSeen(data);
    }
  }

  Future<void> _markAsCompleted() async {
    if (_isAdvancing || _sentences.isEmpty) return;

    if (mounted) {
      setState(() {
        _isAdvancing = true;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final stage = await _stageService.getCurrentStage(prefs: prefs);

    final learnedIds = prefs.getStringList('learned_sentence_ids') ?? [];
    final learnedSet = learnedIds.toSet();
    for (final sentence in _sentences) {
      if (sentence.id.isNotEmpty) learnedSet.add(sentence.id);
    }
    await prefs.setStringList('learned_sentence_ids', learnedSet.toList());
    await _dataService.saveProgressToCloud(
      'learned_sentence_ids',
      learnedSet.toList(),
    );

    await _service.advanceBatchForStage(stage);
    await _loadData();

    // Optional bonus XP for completing sentences
    await OfflineXpService().addXp(5);

    // Keep sentence-set advancement lightweight (no achievement SFX/confetti).

    if (mounted) {
      setState(() {
        _isAdvancing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Moved to the next sentence set."),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleBlackHole(
    DailySentence sentence, [
    VoidCallback? onRefresh,
  ]) async {
    final String word = sentence.text;
    final bool isSaved = _blackHoleWords.contains(word);

    // Create item map
    final Map<String, String> item = {
      'word': sentence.text,
      'meaning': widget.preferredLanguage == 'Hindi'
          ? sentence.hindiText
          : sentence.tamilText, // Primary Display
      'tamil_meaning': sentence.tamilText,
      'hindi_meaning': sentence.hindiText,
      'type': 'sentence',
      'source': 'daily_sentence',
    };

    // Optimistic Update UI
    setState(() {
      if (isSaved) {
        _blackHoleWords.remove(word);
      } else {
        _blackHoleWords.add(word);
      }
    });

    // Refresh Modal if callback provided
    if (onRefresh != null) onRefresh();

    // Immediate Audio Feedback
    if (isSaved) {
      SoundService().playBookmarkRemove();
    } else {
      SoundService().playBookmarkAdd();
    }

    // Immediate Snackbar Feedback
    if (mounted) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;
      final accentColor = isSaved ? colorScheme.outline : colorScheme.primary;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isSaved ? Icons.check_circle_outline : Icons.cyclone,
                color: accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSaved ? 'Removed from Black Hole' : 'Saved for review',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (!isSaved)
                      Text(
                        "Review this sentence later to master it.",
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: isDark
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: accentColor, width: 1.5),
          ),
          duration: const Duration(milliseconds: 1500),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    // Background Database Sync
    await _dataService.toggleBlackHoleItem(item);
  }

  Future<void> _animateTargetIntoScrollView({
    required ScrollController controller,
    required BuildContext targetContext,
    Duration duration = const Duration(milliseconds: 620),
  }) async {
    if (!controller.hasClients) return;

    final renderObject = targetContext.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    final viewport = RenderAbstractViewport.of(renderObject);
    final target = viewport.getOffsetToReveal(renderObject, 0.0).offset - 16;
    final position = controller.position;
    final clamped = target
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((position.pixels - clamped).abs() < 1) return;

    await controller.animateTo(
      clamped,
      duration: duration,
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  Future<void> _focusSentenceRow({
    required int index,
    required List<GlobalKey> rowKeys,
    required ScrollController scrollController,
    required int token,
  }) async {
    if (token != _sentenceFocusRequestToken) return;
    if (index < 0 || index >= rowKeys.length) return;

    final firstContext = rowKeys[index].currentContext;
    if (firstContext == null || !firstContext.mounted) return;

    await _animateTargetIntoScrollView(
      controller: scrollController,
      targetContext: firstContext,
    );
    if (!mounted || token != _sentenceFocusRequestToken) return;

    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted || token != _sentenceFocusRequestToken) return;

    final secondContext = rowKeys[index].currentContext;
    if (secondContext == null || !secondContext.mounted) return;

    await _animateTargetIntoScrollView(
      controller: scrollController,
      targetContext: secondContext,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // If absolutely empty (no fallback), hide
    if (_sentences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: DailyTaskCard(
        title: "Sentence Practice",
        subtitle: _isAdvancing
            ? "Loading your next sentence set..."
            : "Bonus practice - complete this set to unlock the next set",
        icon: Icons.star_rounded,
        color: Colors.amber,
        animationType: 'hop',
        isDone: false,
        scorePercentage: 0,
        showArrow: false,
        onTap: _showSentencesSheet,
      ),
    );
  }

  Future<void> _showSentencesSheet() async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final prefs = await SharedPreferences.getInstance();
    final stage = await _stageService.getCurrentStage(prefs: prefs);
    final previousStage = _stageService.previousStage(stage);
    if (!mounted) return;
    if (previousStage > 0) {
      final key = _stageService.assessmentCompletedKey(previousStage);
      final completed = prefs.getBool(key) ?? false;
      if (!completed) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              "Please complete the Level $previousStage review to confirm your learning.",
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
            backgroundColor: colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    await _showSentencesBottomSheet();
  }

  Future<void> _showSentencesBottomSheet() async {
    _sentenceFocusRequestToken++;
    var rowKeys = List.generate(_sentences.length, (_) => GlobalKey());
    final sheetScrollController = ScrollController();
    int? expandedSentenceIndex;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            void refresh() => setModalState(() {});

            return Material(
              color: Colors.transparent,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 16, bottom: 24),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Sentence Practice",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        "Listen and repeat each sentence to improve your fluency.",
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        controller: sheetScrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        itemCount: _sentences.length,
                        itemBuilder: (context, index) {
                          final isExpanded = expandedSentenceIndex == index;
                          return _buildSentenceRow(
                            _sentences[index],
                            index,
                            refresh,
                            rowKey: rowKeys[index],
                            expanded: isExpanded,
                            onToggle: () {
                              final shouldExpand =
                                  expandedSentenceIndex != index;
                              setModalState(() {
                                expandedSentenceIndex = shouldExpand
                                    ? index
                                    : null;
                              });

                              if (!shouldExpand) {
                                _sentenceFocusRequestToken++;
                                return;
                              }

                              final token = ++_sentenceFocusRequestToken;

                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) async {
                                if (!mounted ||
                                    token != _sentenceFocusRequestToken) {
                                  return;
                                }
                                await Future<void>.delayed(
                                  _expandSettleDuration,
                                );
                                if (!mounted ||
                                    token != _sentenceFocusRequestToken) {
                                  return;
                                }
                                await _focusSentenceRow(
                                  index: index,
                                  rowKeys: rowKeys,
                                  scrollController: sheetScrollController,
                                  token: token,
                                );
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isAdvancing
                              ? null
                              : () async {
                                  _sentenceFocusRequestToken++;
                                  await _markAsCompleted();
                                  if (context.mounted) {
                                    setModalState(() {
                                      // Refresh sheet in-place with the new sentence set.
                                      expandedSentenceIndex = null;
                                      rowKeys = List.generate(
                                        _sentences.length,
                                        (_) => GlobalKey(),
                                      );
                                    });
                                    if (sheetScrollController.hasClients) {
                                      await sheetScrollController.animateTo(
                                        0,
                                        duration: const Duration(
                                          milliseconds: 340,
                                        ),
                                        curve: Curves.easeOutCubic,
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            disabledBackgroundColor: colorScheme.primary
                                .withValues(alpha: 0.45),
                            disabledForegroundColor: colorScheme.onPrimary
                                .withValues(alpha: 0.7),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _isAdvancing ? "Loading..." : "Next Set",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    _sentenceFocusRequestToken++;
    sheetScrollController.dispose();
  }

  Widget _buildSentenceRow(
    DailySentence sentence,
    int index,
    VoidCallback onRefresh, {
    required Key rowKey,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final String translation = widget.preferredLanguage == 'Hindi'
        ? sentence.hindiText
        : sentence.tamilText;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        key: rowKey,
        duration: const Duration(milliseconds: 440),
        curve: Curves.easeInOutCubicEmphasized,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.72)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: expanded
                ? colorScheme.primary.withValues(alpha: 0.45)
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    sentence.text,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: expanded
                          ? colorScheme.primary.withValues(
                              alpha: isDark ? 0.2 : 0.14,
                            )
                          : colorScheme.surfaceContainerHighest.withValues(
                              alpha: isDark ? 0.72 : 0.58,
                            ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: expanded
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                      onPressed: () => _toggleBlackHole(sentence, onRefresh),
                      icon: Icon(
                        _blackHoleWords.contains(sentence.text)
                            ? Icons.cyclone
                            : Icons.cyclone_outlined,
                        color: _blackHoleWords.contains(sentence.text)
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                        size: 26,
                      ),
                      tooltip: _blackHoleWords.contains(sentence.text)
                          ? "Saved for review"
                          : "Add to Black Hole",
                    )
                    .animate(
                      target: _blackHoleWords.contains(sentence.text) ? 1 : 0,
                    )
                    .rotate(
                      begin: 0,
                      end: 1,
                      duration: 800.ms,
                      curve: Curves.easeInOutBack,
                    )
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.3, 1.3),
                      duration: 300.ms,
                    ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerLowest.withValues(
                          alpha: 0.72,
                        )
                      : colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translation,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _ttsService.speak(sentence.text),
                  icon: Icon(
                    Icons.volume_up_rounded,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    'Listen',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: isDark ? 0.16 : 0.12,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}
