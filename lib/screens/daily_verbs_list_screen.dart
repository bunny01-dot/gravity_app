import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:gravity_app/models/verb_item.dart';
import 'package:gravity_app/services/daily_task_completion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/widgets/daily_verb_card.dart';
import 'package:gravity_app/utils/safe_navigation.dart';

class DailyVerbsListScreen extends StatefulWidget {
  final List<VerbItem> verbs;
  final String preferredLanguage;
  final int stageNumber;

  const DailyVerbsListScreen({
    super.key,
    required this.verbs,
    required this.preferredLanguage,
    required this.stageNumber,
  });

  @override
  State<DailyVerbsListScreen> createState() => _DailyVerbsListScreenState();
}

class _DailyVerbsListScreenState extends State<DailyVerbsListScreen> {
  static const String _expandHintSeenKey = 'verbs_expand_hint_seen';
  final DailyTaskCompletionService _completionService =
      DailyTaskCompletionService();
  final ScrollController _scrollController = ScrollController();
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
    final target = viewport.getOffsetToReveal(renderObject, 0.1).offset - 12;
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

  Future<void> _maybeShowExpandHint() async {
    if (widget.verbs.isEmpty) return;
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

  Future<void> _smoothScrollCardIntoFocus(
    int index, {
    required int token,
  }) async {
    // Pass 1: bring the tapped card into view quickly.
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

  Future<void> _markAllComplete() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final completion = await _completionService.completeVerbsListTask(
        learnedVerbs: widget.verbs.map((verb) => verb.base),
      );
      if (mounted) {
        await SafeNavigation.maybePop(
          context,
          result: DailyTaskCompletionService.completionResultPayload(
            completion,
          ),
          source: 'DailyVerbsListScreen._markAllComplete',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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

  @override
  Widget build(BuildContext context) {
    _ensureCardState(widget.verbs.length);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
                  'Verb Practice',
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
                  'Level ${widget.stageNumber} - $_readCount / ${widget.verbs.length} read aloud',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
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
                  onPointerDown: (_) {
                    if (_showExpandHint) {
                      unawaited(_dismissExpandHint());
                    }
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: widget.verbs.length,
                    itemBuilder: (context, index) {
                      final verb = widget.verbs[index];
                      final meaning = _getMeaning(verb);

                      return KeyedSubtree(
                        key: _cardKeys[index],
                        child: DailyVerbCard(
                          verb: verb,
                          meaning: meaning,
                          preferredLanguage: widget.preferredLanguage,
                          onRead: _incrementReadCount,
                          controller: _expansionControllers[index],
                          onExpansionChanged: (expanded) {
                            if (!expanded) {
                              final wasActiveCard = _expandedCardIndex == index;
                              if (wasActiveCard) {
                                _focusRequestToken++;
                                setState(() {
                                  _expandedCardIndex = null;
                                });
                              }
                              return;
                            }

                            setState(() {
                              _expandedCardIndex = index;
                            });
                            _collapseOtherCards(index);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted || _expandedCardIndex != index) {
                                return;
                              }
                              _handleCardExpansion(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (_showExpandHint) _buildExpandHintOverlay(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(
                    alpha: isDark ? 0.2 : 0.08,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _markAllComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Mark All Complete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary.withValues(
                          alpha: _isSubmitting ? 0.9 : 1,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: !_isSubmitting
                          ? const SizedBox(
                              key: ValueKey('verb_complete_no_loader'),
                              width: 0,
                              height: 0,
                            )
                          : Padding(
                              key: const ValueKey('verb_complete_loader'),
                              padding: const EdgeInsets.only(left: 12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: colorScheme.onPrimary,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandHintOverlay() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      left: 18,
      right: 18,
      top: 8,
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
                    color: colorScheme.primary.withValues(alpha: 0.58),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
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

  String _getMeaning(VerbItem verb) {
    switch (widget.preferredLanguage) {
      case 'Tamil':
        return verb.tamilMeaning;
      case 'Hindi':
        return verb.hindiMeaning;
      default:
        return '';
    }
  }

  void _incrementReadCount() {
    setState(() {
      _readCount = (_readCount + 1).clamp(0, widget.verbs.length);
    });
  }
}
