import 'package:flutter/foundation.dart';
import '../models/attempt.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class ProgressController extends ChangeNotifier {
  final StorageService _storage = StorageService();

  final Map<PracticeLevel, int> completion = {
    for (final l in PracticeLevel.values) l: 0,
  };

  String? _currentAlphabet;

  Future<void> loadForAlphabet(String alphabetName) async {
    _currentAlphabet = alphabetName;
    for (final level in PracticeLevel.values) {
      completion[level] = await _storage.getLevelCompletion(alphabetName, level);
    }
    notifyListeners();
  }

  Future<void> recordAttempt({
    required String itemId,
    required PracticeLevel level,
    required int score,
  }) async {
    if (_currentAlphabet == null) return;
    await _storage.saveAttempt(AttemptRecord(
      itemId: itemId,
      alphabetName: _currentAlphabet!,
      levelKey: level.name,
      score: score,
      timestamp: DateTime.now(),
    ));
    await loadForAlphabet(_currentAlphabet!);
  }

  Future<List<AttemptRecord>> historyFor(String itemId) async {
    final all = await _storage.getHistory(alphabetName: _currentAlphabet);
    return all.where((r) => r.itemId == itemId).toList();
  }
}
