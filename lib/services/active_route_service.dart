import 'package:shared_preferences/shared_preferences.dart';

class ActiveRouteState {
  final String lessonId;
  final int index;
  final String type;

  const ActiveRouteState({
    required this.lessonId,
    required this.index,
    required this.type,
  });
}

class ActiveRouteService {
  static const String _lessonIdKey = 'last_active_lesson_id';
  static const String _indexKey = 'last_active_index';
  static const String _typeKey = 'last_active_type';
  static const String _timestampKey = 'last_active_ts';

  static Future<void> save({
    required String lessonId,
    required int index,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lessonIdKey, lessonId);
    await prefs.setInt(_indexKey, index < 0 ? 0 : index);
    await prefs.setString(_typeKey, type);
    await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<ActiveRouteState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lessonId = prefs.getString(_lessonIdKey);
    if (lessonId == null || lessonId.isEmpty) return null;
    final index = prefs.getInt(_indexKey) ?? 0;
    final type = prefs.getString(_typeKey) ?? 'story';
    return ActiveRouteState(lessonId: lessonId, index: index, type: type);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lessonIdKey);
    await prefs.remove(_indexKey);
    await prefs.remove(_typeKey);
    await prefs.remove(_timestampKey);
  }
}
