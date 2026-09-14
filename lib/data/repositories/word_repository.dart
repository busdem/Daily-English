import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/word.dart';

class WordRepository {
  List<Word>? _cache;

  Future<List<Word>> loadWords() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString('assets/data/words_seed.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    final words = decoded
        .map((e) => Word.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = words;
    return words;
  }

  Future<Word?> findById(String id) async {
    final words = await loadWords();
    for (final word in words) {
      if (word.id == id) return word;
    }
    return null;
  }
}
