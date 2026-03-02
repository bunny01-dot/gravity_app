// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'games_hub_card.dart';

extension GamesGridSheetLogic on _GamesGridSheetState {
  Future<void> _loadAvailability() async {
    final learnedItems = await DataService().getLearnedVocabularyItems();
    final learnedSet = learnedItems
        .map((item) => _normalizeWord(item.word))
        .where((word) => word.isNotEmpty)
        .toSet();
    final grammarKnownSet = _buildGrammarKnownSet(learnedSet);
    final learnedCount = learnedSet.length;
    final learnedVerbs = await DataService().getLearnedVerbItems();
    final learnedItemCount = learnedItems.length;
    final synonymCapableCount = _countSynonymCapableWords(learnedItems);
    final antonymCapableCount = _countAntonymCapableWords(learnedItems);
    final wordSearchAvailability = _getWordSearchAvailability(learnedItems);
    final fillTheGapCount = _countFillTheGapQuestions(learnedItems);
    final partsOfSpeechCount = _countPartsOfSpeechQuestions(
      learnedItems,
      grammarKnownSet,
    );
    final grammarChoiceCount = _countGrammarChoiceQuestions(
      learnedItems,
      grammarKnownSet,
    );
    final tenseTrainerCount = _countTenseTrainerQuestions(
      grammarKnownSet,
      learnedVerbs,
    );
    final sentenceBuilderCount = _countSentenceBuilderQuestions(
      learnedItems,
      grammarKnownSet,
    );
    final sentenceScrambleCount = _countSentenceScrambleQuestions(
      learnedItems,
      learnedVerbs,
    );
    final errorHuntCount = _countErrorHuntQuestions(
      learnedItems,
      grammarKnownSet,
    );
    final dailySentences = await DailySentenceService().getDailySentences();
    final repeatAfterMeCount = _countRepeatAfterMeItems(
      learnedItems,
      grammarKnownSet,
      dailySentences,
    );
    final pronunciationMatchCount = _countPronunciationMatchQuestions(
      learnedItems,
      learnedSet,
    );
    final tongueTwisterCount =
        (await TongueTwisterContentService().getEligiblePhrases()).length;
    final readAloudCount =
        (await ReadAloudContentService().getEligibleItems()).length;
    final dictationCount =
        (await DictationContentService().getEligibleSentences()).length;
    final audioGuessCount =
        (await AudioGuessContentService().getEligibleQuestions()).length;
    final conversationCatchCount =
        (await ConversationCatchContentService().getEligibleConversations())
            .length;
    final hangmanCount =
        (await HangmanContentService().getEligibleWords()).length;
    final quizBattleCount =
        (await QuizBattleContentService().getEligibleQuestions()).length;
    final storyAdventureCount =
        (await StoryAdventureContentService().getEligibleStories()).length;
    final hasGrammarWarmup =
        learnedItemCount >= _GamesGridSheetState._minGrammarWarmupWords;
    final hasSentenceScrambleWarmup =
        learnedItemCount >=
            _GamesGridSheetState._minSentenceScrambleWarmupWords ||
        learnedVerbs.length >= 2;
    final hasTenseWarmup =
        learnedVerbs.length >= _GamesGridSheetState._minTenseWarmupVerbs;
    if (!mounted) return;
    setState(() {
      _isFlashcardLocked = false;
      _isWordBuilderLocked =
          learnedCount < _GamesGridSheetState._minWordBuilderWords;
      _isSynonymSwapLocked =
          synonymCapableCount < _GamesGridSheetState._minSynonymSwapWords;
      _isAntonymAttackLocked =
          antonymCapableCount < _GamesGridSheetState._minAntonymAttackWords;
      _isWordSearchLocked = wordSearchAvailability.isLocked;
      _isFillTheGapLocked = fillTheGapCount == 0;
      _isPartsOfSpeechLocked = partsOfSpeechCount == 0 && !hasGrammarWarmup;
      _isGrammarChoiceLocked = grammarChoiceCount == 0 && !hasGrammarWarmup;
      _isTenseTrainerLocked = tenseTrainerCount == 0 && !hasTenseWarmup;
      _isSentenceBuilderLocked = sentenceBuilderCount == 0 && !hasGrammarWarmup;
      _isSentenceScrambleLocked =
          sentenceScrambleCount == 0 && !hasSentenceScrambleWarmup;
      _isErrorHuntLocked = errorHuntCount == 0 && !hasGrammarWarmup;
      _isRepeatAfterMeLocked = repeatAfterMeCount == 0;
      _isPronunciationMatchLocked = pronunciationMatchCount == 0;
      _isTongueTwisterLocked = tongueTwisterCount == 0;
      _isReadAloudLocked = readAloudCount == 0;
      _isDictationLocked = dictationCount == 0;
      _isAudioGuessLocked = audioGuessCount == 0;
      _isConversationCatchLocked = conversationCatchCount == 0;
      _isHangmanLocked = hangmanCount == 0;
      _isQuizBattleLocked = quizBattleCount < 10;
      _isStoryAdventureLocked = storyAdventureCount == 0;
      _isSpeedVocabLocked =
          learnedItemCount < _GamesGridSheetState._minSpeedVocabWords;
      _isWordRaceLocked = learnedItemCount == 0;
      _isAvailabilityLoading = false;
    });
  }

