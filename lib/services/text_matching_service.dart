import 'dart:math' as math;
import 'speech_recognition_service.dart';

class TextMatchingService {
  static const int passingThreshold = 70;

  static const List<String> _bucket1Groups = [
    'زذضظ',
    'تط',
    'حہھ',
    'کق',
    'یے',
    'وؤ',
  ];

  static const String _bucket2Letters = 'صسثاآ';

  final Map<String, String> _bucket1Index = {};

  TextMatchingService() {
    for (final group in _bucket1Groups) {
      final canonical = group[0];
      for (final ch in group.characters) {
        _bucket1Index[ch] = canonical;
      }
    }
  }

  bool _isBucket2(String ch) => _bucket2Letters.contains(ch);

  bool areLettersPhoneticallyEqual(String a, String b) {
    if (a == b) return true;
    if (_isBucket2(a) || _isBucket2(b)) return false;
    return (_bucket1Index[a] ?? a) == (_bucket1Index[b] ?? b);
  }

  String _canonical(String ch) => _isBucket2(ch) ? ch : (_bucket1Index[ch] ?? ch);

  static const String _punctuation = '،۔؟!:؛٫٬"\'()[]{}-–—.,?!;:';

  String _normalize(String input) {
    final collapsed = _collapseRepeats(input);
    final buffer = StringBuffer();
    for (final ch in collapsed.characters) {
      if (ch.trim().isEmpty) continue;
      if (_punctuation.contains(ch)) continue;
      buffer.write(_canonical(ch));
    }
    return buffer.toString();
  }

  String _collapseRepeats(String input) {
    const fillers = ['ام', 'اہ', 'ہم', 'اا'];
    var cleaned = input;
    for (final f in fillers) {
      cleaned = cleaned.replaceAll(RegExp('(^|\\s)$f(\\s|\$)'), ' ');
    }
    final chars = cleaned.replaceAll(' ', '').characters.toList();
    final out = StringBuffer();
    String? last;
    for (final ch in chars) {
      if (ch != last) out.write(ch);
      last = ch;
    }
    return out.toString();
  }

