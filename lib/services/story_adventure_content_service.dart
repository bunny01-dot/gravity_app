import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class StoryAdventureStory {
  final String id;
  final String title;
  final Map<String, StoryAdventureStep> stepsById;
  final List<StoryAdventureStep> orderedSteps;
  final String startStepId;

  const StoryAdventureStory({
    required this.id,
    required this.title,
    required this.stepsById,
    required this.orderedSteps,
    required this.startStepId,
  });
}

class StoryAdventureStep {
  final String id;
  final int order;
  final String text;
  final List<StoryAdventureChoice> choices;
  final bool isEnding;
  final String endingSummary;

  const StoryAdventureStep({
    required this.id,
    required this.order,
    required this.text,
    required this.choices,
    required this.isEnding,
    required this.endingSummary,
  });
}

class StoryAdventureChoice {
  final String text;
  final String nextStepId;

  const StoryAdventureChoice({
    required this.text,
    required this.nextStepId,
  });
}

class StoryAdventureContentService {
  Future<List<StoryAdventureStory>> getEligibleStories() async {
    final learnedSet = await _getLearnedWordSet();
    if (learnedSet.isEmpty) return [];

    final raw = await rootBundle.loadString(
      'assets/data/story_adventure.csv',
    );
    final rows = const CsvToListConverter().convert(raw, eol: '\n');
    if (rows.isEmpty) return [];

    final dataRows = rows.length > 1 ? rows.skip(1) : <List<dynamic>>[];
    final storySteps = <String, List<_StoryRow>>{};
    for (final row in dataRows) {
      if (row.isEmpty) continue;
      final storyId = _read(row, 0);
      final storyTitle = _read(row, 1);
      final stepId = _read(row, 2);
      final order = int.tryParse(_read(row, 3)) ?? 0;
      final text = _read(row, 4);
      if (storyId.isEmpty || stepId.isEmpty || text.isEmpty) continue;

      storySteps.putIfAbsent(storyId, () => []);
      storySteps[storyId]!.add(
        _StoryRow(
          storyId: storyId,
          storyTitle: storyTitle,
          stepId: stepId,
          order: order,
          text: text,
          choiceAText: _read(row, 5),
          choiceANext: _read(row, 6),
          choiceBText: _read(row, 7),
          choiceBNext: _read(row, 8),
          choiceCText: _read(row, 9),
          choiceCNext: _read(row, 10),
          isEnding: _read(row, 11).toLowerCase() == 'true' ||
              _read(row, 11) == '1',
          endingSummary: _read(row, 12),
        ),
      );
    }

    final stories = <StoryAdventureStory>[];
    for (final entry in storySteps.entries) {
      final rowsForStory = entry.value;
      if (rowsForStory.isEmpty) continue;
      final storyTitle = rowsForStory.first.storyTitle;
      if (!_isLearnedOnly(storyTitle, learnedSet)) continue;

      final stepsById = <String, StoryAdventureStep>{};
      for (final row in rowsForStory) {
        if (!_isLearnedOnly(row.text, learnedSet)) {
          stepsById.clear();
          break;
        }
        if (row.isEnding && row.endingSummary.isNotEmpty) {
          if (!_isLearnedOnly(row.endingSummary, learnedSet)) {
            stepsById.clear();
            break;
          }
        }

        final choices = <StoryAdventureChoice>[];
        if (row.choiceAText.isNotEmpty && row.choiceANext.isNotEmpty) {
          if (!_isLearnedOnly(row.choiceAText, learnedSet)) {
            stepsById.clear();
            break;
          }
          choices.add(
            StoryAdventureChoice(
              text: row.choiceAText,
              nextStepId: row.choiceANext,
            ),
          );
        }
        if (row.choiceBText.isNotEmpty && row.choiceBNext.isNotEmpty) {
          if (!_isLearnedOnly(row.choiceBText, learnedSet)) {
            stepsById.clear();
            break;
          }
          choices.add(
            StoryAdventureChoice(
              text: row.choiceBText,
              nextStepId: row.choiceBNext,
            ),
          );
        }
        if (row.choiceCText.isNotEmpty && row.choiceCNext.isNotEmpty) {
          if (!_isLearnedOnly(row.choiceCText, learnedSet)) {
            stepsById.clear();
            break;
          }
          choices.add(
            StoryAdventureChoice(
              text: row.choiceCText,
              nextStepId: row.choiceCNext,
            ),
          );
        }

        stepsById[row.stepId] = StoryAdventureStep(
          id: row.stepId,
          order: row.order,
          text: row.text,
          choices: choices,
          isEnding: row.isEnding,
          endingSummary: row.endingSummary,
        );
      }

      if (stepsById.isEmpty) continue;

      final orderedSteps = stepsById.values.toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      if (orderedSteps.length < 8) continue;
      final endings = orderedSteps.where((step) => step.isEnding).length;
      if (endings < 2) continue;
      final branches = orderedSteps.where((step) => step.choices.length >= 2).length;
      if (branches < 2) continue;

      if (!_allChoiceTargetsExist(stepsById)) continue;

      final startStepId = orderedSteps.first.id;

      stories.add(
        StoryAdventureStory(
          id: entry.key,
          title: storyTitle,
          stepsById: stepsById,
          orderedSteps: orderedSteps,
          startStepId: startStepId,
        ),
      );
    }

    return stories;
  }

  bool _allChoiceTargetsExist(Map<String, StoryAdventureStep> stepsById) {
    for (final step in stepsById.values) {
      for (final choice in step.choices) {
        if (!stepsById.containsKey(choice.nextStepId)) return false;
      }
    }
    return true;
  }

  bool _isLearnedOnly(String text, Set<String> learnedSet) {
    final words = RegExp(r"[A-Za-z']+")
        .allMatches(text)
        .map((match) => match.group(0) ?? '')
        .map(_normalizeWord)
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return false;
    for (final word in words) {
      if (!learnedSet.contains(word)) return false;
    }
    return true;
  }

  String _normalizeWord(String value) {
    final lower = value.trim().toLowerCase();
    return lower.replaceAll(RegExp(r"[^a-z']"), '');
  }

  String _read(List<dynamic> row, int index) {
    if (index >= row.length) return '';
    return row[index]?.toString().trim() ?? '';
  }

  Future<Set<String>> _getLearnedWordSet() async {
    final prefs = await SharedPreferences.getInstance();
    final learnedIds = prefs.getStringList('learned_vocab_ids') ?? [];
    return learnedIds
        .map(_normalizeWord)
        .where((word) => word.isNotEmpty)
        .toSet();
  }
}

class _StoryRow {
  final String storyId;
  final String storyTitle;
  final String stepId;
  final int order;
  final String text;
  final String choiceAText;
  final String choiceANext;
  final String choiceBText;
  final String choiceBNext;
  final String choiceCText;
  final String choiceCNext;
  final bool isEnding;
  final String endingSummary;

  const _StoryRow({
    required this.storyId,
    required this.storyTitle,
    required this.stepId,
    required this.order,
    required this.text,
    required this.choiceAText,
    required this.choiceANext,
    required this.choiceBText,
    required this.choiceBNext,
    required this.choiceCText,
    required this.choiceCNext,
    required this.isEnding,
    required this.endingSummary,
  });
}
