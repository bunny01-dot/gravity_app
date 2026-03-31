import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gravity_app/widgets/mastery_level_map.dart';

class StageJourneyMapScreen extends StatefulWidget {
  const StageJourneyMapScreen({
    super.key,
    required this.completedStage,
    required this.unlockedStage,
  });

  final int completedStage;
  final int unlockedStage;

  @override
  State<StageJourneyMapScreen> createState() => _StageJourneyMapScreenState();
}

class _StageJourneyMapScreenState extends State<StageJourneyMapScreen> {
  late final int _completedStage;
  late final int _unlockedStage;
  late final int _visibleStageCount;
  late final List<Map<String, String>> _levels;
  late List<String> _completedIds;
  late int _unlockedLevelCount;
  bool _hasTriggeredUnlockAnimation = false;

  @override
  void initState() {
    super.initState();
    _completedStage = widget.completedStage < 1 ? 1 : widget.completedStage;
    _unlockedStage = widget.unlockedStage > _completedStage
        ? widget.unlockedStage
        : _completedStage + 1;
    _visibleStageCount = math.max(_unlockedStage + 2, 8);
    _levels = List<Map<String, String>>.generate(_visibleStageCount, (index) {
      final stageNumber = index + 1;
      return {
        'id': 'stage_$stageNumber',
        'stage': '$stageNumber',
        'title': 'Level $stageNumber',
      };
    });
    _completedIds = _buildCompletedIds(upToStage: _completedStage - 1);
    _unlockedLevelCount = _completedStage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!mounted || _hasTriggeredUnlockAnimation) return;
        setState(() {
          _hasTriggeredUnlockAnimation = true;
          _completedIds = _buildCompletedIds(upToStage: _completedStage);
          _unlockedLevelCount = _unlockedStage;
        });
      });
    });
  }

  List<String> _buildCompletedIds({required int upToStage}) {
    final capped = upToStage.clamp(0, _visibleStageCount);
    return List<String>.generate(capped, (index) => 'stage_${index + 1}');
  }

  bool _isLockedLevel(Map<String, String> level, int index) {
    return index + 1 > _unlockedStage;
  }

  String _lockReason(Map<String, String> level, int index) {
    final stageNumber = index + 1;
    return 'Finish Level ${stageNumber - 1} first.';
  }

  void _handleLevelTap(Map<String, String> level) {
    final stageNumber = int.tryParse(level['stage'] ?? '') ?? 0;
    if (stageNumber == _unlockedStage) {
      Navigator.of(context).pop(true);
      return;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final message = stageNumber < _unlockedStage
        ? 'Level $stageNumber is complete. Tap Level $_unlockedStage to continue.'
        : 'Level $stageNumber will unlock later.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: colorScheme.onSecondaryContainer),
          ),
          backgroundColor: colorScheme.secondaryContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          MasteryLevelMap(
            title: 'Your Journey',
            exercises: _levels,
            completedIds: _completedIds,
            unlockedLevelCount: _unlockedLevelCount,
            onTapExercise: _handleLevelTap,
            isLockedOverride: _isLockedLevel,
            lockReasonOverride: _lockReason,
            onBack: () => Navigator.of(context).pop(),
            useStarRating: false,
            showInfoButton: false,
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: IgnorePointer(
              ignoring: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Level $_unlockedStage unlocked',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap the glowing Level $_unlockedStage node to continue learning.',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
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
}
