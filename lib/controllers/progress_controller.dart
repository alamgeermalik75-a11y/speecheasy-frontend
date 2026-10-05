import 'package:flutter/foundation.dart';
import '../models/attempt.dart';
import '../services/core_backend_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class ProgressController extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final CoreBackendService _backend = CoreBackendService();

  final Map<PracticeLevel, int> completion = {
    for (final l in PracticeLevel.values) l: 0,
  };

  final Map<PracticeLevel, bool> completed = {
    for (final l in PracticeLevel.values) l: false,
  };

  final Map<PracticeLevel, bool> unlocked = {
    for (final l in PracticeLevel.values) l: l == PracticeLevel.words,
  };

  double alphabetProgress = 0.0;
  double overallProgress = 0.0;
  double dailyProgress = 0.0;
  double weeklyProgress = 0.0;
  double monthlyProgress = 0.0;

  String? _currentAlphabet;
  String? get currentAlphabet => _currentAlphabet;

  bool isLevelUnlocked(PracticeLevel level) {
    return unlocked[level] ?? (level == PracticeLevel.words);
  }

  bool isLevelCompleted(PracticeLevel level) {
    return completed[level] ?? false;
  }

  Future<void> loadForAlphabet(String alphabetName) async {
    _currentAlphabet = alphabetName;

    // 1. Try to fetch from backend source of truth
    try {
      final overview = await _backend.getProgressOverview(alphabetName: alphabetName);
      if (overview != null) {
        alphabetProgress = (overview['alphabet_progress'] as num?)?.toDouble() ?? 0.0;
        overallProgress = (overview['overall_progress'] as num?)?.toDouble() ?? 0.0;
        dailyProgress = (overview['daily_progress'] as num?)?.toDouble() ?? 0.0;
        weeklyProgress = (overview['weekly_progress'] as num?)?.toDouble() ?? 0.0;
        monthlyProgress = (overview['monthly_progress'] as num?)?.toDouble() ?? 0.0;

        final cats = overview['categories'] as Map<String, dynamic>? ?? {};
        bool prevComp = true;
        for (final level in PracticeLevel.values) {
          final cat = cats[level.name] as Map<String, dynamic>?;
          if (cat != null) {
            completion[level] = ((cat['score_percentage'] as num?)?.toDouble() ?? 0.0).round();
            completed[level] = (cat['is_completed'] as bool?) ?? false;
            unlocked[level] = (cat['is_unlocked'] as bool?) ?? prevComp;
            prevComp = completed[level]!;
          } else {
            completion[level] = 0;
            completed[level] = false;
            unlocked[level] = prevComp;
          }
        }
        notifyListeners();
        return;
      }
    } catch (_) {}

    // 2. Fallback to local storage if backend offline
    bool prevCompFallback = true;
    for (final level in PracticeLevel.values) {
      final score = await _storage.getLevelCompletion(alphabetName, level);
      completion[level] = score;
      completed[level] = score >= 70;
      unlocked[level] = prevCompFallback;
      prevCompFallback = completed[level]!;
    }
    alphabetProgress = completion.values.fold(0.0, (sum, v) => sum + (v * 0.20));
    notifyListeners();
  }

  Future<void> recordAttempt({
    required String itemId,
    required PracticeLevel level,
    required int score,
    String? alphabetName,
  }) async {
    final alpha = (alphabetName != null && alphabetName.trim().isNotEmpty)
        ? alphabetName.trim()
        : (_currentAlphabet ?? (itemId.contains('_') ? itemId.split('_').first : 'bay'));
    _currentAlphabet = alpha;

    // 1. Send to backend immediately
    try {
      final res = await _backend.recordAttempt(
        itemId: itemId,
        alphabetName: alpha,
        levelKey: level.name,
        score: score,
      );
      if (res != null) {
        if (res['category_progress'] != null) {
          completion[level] = ((res['category_progress'] as num).toDouble()).round();
        }
        if (res['is_category_completed'] != null) {
          completed[level] = res['is_category_completed'] as bool;
        }
        if (res['alphabet_progress'] != null) {
          alphabetProgress = (res['alphabet_progress'] as num).toDouble();
        }
        if (res['overall_progress'] != null) {
          overallProgress = (res['overall_progress'] as num).toDouble();
        }
      }
    } catch (e) {
      debugPrint('Error recording attempt to backend: $e');
    }

    // 2. Save locally for offline cache
    await _storage.saveAttempt(AttemptRecord(
      itemId: itemId,
      alphabetName: alpha,
      levelKey: level.name,
      score: score,
      timestamp: DateTime.now(),
    ));

    // 3. Reload full progress from backend to refresh sequential unlocks
    await loadForAlphabet(alpha);
  }

  Future<List<AttemptRecord>> historyFor(String itemId) async {
    final all = await _storage.getHistory(alphabetName: _currentAlphabet);
    return all.where((r) => r.itemId == itemId).toList();
  }
}
