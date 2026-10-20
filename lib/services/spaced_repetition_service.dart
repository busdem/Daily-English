import '../core/utils/date_utils.dart';
import '../data/models/word_progress.dart';

const int maxReviewIntervalDays = 30;

WordProgress applyCorrectAnswer(WordProgress progress, DateTime today) {
  final newInterval = (progress.reviewIntervalDays * 2).clamp(
    1,
    maxReviewIntervalDays,
  );
  return progress.copyWith(
    reviewIntervalDays: newInterval,
    nextReviewDue: addDays(today, newInterval),
    correctCount: progress.correctCount + 1,
  );
}

WordProgress applyIncorrectAnswer(WordProgress progress, DateTime today) {
  return progress.copyWith(
    reviewIntervalDays: 1,
    nextReviewDue: addDays(today, 1),
    incorrectCount: progress.incorrectCount + 1,
  );
}
