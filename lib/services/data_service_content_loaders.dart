import 'package:csv/csv.dart';
import 'package:gravity_app/services/data_service_text_utils.dart';

List<List<dynamic>> parseCsvRows(String rawData) {
  return const CsvToListConverter().convert(rawData);
}

List<List<dynamic>> normalizeImportedRows(List<List<dynamic>> rows) {
  final result = List<List<dynamic>>.from(rows);
  if (result.isNotEmpty) {
    final firstCell = result[0][0].toString().toLowerCase();
    if (firstCell.contains('serial') ||
        firstCell.contains('word') ||
        firstCell.contains('english') ||
        firstCell.contains('id') ||
        firstCell.contains('title') ||
        firstCell.contains('focus')) {
      result.removeAt(0);
    }
  }
  return result;
}

List<List<dynamic>> normalizeVocabularyRows(List<List<dynamic>> rows) {
  final result = List<List<dynamic>>.from(rows);
  if (result.isNotEmpty) {
    final firstCell = result[0][0].toString().toLowerCase();
    if (firstCell.contains('serial') || firstCell.contains('word')) {
      result.removeAt(0);
    }
  }
  return result;
}

List<List<dynamic>> normalizeVerbRows(List<List<dynamic>> rows) {
  final result = List<List<dynamic>>.from(rows);
  if (result.isNotEmpty) {
    final firstRow = result[0];
    final firstCol = firstRow.isNotEmpty
        ? firstRow[0].toString().toLowerCase().trim()
        : '';
    final secondCol = firstRow.length > 1
        ? firstRow[1].toString().toLowerCase()
        : '';

    if (firstCol == 'null' ||
        firstCol.isEmpty ||
        firstCol.contains('serial') ||
        firstCol.startsWith('english') ||
        secondCol.contains('english') ||
        secondCol.contains('verb') ||
        secondCol.contains('base')) {
      result.removeAt(0);
    }
  }
  return result;
}

List<List<dynamic>> normalizeVerbRowsFallback(List<List<dynamic>> rows) {
  final result = List<List<dynamic>>.from(rows);
  if (result.isNotEmpty) {
    final firstRow = result[0];
    if (firstRow.isNotEmpty &&
        (firstRow[0].toString().toLowerCase().contains('serial') ||
            firstRow[1].toString().toLowerCase().contains('english'))) {
      result.removeAt(0);
    }
  }
  return result;
}

List<List<dynamic>> normalizeReadingRows(List<List<dynamic>> rows) {
  final result = List<List<dynamic>>.from(rows);
  if (result.isNotEmpty) {
    if (result[0][0].toString().toLowerCase().contains('id')) {
      result.removeAt(0);
    }
  }
  return result;
}

List<List<dynamic>> normalizeWritingRows(List<List<dynamic>> rows) {
  final result = List<List<dynamic>>.from(rows);
  if (result.isNotEmpty) {
    if (result[0][0].toString().toLowerCase().contains('id')) {
      result.removeAt(0);
    }
  }
  return result;
}

List<List<dynamic>> normalizeSpeakingRows(List<List<dynamic>> rows) {
  final result = List<List<dynamic>>.from(rows);
  if (result.isNotEmpty) {
    if (result[0][0].toString().toLowerCase().contains('id')) {
      result.removeAt(0);
    }
  }
  return result;
}

List<List<dynamic>> normalizeListeningRows(List<List<dynamic>> rows) {
  final result = List<List<dynamic>>.from(rows);
  if (result.isNotEmpty) {
    result.removeWhere((row) {
      if (row.isEmpty) return true;
      final firstCol = row[0].toString().toLowerCase().trim();
      if (firstCol.isEmpty) return true;
      if (firstCol.contains('id') || firstCol.contains('exercise')) return true;
      return false;
    });
  }
  return result;
}

