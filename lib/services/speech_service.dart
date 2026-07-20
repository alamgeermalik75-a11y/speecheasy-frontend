import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool available = false;

  Future<String?> init() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) return "Microphone permission zaroori hai.";

    await _tts.setLanguage("ur-PK");
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(1.0);

    available = await _speech.initialize();
    if (!available) return "Is device par speech recognition available nahi hai.";
    return null;
  }

  Future<void> speak(String text) => _tts.speak(text);

  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
    Duration listenFor = const Duration(seconds: 15),
    Duration pauseFor = const Duration(seconds: 4),
  }) {
    return _speech.listen(
      localeId: "ur_PK",
      onResult: (res) => onResult(res.recognizedWords, res.finalResult),
      listenFor: listenFor,
      pauseFor: pauseFor,
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() => _speech.stop();

  void dispose() {
    _speech.stop();
    _tts.stop();
  }
}
