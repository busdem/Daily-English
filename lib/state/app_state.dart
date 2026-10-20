import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/utils/date_utils.dart';
import '../data/models/daily_state.dart';
import '../data/models/word.dart';
import '../data/models/word_progress.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/word_repository.dart';
import '../services/notification_service.dart';
import '../services/spaced_repetition_service.dart';

const int kMaxDailyReviews = 3;

typedef Clock = DateTime Function();

class AppState extends ChangeNotifier {
  AppState({
    WordRepository? wordRepository,
    ProgressRepository? progressRepository,
    NotificationService? notificationService,
    Clock? clock,
  }) : _wordRepository = wordRepository ?? WordRepository(),
       _progressRepository = progressRepository ?? ProgressRepository(),
       _notificationService = notificationService ?? NotificationService(),
       _clock = clock ?? DateTime.now;

  final WordRepository _wordRepository;
  final ProgressRepository _progressRepository;
  final NotificationService _notificationService;
  final Clock _clock;

  bool isLoading = true;
  List<Word> words = [];
  Map<String, WordProgress> progressMap = {};
  StreakData streak = StreakData.empty;
  NotificationSettings notificationSettings = NotificationSettings.defaults;

  Map<String, Word> _wordsById = {};
  DailyState? _daily;

  DateTime get _today => dateOnly(_clock());

  Future<void> init() async {
    words = await _wordRepository.loadWords();
    _wordsById = {for (final word in words) word.id: word};
    progressMap = await _progressRepository.loadProgress();
    streak = await _progressRepository.loadStreak();
    notificationSettings = await _progressRepository.loadNotificationSettings();
    _daily = await _progressRepository.loadDailyState();
    _currentDaily();
    await _completeDayIfDone();
    await _applyNotificationSchedule();
    isLoading = false;
    notifyListeners();
  }

  Word? get todayNewWord {
    final id = _currentDaily().newWordId;
    return id == null ? null : _wordsById[id];
  }

  bool get isNewWordLearned => _currentDaily().newWordLearned;

  List<Word> get pendingReviewWords {
    final daily = _currentDaily();
    return [
      for (final id in daily.reviewQueueIds)
        if (!daily.reviewedIds.contains(id)) _wordsById[id]!,
    ];
  }

  int get reviewTotalToday => _currentDaily().reviewQueueIds.length;

  int get reviewDoneToday => _currentDaily().reviewedIds.length;

  bool get isTodayCompleted {
    final daily = _currentDaily();
    final newWordDone = daily.newWordId == null || daily.newWordLearned;
    return newWordDone && daily.reviewedIds.length >= daily.reviewQueueIds.length;
  }

  int get wordsLearnedCount => progressMap.length;

  List<String> quizOptionsFor(Word word) {
    final others = words.where((w) => w.id != word.id).toList()
      ..shuffle(Random(word.id.hashCode));
    final distractors = others.take(3).map((w) => w.trMeaning).toList();
    final options = [word.trMeaning, ...distractors];
    options.shuffle(Random(word.id.hashCode ^ _today.day));
    return options;
  }

  Future<void> markNewWordLearned() async {
    final daily = _currentDaily();
    final id = daily.newWordId;
    if (id == null || daily.newWordLearned) return;

    progressMap = {...progressMap, id: WordProgress.initial(id, _today)};
    _daily = daily.copyWith(newWordLearned: true);

    await _progressRepository.saveProgress(progressMap);
    await _progressRepository.saveDailyState(_daily!);
    await _completeDayIfDone();
    notifyListeners();
  }

  Future<void> submitReviewAnswer(Word word, bool correct) async {
    final daily = _currentDaily();
    final existing = progressMap[word.id];
    if (existing == null ||
        !daily.reviewQueueIds.contains(word.id) ||
        daily.reviewedIds.contains(word.id)) {
      return;
    }

    final todayDate = _today;
    final updated = correct
        ? applyCorrectAnswer(existing, todayDate)
        : applyIncorrectAnswer(existing, todayDate);

    progressMap = {...progressMap, word.id: updated};
    _daily = daily.copyWith(reviewedIds: [...daily.reviewedIds, word.id]);

    await _progressRepository.saveProgress(progressMap);
    await _progressRepository.saveDailyState(_daily!);
    await _completeDayIfDone();
    notifyListeners();
  }

  DailyState _currentDaily() {
    final todayDate = _today;
    final existing = _daily;
    if (existing != null && isSameDay(existing.date, todayDate)) {
      return existing;
    }
    final built = _buildDailyState(todayDate);
    _daily = built;
    unawaited(_progressRepository.saveDailyState(built));
    return built;
  }

  DailyState _buildDailyState(DateTime todayDate) {
    String? newWordId;
    for (final word in words) {
      if (!progressMap.containsKey(word.id)) {
        newWordId = word.id;
        break;
      }
    }

    final due = progressMap.values
        .where(
          (p) =>
              _wordsById.containsKey(p.wordId) &&
              !p.nextReviewDue.isAfter(todayDate),
        )
        .toList()
      ..sort((a, b) {
        final byDate = a.nextReviewDue.compareTo(b.nextReviewDue);
        return byDate != 0 ? byDate : a.wordId.compareTo(b.wordId);
      });

    return DailyState(
      date: todayDate,
      newWordId: newWordId,
      newWordLearned: false,
      reviewQueueIds: due.take(kMaxDailyReviews).map((p) => p.wordId).toList(),
      reviewedIds: const [],
    );
  }

  Future<void> _completeDayIfDone() async {
    if (!isTodayCompleted) return;

    final todayDate = _today;
    final last = streak.lastCompletedDate;
    if (last != null && isSameDay(last, todayDate)) return;

    final continues = last != null && isYesterday(last, todayDate);
    final newCurrent = continues ? streak.currentStreak + 1 : 1;
    streak = streak.copyWith(
      currentStreak: newCurrent,
      longestStreak: max(streak.longestStreak, newCurrent),
      lastCompletedDate: todayDate,
    );
    await _progressRepository.saveStreak(streak);
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
}
