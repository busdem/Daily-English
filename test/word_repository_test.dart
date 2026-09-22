import 'package:flutter_test/flutter_test.dart';

import 'package:daily_english_app/data/repositories/word_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all seed words with valid schema and unique ids', () async {
    final words = await WordRepository().loadWords();

    expect(words.length, 240);

    final ids = words.map((w) => w.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'ids must be unique');

    final levelCounts = <String, int>{};
    for (final word in words) {
      levelCounts[word.cefrLevel] = (levelCounts[word.cefrLevel] ?? 0) + 1;

      expect(word.word, isNotEmpty);
      expect(word.ipa, isNotEmpty);
      expect(word.partOfSpeech, isNotEmpty);
      expect(word.exampleNeutral, isNotEmpty);
      expect(word.exampleMistakeNote, isNotEmpty);
      expect(word.trNuance, isNotEmpty);
      expect(word.trMeaning, isNotEmpty);
      expect(word.tags, isNotEmpty);
    }

    expect(levelCounts['A2'], 50);
    expect(levelCounts['B1'], 70);
    expect(levelCounts['B2'], 70);
    expect(levelCounts['C1'], 50);

    final meanings = words.map((w) => w.trMeaning).toList();
    expect(
      meanings.toSet().length,
      meanings.length,
      reason: 'tr_meaning values must be distinct for quiz options',
    );
  });
}
