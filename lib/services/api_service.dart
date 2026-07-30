import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alphabet.dart';
import '../models/fill_blank_item.dart';
import '../models/word_item.dart';
import '../utils/constants.dart';

class ApiService {
  final http.Client _client;

  static final ApiService _instance = ApiService._internal(http.Client());
  ApiService._internal(this._client);

  factory ApiService({http.Client? client}) {
    if (client != null) return ApiService._internal(client);
    return _instance;
  }

  final Map<String, Map<String, dynamic>> _detailCache = {};

  final Map<String, Future<Map<String, dynamic>>> _detailInFlight = {};

  static const _requestTimeout = Duration(seconds: 15);

  Future<http.Response> _get(Uri uri) {
    return _client.get(uri).timeout(
          _requestTimeout,
          onTimeout: () => throw ApiException('Request timed out. Please check your connection and try again.'),
        );
  }

  Future<bool> checkHealth() async {
    try {
      final res = await _get(Uri.parse(ApiConfig.health));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _getAlphabetDetail(String name) async {
    final cached = _detailCache[name];
    if (cached != null) return cached;

    final inFlight = _detailInFlight[name];
    if (inFlight != null) return inFlight;

    final future = _fetchAlphabetDetail(name);
    _detailInFlight[name] = future;
    try {
      return await future;
    } finally {
      _detailInFlight.remove(name);
    }
  }

  Future<Map<String, dynamic>> _fetchAlphabetDetail(String name) async {
    final res = await _get(Uri.parse(ApiConfig.alphabet(name)));
    _throwIfNotOk(res);
    final body = jsonDecode(res.body);
    final data = _asMap(body, ['data']);
    _detailCache[name] = data;
    return data;
  }

  Future<List<Alphabet>> getAlphabets() async {
    final res = await _get(Uri.parse(ApiConfig.alphabets));
    _throwIfNotOk(res);
    final body = jsonDecode(res.body);
    final List rawList = _asList(body, ['data', 'alphabets']);

    if (rawList.isEmpty) return [];

    if (rawList.first is String) {
      final names = rawList.cast<String>();

      const batchSize = 2;
      final results = <Alphabet>[];
      for (var i = 0; i < names.length; i += batchSize) {
        final batch = names.skip(i).take(batchSize);
        final batchResults = await Future.wait(batch.map((name) => _getAlphabetWithRetry(name)));
        results.addAll(batchResults);
      }
      return results;
    }

    return rawList.map((e) => Alphabet.fromJson(e)).toList();
  }

  Future<Alphabet> _getAlphabetWithRetry(String name) async {
    Object? lastError;
    for (int attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {

        await Future.delayed(Duration(milliseconds: 400 * attempt));
      }
      try {
        return await getAlphabet(name);
      } catch (e) {
        lastError = e;
      }
    }

    assert(lastError != null);
    return Alphabet(name: name, letter: name, exampleWord: '');
  }

  Future<Alphabet> getAlphabet(String name) async {
    final data = await _getAlphabetDetail(name);

    final letter = _firstNonEmptyString(data, ['letter', 'alphabet', 'char', 'symbol']) ?? '';
    var exampleWord = _firstNonEmptyString(data, ['exampleWord', 'example', 'sampleWord']) ?? '';

    if (exampleWord.isEmpty) {
      exampleWord = _firstWordFromAnyShape(data['words']) ?? '';
    }

    return Alphabet(
      name: name,
      letter: letter,
      exampleWord: exampleWord,
      audioUrl: data['audioUrl'],
    );
  }

  Future<Map<WordPosition, List<WordItem>>> getWords(String alphabetName, String letter) async {
    final data = await _getAlphabetDetail(alphabetName);

    final Map<String, dynamic> wordsContainer =
        (data['words'] is Map) ? Map<String, dynamic>.from(data['words']) : data;

    const initialKeys = ['initial', 'start', 'beginning', 'Initial'];
    const middleKeys = ['middle', 'mid', 'Middle'];
    const finalKeys = ['final', 'end', 'ending', 'Final', 'final_'];

    List<WordItem> parseAny(List<String> candidateKeys, WordPosition pos) {
      for (final key in candidateKeys) {
        if (wordsContainer.containsKey(key)) {
          return _parseWordList(wordsContainer[key], alphabetName, key, letter, pos);
        }
      }
      return [];
    }

    var initial = parseAny(initialKeys, WordPosition.initial);
    var middle = parseAny(middleKeys, WordPosition.middle);
    var final_ = parseAny(finalKeys, WordPosition.final_);

    if (initial.isEmpty && middle.isEmpty && final_.isEmpty) {
      final flat = _flattenAnyListValue(wordsContainer) ?? _flattenAnyListValue(data);
      if (flat != null && flat.isNotEmpty) {
        initial = _parseWordList(flat, alphabetName, 'initial', letter, WordPosition.initial);
      }
    }

    return {
      WordPosition.initial: initial,
      WordPosition.middle: middle,
      WordPosition.final_: final_,
    };
  }

  Future<List<WordItem>> getSentences(String alphabetName, String letter) async {
    final data = await _getAlphabetDetail(alphabetName);
    final list = data['sentences'];
    if (list is List && list.isNotEmpty) {
      return _stringListToItems(list, letter);
    }

    return _tryFallbackEndpoint(ApiConfig.alphabetSentences(alphabetName), letter, ['sentences', 'items', 'list']);
  }

  Future<List<WordItem>> getPoems(String alphabetName, String letter) async {
    final data = await _getAlphabetDetail(alphabetName);
    final poem = data['poem'];
    if (poem is String && poem.trim().isNotEmpty) {
      return [WordItem(id: '${alphabetName}_poem', text: poem, targetLetter: letter)];
    }

    final poems = data['poems'];
    if (poems is List && poems.isNotEmpty) {
      return _stringListToItems(poems, letter);
    }
    return _tryFallbackEndpoint(ApiConfig.alphabetPoems(alphabetName), letter, ['poem', 'poems', 'items']);
  }

  Future<List<WordItem>> getStory(String alphabetName, String letter) async {
    final data = await _getAlphabetDetail(alphabetName);
    final story = data['story'];
    if (story is String && story.trim().isNotEmpty) {
      return [WordItem(id: '${alphabetName}_story', text: story, targetLetter: letter)];
    }
    return _tryFallbackEndpoint(ApiConfig.alphabetStory(alphabetName), letter, ['story', 'items']);
  }

  Future<List<FillBlankItem>> getFillBlanks(String alphabetName) async {
    final data = await _getAlphabetDetail(alphabetName);
    final list = data['fillBlanks'];
    if (list is List && list.isNotEmpty) {
      final items = <FillBlankItem>[];
      for (int i = 0; i < list.length; i++) {
        final entry = list[i];
        if (entry is! Map) continue;
        final item = FillBlankItem.fromJson(Map<String, dynamic>.from(entry), id: '${alphabetName}_fillBlank_$i');
        if (item.question.isEmpty || item.options.isEmpty) continue;
        items.add(item);
      }
      if (items.isNotEmpty) return items;
    }

    try {
      final res = await _get(Uri.parse(ApiConfig.alphabetFillBlanks(alphabetName)));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body);
      final fallbackData = _asMap(body, ['data']);
      final fallbackList = fallbackData['fillBlanks'] ?? fallbackData['items'];
      if (fallbackList is List) {
        final items = <FillBlankItem>[];
        for (int i = 0; i < fallbackList.length; i++) {
          if (fallbackList[i] is! Map) continue;
          final item = FillBlankItem.fromJson(
            Map<String, dynamic>.from(fallbackList[i]),
            id: '${alphabetName}_fillBlank_$i',
          );
          if (item.question.isNotEmpty && item.options.isNotEmpty) items.add(item);
        }
        return items;
      }
    } catch (_) {

    }
    return [];
  }

  Future<List<String>> searchWord(String word) async {
    final res = await _get(Uri.parse(ApiConfig.search(word)));
    _throwIfNotOk(res);
    final body = jsonDecode(res.body);
    final data = body is Map ? (body['data'] ?? body) : body;
    if (data is List) return data.map((e) => e.toString()).toList();
    return [data.toString()];
  }

  List<WordItem> _stringListToItems(List raw, String letter) {
    return raw
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .map((e) => WordItem(id: UniqueKeyLocal.next(), text: e.toString(), targetLetter: letter))
        .toList();
  }

  Future<List<WordItem>> _tryFallbackEndpoint(String url, String letter, List<String> candidateKeys) async {
    try {
      final res = await _get(Uri.parse(url));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body);
      final data = _asMap(body, ['data']);

      for (final key in candidateKeys) {
        final v = data[key];
        if (v is List && v.isNotEmpty) return _stringListToItems(v, letter);
        if (v is String && v.trim().isNotEmpty) {
          return [WordItem(id: UniqueKeyLocal.next(), text: v, targetLetter: letter)];
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  List<WordItem> _parseWordList(
    dynamic raw,
    String alphabetName,
    String keyForId,
    String letter,
    WordPosition pos,
  ) {
    if (raw == null) return [];
    if (raw is String || raw is Map) {
      raw = [raw];
    }
    if (raw is! List) return [];

    final items = <WordItem>[];
    for (int i = 0; i < raw.length; i++) {
      final w = raw[i];
      if (w is String) {
        if (w.trim().isEmpty) continue;
        items.add(WordItem(
          id: '${alphabetName}_${keyForId}_$i',
          text: w,
          targetLetter: letter,
          position: pos,
        ));
      } else if (w is Map) {
        items.add(WordItem.fromJson(Map<String, dynamic>.from(w), targetLetter: letter, position: pos));
      }
    }

    return items;
  }

  List? _flattenAnyListValue(Map<String, dynamic> data) {
    const candidateKeys = ['items', 'sentences', 'fillBlanks', 'poems', 'story', 'words', 'list', 'data'];
    for (final key in candidateKeys) {
      final v = data[key];
      if (v is List) return v;
    }
    return null;
  }

  String? _firstNonEmptyString(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) return v;
    }
    return null;
  }

  String? _firstWordFromAnyShape(dynamic words) {
    if (words == null) return null;
    if (words is String) return words;
    if (words is Map) {
      for (final v in words.values) {
        final found = _firstWordFromAnyShape(v);
        if (found != null && found.isNotEmpty) return found;
      }
    }
    if (words is List && words.isNotEmpty) {
      final first = words.first;
      if (first is String) return first;
      if (first is Map) return (first['word'] ?? first['text'])?.toString();
    }
    return null;
  }

  List _asList(dynamic body, List<String> keys) {
    if (body is List) return body;
    if (body is Map) {
      for (final k in keys) {
        if (body[k] is List) return body[k];
      }
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic body, List<String> keys) {
    if (body is Map) {
      for (final k in keys) {
        if (body[k] is Map) return Map<String, dynamic>.from(body[k]);
      }
      return Map<String, dynamic>.from(body);
    }
    return {};
  }

  void _throwIfNotOk(http.Response res) {
    if (res.statusCode != 200) {
      throw ApiException('Request failed (${res.statusCode}): ${res.request?.url}');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class UniqueKeyLocal {
  static int _c = 0;
  static String next() => 'gen_${_c++}_${DateTime.now().microsecondsSinceEpoch}';
}
