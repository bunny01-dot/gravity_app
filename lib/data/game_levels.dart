// ignore_for_file: unnecessary_import

import 'package:gravity_app/data/game_data/vocab/vocab_levels.dart';
import 'package:gravity_app/data/game_data/grammar/grammar_levels.dart';
import 'package:gravity_app/data/game_data/speaking/speaking_levels.dart';
import 'package:gravity_app/data/game_data/listening/listening_levels.dart';
import 'package:gravity_app/data/game_data/fun/fun_levels.dart';
import 'package:gravity_app/data/game_data/reading_writing/reading_writing_levels.dart';
import 'package:gravity_app/data/game_data/multiplayer/multiplayer_levels.dart';

class GameLevels {
  // ------------------------------------------
  // VOCAB LEVEL ACCESS
  // ------------------------------------------
  static Map<String, dynamic> getLevel(int level) {
    if (level <= 1) return VocabLevels.vocabLevel1;
    if (level == 2) return VocabLevels.vocabLevel2;
    if (level == 3) return VocabLevels.vocabLevel3;
    if (level == 4) return VocabLevels.vocabLevel4;
    if (level == 5) return VocabLevels.vocabLevel5;
    if (level == 6) return VocabLevels.vocabLevel6;
    if (level == 7) return VocabLevels.vocabLevel7;
    if (level == 8) return VocabLevels.vocabLevel8;
    if (level == 9) return VocabLevels.vocabLevel9;
    return VocabLevels.vocabLevel10;
  }

  // ------------------------------------------
  // GRAMMAR LEVEL ACCESS
  // ------------------------------------------
  static Map<String, dynamic> getGrammarLevel(int level) {
    if (level <= 1) return GrammarLevels.grammarLevel1;
    if (level == 2) return GrammarLevels.grammarLevel2;
    if (level == 3) return GrammarLevels.grammarLevel3;
    if (level == 4) return GrammarLevels.grammarLevel4;
    if (level == 5) return GrammarLevels.grammarLevel5;
    if (level == 6) return GrammarLevels.grammarLevel6;
    if (level == 7) return GrammarLevels.grammarLevel7;
    if (level == 8) return GrammarLevels.grammarLevel8;
    if (level == 9) return GrammarLevels.grammarLevel9;
    return GrammarLevels.grammarLevel10;
  }

  // ------------------------------------------
  // SPEAKING LEVEL ACCESS
  // ------------------------------------------
  static Map<String, dynamic> getSpeakingLevel(int level) {
    if (level <= 1) return SpeakingLevels.speakingLevel1;
    if (level == 2) return SpeakingLevels.speakingLevel2;
    if (level == 3) return SpeakingLevels.speakingLevel3;
    if (level == 4) return SpeakingLevels.speakingLevel4;
    if (level == 5) return SpeakingLevels.speakingLevel5;
    if (level == 6) return SpeakingLevels.speakingLevel6;
    if (level == 7) return SpeakingLevels.speakingLevel7;
    if (level == 8) return SpeakingLevels.speakingLevel8;
    if (level == 9) return SpeakingLevels.speakingLevel9;
    return SpeakingLevels.speakingLevel10;
  }

  // ------------------------------------------
  // LISTENING LEVEL ACCESS
  // ------------------------------------------
  static Map<String, dynamic> getListeningLevel(int level) {
    if (level <= 1) return ListeningLevels.listeningLevel1;
    if (level == 2) return ListeningLevels.listeningLevel2;
    if (level == 3) return ListeningLevels.listeningLevel3;
    if (level == 4) return ListeningLevels.listeningLevel4;
    if (level == 5) return ListeningLevels.listeningLevel5;
    if (level == 6) return ListeningLevels.listeningLevel6;
    if (level == 7) return ListeningLevels.listeningLevel7;
    if (level == 8) return ListeningLevels.listeningLevel8;
    if (level == 9) return ListeningLevels.listeningLevel9;
    return ListeningLevels.listeningLevel10;
  }

  // ------------------------------------------
  // FUN LEVEL ACCESS
  // ------------------------------------------
  static Map<String, dynamic> getFunLevel(int level) {
    if (level <= 1) return FunLevels.funLevel1;
    if (level == 2) return FunLevels.funLevel2;
    if (level == 3) return FunLevels.funLevel3;
    if (level == 4) return FunLevels.funLevel4;
    if (level == 5) return FunLevels.funLevel5;
    if (level == 6) return FunLevels.funLevel6;
    if (level == 7) return FunLevels.funLevel7;
    if (level == 8) return FunLevels.funLevel8;
    if (level == 9) return FunLevels.funLevel9;
    return FunLevels.funLevel10;
  }

  // ------------------------------------------
  // READING & WRITING LEVEL ACCESS
  // ------------------------------------------
  static Map<String, dynamic> getReadingWritingLevel(int level) {
    if (level <= 1) return ReadingWritingLevels.readingWritingLevel1;
    if (level == 2) return ReadingWritingLevels.readingWritingLevel2;
    if (level == 3) return ReadingWritingLevels.readingWritingLevel3;
    if (level == 4) return ReadingWritingLevels.readingWritingLevel4;
    if (level == 5) return ReadingWritingLevels.readingWritingLevel5;
    if (level == 6) return ReadingWritingLevels.readingWritingLevel6;
    if (level == 7) return ReadingWritingLevels.readingWritingLevel7;
    if (level == 8) return ReadingWritingLevels.readingWritingLevel8;
    if (level == 9) return ReadingWritingLevels.readingWritingLevel9;
    return ReadingWritingLevels.readingWritingLevel10;
  }

  // ------------------------------------------
  // MULTIPLAYER LEVEL ACCESS
  // ------------------------------------------
  static Map<String, dynamic> getMultiplayerLevel(int level) {
    if (level <= 1) return MultiplayerLevels.multiplayerLevel1;
    if (level == 2) return MultiplayerLevels.multiplayerLevel2;
    if (level == 3) return MultiplayerLevels.multiplayerLevel3;
    if (level == 4) return MultiplayerLevels.multiplayerLevel4;
    if (level == 5) return MultiplayerLevels.multiplayerLevel5;
    if (level == 6) return MultiplayerLevels.multiplayerLevel6;
    if (level == 7) return MultiplayerLevels.multiplayerLevel7;
    if (level == 8) return MultiplayerLevels.multiplayerLevel8;
    if (level == 9) return MultiplayerLevels.multiplayerLevel9;
    return MultiplayerLevels.multiplayerLevel10;
  }
}
