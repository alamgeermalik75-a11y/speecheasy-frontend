import '../models/attempt.dart';
import '../utils/constants.dart';
import 'speech_recognition_service.dart';
import 'text_matching_service.dart';

class EvaluationService {
  final TextMatchingService _textMatcher = TextMatchingService();

  Future<PronunciationResult> evaluate({
    required PracticeLevel level,
    required String expectedText,
    required String targetLetter,
    required List<RecognitionSnapshot> recognitionHistory,
  }) async {
    final TextMatchResult textResult = level.isWholeWordScored
        ? _textMatcher.evaluate(expectedText: expectedText, snapshots: recognitionHistory)
        : _textMatcher.evaluateTargetLetterOnly(
            expectedText: expectedText,
            targetLetter: targetLetter,
            snapshots: recognitionHistory,
          );

    return PronunciationResult(
      overallScore: textResult.accuracyPercent,
      passed: textResult.passed,
      recognizedText: textResult.bestRecognizedText,
      expectedText: expectedText,
    );
  }
}
