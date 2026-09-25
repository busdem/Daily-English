import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/utils/date_utils.dart';
import '../data/models/word.dart';
import '../data/models/word_progress.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/word_repository.dart';
import '../services/notification_service.dart';
import '../services/spaced_repetition_service.dart';

enum TodayWordKind { newWord, dueReview, practice }

class AppState extends ChangeNotifier {
  AppState({
    WordRepository? wordRepository,
    ProgressRepository? progressRepository,
    NotificationService? notificationService,
  }) : _wordRepository = wordRepository ?? WordRepository(),
       _progressRepository = progressRepository ?? ProgressRepository(),
       _notificationService = notificationService ?? NotificationService();

  final WordRepository _wordRepository;
  final ProgressRepository _progressRepository;
  final NotificationService _notificationService;

  bool isLoading = true;
  List<Word> words = [];
  Map<String, WordProgress> progressMap = {};
  StreakData streak = StreakData.empty;
  NotificationSettings notificationSettings = NotificationSettings.defaults;

  Word? _todayWord;
  TodayWordKind? _todayWordKind;
  DateTime? _todayWordComputedOn;

  Future<void> init() async {
    words = await _wordRepository.loadWords();
    progressMap = await _progressRepository.loadProgress();
    streak = await _progressRepository.loadStreak();
    notificationSettings = await _progressRepository.loadNotificationSettings();
    await _applyNotificationSchedule();
    isLoading = false;
    notifyListeners();
  }

  Word? get todayWord {
    _ensureTodayWordComputed();
    return _todayWord;
  }

  TodayWordKind todayWordKindForToday() {
    _ensureTodayWordComputed();
    return _todayWordKind ?? TodayWordKind.newWord;
  }

  void _ensureTodayWordComputed() {
    final todayDate = today();
    if (_todayWord != null && isSameDay(_todayWordComputedOn!, todayDate)) {
      return;
    }
    final word = _computeTodayWord(todayDate);
    final progress = word == null ? null : progressMap[word.id];
    _todayWord = word;
    _todayWordKind = progress == null
        ? TodayWordKind.newWord
        : (!progress.nextReviewDue.isAfter(todayDate)
              ? TodayWordKind.dueReview
              : TodayWordKind.practice);
    _todayWordComputedOn = todayDate;
  }

  bool get isTodayCompleted {
    final word = todayWord;
    if (word == null) return false;
    return streak.lastCompletedWordId == word.id &&
        streak.lastCompletedDate != null &&
        isSameDay(streak.lastCompletedDate!, today());
  }

  int get wordsLearnedCount =>
      progressMap.values.where((p) => p.correctCount >= 1).length;

  List<String> quizOptionsFor(Word word) {
    final others = words.where((w) => w.id != word.id).toList()
      ..shuffle(Random(word.id.hashCode));
    final distractors = others.take(3).map((w) => w.trMeaning).toList();
    final options = [word.trMeaning, ...distractors];
    options.shuffle(Random(word.id.hashCode ^ today().day));
    return options;
  }

  Future<void> submitTodayAnswer(bool correct) async {
    final word = todayWord;
    if (word == null) return;

    final todayDate = today();
    final existing = progressMap[word.id] ?? WordProgress.initial(word.id, todayDate);
    final updated = correct
        ? applyCorrectAnswer(existing, todayDate)
        : applyIncorrectAnswer(existing, todayDate);

    progressMap = {...progressMap, word.id: updated};
    await _progressRepository.saveProgress(progressMap);

    streak = _advanceStreak(word.id, todayDate);
    await _progressRepository.saveStreak(streak);

    notifyListeners();
  }

  StreakData _advanceStreak(String wordId, DateTime todayDate) {
    if (streak.lastCompletedDate != null &&
        isSameDay(streak.lastCompletedDate!, todayDate)) {
      return streak;
    }

    final wasYesterday = streak.lastCompletedDate != null &&
        isYesterday(streak.lastCompletedDate!, todayDate);
    final newCurrent = wasYesterday ? streak.currentStreak + 1 : 1;
    final newLongest = max(streak.longestStreak, newCurrent);

    return streak.copyWith(
      currentStreak: newCurrent,
      longestStreak: newLongest,
      lastCompletedDate: todayDate,
      lastCompletedWordId: wordId,
    );
  }

  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    final turnedOn = settings.enabled && !notificationSettings.enabled;
    if (turnedOn) {
      await _notificationService.requestExactAlarmPermission();
    }
    notificationSettings = settings;
    await _progressRepository.saveNotificationSettings(settings);
    await _applyNotificationSchedule();
    notifyListeners();
  }

  Future<void> _applyNotificationSchedule() async {
    if (notificationSettings.enabled) {
      await _notificationService.scheduleDailyReminder(
        hour: notificationSettings.hour,
        minute: notificationSettings.minute,
      );
    } else {
      await _notificationService.cancelDailyReminder();
    }
  }

  Word? _computeTodayWord(DateTime todayDate) {
    if (words.isEmpty) return null;

    for (final word in words) {
      if (!progressMap.containsKey(word.id)) return word;
    }

    final due = words.where((w) {
      final progress = progressMap[w.id];
      return progress != null && !progress.nextReviewDue.isAfter(todayDate);
    }).toList()
      ..sort(
        (a, b) => progressMap[a.id]!.nextReviewDue.compareTo(
          progressMap[b.id]!.nextReviewDue,
        ),
      );
    if (due.isNotEmpty) return due.first;

    final reviewed = words.where((w) => progressMap.containsKey(w.id)).toList()
      ..sort(
        (a, b) => progressMap[b.id]!.nextReviewDue.compareTo(
          progressMap[a.id]!.nextReviewDue,
        ),
      );
    return reviewed.isNotEmpty ? reviewed.first : words.first;
  }
}
