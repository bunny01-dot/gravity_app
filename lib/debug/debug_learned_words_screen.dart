import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/word_match_unlock_service.dart';
import 'package:gravity_app/services/stage_progress_service.dart';

class DebugLearnedWordsScreen extends StatefulWidget {
  const DebugLearnedWordsScreen({super.key});

  @override
  State<DebugLearnedWordsScreen> createState() =>
      _DebugLearnedWordsScreenState();
}

class _DebugLearnedWordsScreenState extends State<DebugLearnedWordsScreen> {
  String _debugInfo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final stageService = StageProgressService();
    final stage = await stageService.getCurrentStage(prefs: prefs);

    // Force reload
    await prefs.reload();

    // Get all relevant data
    final vocabIds = prefs.getStringList('learned_vocab_ids') ?? [];
    final verbIds = prefs.getStringList('learned_verbs_ids') ?? [];
    final vocabDone = prefs.getBool(stageService.vocabTaskKey(stage)) ?? false;
    final verbsDone = prefs.getBool(stageService.verbsTaskKey(stage)) ?? false;
    final speakingDone =
        prefs.getBool(stageService.speakingTaskKey(stage)) ?? false;
    final totalLearnedWords = vocabIds.length + verbIds.length;

    // Build debug string
    String info = 'DEBUG INFO\n\n';
    info += 'Level: $stage\n\n';
    info += 'DAILY TASKS:\n';
    info += '  Vocab: ${vocabDone ? "YES" : "NO"}\n';
    info += '  Verbs: ${verbsDone ? "YES" : "NO"}\n';
    info += '  Speaking: ${speakingDone ? "YES" : "NO"}\n\n';
    info += 'LEARNED WORDS:\n';
    info += '  Vocab IDs: ${vocabIds.length} words\n';
    info += '  Verb IDs: ${verbIds.length} words\n';
    info += '  TOTAL: $totalLearnedWords words\n\n';
    info += 'GAME REQUIREMENTS:\n';
    final wordMatchRequired = WordMatchUnlockService.requiredWordsForDifficulty(
      'Easy',
    );
    final wordMatchUnlocked = WordMatchUnlockService.isWordMatchUnlocked(
      totalLearnedWords,
      difficulty: 'Easy',
    );
    info +=
        '  Word Match: needs $wordMatchRequired, ${wordMatchUnlocked ? "UNLOCKED" : "LOCKED"}\n';
    info +=
        '  Flashcard: needs 3, ${vocabIds.length + verbIds.length >= 3 ? "UNLOCKED" : "LOCKED"}\n';
    info +=
        '  Word Builder: needs 10, ${vocabIds.length + verbIds.length >= 10 ? "UNLOCKED" : "LOCKED"}\n\n';
    info += 'VOCAB IDs:\n';
    if (vocabIds.isEmpty) {
      info += '  (empty)\n';
    } else {
      info += '  ${vocabIds.take(10).join(", ")}\n';
      if (vocabIds.length > 10) {
        info += '  ...and ${vocabIds.length - 10} more\n';
      }
    }
    info += '\nVERB IDs:\n';
    if (verbIds.isEmpty) {
      info += '  (empty)\n';
    } else {
      info += '  ${verbIds.take(10).join(", ")}\n';
      if (verbIds.length > 10) info += '  ...and ${verbIds.length - 10} more\n';
    }

    setState(() {
      _debugInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Learned Words'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: SelectableText(
                _debugInfo,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  color: Colors.greenAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDebugInfo,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Data'),
            ),
          ],
        ),
      ),
    );
  }
}
