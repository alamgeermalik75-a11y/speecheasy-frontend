import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

import 'audio_platform_io.dart'
    if (dart.library.js_interop) 'audio_platform_web.dart'
    if (dart.library.html) 'audio_platform_web.dart';

/// Records raw mic audio and sends it to our backend proxy, which forwards
/// it to Groq's Whisper API for transcription. This replaces the phone's
/// built-in speech recognizer as the source of truth for scoring, so every
/// device gets identical transcription quality.
class WhisperTranscriptionService {
  final AudioRecorder _recorder = AudioRecorder();

  /// Your backend proxy endpoint, e.g.
  /// https://fastapi-backend-speech.onrender.com/api/transcribe
  final String backendUrl;

  bool _recording = false;
  String? _stoppedFilePath;
  Uint8List? _stoppedAudioBytes;

  WhisperTranscriptionService({required this.backendUrl});

  bool get isRecording => _recording;

  /// Starts capturing raw audio to a temp file (or memory blob on Web).
  /// Returns false if mic permission was denied.
  Future<bool> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      debugPrint('[Whisper] hasPermission: $hasPermission');
      if (!hasPermission) return false;

      final path = await getAudioRecordPath();

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      _recording = true;
      _stoppedFilePath = null;
      _stoppedAudioBytes = null;
      debugPrint('[Whisper] started recording to "$path"');
      return true;
    } catch (e) {
      debugPrint('[Whisper] startRecording error: $e');
      _recording = false;
      return false;
    }
  }

  /// Stops recording and keeps the audio for later transcription, without
  /// uploading anything yet.
  Future<String?> stopRecording() async {
    if (!_recording) {
      debugPrint('[Whisper] stopRecording called but not recording');
      return _stoppedFilePath;
    }
    try {
      final path = await _recorder.stop();
      _recording = false;
      debugPrint('[Whisper] stopped recording, path: $path');
      if (path == null || path.isEmpty) {
        debugPrint('[Whisper] stop returned null or empty path');
        return null;
      }

      final bytes = await getAudioBytes(path);
      if (bytes == null || bytes.length < 500) {
        debugPrint('[Whisper] file/blob too small or unreadable');
        return null;
      }

      _stoppedFilePath = path;
      _stoppedAudioBytes = bytes;
      return path;
    } catch (e) {
      debugPrint('[Whisper] stopRecording error: $e');
      _recording = false;
      return null;
    }
  }

  /// Uploads a previously-stopped recording and returns the transcribed
  /// text. Returns an empty string if nothing usable was captured.
  Future<String> transcribeStoppedRecording({String language = 'ur'}) async {
    final path = _stoppedFilePath;
    var bytes = _stoppedAudioBytes;

    if (bytes == null && path != null && path.isNotEmpty) {
      bytes = await getAudioBytes(path);
    }

    if (bytes == null || bytes.isEmpty) {
      debugPrint('[Whisper] no audio bytes available to transcribe');
      return '';
    }

    try {
      debugPrint('[Whisper] uploading ${bytes.length} bytes to $backendUrl (lang: $language)');
      final request = http.MultipartRequest('POST', Uri.parse(backendUrl))
        ..fields['language'] = language
        ..files.add(
          http.MultipartFile.fromBytes(
            'audio',
            bytes,
            filename: 'attempt.wav',
          ),
        );

      final streamed = await request.send().timeout(
            const Duration(seconds: 45),
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
    } catch (e) {
      debugPrint('[Whisper] transcription request error: $e');
      return '';
    } finally {
      if (path != null) {
        await deleteAudioRecording(path);
      }
      _stoppedFilePath = null;
      _stoppedAudioBytes = null;
    }
  }

  /// Convenience: stops (if still recording) and transcribes in one call.
  Future<String> stopAndTranscribe({String language = 'ur'}) async {
    if (_recording) {
      final stopped = await stopRecording();
      if (stopped == null) return '';
    }
    if (_stoppedFilePath == null && _stoppedAudioBytes == null) return '';
    return transcribeStoppedRecording(language: language);
  }

  /// Cancels an in-progress recording without transcribing it.
  Future<void> cancel() async {
    try {
      if (_recording) {
        final path = await _recorder.stop();
        _recording = false;
        if (path != null) {
          await deleteAudioRecording(path);
        }
      }
      if (_stoppedFilePath != null) {
        await deleteAudioRecording(_stoppedFilePath!);
      }
    } catch (e) {
      debugPrint('[Whisper] cancel error: $e');
    } finally {
      _stoppedFilePath = null;
      _stoppedAudioBytes = null;
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}