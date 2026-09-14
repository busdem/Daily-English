class WordProgress {
  final String wordId;
  final DateTime nextReviewDue;
  final int reviewIntervalDays;
  final int correctCount;
  final int incorrectCount;

  const WordProgress({
    required this.wordId,
    required this.nextReviewDue,
    required this.reviewIntervalDays,
    required this.correctCount,
    required this.incorrectCount,
  });

  factory WordProgress.initial(String wordId, DateTime today) {
    return WordProgress(
      wordId: wordId,
      nextReviewDue: today,
      reviewIntervalDays: 1,
      correctCount: 0,
      incorrectCount: 0,
    );
  }

  WordProgress copyWith({
    DateTime? nextReviewDue,
    int? reviewIntervalDays,
    int? correctCount,
    int? incorrectCount,
  }) {
    return WordProgress(
      wordId: wordId,
      nextReviewDue: nextReviewDue ?? this.nextReviewDue,
      reviewIntervalDays: reviewIntervalDays ?? this.reviewIntervalDays,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
    );
  }

  factory WordProgress.fromJson(Map<String, dynamic> json) {
    return WordProgress(
      wordId: json['word_id'] as String,
      nextReviewDue: DateTime.parse(json['next_review_due'] as String),
      reviewIntervalDays: json['review_interval_days'] as int,
      correctCount: json['correct_count'] as int,
      incorrectCount: json['incorrect_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word_id': wordId,
      'next_review_due': _dateOnly(nextReviewDue),
      'review_interval_days': reviewIntervalDays,
      'correct_count': correctCount,
      'incorrect_count': incorrectCount,
    };
  }

  static String _dateOnly(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.toIso8601String().split('T').first;
  }
}
