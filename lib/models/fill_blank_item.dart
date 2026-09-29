class FillBlankItem {
  final String id;
  final String question;
  final List<String> options;
  final String answer;

  FillBlankItem({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
  });

  factory FillBlankItem.fromJson(Map<String, dynamic> json, {required String id}) {
    final rawOptions = json['options'];
    return FillBlankItem(
      id: id,
      question: json['question']?.toString() ?? '',
      options: rawOptions is List ? rawOptions.map((e) => e.toString()).toList() : const [],
      answer: json['answer']?.toString() ?? '',
    );
  }
}
