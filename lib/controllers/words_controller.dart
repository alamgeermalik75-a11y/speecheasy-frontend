import 'package:flutter/foundation.dart';
import '../models/word_item.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class WordsController extends ChangeNotifier {
  final ApiService _api;
  final StorageService _storage;
  WordsController({ApiService? api, StorageService? storage})
      : _api = api ?? ApiService(),
        _storage = storage ?? StorageService();

  Map<WordPosition, List<WordItem>>? words;
  bool loading = true;
  String? error;

  Future<void> load(String alphabetName, String letter) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      words = await _api.getWords(alphabetName, letter);
      loading = false;
      final total = words!.values.fold<int>(0, (sum, list) => sum + list.length);
      await _storage.saveLevelTotal(alphabetName, PracticeLevel.words.name, total);
    } catch (e) {
      error = e.toString();
      loading = false;
    }
    notifyListeners();
  }
}