  String _availabilitySubtitle(String readyText, bool hasContent) {
    if (_isAvailabilityLoading) return 'Checking availability...';
    if (hasContent) return readyText;
    return 'Learn a few words to play this mode.';
  }

  int _countSynonymCapableWords(List<VocabularyItem> items) {
    final learnedMap = <String, VocabularyItem>{};
    for (final item in items) {
      learnedMap[_normalize(item.word)] = item;
    }

    int count = 0;
    for (final item in items) {
      final pos = item.pos.trim().toLowerCase();
      if (pos.isEmpty) continue;
      final synonyms = item.synonyms
          .map(_normalize)
          .where((syn) => syn.isNotEmpty && syn != _normalize(item.word))
          .toList();
      if (synonyms.isEmpty) continue;

      final antonyms = item.antonyms
          .map(_normalize)
          .where((ant) => ant.isNotEmpty)
          .toSet();

      final hasValidSynonym = synonyms.any((syn) {
        final match = learnedMap[syn];
        if (match == null) return false;
        if (antonyms.contains(syn)) return false;
        return match.pos.trim().toLowerCase() == pos;
      });

      if (hasValidSynonym) {
        count++;
      }
    }

    return count;
  }

  int _countAntonymCapableWords(List<VocabularyItem> items) {
    final learnedMap = <String, VocabularyItem>{};
    for (final item in items) {
      learnedMap[_normalize(item.word)] = item;
    }

    int count = 0;
    for (final item in items) {
      final pos = item.pos.trim().toLowerCase();
      if (pos.isEmpty) continue;
      final antonyms = item.antonyms
          .map(_normalize)
          .where((ant) => ant.isNotEmpty && ant != _normalize(item.word))
          .toList();
      if (antonyms.isEmpty) continue;

      final synonyms = item.synonyms
          .map(_normalize)
          .where((syn) => syn.isNotEmpty)
          .toSet();

      final hasValidAntonym = antonyms.any((ant) {
        final match = learnedMap[ant];
        if (match == null) return false;
        if (synonyms.contains(ant)) return false;
        if (_isMorphologicalVariant(item.word, ant)) return false;
        return true;
      });

      if (hasValidAntonym) {
        count++;
      }
    }

    return count;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  String _normalizeWord(String value) {
    final lower = _normalize(value);
    final cleaned = lower.replaceAll(RegExp(r"[^a-z']"), '');
    return cleaned.replaceAll(RegExp(r"^'+|'+$"), '');
  }

  String? _normalizePos(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'noun':
        return 'Noun';
      case 'verb':
        return 'Verb';
      case 'adjective':
      case 'adj':
        return 'Adjective';
      case 'adverb':
      case 'adv':
        return 'Adverb';
      case 'pronoun':
      case 'pron':
        return 'Pronoun';
      case 'preposition':
      case 'prep':
        return 'Preposition';
      case 'conjunction':
      case 'conj':
        return 'Conjunction';
      case 'article':
      case 'determiner':
      case 'det':
        return 'Article / Determiner';
      default:
        return null;
    }
  }

  Set<String> _buildGrammarKnownSet(Set<String> learnedWords) {
    return <String>{
      ...learnedWords,
      ..._GamesGridSheetState._derivedGrammarPos.keys,
    };
  }

