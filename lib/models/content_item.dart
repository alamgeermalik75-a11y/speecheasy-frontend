class ContentItem {
  final String id;
  final String text;
  final String? meaningEn;

  ContentItem({required this.id, required this.text, this.meaningEn});

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json["id"],
      text: json["text"],
      meaningEn: json["meaning_en"],
    );
  }

  bool get isSingleWord => meaningEn != null;
}


class FillBlankItem {
  final String id;
  final String template;
  final List<String> options;
  final String answer;
  final String fullText;

  FillBlankItem({
    required this.id,
    required this.template,
    required this.options,
    required this.answer,
    required this.fullText,
  });

  factory FillBlankItem.fromJson(Map<String, dynamic> json) {
    return FillBlankItem(
      id: json["id"],
      template: json["template"],
      options: List<String>.from(json["options"]),
      answer: json["answer"],
      fullText: json["full_text"],
    );
  }
}

class AppContent {
  final List<ContentItem> words;
  final List<ContentItem> sentences;
  final List<ContentItem> poem;
  final List<ContentItem> story;
  final List<FillBlankItem> fillBlanks;

  AppContent({
    required this.words,
    required this.sentences,
    required this.poem,
    required this.story,
    required this.fillBlanks,
  });

  factory AppContent.fromJson(Map<String, dynamic> json) {
    List<ContentItem> parseItems(String key) =>
        (json[key] as List).map((e) => ContentItem.fromJson(e)).toList();

    return AppContent(
      words: parseItems("words"),
      sentences: parseItems("sentences"),
      poem: parseItems("poem"),
      story: parseItems("story"),
      fillBlanks: (json["fill_blanks"] as List).map((e) => FillBlankItem.fromJson(e)).toList(),
    );
  }
}
