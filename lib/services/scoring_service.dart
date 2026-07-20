class WordScore {
  final String word;
  final int score;
  WordScore(this.word, this.score);
}

class ScoreResult {
  final int score;
  final List<WordScore> breakdown;
  ScoreResult({required this.score, this.breakdown = const []});
}

class ScoringService {
  static String _normalize(String s) {
    return s
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll(RegExp(r'[۔،؟!\s]'), '')
        .trim();
  }

  static int wordSimilarity(String recognized, String target) {
    final a = _normalize(recognized);
    final b = _normalize(target);

    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 100;

    final la = a.length, lb = b.length;
    final dp = List.generate(la + 1, (_) => List<int>.filled(lb + 1, 0));
    for (int i = 0; i <= la; i++) dp[i][0] = i;
    for (int j = 0; j <= lb; j++) dp[0][j] = j;
    for (int i = 1; i <= la; i++) {
      for (int j = 1; j <= lb; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost]
            .reduce((x, y) => x < y ? x : y);
      }
    }
    final distance = dp[la][lb];
    final maxLen = la > lb ? la : lb;
    return (100 - (distance / maxLen) * 100).round().clamp(0, 100);
  }

  static List<String> extractFocusWords(String sentence) {
    final words = sentence.replaceAll(RegExp(r'[۔،؟!]'), '').split(RegExp(r'\s+'));
    return words.where((w) => w.contains('\u067E')).where((w) => w.trim().isNotEmpty).toList();
  }

  static ScoreResult scoreFullWord(String recognized, String target) {
    return ScoreResult(score: wordSimilarity(recognized, target));
  }

  static ScoreResult scoreFocusWords(String recognizedFull, String targetFull) {
    final focusWords = extractFocusWords(targetFull);
    final recognizedWords =
        recognizedFull.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();

    if (focusWords.isEmpty) {
      return ScoreResult(score: wordSimilarity(recognizedFull, targetFull));
    }

    final breakdown = <WordScore>[];
    int total = 0;
    for (final fw in focusWords) {
      int best = 0;
      for (final rw in recognizedWords) {
        final s = wordSimilarity(rw, fw);
        if (s > best) best = s;
      }
      breakdown.add(WordScore(fw, best));
      total += best;
    }

    final avg = (total / focusWords.length).round();
    return ScoreResult(score: avg, breakdown: breakdown);
  }

  static String feedbackFor(int score) {
    if (score >= 80) return "Zabardast! Bilkul sahi talaffuz.";
    if (score >= 60) return "Achha! Thori si mushq aur karein.";
    if (score >= 35) return "Koshish achi hai, dobara ahista bolein.";
    return "Dobara koshish karein.";
  }
}
