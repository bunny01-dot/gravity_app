import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gravity_app/models/verb_item.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/tts_service.dart';

class DailyVerbCard extends StatefulWidget {
  final VerbItem verb;
  final String meaning;
  final String preferredLanguage;
  final VoidCallback? onRead;
  final ExpansibleController? controller;
  final ValueChanged<bool>? onExpansionChanged;
  final GlobalKey? headerKey;

  const DailyVerbCard({
    super.key,
    required this.verb,
    required this.meaning,
    required this.preferredLanguage,
    this.onRead,
    this.controller,
    this.onExpansionChanged,
    this.headerKey,
  });

  @override
  State<DailyVerbCard> createState() => _DailyVerbCardState();
}

class _DailyVerbCardState extends State<DailyVerbCard> {
  final TtsService _ttsService = TtsService();
  final DataService _dataService = DataService();
  final GlobalKey _localHeaderKey = GlobalKey();

  Future<void> _focusExpandedHeader() async {
    final headerContext =
        widget.headerKey?.currentContext ?? _localHeaderKey.currentContext;
    if (headerContext == null || !headerContext.mounted) return;

    await Scrollable.ensureVisible(
      headerContext,
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeInOutCubic,
      alignment: 0.0,
    );

    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    final secondHeaderContext =
        widget.headerKey?.currentContext ?? _localHeaderKey.currentContext;
    if (secondHeaderContext == null || !secondHeaderContext.mounted) return;

    await Scrollable.ensureVisible(
      secondHeaderContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      alignment: 0.0,
    );
  }

  void _handleExpansionChanged(bool expanded) {
    widget.onExpansionChanged?.call(expanded);
    if (!expanded) return;
    if (widget.onExpansionChanged != null) return;

    unawaited(_focusExpandedHeader());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surface;
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.5);

    // English Forms are PRIMARY (Visible on card)
    final forms = [
      widget.verb.base,
      widget.verb.past,
      widget.verb.pastParticiple,
    ].where((e) => e.trim().isNotEmpty).join(' / ');
    final englishExample = _formatExample(_getEnglishExample(widget.verb));
    final localizedExample = _formatExample(_getLocalizedExample(widget.verb));
    final localizedLabel = widget.preferredLanguage == 'Hindi'
        ? 'Hindi'
        : 'Tamil';
    final verbId = widget.verb.id.isNotEmpty
        ? widget.verb.id
        : widget.verb.base;
    const cardRadius = BorderRadius.all(Radius.circular(16));
    final tileShape = RoundedRectangleBorder(borderRadius: cardRadius);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: cardRadius,
        border: Border.all(color: borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(verbId),
          controller: widget.controller,
          onExpansionChanged: _handleExpansionChanged,
          maintainState: true,
          clipBehavior: Clip.antiAlias,
          shape: tileShape,
          collapsedShape: tileShape,
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          splashColor: colorScheme.primary.withValues(alpha: 0.08),
          expansionAnimationStyle: const AnimationStyle(
            duration: Duration(milliseconds: 540),
            reverseDuration: Duration(milliseconds: 460),
            curve: Curves.easeInOutCubic,
            reverseCurve: Curves.easeInOutCubic,
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

          // HEADER: Forms + Meaning
          title: Row(
            key: widget.headerKey ?? _localHeaderKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PRIMARY: English Forms (Blue)
                    Text(
                      forms,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // SECONDARY: Meaning (White)
                    if (widget.meaning.isNotEmpty)
                      Text(
                        widget.meaning,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

              // ACTIONS
              Column(
                children: [
                  FutureBuilder<bool>(
                    future: _dataService.isInBlackHole(verbId),
                    builder: (context, snapshot) {
                      final isSaved = snapshot.data ?? false;
                      return GestureDetector(
                        onTap: () async {
                          final map = {
                            'id': verbId,
                            'word': widget.verb.base,
                            'meaning': widget.meaning,
                            'type': 'verb',
                          };
                          await _dataService.toggleBlackHoleItem(map);
                          setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            isSaved ? Icons.cyclone : Icons.cyclone_outlined,
                            color: isSaved
                                ? Colors.purpleAccent
                                : colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: () async {
                      // Sequence: V1 -> 0.5s Pause -> V2 -> 0.5s Pause -> V3
                      await _ttsService.speak(widget.verb.base);
                      await Future.delayed(const Duration(milliseconds: 500));
                      await _ttsService.speak(widget.verb.past);
                      await Future.delayed(const Duration(milliseconds: 500));
                      await _ttsService.speak(widget.verb.pastParticiple);

                      widget.onRead?.call();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.volume_up_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // EXPANDED: Examples (Directly Visible)
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Divider(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                    height: 1,
                  ),
                  const SizedBox(height: 10),

                  // Examples Box (Visible without further clicking)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(
                        alpha: isDark ? 0.22 : 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.secondary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Example",
                              style: TextStyle(
                                color: Colors.amber.withValues(alpha: 0.9),
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
                          Text(
                            "No English example available.",
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.translate_rounded,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "$localizedLabel Example",
                              style: TextStyle(
                                color: Colors.amber.withValues(alpha: 0.9),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEnglishExample(VerbItem verb) {
    return verb.exampleSentences['english'] ?? '';
  }

  String _getLocalizedExample(VerbItem verb) {
    switch (widget.preferredLanguage) {
      case 'Hindi':
        return verb.exampleSentences['hindi'] ?? '';
      case 'Tamil':
      default:
        return verb.exampleSentences['tamil'] ?? '';
    }
  }

  String _formatExample(String text) {
    if (text.isEmpty) return text;
    return text.replaceAll(RegExp(r'\s*//\s*'), '\n').trim();
  }
}