List<Map<String, String>> mapItemsForType(
  List<List<dynamic>> rows,
  String type, {
  required String userLanguage,
}) {
  return rows.asMap().entries.map((entry) {
    final index = entry.key;
    final row = entry.value;
    final Map<String, String> map = {'_index': index.toString()};

    if (type == 'vocabulary') {
      map['word'] = row.length > 2 ? row[2].toString() : '';
      map['type'] = row.length > 3 ? row[3].toString() : '';
      map['level'] = row.length > 4 ? row[4].toString() : '';
      map['tamil_meaning'] = row.length > 5 ? row[5].toString() : '';
      map['hindi_meaning'] = row.length > 6 ? row[6].toString() : '';

      if (userLanguage == 'Hindi') {
        map['meaning'] = map['hindi_meaning']!;
      } else {
        map['meaning'] = map['tamil_meaning']!;
      }
      if (map['meaning']!.isEmpty) {
        map['meaning'] = map['tamil_meaning']!.isNotEmpty
            ? map['tamil_meaning']!
            : map['hindi_meaning']!;
      }

      map['example'] = row.length > 7 ? row[7].toString() : '';
      map['synonyms'] = row.length > 10 ? row[10].toString() : '';
      map['tamil_synonyms'] = row.length > 11 ? row[11].toString() : '';
    } else if (type == 'verbs') {
      map['word'] = row.isNotEmpty ? row[0].toString() : '';
      map['level'] = row.length > 2 ? row[2].toString() : '';
      map['tamil_meaning'] = row.length > 3 ? row[3].toString() : '';
      map['hindi_meaning'] = row.length > 4 ? row[4].toString() : '';

      if (userLanguage == 'Hindi') {
        map['meaning'] = map['hindi_meaning']!;
      } else {
        map['meaning'] = map['tamil_meaning']!;
      }
      if (map['meaning']!.isEmpty) {
        map['meaning'] = map['tamil_meaning']!.isNotEmpty
            ? map['tamil_meaning']!
            : map['hindi_meaning']!;
      }

      map['example'] = '';
    } else if (type == 'reading') {
      map['id'] = row.isNotEmpty ? row[0].toString() : '';
      map['title'] = row.length > 1 ? row[1].toString() : '';
      map['passage'] = row.length > 2 ? row[2].toString() : '';
      map['q1'] = row.length > 3 ? row[3].toString() : '';
      map['a1'] = row.length > 4 ? row[4].toString() : '';
      map['q2'] = row.length > 5 ? row[5].toString() : '';
      map['a2'] = row.length > 6 ? row[6].toString() : '';
      map['level'] = row.length > 7 ? row[7].toString() : '';
      map['tamil'] = row.length > 8 ? row[8].toString() : '';
      map['hindi'] = row.length > 9 ? row[9].toString() : '';
    } else if (type == 'writing') {
      map['id'] = row.isNotEmpty ? row[0].toString() : '';
      map['level'] = row.length > 1 ? row[1].toString() : '';
      map['focus'] = row.length > 1 ? row[1].toString() : '';
      map['type'] = row.length > 2 ? row[2].toString() : '';
      map['instruction'] = row.length > 3 ? row[3].toString() : '';
      map['input'] = row.length > 4 ? row[4].toString() : '';
      map['answer'] = row.length > 5 ? row[5].toString() : '';
      map['explanation'] = row.length > 6 ? row[6].toString() : '';
    } else if (type == 'speaking') {
      map['id'] = row.isNotEmpty ? row[0].toString() : '';

      if (row.length >= 7) {
        map['speaking_focus'] = row.length > 1 ? row[1].toString() : '';
        map['category'] = row.length > 1 ? row[1].toString() : '';
        map['task_type'] = row.length > 2 ? row[2].toString() : '';
        map['role'] = row.length > 3 ? row[3].toString() : '';
        map['prompt'] = row.length > 4 ? row[4].toString() : '';
        map['response'] = row.length > 5 ? row[5].toString() : '';
        map['criteria'] = row.length > 6 ? row[6].toString() : '';
        map['level'] = row.length > 7
            ? row[7].toString()
            : (row.length > 2 ? row[2].toString() : '');
      } else {
        map['category'] = row.length > 1 ? row[1].toString() : '';
        map['level'] = row.length > 2 ? row[2].toString() : 'Beginner';
        map['text'] = row.length > 3 ? row[3].toString() : '';
        map['prompt'] = map['text']!;
        map['task_type'] = map['category']!;
      }
    } else if (type == 'listening') {
      map['id'] = row.isNotEmpty ? row[0].toString() : '';
      map['title'] = row.length > 1 ? row[1].toString() : '';
      map['audio_key'] = row.length > 4 ? row[4].toString() : '';
      map['question'] = row.length > 5 ? row[5].toString() : '';
      map['answer'] = row.length > 6 ? row[6].toString() : '';
      map['level'] = row.length > 7 ? row[7].toString() : '';
    } else if (type == 'quiz') {
      map['id'] = row.isNotEmpty ? row[0].toString() : '';
      map['question'] = row.length > 1 ? row[1].toString() : '';
      map['option1'] = row.length > 2 ? row[2].toString() : '';
      map['option2'] = row.length > 3 ? row[3].toString() : '';
      map['option3'] = row.length > 4 ? row[4].toString() : '';
      map['option4'] = row.length > 5 ? row[5].toString() : '';
      map['answer'] = row.length > 6 ? row[6].toString() : '';
    }
    return map;
  }).toList();
}

