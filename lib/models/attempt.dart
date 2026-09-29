class PronunciationResult {
  final int overallScore;
  final bool passed;
  final String recognizedText;
  final String expectedText;

  final bool? answerCorrect;

  PronunciationResult({
    required this.overallScore,
    required this.passed,
    required this.recognizedText,
    required this.expectedText,
    this.answerCorrect,
  });
}

class AttemptRecord {
  final String itemId;
  final String alphabetName;
  final String levelKey;
  final int score;
  final DateTime timestamp;

  AttemptRecord({
    required this.itemId,
    required this.alphabetName,
    required this.levelKey,
    required this.score,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'alphabetName': alphabetName,
        'levelKey': levelKey,
        'score': score,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AttemptRecord.fromJson(Map<String, dynamic> j) => AttemptRecord(
        itemId: j['itemId'],
        alphabetName: j['alphabetName'],
        levelKey: j['levelKey'],
        score: j['score'],
        timestamp: DateTime.parse(j['timestamp']),
      );
}
