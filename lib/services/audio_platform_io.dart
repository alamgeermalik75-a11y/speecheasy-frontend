import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Returns a temporary file path for audio recording on mobile/desktop.
Future<String> getAudioRecordPath() async {
  final dir = await getTemporaryDirectory();
  return '${dir.path}/attempt_${DateTime.now().millisecondsSinceEpoch}.wav';
}

/// Reads the recorded audio bytes from the file on mobile/desktop.
Future<Uint8List?> getAudioBytes(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) {
      debugPrint('[AudioPlatform] file does not exist: $path');
      return null;
    }
    final bytes = await file.readAsBytes();
    debugPrint('[AudioPlatform] read ${bytes.length} bytes from file');
    if (bytes.length < 500) {
      debugPrint('[AudioPlatform] file too small: ${bytes.length} bytes');
      return null;
    }
    return bytes;
  } catch (e) {
    debugPrint('[AudioPlatform] error reading file: $e');
    return null;
  }
}

/// Deletes the temporary audio file on mobile/desktop.
Future<void> deleteAudioRecording(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      debugPrint('[AudioPlatform] deleted temp file: $path');
    }
  } catch (e) {
    debugPrint('[AudioPlatform] error deleting file: $e');
  }
}
