class Alphabet {
  final String name;
  final String letter;
  final String exampleWord;
  final String? audioUrl;

  Alphabet({
    required this.name,
    required this.letter,
    required this.exampleWord,
    this.audioUrl,
  });

  factory Alphabet.fromJson(Map<String, dynamic> json) {
    return Alphabet(
      name: json['name'] ?? json['key'] ?? '',
      letter: json['letter'] ?? json['alphabet'] ?? '',
      exampleWord: json['exampleWord'] ?? json['example'] ?? '',
      audioUrl: json['audioUrl'],
    );
  }
}
