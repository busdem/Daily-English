class Word {
  final String id;
  final String word;
  final String ipa;
  final String cefrLevel;
  final String partOfSpeech;
  final String exampleNeutral;
  final String exampleMistakeNote;
  final String trNuance;
  final String trMeaning;
  final String? audioUrl;
  final List<String> tags;

  const Word({
    required this.id,
    required this.word,
    required this.ipa,
    required this.cefrLevel,
    required this.partOfSpeech,
    required this.exampleNeutral,
    required this.exampleMistakeNote,
    required this.trNuance,
    required this.trMeaning,
    required this.audioUrl,
    required this.tags,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String,
      word: json['word'] as String,
      ipa: json['ipa'] as String,
      cefrLevel: json['cefr_level'] as String,
      partOfSpeech: json['part_of_speech'] as String,
      exampleNeutral: json['example_neutral'] as String,
      exampleMistakeNote: json['example_mistake_note'] as String,
      trNuance: json['tr_nuance'] as String,
      trMeaning: json['tr_meaning'] as String,
      audioUrl: json['audio_url'] as String?,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}
