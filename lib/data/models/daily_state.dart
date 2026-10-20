import '../../core/utils/date_utils.dart';

class DailyState {
  final DateTime date;
  final String? newWordId;
  final bool newWordLearned;
  final List<String> reviewQueueIds;
  final List<String> reviewedIds;

  const DailyState({
    required this.date,
    required this.newWordId,
    required this.newWordLearned,
    required this.reviewQueueIds,
    required this.reviewedIds,
  });

  DailyState copyWith({bool? newWordLearned, List<String>? reviewedIds}) {
    return DailyState(
      date: date,
      newWordId: newWordId,
      newWordLearned: newWordLearned ?? this.newWordLearned,
      reviewQueueIds: reviewQueueIds,
      reviewedIds: reviewedIds ?? this.reviewedIds,
    );
  }

  factory DailyState.fromJson(Map<String, dynamic> json) {
    return DailyState(
      date: DateTime.parse(json['date'] as String),
      newWordId: json['new_word_id'] as String?,
      newWordLearned: json['new_word_learned'] as bool,
      reviewQueueIds: (json['review_queue_ids'] as List<dynamic>).cast<String>(),
      reviewedIds: (json['reviewed_ids'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': toDateString(date),
      'new_word_id': newWordId,
      'new_word_learned': newWordLearned,
      'review_queue_ids': reviewQueueIds,
      'reviewed_ids': reviewedIds,
    };
  }
}
