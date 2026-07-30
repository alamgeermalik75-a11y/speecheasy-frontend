import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attempt.dart';
import '../services/text_matching_service.dart';
import '../utils/constants.dart';

class StorageService {
  static const _historyKey = 'attempt_history';
  static const _totalPrefix = 'total_';

  Future<void> saveAttempt(AttemptRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? [];
    list.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_historyKey, list);
  }

  Future<List<AttemptRecord>> getHistory({String? alphabetName, String? levelKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? [];
    var records = list.map((s) => AttemptRecord.fromJson(jsonDecode(s))).toList();
    if (alphabetName != null) {
      records = records.where((r) => r.alphabetName == alphabetName).toList();
    }
    if (levelKey != null) {
      records = records.where((r) => r.levelKey == levelKey).toList();
    }
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }

  Future<void> saveLevelTotal(String alphabetName, String levelKey, int total) async {
    if (total <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_totalPrefix${alphabetName}_$levelKey', total);
  }

  Future<int> getLevelCompletion(String alphabetName, PracticeLevel level) async {
    final prefs = await SharedPreferences.getInstance();
    final total = prefs.getInt('$_totalPrefix${alphabetName}_${level.name}') ?? 0;
    if (total <= 0) return 0;

    final history = await getHistory(alphabetName: alphabetName, levelKey: level.name);
    if (history.isEmpty) return 0;

    final bestScorePerItem = <String, int>{};
    for (final record in history) {
      final best = bestScorePerItem[record.itemId];
      if (best == null || record.score > best) {
        bestScorePerItem[record.itemId] = record.score;
      }
    }
    final passedCount =
        bestScorePerItem.values.where((score) => score >= TextMatchingService.passingThreshold).length;

    return ((passedCount / total) * 100).round().clamp(0, 100);
  }

}
