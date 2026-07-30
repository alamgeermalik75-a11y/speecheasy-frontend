import 'package:speech_to_text/speech_to_text.dart' as stt;

class RecognitionSnapshot {
  final String text;
  final double confidence;
  final bool isFinal;
  RecognitionSnapshot({required this.text, required this.confidence, required this.isFinal});
}

class SpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  String? _resolvedLocaleId;
  final List<RecognitionSnapshot> history = [];

  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;

  String? get resolvedLocaleId => _resolvedLocaleId;

  Future<bool> init({void Function(String error)? onError}) async {
    _available = await _speech.initialize(
      onError: (e) => onError?.call(e.errorMsg),
      onStatus: (s) => print('Speech status: $s'),
    );
    if (_available) {
      _resolvedLocaleId = await _resolveUrduLocale();
    }
    return _available;
  }

  Future<String> _resolveUrduLocale() async {
    const preferred = ['ur_PK', 'ur-PK', 'ur_IN', 'ur-IN', 'ur'];
    try {
      final locales = await _speech.locales();
      for (final want in preferred) {
        final match = locales.where((l) => l.localeId.replaceAll('-', '_').toLowerCase() == want.replaceAll('-', '_').toLowerCase());
        if (match.isNotEmpty) return match.first.localeId;
      }

      final anyUrdu = locales.where((l) => l.localeId.toLowerCase().startsWith('ur'));
      if (anyUrdu.isNotEmpty) return anyUrdu.first.localeId;
    } catch (_) {

    }
    return 'ur_PK';
  }

  Future<void> startListening({
    required void Function(String text, bool isFinal, double confidence) onResult,
    String? localeId,
    void Function(String error)? onError,
  }) async {
    history.clear();
    if (!_available) {
      final ok = await init(onError: onError);
      if (!ok) {
        onError?.call('Speech recognizer unavailable - check RECORD_AUDIO permission and locale.');
        return;
      }
    }
    await _speech.listen(
      onResult: (result) {
        final confidence = result.confidence.isNaN ? 0.5 : result.confidence;
        history.add(RecognitionSnapshot(
          text: result.recognizedWords,
          confidence: confidence,
          isFinal: result.finalResult,
        ));
        onResult(result.recognizedWords, result.finalResult, confidence);
      },
      localeId: localeId ?? _resolvedLocaleId ?? 'ur_PK',
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 30),

      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
        onDevice: false,
      ),
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  Future<void> cancel() async {
    await _speech.cancel();
  }
}
