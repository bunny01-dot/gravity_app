import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BlackHoleRepository {
  static const String blackHoleKey = 'black_hole_items';

  Future<List<Map<String, String>>> getItems({
    Future<void> Function()? onMissingLocal,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? encodedItems = prefs.getStringList(blackHoleKey);

    if (encodedItems == null && onMissingLocal != null) {
      await onMissingLocal();
      encodedItems = prefs.getStringList(blackHoleKey);
    }

    encodedItems ??= [];

    return encodedItems
        .map((e) => Map<String, String>.from(jsonDecode(e)))
        .toList();
  }

  Future<bool> toggleItem(
    Map<String, String> item, {
    Future<void> Function(List<String> encodedItems)? onSaveEncoded,
    Future<void> Function()? onMissingLocal,
  }) async {
    final id = (item['id'] ?? item['word'] ?? '').trim();
    if (id.isEmpty) return false;

    final items = await getItems(onMissingLocal: onMissingLocal);
    final existingIndex =
        items.indexWhere((i) => (i['id'] ?? i['word']) == id);
    bool added = false;

    if (existingIndex >= 0) {
      items.removeAt(existingIndex);
      added = false;
    } else {
      items.add(item);
      added = true;
    }

    final encodedItems = items.map((i) => jsonEncode(i)).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(blackHoleKey, encodedItems);

    if (onSaveEncoded != null) {
      await onSaveEncoded(encodedItems);
    }

    return added;
  }

  Future<bool> isInBlackHole(
    String id, {
    Future<void> Function()? onMissingLocal,
  }) async {
    final items = await getItems(onMissingLocal: onMissingLocal);
    return items.any((i) => (i['id'] ?? i['word']) == id);
  }
}
