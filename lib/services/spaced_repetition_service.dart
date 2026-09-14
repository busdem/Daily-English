import '../data/models/word_progress.dart';

const int maxReviewIntervalDays = 30;

WordProgress applyCorrectAnswer(WordProgress progress, DateTime today) {
  final newInterval = (progress.reviewIntervalDays * 2).clamp(
    1,
    maxReviewIntervalDays,
  );
  return progress.copyWith(
    reviewIntervalDays: newInterval,
    nextReviewDue: today.add(Duration(days: newInterval)),
    correctCount: progress.correctCount + 1,
  );
}

WordProgress applyIncorrectAnswer(WordProgress progress, DateTime today) {
  return progress.copyWith(
    reviewIntervalDays: 1,
    nextReviewDue: today.add(const Duration(days: 1)),
    incorrectCount: progress.incorrectCount + 1,
  );
}
