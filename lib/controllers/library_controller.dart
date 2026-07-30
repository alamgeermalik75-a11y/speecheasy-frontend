import 'package:flutter/foundation.dart';
import '../models/alphabet.dart';
import '../services/api_service.dart';

enum LoadState { idle, loading, loaded, error }

class LibraryController extends ChangeNotifier {
  final ApiService _api;
  LibraryController({ApiService? api}) : _api = api ?? ApiService();

  LoadState state = LoadState.idle;
  List<Alphabet> alphabets = [];
  String? errorMessage;

  Future<void> loadAlphabets() async {
    state = LoadState.loading;
    notifyListeners();
    try {
      alphabets = await _api.getAlphabets();
      state = LoadState.loaded;
    } catch (e) {
      errorMessage = e.toString();
      state = LoadState.error;
    }
    notifyListeners();
  }

  bool letterLooksUnresolved(Alphabet a) => a.letter == a.name && !_hasArabicChar(a.letter);

  bool _hasArabicChar(String s) => s.runes.any((r) => r >= 0x0600 && r <= 0x06FF);

  Future<void> retryOne(String name) async {
    try {
      final fresh = await _api.getAlphabet(name);
      final index = alphabets.indexWhere((a) => a.name == name);
      if (index != -1) {
        alphabets[index] = fresh;
        notifyListeners();
      }
    } catch (_) {

    }
  }
}
