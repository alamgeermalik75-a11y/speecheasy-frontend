import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Returns an empty path for recording on Web (in-memory Blob).
Future<String> getAudioRecordPath() async {
  return '';
}

/// Reads the recorded audio bytes from the blob URL on Web.
Future<Uint8List?> getAudioBytes(String path) async {
  try {
    debugPrint('[AudioPlatformWeb] fetching blob bytes from: $path');
    final response = await http.get(Uri.parse(path));
    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      debugPrint('[AudioPlatformWeb] fetched ${response.bodyBytes.length} bytes');
      if (response.bodyBytes.length < 500) {
        debugPrint('[AudioPlatformWeb] audio blob too small (${response.bodyBytes.length} bytes)');
        return null;
      }
      return response.bodyBytes;
    }
    debugPrint('[AudioPlatformWeb] failed to fetch blob: status ${response.statusCode}');
    return null;
  } catch (e) {
    debugPrint('[AudioPlatformWeb] error fetching blob audio: $e');
    return null;
  }
}

/// No filesystem file to delete on Web.
Future<void> deleteAudioRecording(String path) async {
  debugPrint('[AudioPlatformWeb] cleanup for: $path');
}
