import 'package:flutter/foundation.dart';
import '../models/alphabet.dart';
import '../models/attempt.dart';
import '../models/fill_blank_item.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/speech_recognition_service.dart';
import '../services/storage_service.dart';
import '../services/text_matching_service.dart';
import '../utils/constants.dart';

class FillBlankController extends ChangeNotifier {
  final ApiService _api;
  final AudioService audio;
  final SpeechRecognitionService speech;
  final StorageService _storage;
  final TextMatchingService _matcher = TextMatchingService();

  FillBlankController({
    ApiService? api,
    AudioService? audioService,
    SpeechRecognitionService? speechService,
    StorageService? storage,
  })  : _api = api ?? ApiService(),
        audio = audioService ?? AudioService(),
        speech = speechService ?? SpeechRecognitionService(),
        _storage = storage ?? StorageService() {
    audio.onStateChanged = notifyListeners;
    audio.warmUp();
  }

  bool get isSpeaking => audio.isSpeaking;

  String _finalizedLiveText = '';
  String _currentSegmentText = '';

  List<FillBlankItem> items = [];
  int index = 0;
  bool loading = false;
  String? loadError;

  String? selectedOption;
  bool isRecording = false;
  String liveText = '';
  bool isChecking = false;
  PronunciationResult? result;

  FillBlankItem? get current => items.isEmpty ? null : items[index];
  bool get hasNext => index < items.length - 1;

  Future<String?> initSpeech() async {
    await speech.init();
    final locale = speech.resolvedLocaleId ?? '';
    if (!locale.toLowerCase().startsWith('ur')) {
      return  'Speech Recognition is not installed in this device therefore live text can be wrong.';
    }
    return null;
  }

  Future<void> loadFromApi(Alphabet alphabet) async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      items = await _api.getFillBlanks(alphabet.name);
      loading = false;
      await _storage.saveLevelTotal(alphabet.name, PracticeLevel.fillBlanks.name, items.length);
    } catch (e) {
      loadError = e.toString();
      loading = false;
    }
    notifyListeners();
  }

  void selectOption(String option) {
    if (isRecording) return;
    selectedOption = option;
    result = null;
    liveText = '';
    notifyListeners();
  }

  Future<void> playSelectedOption() async {
    if (selectedOption != null) await audio.playReference(selectedOption!);
  }

  Future<void> toggleMic({required void Function(String error) onError}) async {
    if (isRecording) {
      await speech.stop();
      isRecording = false;
      notifyListeners();
      return;
    }
    isRecording = true;
    liveText = '';
    _finalizedLiveText = '';
    _currentSegmentText = '';
    result = null;
    notifyListeners();
    try {
      await speech.startListening(
        onResult: (text, isFinal, confidence) {
          if (isFinal) {
            _finalizedLiveText = _finalizedLiveText.isEmpty ? text : '$_finalizedLiveText $text';
            _currentSegmentText = '';
            liveText = _finalizedLiveText;
          } else {
            if (_currentSegmentText.isNotEmpty && text.length < _currentSegmentText.length) {
              _finalizedLiveText =
                  _finalizedLiveText.isEmpty ? _currentSegmentText : '$_finalizedLiveText $_currentSegmentText';
            }
            _currentSegmentText = text;
            liveText = _finalizedLiveText.isEmpty ? _currentSegmentText : '$_finalizedLiveText $_currentSegmentText';
          }
          notifyListeners();
        },
        onError: onError,
      );
    } catch (e) {
      isRecording = false;
      notifyListeners();
      onError(e.toString());
    }
  }

  Future<void> checkPronunciation({
    required void Function(String itemId, int score) onScored,
    required void Function(String message) onInfo,
  }) async {
    if (selectedOption == null) {
      onInfo('Choose one option first.');
      return;
    }
    if (isRecording) {
      await speech.stop();
      isRecording = false;
    }
    if (speech.history.isEmpty) {
      onInfo('Nothing was said.');
      return;
    }
    isChecking = true;
    notifyListeners();

    final fullAttemptText = [_finalizedLiveText, _currentSegmentText].where((s) => s.isNotEmpty).join(' ');
    final historyForEval = List.of(speech.history);
    if (fullAttemptText.isNotEmpty && fullAttemptText != speech.history.last.text) {
      historyForEval.add(RecognitionSnapshot(text: fullAttemptText, confidence: 0.9, isFinal: true));
    }
    final textResult = _matcher.evaluate(expectedText: selectedOption!, snapshots: historyForEval);
    final isCorrectOption = selectedOption == current!.answer;
    result = PronunciationResult(
      overallScore: textResult.accuracyPercent,

      passed: textResult.passed && isCorrectOption,
      recognizedText: textResult.bestRecognizedText,
      expectedText: selectedOption!,
      answerCorrect: isCorrectOption,
    );
    isChecking = false;
    notifyListeners();

    onScored(current!.id, isCorrectOption ? result!.overallScore : 0);
  }

  void retry() {
    result = null;
    liveText = '';
    _finalizedLiveText = '';
    _currentSegmentText = '';
    notifyListeners();
  }

  void next() {
    if (!hasNext) return;
    index++;
    selectedOption = null;
    result = null;
    liveText = '';
    _finalizedLiveText = '';
    _currentSegmentText = '';
    notifyListeners();
  }

  void disposeControllers() {
    audio.dispose();
    speech.cancel();
  }
}