  Map<String, Set<String>> _buildPosMap(
    List<VocabularyItem> learnedItems,
    Set<String> learnedSet,
  ) {
    final map = <String, Set<String>>{};

    for (final item in learnedItems) {
      final word = _normalizeWord(item.word);
      if (word.isEmpty || !learnedSet.contains(word)) continue;
      final pos = _normalizePos(item.pos);
      if (pos == null) continue;
      map.putIfAbsent(word, () => <String>{}).add(pos);
    }

    for (final entry in _GamesGridSheetState._derivedGrammarPos.entries) {
      map.putIfAbsent(entry.key, () => <String>{}).add(entry.value);
    }

    return map;
  }

  bool _hasPlaceholder(String sentence) {
    return RegExp(r'_{2,}').hasMatch(sentence);
  }

  bool _hasGrammarChoiceQuestion(
    String sentence,
    Set<String> learnedSet,
    Map<String, Set<String>> posMap,
  ) {
    if (_hasPlaceholder(sentence)) return false;
    if (RegExp(r'\d').hasMatch(sentence)) return false;

    final words = RegExp(r"[A-Za-z']+")
        .allMatches(sentence)
        .map((match) => _normalizeWord(match.group(0) ?? ''))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.length < 3) return false;
    if (words.toSet().length != words.length) return false;

    for (final word in words) {
      if (!learnedSet.contains(word)) return false;
      final posSet = posMap[word];
      if (posSet == null || posSet.length != 1) return false;
    }

    if (_hasBeAgreementQuestion(words, learnedSet)) return true;
    if (_hasArticleQuestion(words, learnedSet)) return true;

