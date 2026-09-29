import '../utils/constants.dart';

class WordItem {
  final String id;
  final String text;
  final String? audioUrl;
  final WordPosition? position;
  final String targetLetter;

  WordItem({
    required this.id,
    required this.text,
    required this.targetLetter,
    this.audioUrl,
    this.position,
  });

  factory WordItem.fromJson(Map<String, dynamic> json, {String? targetLetter, WordPosition? position}) {
    return WordItem(
      id: json['id']?.toString() ?? json['text'] ?? UniqueKey_.next(),
      text: json['word'] ?? json['text'] ?? json['sentence'] ?? '',
      audioUrl: json['audioUrl'] ?? json['audio'],
      position: position,
      targetLetter: targetLetter ?? json['letter'] ?? '',
    );
  }
}

class UniqueKey_ {
  static int _c = 0;
  static String next() => 'item_${_c++}_${DateTime.now().microsecondsSinceEpoch}';
}