  int _lcsLength(String a, String b) {
    final n = a.length, m = b.length;
    if (n == 0 || m == 0) return 0;
    final dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        dp[i][j] = a[i - 1] == b[j - 1] ? dp[i - 1][j - 1] + 1 : math.max(dp[i - 1][j], dp[i][j - 1]);
      }
    }
    return dp[n][m];
  }

  int _editDistance(String a, String b) {
    final dp = _editDistanceTable(a, b);
    return dp[a.length][b.length];
  }

  List<List<int>> _editDistanceTable(String a, String b) {
    final n = a.length, m = b.length;
    final dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));
    for (int i = 0; i <= n; i++) dp[i][0] = i;
    for (int j = 0; j <= m; j++) dp[0][j] = j;
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(math.min);
        }
      }
    }
    return dp;
  }

  List<int> _alignPositions(String expected, String recognized) {
    final dp = _editDistanceTable(expected, recognized);
    final n = expected.length, m = recognized.length;
    final alignment = List<int>.filled(n, -1);
    int i = n, j = m;
    while (i > 0 && j > 0) {
      if (expected[i - 1] == recognized[j - 1]) {
        alignment[i - 1] = j - 1;
        i--;
        j--;
      } else {
        final sub = dp[i - 1][j - 1];
        final del = dp[i - 1][j];
        final ins = dp[i][j - 1];
        final best = math.min(sub, math.min(del, ins));
        if (best == sub) {
          alignment[i - 1] = j - 1;
          i--;
          j--;
        } else if (best == del) {
          i--;
        } else {
          j--;
        }
      }
    }
    return alignment;
  }

  TextMatchResult evaluate({
    required String expectedText,
    required List<RecognitionSnapshot> snapshots,
  }) {
    final expectedNorm = _normalize(expectedText);
    if (expectedNorm.isEmpty || snapshots.isEmpty) {
      return TextMatchResult(accuracyPercent: 0, passed: false, bestRecognizedText: '', matchedSnapshotConfidence: 0);
    }

    double bestScore = -1;
    String bestText = snapshots.last.text;
    double bestConfidence = snapshots.last.confidence;

    for (final snap in snapshots) {
      final norm = _normalize(snap.text);
      if (norm.isEmpty) continue;

      if (norm == expectedNorm) {
        bestScore = 1.0;
        bestText = snap.text;
        bestConfidence = snap.confidence;
        break;
      }

      final lcs = _lcsLength(expectedNorm, norm);
      final lcsCoverage = (lcs / expectedNorm.length).clamp(0.0, 1.0);

      final dist = _editDistance(expectedNorm, norm);
      final editScore = (1 - (dist / math.max(expectedNorm.length, norm.length))).clamp(0.0, 1.0);

      final combined = lcsCoverage * 0.7 + editScore * 0.3;

      if (combined > bestScore ||
          (combined == bestScore && snap.confidence > bestConfidence)) {
        bestScore = combined;
        bestText = snap.text;
        bestConfidence = snap.confidence;
      }
    }

    final accuracy = (bestScore.clamp(0.0, 1.0) * 100).round();
    return TextMatchResult(
      accuracyPercent: accuracy,
      passed: accuracy >= passingThreshold,
      bestRecognizedText: bestText,
      matchedSnapshotConfidence: bestConfidence,
    );
  }

  TextMatchResult evaluateTargetLetterOnly({
    required String expectedText,
    required String targetLetter,
    required List<RecognitionSnapshot> snapshots,
  }) {
    final expectedChars = expectedText.characters.toList();
    final targetPositions = <int>[];

    for (int i = 0; i < expectedChars.length; i++) {
      if (expectedChars[i] == targetLetter) {
        targetPositions.add(i);
      }
    }

    if (targetPositions.isEmpty || snapshots.isEmpty) {
      return TextMatchResult(
        accuracyPercent: 100,
        passed: true,
        bestRecognizedText: snapshots.isEmpty ? '' : snapshots.last.text,
        matchedSnapshotConfidence: snapshots.isEmpty ? 0 : snapshots.last.confidence,
      );
    }

    final expectedJoined = expectedChars.join();

    double bestScore = -1;
    String bestText = snapshots.last.text;
    double bestConfidence = snapshots.last.confidence;

    for (final snap in snapshots) {
      final cleanedText = _collapseRepeats(snap.text);
      final recognizedChars = cleanedText.characters.toList();
      if (recognizedChars.isEmpty) continue;

      final alignment = _alignPositions(expectedJoined, cleanedText);
      const window = 2;
      final usedRecognizedIdx = <int>{};
      int correctOccurrences = 0;
      for (final pos in targetPositions) {
        int anchor = alignment[pos];
        if (anchor == -1) {
          for (int offset = 1; offset <= 3 && anchor == -1; offset++) {
            final before = pos - offset >= 0 ? alignment[pos - offset] : -1;
            final after = pos + offset < alignment.length ? alignment[pos + offset] : -1;
            if (before != -1) {
              anchor = before + offset;
            } else if (after != -1) {
              anchor = after - offset;
            }
          }
        }
        if (anchor == -1) continue;

        int? matchIdx;
        for (int d = 0; d <= window; d++) {
          for (final candidate in d == 0 ? [anchor] : [anchor - d, anchor + d]) {
            if (candidate < 0 || candidate >= recognizedChars.length) continue;
            if (usedRecognizedIdx.contains(candidate)) continue;
            if (areLettersPhoneticallyEqual(recognizedChars[candidate], targetLetter)) {
              matchIdx = candidate;
              break;
            }
          }
          if (matchIdx != null) break;
        }
        if (matchIdx != null) {
          usedRecognizedIdx.add(matchIdx);
          correctOccurrences++;
        }
      }

      final occurrenceScore = correctOccurrences / targetPositions.length;

      if (occurrenceScore > bestScore ||
          (occurrenceScore == bestScore && snap.confidence > bestConfidence)) {
        bestScore = occurrenceScore;
        bestText = snap.text;
        bestConfidence = snap.confidence;
      }
    }

    if (bestScore < 0) bestScore = 0;
    final accuracy = (bestScore.clamp(0.0, 1.0) * 100).round();
    return TextMatchResult(
      accuracyPercent: accuracy,
      passed: accuracy >= passingThreshold,
      bestRecognizedText: bestText,
      matchedSnapshotConfidence: bestConfidence,
    );
  }
}

class TextMatchResult {
  final int accuracyPercent;
  final bool passed;
  final String bestRecognizedText;
  final double matchedSnapshotConfidence;

  TextMatchResult({
    required this.accuracyPercent,
    required this.passed,
    required this.bestRecognizedText,
    required this.matchedSnapshotConfidence,
  });
}

extension on String {
  Iterable<String> get characters => runes.map((r) => String.fromCharCode(r));
}