List<Map<String, String>> mapVocabularyByIndices(
  List<List<dynamic>> rows,
  List<int> indices, {
  String userLanguage = 'Tamil',
}) {
  final List<Map<String, String>> result = [];
  for (final i in indices) {
    if (i < 0 || i >= rows.length) continue;

    final row = rows[i];

    final word = row.length > 2 ? row[2].toString() : 'Unknown';
    final pos = row.length > 3 ? row[3].toString() : '';
    final englishExample = row.length > 7 ? row[7].toString() : '';
    final synonyms = row.length > 10 ? row[10].toString() : '';

    String tamilMeaning = '';
    String hindiMeaning = '';
    String tamilExample = '';
    String hindiExample = '';
    String tamilSynonyms = '';

    if (userLanguage == 'Tamil') {
      tamilMeaning = row.length > 5 ? row[5].toString() : '';
      tamilExample = row.length > 8 ? row[8].toString() : '';
      tamilSynonyms = row.length > 11 ? row[11].toString() : '';
      hindiMeaning = '';
      hindiExample = '';
    } else if (userLanguage == 'Hindi') {
      hindiMeaning = row.length > 6 ? row[6].toString() : '';
      hindiExample = row.length > 9 ? row[9].toString() : '';
      tamilMeaning = '';
      tamilExample = '';
      tamilSynonyms = '';
    }

    result.add({
      'word': word,
      'pos': pos,
      'tamil_meaning': tamilMeaning,
      'hindi_meaning': hindiMeaning,
      'english_example': englishExample,
      'tamil_example': tamilExample,
      'hindi_example': hindiExample,
      'synonyms': synonyms,
      'tamil_synonyms': tamilSynonyms,
    });
  }
  return result;
}

