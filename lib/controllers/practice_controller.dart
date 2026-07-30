import 'package:flutter/foundation.dart';
import '../models/alphabet.dart';
import '../models/attempt.dart';
import '../models/word_item.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/evaluation_service.dart';
import '../services/speech_recognition_service.dart';
import '../services/storage_service.dart';
import '../services/whisper_transcription_service.dart';
import '../utils/constants.dart';

class PracticeController extends ChangeNotifier {
  final ApiService _api;
  final AudioService audio;
  final SpeechRecognitionService speech;
  final WhisperTranscriptionService whisper;
  final EvaluationService _evaluation;
  final StorageService _storage;

  PracticeController({
    ApiService? api,
    AudioService? audioService,
    SpeechRecognitionService? speechService,
    WhisperTranscriptionService? whisperService,
    EvaluationService? evaluationService,
    StorageService? storage,
  })  : _api = api ?? ApiService(),
        audio = audioService ?? AudioService(),
        speech = speechService ?? SpeechRecognitionService(),
        whisper = whisperService ??
            WhisperTranscriptionService(
              backendUrl: 'http://192.168.1.4:3000/api/transcribe',
            ),
        _evaluation = evaluationService ?? EvaluationService(),
        _storage = storage ?? StorageService() {
    audio.onStateChanged = notifyListeners;

    audio.warmUp();
  }

  bool get isSpeaking => audio.isSpeaking;

  String _finalizedLiveText = '';

  String _currentSegmentText = '';

  List<WordItem> items = [];
  int index = 0;
  bool loading = false;
  String? loadError;

  bool isRecording = false;
  String liveText = '';
  bool isChecking = false;
  PronunciationResult? result;

  WordItem? get current => items.isEmpty ? null : items[index];
  bool get hasNext => index < items.length - 1;

  Future<String?> initSpeech() async {
    await speech.init();
    final locale = speech.resolvedLocaleId ?? '';
    if (!locale.toLowerCase().startsWith('ur')) {
      return 'Is device par Urdu speech recognition install nahi hai - live text galat aa sakta hai.';
    }
    return null;
  }

  void setItems(List<WordItem> list, {int startIndex = 0}) {
    items = list;
    index = startIndex;
    loading = false;
    notifyListeners();
  }

  Future<void> loadFromApi(Alphabet alphabet, PracticeLevel level) async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      List<WordItem> fetched;
      switch (level) {
        case PracticeLevel.sentences:
          fetched = await _api.getSentences(alphabet.name, alphabet.letter);
          break;
        case PracticeLevel.poems:
          fetched = await _api.getPoems(alphabet.name, alphabet.letter);
          break;
        case PracticeLevel.story:
          fetched = await _api.getStory(alphabet.name, alphabet.letter);
          break;
        case PracticeLevel.words:
        case PracticeLevel.fillBlanks:
          fetched = [];
          break;
      }
      items = fetched;
      loading = false;
      if (level != PracticeLevel.words && level != PracticeLevel.fillBlanks) {
        await _storage.saveLevelTotal(alphabet.name, level.name, items.length);
      }
    } catch (e) {
      loadError = e.toString();
      loading = false;
    }
    notifyListeners();
  }

  Future<void> playReference() async {
    if (current != null) await audio.playReference(current!.text);
  }

  Future<void> toggleMic({required void Function(String error) onError}) async {
    if (isRecording) {
      await whisper.stopRecording();
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

    final micOk = await whisper.startRecording();
    if (!micOk) {
      isRecording = false;
      notifyListeners();
      onError('Microphone permission denied.');
      return;
    }
    // Native speech_to_text is intentionally NOT started here. Log evidence
    // (AudioManager dispatching onAudioFocusChange(-2) to the record
    // package's AudioSessionManager the instant STT starts listening)
    // confirms STT steals audio focus from the Whisper recorder mid-attempt,
    // causing it to capture silence. Live word-by-word captions are
    // disabled - the practice screen should show a simple "Listening..."
    // state instead while isRecording is true.
  }

  Future<void> checkPronunciation({
    required PracticeLevel level,
    required String targetLetter,
    required void Function(String itemId, int score) onScored,
    required void Function(String message) onInfo,
  }) async {
    if (current == null) return;
    if (isRecording) {
      isRecording = false;
    }
    isChecking = true;
    notifyListeners();
    try {
      final transcribed = await whisper.stopAndTranscribe();
      if (transcribed.isEmpty) {
        isChecking = false;
        notifyListeners();
        onInfo('Kuch bola nahi gaya.');
        return;
      }
      liveText = transcribed;
      final historyForEval = [
        RecognitionSnapshot(text: transcribed, confidence: 1.0, isFinal: true),
      ];
      final evaluated = await _evaluation.evaluate(
        level: level,
        expectedText: current!.text,
        targetLetter: targetLetter,
        recognitionHistory: historyForEval,
      );
      result = evaluated;
      isChecking = false;
      notifyListeners();
      onScored(current!.id, evaluated.overallScore);
    } catch (e) {
      isChecking = false;
      notifyListeners();
      onInfo('Evaluation error: $e');
    }
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
    result = null;
    liveText = '';
    _finalizedLiveText = '';
    _currentSegmentText = '';
    notifyListeners();
  }

  void disposeControllers() {
    audio.dispose();
    speech.cancel();
    whisper.dispose();
  }
}