    return false;
  }

  int _countTenseTrainerQuestions(
    Set<String> learnedSet,
    List<VerbItem> learnedVerbs,
  ) {
    if (learnedVerbs.isEmpty) return 0;

    final verbForms = _buildVerbFormSet(learnedVerbs);
    int count = 0;

    for (final verb in learnedVerbs) {
      if (verb.base.isEmpty || verb.past.isEmpty || verb.present3rd.isEmpty) {
        continue;
      }

      if (!learnedSet.contains(_normalizeWord(verb.base))) continue;

      for (final tense in const ['present', 'past', 'future']) {
        final sentence = verb.exampleSentences[tense]?.trim() ?? '';
        if (sentence.isEmpty) continue;
        if (_hasPlaceholder(sentence)) continue;
        if (RegExp(r'\d').hasMatch(sentence)) continue;

        final words = RegExp(r"[A-Za-z']+")
            .allMatches(sentence)
            .map((match) => _normalizeWord(match.group(0) ?? ''))
            .where((word) => word.isNotEmpty)
            .toList();

        if (words.length < 3) continue;
        if (!_allLearned(words, learnedSet)) continue;
        if (_countVerbForms(words, verbForms) != 1) continue;

        if (tense == 'future') {
          if (!_hasFuturePattern(words, learnedSet)) continue;
          if (!_canBuildFutureOptions(words, verb, learnedSet)) continue;
        } else {
          if (_containsAuxiliary(words)) continue;
          if (!_canBuildSimpleOptions(words, verb, tense, learnedSet)) continue;
        }

        count++;
      }
    }

    return count;
  }

  Set<String> _buildVerbFormSet(List<VerbItem> verbs) {
    final set = <String>{};
    for (final verb in verbs) {
      if (verb.base.isNotEmpty) set.add(_normalizeWord(verb.base));
      if (verb.past.isNotEmpty) set.add(_normalizeWord(verb.past));
      if (verb.present3rd.isNotEmpty) {
        set.add(_normalizeWord(verb.present3rd));
      }
    }
    return set;
  }

  bool _allLearned(List<String> words, Set<String> learnedSet) {
    for (final word in words) {
      if (!learnedSet.contains(word)) return false;
    }
    return true;
  }

  int _countVerbForms(List<String> words, Set<String> verbForms) {
    int count = 0;
    for (final word in words) {
      if (verbForms.contains(word)) count++;
    }
    return count;
  }

  bool _containsAuxiliary(List<String> words) {
    for (final word in words) {
      if (_tenseAuxiliaries.contains(word)) return true;
    }
    return false;
  }

  bool _hasFuturePattern(List<String> words, Set<String> learnedSet) {
    if (!words.contains('will')) return false;
    if (!learnedSet.contains('will')) return false;
    for (final word in words) {
      if (word == 'will') continue;
      if (_tenseAuxiliaries.contains(word)) return false;
    }
    return true;
  }

  bool _canBuildSimpleOptions(
    List<String> words,
    VerbItem verb,
    String tense,
    Set<String> learnedSet,
  ) {
    final base = _normalizeWord(verb.base);
    final past = _normalizeWord(verb.past);
    final present3rd = _normalizeWord(verb.present3rd);

    final present = _presentFormForSubject(words, present3rd, base);
    final hasPresent = words.contains(present);
    final hasBase = words.contains(base);
    final hasPresent3rd = words.contains(present3rd);
    final hasPast = words.contains(past);

    if (tense == 'present') {
      if (!(hasPresent || hasBase || hasPresent3rd)) return false;
      if (!learnedSet.contains(past)) return false;
      return past != present;
    }

    if (tense == 'past') {
      if (!hasPast) return false;
      if (!learnedSet.contains(present)) return false;
      return past != present;
    }

    return false;
  }

  bool _canBuildFutureOptions(
    List<String> words,
    VerbItem verb,
    Set<String> learnedSet,
  ) {
    final base = _normalizeWord(verb.base);
    final past = _normalizeWord(verb.past);
    final present3rd = _normalizeWord(verb.present3rd);

    if (!words.contains(base)) return false;

    final present = _presentFormForSubject(words, present3rd, base);
    final canPast = learnedSet.contains(past) && past != base;
    final canPresent = learnedSet.contains(present) && present != base;

    return canPast || canPresent;
  }

  String _presentFormForSubject(
    List<String> words,
    String present3rd,
    String base,
  ) {
    if (words.isEmpty) return base;
    final subject = words.first;
    if (subject == 'he' || subject == 'she' || subject == 'it') {
      return present3rd;
    }
    return base;
  }

  static const Set<String> _tenseAuxiliaries = {
    'am',
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'being',
    'has',
    'have',
    'had',
    'do',
    'does',
    'did',
    'can',
    'could',
    'should',
    'would',
    'may',
    'might',
    'must',
    'shall',
    'will',
  };

  bool _hasBeAgreementQuestion(List<String> words, Set<String> learnedSet) {
    if (words.length < 2) return false;
    final subject = words[0];
    final verb = words[1];
    final expected = _expectedPresentBe(subject);
    if (expected == null) return false;
    if (!_presentBeForms.contains(verb)) return false;
    if (verb != expected) return false;

    for (final form in _presentBeForms) {
      if (form == expected) continue;
      if (learnedSet.contains(form)) return true;
    }
    return false;
  }

  bool _hasArticleQuestion(List<String> words, Set<String> learnedSet) {
    for (int i = 0; i < words.length - 1; i++) {
      final article = words[i];
      if (article != 'a' && article != 'an') continue;
      final nextWord = words[i + 1];
      if (nextWord.isEmpty) continue;
      final expected = _startsWithVowel(nextWord) ? 'an' : 'a';
      if (article != expected) continue;
      final wrong = expected == 'a' ? 'an' : 'a';
      if (!learnedSet.contains(wrong)) continue;
      return true;
    }
    return false;
  }

  bool _startsWithVowel(String word) {
    return RegExp(r'^[aeiou]').hasMatch(word);
  }

  String? _expectedPresentBe(String subject) {
    switch (subject) {
      case 'i':
        return 'am';
      case 'you':
      case 'we':
      case 'they':
        return 'are';
      case 'he':
      case 'she':
      case 'it':
        return 'is';
      default:
        return null;
    }
  }

  static const Set<String> _presentBeForms = {'am', 'is', 'are'};

  int _countPartsOfSpeechQuestions(
    List<VocabularyItem> learnedItems,
    Set<String> learnedSet,
  ) {
    final posMap = _buildPosMap(learnedItems, learnedSet);
    final sentences = <String>[];
    final seen = <String>{};

    for (final item in learnedItems) {
      final sentence = item.exampleSentence.trim();
      if (sentence.isEmpty) continue;
      final key = sentence.toLowerCase();
      if (seen.add(key)) {
        sentences.add(sentence);
      }
    }

    int count = 0;
    for (final sentence in sentences) {
      if (_hasPlaceholder(sentence)) continue;
      if (RegExp(r'\d').hasMatch(sentence)) continue;

      final words = RegExp(r"[A-Za-z']+")
          .allMatches(sentence)
          .map((match) => _normalizeWord(match.group(0) ?? ''))
          .where((word) => word.isNotEmpty)
          .toList();

      if (words.length < 3) continue;

      bool valid = true;
      for (final word in words) {
        if (!learnedSet.contains(word)) {
          valid = false;
          break;
        }
        final posSet = posMap[word];
        if (posSet == null || posSet.length != 1) {
          valid = false;
          break;
        }
      }

      if (valid) {
        count++;
      }
    }

    return count;
  }

  int _countGrammarChoiceQuestions(
    List<VocabularyItem> learnedItems,
    Set<String> learnedSet,
  ) {
    final posMap = _buildPosMap(learnedItems, learnedSet);
    final sentences = <String>[];
    final seen = <String>{};

    for (final item in learnedItems) {
      final sentence = item.exampleSentence.trim();
      if (sentence.isEmpty) continue;
      final key = sentence.toLowerCase();
      if (seen.add(key)) {
        sentences.add(sentence);
      }
    }

    int count = 0;
    for (final sentence in sentences) {
      if (_hasGrammarChoiceQuestion(sentence, learnedSet, posMap)) {
        count++;
      }
    }

    return count;
  }

  int _countSentenceBuilderQuestions(
    List<VocabularyItem> learnedItems,
    Set<String> learnedSet,
  ) {
    final posMap = _buildPosMap(learnedItems, learnedSet);
    final sentences = <String>[];
    final seen = <String>{};

    for (final item in learnedItems) {
      final sentence = item.exampleSentence.trim();
      if (sentence.isEmpty) continue;
      final key = sentence.toLowerCase();
      if (seen.add(key)) {
        sentences.add(sentence);
      }
    }

    int count = 0;
    for (final sentence in sentences) {
      if (_isSentenceBuilderEligible(sentence, learnedSet, posMap)) {
        count++;
      }
    }

    return count;
  }

  int _countSentenceScrambleQuestions(
    List<VocabularyItem> learnedItems,
    List<VerbItem> learnedVerbs,
  ) {
    final sentences = <String>{};

    for (final item in learnedItems) {
      final sentence = item.exampleSentence.trim();
      if (_isSentenceScrambleEligible(sentence)) {
        sentences.add(sentence.toLowerCase());
      }
    }

    for (final verb in learnedVerbs) {
      for (final sentence in verb.exampleSentences.values) {
        final trimmed = sentence.trim();
        if (_isSentenceScrambleEligible(trimmed)) {
          sentences.add(trimmed.toLowerCase());
        }
      }
    }

    return sentences.length;
  }

  bool _isSentenceScrambleEligible(String sentence) {
    if (sentence.isEmpty) return false;
    final words = sentence
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();
    return words.length >= 3 && words.length <= 12;
  }

  bool _isSentenceBuilderEligible(
    String sentence,
    Set<String> learnedSet,
    Map<String, Set<String>> posMap,
  ) {
    if (_hasPlaceholder(sentence)) return false;
    if (RegExp(r'\d').hasMatch(sentence)) return false;
    if (RegExp(r'[?!]').hasMatch(sentence)) return false;
    if (RegExp(r'[,;:]').hasMatch(sentence)) return false;

    final words = RegExp(r"[A-Za-z']+")
        .allMatches(sentence)
        .map((match) => _normalizeWord(match.group(0) ?? ''))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.length < 3) return false;

    final posList = <String>[];
    for (final word in words) {
      if (!learnedSet.contains(word)) return false;
      final posSet = posMap[word];
      if (posSet == null || posSet.length != 1) return false;
      posList.add(posSet.first);
    }

    if (posList.any(
      (pos) => pos == 'Preposition' || pos == 'Conjunction' || pos == 'Adverb',
    )) {
      return false;
    }

    final verbIndices = <int>[];
    for (int i = 0; i < posList.length; i++) {
      if (posList[i] == 'Verb') verbIndices.add(i);
    }
    if (verbIndices.length != 1) return false;

    final verbIndex = verbIndices.first;
    if (verbIndex == 0) return false;

    final subjectPos = posList.sublist(0, verbIndex);
    final objectPos = verbIndex < posList.length - 1
        ? posList.sublist(verbIndex + 1)
        : <String>[];

    if (!_matchesNounPhrase(subjectPos)) return false;

    final verbWord = words[verbIndex];
    if (objectPos.isEmpty) {
      return true;
    }

    if (_isBeVerb(verbWord) &&
        objectPos.length == 1 &&
        objectPos.first == 'Adjective') {
      return true;
    }

    return _matchesNounPhrase(objectPos);
  }

  bool _matchesNounPhrase(List<String> posList) {
    if (posList.isEmpty) return false;
    int index = 0;
    if (posList[index] == 'Article / Determiner') {
      index++;
      if (index >= posList.length) return false;
    }

    int adjectiveCount = 0;
    while (index < posList.length - 1 && posList[index] == 'Adjective') {
      adjectiveCount++;
      if (adjectiveCount > 1) return false;
      index++;
    }

    if (index != posList.length - 1) return false;

    final last = posList.last;
    return last == 'Noun' || last == 'Pronoun';
  }

  bool _isBeVerb(String word) {
    return word == 'am' ||
        word == 'is' ||
        word == 'are' ||
        word == 'was' ||
        word == 'were';
  }

  int _countErrorHuntQuestions(
    List<VocabularyItem> learnedItems,
    Set<String> learnedSet,
  ) {
    final posMap = _buildPosMap(learnedItems, learnedSet);
    final sentences = <String>[];
    final seen = <String>{};

    for (final item in learnedItems) {
      final sentence = item.exampleSentence.trim();
      if (sentence.isEmpty) continue;
      final key = sentence.toLowerCase();
      if (seen.add(key)) {
        sentences.add(sentence);
      }
    }

    int count = 0;
    for (final sentence in sentences) {
      if (_canBuildErrorQuestion(sentence, learnedSet, posMap)) {
        count++;
      }
    }

    return count;
  }

  bool _canBuildErrorQuestion(
    String sentence,
    Set<String> learnedSet,
    Map<String, Set<String>> posMap,
  ) {
    if (_hasPlaceholder(sentence)) return false;
    if (RegExp(r'\d').hasMatch(sentence)) return false;
    if (RegExp(r'[?!]').hasMatch(sentence)) return false;
    if (RegExp(r'[,;:]').hasMatch(sentence)) return false;

    final words = RegExp(r"[A-Za-z']+")
        .allMatches(sentence)
        .map((match) => _normalizeWord(match.group(0) ?? ''))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.length < 3) return false;
    if (words.toSet().length != words.length) return false;

    final posList = <String>[];
    for (final word in words) {
      if (!learnedSet.contains(word)) return false;
      final posSet = posMap[word];
      if (posSet == null || posSet.length != 1) return false;
      posList.add(posSet.first);
    }

    if (posList.any(
      (pos) => pos == 'Preposition' || pos == 'Conjunction' || pos == 'Adverb',
    )) {
      return false;
    }

    final verbIndices = <int>[];
    for (int i = 0; i < posList.length; i++) {
      if (posList[i] == 'Verb') verbIndices.add(i);
    }
    if (verbIndices.length != 1) return false;

    final verbIndex = verbIndices.first;
    if (verbIndex == 0) return false;

    final subjectPos = posList.sublist(0, verbIndex);
    final objectPos = verbIndex < posList.length - 1
        ? posList.sublist(verbIndex + 1)
        : <String>[];

    if (!_matchesNounPhrase(subjectPos)) return false;

    final verbWord = words[verbIndex];
    if (objectPos.isNotEmpty) {
      if (_isBeVerb(verbWord) &&
          objectPos.length == 1 &&
          objectPos.first == 'Adjective') {
        // ok
      } else if (!_matchesNounPhrase(objectPos)) {
        return false;
      }
    }

    if (_canInjectAgreementError(words, verbIndex, learnedSet)) return true;
    if (_canInjectArticleError(words, learnedSet)) return true;
    if (_canInjectSimpleTenseError(words, verbIndex, learnedSet)) return true;

    return false;
  }

  bool _canInjectAgreementError(
    List<String> words,
    int verbIndex,
    Set<String> learnedSet,
  ) {
    final subject = words.first;
    if (subject != 'he' && subject != 'she' && subject != 'it') return false;
    final verb = words[verbIndex];
    if (!verb.endsWith('s')) return false;
    final wrong = _stripSimpleS(verb);
    if (wrong == verb) return false;
    return learnedSet.contains(wrong);
  }

  bool _canInjectArticleError(List<String> words, Set<String> learnedSet) {
    for (int i = 0; i < words.length - 1; i++) {
      final article = words[i];
      if (article != 'a' && article != 'an') continue;
      final next = words[i + 1];
      final expected = _startsWithVowel(next) ? 'an' : 'a';
      if (article != expected) continue;
      final wrong = expected == 'a' ? 'an' : 'a';
      if (!learnedSet.contains(wrong)) continue;
      return true;
    }
    return false;
  }

  bool _canInjectSimpleTenseError(
    List<String> words,
    int verbIndex,
    Set<String> learnedSet,
  ) {
    final verb = words[verbIndex];
    if (verb.endsWith('ed')) return false;
    final wrong = verb.endsWith('s') ? _stripSimpleS(verb) : '${verb}ed';
    if (wrong == verb) return false;
    return learnedSet.contains(wrong);
  }

  String _stripSimpleS(String word) {
    if (word.endsWith('es')) {
      return word.substring(0, word.length - 2);
    }
    if (word.endsWith('s')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  String _canonicalForm(String value) {
    var normalized = _normalize(value);
    if (normalized.length > 4 && normalized.endsWith('ing')) {
      normalized = normalized.substring(0, normalized.length - 3);
    } else if (normalized.length > 3 && normalized.endsWith('ed')) {
      normalized = normalized.substring(0, normalized.length - 2);
    } else if (normalized.length > 3 && normalized.endsWith('es')) {
      normalized = normalized.substring(0, normalized.length - 2);
    } else if (normalized.length > 2 && normalized.endsWith('s')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  bool _isMorphologicalVariant(String a, String b) {
    return _canonicalForm(a) == _canonicalForm(b);
  }

  int _countRepeatAfterMeItems(
    List<VocabularyItem> learnedItems,
    Set<String> learnedSet,
    List<DailySentence> dailySentences,
  ) {
    final seen = <String>{};
    int count = 0;

    void addText(String text) {
      final key = _normalizeSentenceKey(text);
      if (key.isEmpty || !seen.add(key)) return;
      count++;
    }

    for (final item in learnedItems) {
      final word = _normalizeWord(item.word);
      if (word.isEmpty || !learnedSet.contains(word)) continue;
      addText(item.word);
    }

    for (final sentence in dailySentences) {
      if (_isSentenceLearnedOnly(sentence.text, learnedSet)) {
        addText(sentence.text);
      }
    }

    for (final item in learnedItems) {
      final sentence = item.exampleSentence.trim();
      if (sentence.isEmpty) continue;
      if (_isSentenceLearnedOnly(sentence, learnedSet)) {
        addText(sentence);
      }
    }

    return count;
  }

  int _countPronunciationMatchQuestions(
    List<VocabularyItem> learnedItems,
    Set<String> learnedSet,
  ) {
    int count = 0;
    for (final item in learnedItems) {
      final word = item.word.trim();
      final normalizedWord = _normalizeWord(word);
      if (normalizedWord.isEmpty || !learnedSet.contains(normalizedWord)) {
        continue;
      }
      if (!_isSpeakableWord(word)) continue;

      final pos = item.pos.trim().toLowerCase();
      if (pos.isEmpty) continue;

      final synonyms = item.synonyms
          .map(_normalizeWord)
          .where((value) => value.isNotEmpty)
          .toSet();
      final antonyms = item.antonyms
          .map(_normalizeWord)
          .where((value) => value.isNotEmpty)
          .toSet();

      int candidateCount = 0;
      for (final candidate in learnedItems) {
        final candidateWord = candidate.word.trim();
        if (!_isSpeakableWord(candidateWord)) continue;
        final normalizedCandidate = _normalizeWord(candidateWord);
        if (normalizedCandidate == normalizedWord) continue;
        if (candidate.pos.trim().toLowerCase() != pos) continue;
        if (synonyms.contains(normalizedCandidate) ||
            antonyms.contains(normalizedCandidate)) {
          continue;
        }
        candidateCount++;
        if (candidateCount >= 2) break;
      }

      if (candidateCount >= 2) count++;
    }
    return count;
  }

  bool _isSentenceLearnedOnly(String sentence, Set<String> learnedSet) {
    final words = RegExp(r"[A-Za-z']+")
        .allMatches(sentence)
        .map((match) => _normalizeWord(match.group(0) ?? ''))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return false;
    for (final word in words) {
      if (!learnedSet.contains(word)) return false;
    }
    return true;
  }

  bool _isSpeakableWord(String word) {
    final normalized = _normalizeWord(word);
    if (normalized.isEmpty) return false;
    if (RegExp(r'\d').hasMatch(word)) return false;
    return true;
  }

  String _normalizeSentenceKey(String sentence) {
    final words = RegExp(r"[A-Za-z']+")
        .allMatches(sentence)
        .map((match) => _normalizeWord(match.group(0) ?? ''))
        .where((word) => word.isNotEmpty)
        .toList();
    return words.join(' ');
  }

  int _countFillTheGapQuestions(List<VocabularyItem> learnedItems) {
    int count = 0;
    for (final item in learnedItems) {
      final sentence = item.exampleSentence.trim();
      if (sentence.isEmpty) continue;

      final pos = item.pos.trim().toLowerCase();
      if (pos.isEmpty) continue;

      if (!_sentenceContainsWord(sentence, item.word)) continue;

      final synonyms = item.synonyms
          .map(_normalize)
          .where((syn) => syn.isNotEmpty)
          .toSet();
      final antonyms = item.antonyms
          .map(_normalize)
          .where((ant) => ant.isNotEmpty)
          .toSet();

      final candidateDistractors = learnedItems.where((candidate) {
        final candidateWord = _normalize(candidate.word);
        if (candidateWord == _normalize(item.word)) return false;
        if (candidate.pos.trim().toLowerCase() != pos) return false;
        if (synonyms.contains(candidateWord)) return false;
        if (antonyms.contains(candidateWord)) return false;
        return true;
      }).toList();

      if (candidateDistractors.length < 2) continue;
      count++;
    }

    return count;
  }

  bool _sentenceContainsWord(String sentence, String word) {
    final regex = RegExp(
      r'\b' + RegExp.escape(word) + r'\b',
      caseSensitive: false,
    );
    return regex.hasMatch(sentence);
  }

  _WordSearchAvailability _getWordSearchAvailability(
    List<VocabularyItem> items,
  ) {
    final uniqueWords = <String>{};
    for (final item in items) {
      final word = _normalize(item.word);
      if (word.length <= 2 || word.length > 8) continue;
      uniqueWords.add(word);
    }

    final totalEligible = uniqueWords.length;
    if (totalEligible < _GamesGridSheetState._minWordSearchWords) {
      return _WordSearchAvailability(
        isLocked: true,
        missing: _GamesGridSheetState._minWordSearchWords - totalEligible,
      );
    }

    final plan = _wordSearchPlanForCount(totalEligible);
    final usableCount = uniqueWords
        .where((word) => word.length <= plan.gridSize)
        .length;

    if (usableCount < plan.wordsToPlace) {
      return _WordSearchAvailability(
        isLocked: true,
        missing: plan.wordsToPlace - usableCount,
      );
    }

    return const _WordSearchAvailability(isLocked: false, missing: 0);
  }

  _WordSearchPlan _wordSearchPlanForCount(int totalEligible) {
    if (totalEligible <= 7) {
      return const _WordSearchPlan(gridSize: 5, wordsToPlace: 5);
    }
    if (totalEligible <= 9) {
      return const _WordSearchPlan(gridSize: 6, wordsToPlace: 6);
    }
    if (totalEligible <= 12) {
      return const _WordSearchPlan(gridSize: 6, wordsToPlace: 8);
    }
    if (totalEligible <= 14) {
      return const _WordSearchPlan(gridSize: 8, wordsToPlace: 8);
    }
    return const _WordSearchPlan(gridSize: 8, wordsToPlace: 10);
  }
}
