import 'package:flutter/material.dart';

class ApiConfig {
  static const String baseUrl = 'https://booklearningapi.up.railway.app';

  static const String health = '$baseUrl/health';
  static const String alphabets = '$baseUrl/alphabets';

  static String alphabet(String name) => '$baseUrl/alphabet/$name';
  static String alphabetWords(String name) => '$baseUrl/alphabet/$name/words';
  static String alphabetFillBlanks(String name) =>
      '$baseUrl/alphabet/$name/fillBlanks';
  static String alphabetSentences(String name) =>
      '$baseUrl/alphabet/$name/sentences';
  static String alphabetPoems(String name) => '$baseUrl/alphabet/$name/poems';
  static String alphabetStory(String name) => '$baseUrl/alphabet/$name/story';

  static String search(String word) => '$baseUrl/search?word=$word';
}

/// Config for the separate Speechmatics transcription backend
/// (whisper-transcription-backend). This is NOT the same server as
/// ApiConfig.baseUrl above - it's a standalone Node/Express proxy that
/// currently only runs locally on the developer's machine, not deployed
/// anywhere yet.
///
/// While testing like this, your phone and computer must be on the same
/// Wi-Fi network, and this IP must be your computer's *current* local
/// network address (it can change when you reconnect to Wi-Fi):
///   - Windows: run `ipconfig` in cmd, look for "IPv4 Address"
///   - Mac/Linux: run `ifconfig` (or `ipconfig getifaddr en0` on Mac)
///
/// Before releasing this app to real users, deploy this backend somewhere
/// reachable from anywhere (Railway, Render, etc.) and point this at that
/// public URL instead - a hardcoded local IP will only ever work on your
/// own Wi-Fi.
class WhisperConfig {
  static const String transcribe = 'http://192.168.1.4:3000/api/transcribe';
}

enum PracticeLevel { words, sentences, fillBlanks, poems, story }

extension PracticeLevelX on PracticeLevel {
  String get label {
    switch (this) {
      case PracticeLevel.words:
        return 'Words';
      case PracticeLevel.sentences:
        return 'Sentences';
      case PracticeLevel.fillBlanks:
        return 'Fill in the blanks';
      case PracticeLevel.poems:
        return 'Poems';
      case PracticeLevel.story:
        return 'Story';
    }
  }

  bool get isWholeWordScored => this == PracticeLevel.words;
}

enum WordPosition { initial, middle, final_ }

extension WordPositionX on WordPosition {
  String get label {
    switch (this) {
      case WordPosition.initial:
        return 'Initial';
      case WordPosition.middle:
        return 'Middle';
      case WordPosition.final_:
        return 'Final';
    }
  }

  String get hint {
    switch (this) {
      case WordPosition.initial:
        return 'Sound at the start';
      case WordPosition.middle:
        return 'Sound in the middle';
      case WordPosition.final_:
        return 'Sound at the end';
    }
  }
}

class AppColors {
  static const Color primaryDark = Color(0xFF0D2B4E);
  static const Color primary = Color(0xFF123A63);
  static const Color accentGreen = Color(0xFF1E8E3E);
  static const Color lightGreenBg = Color(0xFFE6F4EA);
  static const Color background = Color(0xFFF6F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE4E7EC);
  static const Color textPrimary = Color(0xFF1A2330);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color locked = Color(0xFFB0B4BA);

  static const Color accentGold = Color(0xFFC08A28);
  static const Color lightGoldBg = Color(0xFFFBF1DE);

  static const Color danger = Color(0xFFC0392B);
  static const Color lightDangerBg = Color(0xFFFCEBE9);

  static const Color shadow = Color(0x14000000);
}