List<Map<String, String>> mapVerbsByIndices(
  List<List<dynamic>> rows,
  List<int> indices, {
  String userLanguage = 'Tamil',
}) {
  final List<Map<String, String>> result = [];
  for (final i in indices) {
    if (i < 0 || i >= rows.length) continue;
    final row = rows[i];

    String v1 = '';
    String v2 = '';
    String v3 = '';
    String tamilMeaning = '';
    String hindiMeaning = '';
    String englishExamples = '';
    String tamilExamples = '';
    String hindiExamples = '';
    int dayNumber = 0;

    if (row.isNotEmpty) {
      final col0 = row[0].toString().trim();
      if (col0.contains('/')) {
        final parts = col0.split('/');
        v1 = parts.isNotEmpty ? parts[0].trim() : col0;
        v2 = parts.length > 1 ? parts[1].trim() : '';
        v3 = parts.length > 2 ? parts[2].trim() : '';
      } else {
        v1 = col0;
      }

      if (row.length > 1) {
        final dayStr = row[1].toString().trim();
        dayNumber = int.tryParse(dayStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }

      if (userLanguage == 'Tamil') {
        tamilMeaning = row.length > 3
            ? DataServiceTextUtils.removeParentheses(row[3].toString())
            : '';
        hindiMeaning = '';
      } else if (userLanguage == 'Hindi') {
        hindiMeaning = row.length > 4
            ? DataServiceTextUtils.removeParentheses(row[4].toString())
            : '';
        tamilMeaning = '';
      }

      englishExamples = row.length > 5 ? row[5].toString().trim() : '';
      tamilExamples = row.length > 6 ? row[6].toString().trim() : '';
      hindiExamples = row.length > 7 ? row[7].toString().trim() : '';
    }

    String v4 = '';
    if (v1.isNotEmpty) {
      if (v1.endsWith('s') ||
          v1.endsWith('sh') ||
          v1.endsWith('ch') ||
          v1.endsWith('x') ||
          v1.endsWith('o')) {
        v4 = "${v1}es";
      } else if (v1.endsWith('y') &&
          v1.length > 1 &&
          !['a', 'e', 'i', 'o', 'u'].contains(v1[v1.length - 2])) {
        v4 = "${v1.substring(0, v1.length - 1)}ies";
      } else {
        v4 = "${v1}s";
      }
    }

    String v5 = '';
    if (v1.isNotEmpty) {
      if (v1.endsWith('e') && !v1.endsWith('ee') && v1.length > 1) {
        v5 = "${v1.substring(0, v1.length - 1)}ing";
      } else {
        v5 = "${v1}ing";
      }
    }

    final fullForms = [
      v1,
      v2,
      v3,
      v4,
      v5,
    ].where((e) => e.isNotEmpty).join(' / ');

    final id = dayNumber > 0 && v1.isNotEmpty
        ? 'verb_day${dayNumber}_${v1.replaceAll(" ", "_")}'
        : v1;

    result.add({
      'id': id,
      'word': v1,
      'v1': v1,
      'v2': v2,
      'v3': v3,
      'v4': v4,
      'v5': v5,
      'forms': fullForms,
      'tamil_meaning': tamilMeaning,
      'hindi_meaning': hindiMeaning,
      'meaning': userLanguage == 'Tamil' ? tamilMeaning : hindiMeaning,
      'english_example': englishExamples.isNotEmpty
          ? englishExamples
          : "Forms: $fullForms",
      'tamil_example': tamilExamples.isNotEmpty ? tamilExamples : tamilMeaning,
      'hindi_example': hindiExamples.isNotEmpty ? hindiExamples : hindiMeaning,
    });
  }
  return result;
}

List<Map<String, String>> mapReadingExercises(List<List<dynamic>> rows) {
  return rows.map((row) {
    return {
      'id': row.isNotEmpty ? row[0].toString() : '',
      'title': row.length > 1 ? row[1].toString() : '',
      'passage': row.length > 2 ? row[2].toString() : '',
      'q1': row.length > 3 ? row[3].toString() : '',
      'a1': row.length > 4 ? row[4].toString() : '',
      'q2': row.length > 5 ? row[5].toString() : '',
      'a2': row.length > 6 ? row[6].toString() : '',
      'level': row.length > 7 ? row[7].toString() : '',
      'tamil': row.length > 8 ? row[8].toString() : '',
      'hindi': row.length > 9 ? row[9].toString() : '',
    };
  }).toList();
}

List<Map<String, String>> mapWritingExercises(List<List<dynamic>> rows) {
  return rows.map((row) {
    final type = row.length > 3 ? row[3].toString() : 'Exercise';
    String instruction = '';

    if (type.contains('Correction')) {
      instruction = "Correct the sentence errors.";
    } else if (type.contains('Translation')) {
      instruction = "Translate to English.";
    } else if (type.contains('Completion')) {
      instruction = "Complete the sentence.";
    } else {
      instruction = "Rewrite correctly.";
    }

    final tamil = row.length > 6 ? row[6].toString() : '';
    final hindi = row.length > 7 ? row[7].toString() : '';

    return {
      'id': row.isNotEmpty ? row[0].toString() : '',
      'level': row.length > 1 ? row[1].toString() : 'Beginner',
      'focus': row.length > 2 ? row[2].toString() : '',
      'type': type,
      'instruction': instruction,
      'input': row.length > 4 ? row[4].toString() : '',
      'answer': row.length > 5 ? row[5].toString() : '',
      'tamil': tamil,
      'hindi': hindi,
      'explanation': "",
    };
  }).toList();
}

List<Map<String, String>> mapListeningExercises(List<List<dynamic>> rows) {
  return rows.map((row) {
    return {
      'id': row.isNotEmpty ? row[0].toString() : '',
      'sp1': row.length > 2
          ? DataServiceTextUtils.repairMojibake(row[2].toString())
          : '',
      'sp2': row.length > 3
          ? DataServiceTextUtils.repairMojibake(row[3].toString())
          : '',
      'question': row.length > 5
          ? DataServiceTextUtils.repairMojibake(row[5].toString())
          : '',
      'answer': row.length > 6
          ? DataServiceTextUtils.repairMojibake(row[6].toString())
          : '',
      'level': row.length > 7 ? row[7].toString() : 'Beginner',
      'title': 'Listening Mission',
      'audio_key': row.length > 4 ? row[4].toString() : '',
    };
  }).toList();
}

List<Map<String, String>> mapSpeakingExercises(List<List<dynamic>> rows) {
  return rows.map((row) {
    String id = row.isNotEmpty ? row[0].toString().trim() : '';
    String category = 'General';
    String level = '';
    String prompt = '';
    String taskType = 'Speaking';
    String response = '';
    String criteria = '';

    if (row.length >= 7) {
      category = row[1].toString();
      taskType = row[2].toString();
      prompt = row[4].toString();
      response = row[5].toString();
      criteria = row[6].toString();
      if (row.length > 7) {
        level = row[7].toString();
      } else if (row.length > 2) {
        level = row[2].toString();
      }
    } else {
      if (row.length > 1) category = row[1].toString();
      if (row.length > 2) level = row[2].toString();
      if (row.length > 3) prompt = row[3].toString();

      taskType = category;
      response = prompt;
    }

    return {
      'id': id,
      'category': category,
      'level': level,
      'prompt': prompt,
      'response': response,
      'task_type': taskType,
      'criteria': criteria,
    };
  }).toList();
}

List<Map<String, String>> mapQuizQuestions(List<List<dynamic>> rows) {
  return rows.map((row) {
    return {
      'id': row.isNotEmpty ? row[0].toString() : '',
      'question': row.length > 1 ? row[1].toString() : '',
      'option1': row.length > 2 ? row[2].toString() : '',
      'option2': row.length > 3 ? row[3].toString() : '',
      'option3': row.length > 4 ? row[4].toString() : '',
      'option4': row.length > 5 ? row[5].toString() : '',
      'answer': row.length > 6 ? row[6].toString() : '',
    };
  }).toList();
}
