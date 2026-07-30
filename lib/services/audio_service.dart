import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  final FlutterTts _tts = FlutterTts();
  bool _ttsConfigured = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  void Function()? onStateChanged;

  Future<void> _ensureTtsConfigured() async {
    if (_ttsConfigured) return;
    await _tts.setLanguage('ur-PK');
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(_markStopped);
    _tts.setCancelHandler(_markStopped);
    _tts.setErrorHandler((msg) => _markStopped());
    _ttsConfigured = true;
  }

  Future<void> warmUp() => _ensureTtsConfigured();

  void _markStopped() {
    _isSpeaking = false;
    onStateChanged?.call();
  }

  Future<void> playReference(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureTtsConfigured();
    if (_isSpeaking) {
      await stop();
      return;
    }
    _isSpeaking = true;
    onStateChanged?.call();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _markStopped();
  }

  Future<void> dispose() async {
    await _tts.stop();
    _isSpeaking = false;
  }
}
