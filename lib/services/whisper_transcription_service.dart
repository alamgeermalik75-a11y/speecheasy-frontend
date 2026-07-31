import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records raw mic audio and sends it to our backend proxy, which forwards
/// it to Groq's Whisper API for transcription. This replaces the phone's
/// built-in speech recognizer as the source of truth for scoring, so every
/// device gets identical transcription quality.
class WhisperTranscriptionService {
  final AudioRecorder _recorder = AudioRecorder();

  /// Your backend proxy endpoint, e.g.
  /// https://booklearningapi.up.railway.app/api/transcribe
  /// NOTE: never call Groq directly from the app with the API key embedded -
  /// the proxy is what keeps the key off the device.
  final String backendUrl;

  String? _currentFilePath;
  bool _recording = false;
  String? _stoppedFilePath;

  WhisperTranscriptionService({required this.backendUrl});

  bool get isRecording => _recording;

  /// Starts capturing raw audio to a temp file. Returns false if mic
  /// permission was denied.
  Future<bool> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    debugPrint('[Whisper] hasPermission: $hasPermission');
    if (!hasPermission) return false;

    final dir = await getTemporaryDirectory();
    _currentFilePath =
    '${dir.path}/attempt_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _currentFilePath!,
    );
    _recording = true;
    debugPrint('[Whisper] started recording to $_currentFilePath');
    return true;
  }

  /// Stops recording and keeps the file for later transcription, without
  /// uploading anything yet.
  Future<String?> stopRecording() async {
    if (!_recording) {
      debugPrint('[Whisper] stopRecording called but not recording');
      return _stoppedFilePath;
    }
    final path = await _recorder.stop();
    _recording = false;
    debugPrint('[Whisper] stopped recording, path: $path');
    if (path == null) return null;

    final file = File(path);
    final exists = await file.exists();
    final size = exists ? await file.length() : -1;
    debugPrint('[Whisper] file exists: $exists, size: $size bytes');
    if (!exists || size < 1000) {
      debugPrint('[Whisper] file too small');
      return null;
    }
    _stoppedFilePath = path;
    return path;
  }

  /// Uploads a previously-stopped recording and returns the transcribed
  /// text. Returns an empty string if nothing usable was captured.
  Future<String> transcribeStoppedRecording({String language = 'ur'}) async {
    final path = _stoppedFilePath;
    if (path == null) return '';
    final file = File(path);
    if (!await file.exists()) return '';

    try {
      debugPrint('[Whisper] uploading to $backendUrl');
      final request = http.MultipartRequest('POST', Uri.parse(backendUrl))
        ..fields['language'] = language
        ..files.add(await http.MultipartFile.fromPath('audio', file.path));

      final streamed = await request.send().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(
              'Transcription is taking too long. Please check your internet connection and try again.',
            ),
          );
      final response = await http.Response.fromStream(streamed);
      debugPrint('[Whisper] response ${response.statusCode}: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Transcription failed (${response.statusCode}): ${response.body}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return (decoded['text'] as String? ?? '').trim();
    } finally {
      file.delete().catchError((_) => file);
      _stoppedFilePath = null;
    }
  }

  /// Convenience: stops (if still recording) and transcribes in one call -
  /// used when Check pronunciation is tapped without stopping first.
  Future<String> stopAndTranscribe({String language = 'ur'}) async {
    if (_recording) {
      final stopped = await stopRecording();
      if (stopped == null) return '';
    }
    if (_stoppedFilePath == null) return '';
    return transcribeStoppedRecording(language: language);
  }

  /// Cancels an in-progress recording without transcribing it.
  Future<void> cancel() async {
    if (_recording) {
      final path = await _recorder.stop();
      _recording = false;
      if (path != null) {
        File(path).delete().catchError((_) => File(path));
      }
    }
    if (_stoppedFilePath != null) {
      File(_stoppedFilePath!).delete().catchError((_) => File(_stoppedFilePath!));
      _stoppedFilePath = null;
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}