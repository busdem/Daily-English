import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_english_app/data/models/word_progress.dart';
import 'package:daily_english_app/data/repositories/word_repository.dart';
import 'package:daily_english_app/services/notification_service.dart';
import 'package:daily_english_app/state/app_state.dart';

class _NoopNotificationService extends NotificationService {
  int exactAlarmPermissionRequests = 0;

  @override
  Future<void> scheduleDailyReminder({required int hour, required int minute}) async {}

  @override
  Future<void> cancelDailyReminder() async {}

  @override
  Future<void> requestExactAlarmPermission() async {
    exactAlarmPermissionRequests++;
  }
}

DateTime _day(int offset) => DateTime(2026, 10, 20 + offset);

AppState _createAppState(
  Clock clock, [
  NotificationService? notificationService,
]) => AppState(
  notificationService: notificationService ?? _NoopNotificationService(),
  clock: clock,
);

Future<AppState> _startOn(int dayOffset) async {
  final appState = _createAppState(() => _day(dayOffset));
  await appState.init();
  return appState;
}

void _seedProgress(Map<String, DateTime> dueDates) {
  final encoded = dueDates.map(
    (id, due) => MapEntry(
      id,
      WordProgress(
        wordId: id,
        nextReviewDue: due,
        reviewIntervalDays: 1,
        correctCount: 1,
        incorrectCount: 0,
      ).toJson(),
    ),
  );
  SharedPreferences.setMockInitialValues({
    'word_progress_map': jsonEncode(encoded),
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('first day: the first word is new, there are no reviews, learning it completes the day', () async {
    final appState = await _startOn(0);

    expect(appState.todayNewWord!.id, 'w_0001');
    expect(appState.pendingReviewWords, isEmpty);
    expect(appState.isTodayCompleted, isFalse);

    await appState.markNewWordLearned();

    final progress = appState.progressMap['w_0001']!;
    expect(progress.reviewIntervalDays, 1);
    expect(progress.nextReviewDue, _day(1), reason: 'first review is tomorrow');
    expect(progress.correctCount, 0);
    expect(progress.incorrectCount, 0);

    expect(appState.isNewWordLearned, isTrue);
    expect(appState.isTodayCompleted, isTrue);
    expect(appState.streak.currentStreak, 1);
    expect(appState.streak.longestStreak, 1);
    expect(appState.wordsLearnedCount, 1);
    expect(appState.todayNewWord!.id, 'w_0001',
        reason: 'the card must not flip to the next word after learning');
  });

  test('second day: yesterday\'s word comes back as a review and a correct answer doubles its interval', () async {
    await (await _startOn(0)).markNewWordLearned();

    final appState = await _startOn(1);
    expect(appState.todayNewWord!.id, 'w_0002');
    expect(appState.pendingReviewWords.map((w) => w.id), ['w_0001']);
    expect(appState.isTodayCompleted, isFalse);
    expect(appState.streak.currentStreak, 1);

    await appState.submitReviewAnswer(appState.pendingReviewWords.first, true);

    final progress = appState.progressMap['w_0001']!;
    expect(progress.correctCount, 1);
    expect(progress.incorrectCount, 0);
    expect(progress.reviewIntervalDays, 2);
    expect(progress.nextReviewDue, _day(3));
    expect(appState.pendingReviewWords, isEmpty);
    expect(appState.isTodayCompleted, isFalse,
        reason: 'the new word is still not learned');

    await appState.markNewWordLearned();
    expect(appState.isTodayCompleted, isTrue);
    expect(appState.streak.currentStreak, 2);
    expect(appState.streak.longestStreak, 2);
  });

  test('an incorrect review answer resets the interval to one day', () async {
    await (await _startOn(0)).markNewWordLearned();

    final appState = await _startOn(1);
    await appState.submitReviewAnswer(appState.pendingReviewWords.first, false);

    final progress = appState.progressMap['w_0001']!;
    expect(progress.correctCount, 0);
    expect(progress.incorrectCount, 1);
    expect(progress.reviewIntervalDays, 1);
    expect(progress.nextReviewDue, _day(2));
  });

  test('daily reviews are capped and the most overdue words come first', () async {
    _seedProgress({
      'w_0001': _day(-1),
      'w_0002': _day(-2),
      'w_0003': _day(-3),
      'w_0004': _day(-4),
      'w_0005': _day(-5),
    });

    final appState = await _startOn(0);

    expect(kMaxDailyReviews, 3);
    expect(appState.pendingReviewWords.map((w) => w.id), [
      'w_0005',
      'w_0004',
      'w_0003',
    ]);
    expect(appState.reviewTotalToday, 3);
    expect(appState.todayNewWord!.id, 'w_0006');
  });

  test('a missed day breaks the streak but keeps the longest one', () async {
    await (await _startOn(0)).markNewWordLearned();

    final dayOne = await _startOn(1);
    await dayOne.submitReviewAnswer(dayOne.pendingReviewWords.first, true);
    await dayOne.markNewWordLearned();
    expect(dayOne.streak.currentStreak, 2);

    final dayThree = await _startOn(3);
    expect(dayThree.pendingReviewWords.map((w) => w.id), ['w_0002', 'w_0001']);
    for (final word in dayThree.pendingReviewWords) {
      await dayThree.submitReviewAnswer(word, true);
    }
    await dayThree.markNewWordLearned();

    expect(dayThree.isTodayCompleted, isTrue);
    expect(dayThree.streak.currentStreak, 1);
    expect(dayThree.streak.longestStreak, 2);
  });

  test('the displayed streak drops to zero once a day is missed but stays alive until then', () async {
    await (await _startOn(0)).markNewWordLearned();

    final dayOne = await _startOn(1);
    await dayOne.submitReviewAnswer(dayOne.pendingReviewWords.first, true);
    await dayOne.markNewWordLearned();
    expect(dayOne.activeStreak, 2);

    final dayTwo = await _startOn(2);
    expect(dayTwo.activeStreak, 2,
        reason: 'yesterday was completed, so today can still extend the streak');

    final dayThree = await _startOn(3);
    expect(dayThree.activeStreak, 0);
    expect(dayThree.streak.longestStreak, 2);
  });

  test('a fresh install has no streak', () async {
    final appState = await _startOn(0);
    expect(appState.activeStreak, 0);
  });

  test('answers for words outside today\'s queue or repeated answers are ignored', () async {
    await (await _startOn(0)).markNewWordLearned();

    final appState = await _startOn(1);
    final due = appState.pendingReviewWords.first;

    await appState.submitReviewAnswer(appState.words[10], true);
    expect(appState.progressMap.containsKey(appState.words[10].id), isFalse);

    await appState.submitReviewAnswer(due, true);
    await appState.submitReviewAnswer(due, false);

    final progress = appState.progressMap[due.id]!;
    expect(progress.correctCount, 1);
    expect(progress.incorrectCount, 0);
  });

  test('today\'s state survives an app restart on the same day', () async {
    await (await _startOn(0)).markNewWordLearned();

    final restarted = await _startOn(0);

    expect(restarted.todayNewWord!.id, 'w_0001');
    expect(restarted.isNewWordLearned, isTrue);
    expect(restarted.isTodayCompleted, isTrue);
    expect(restarted.streak.currentStreak, 1);
  });

  test('the day rolls over while the app stays open', () async {
    var now = _day(0);
    final appState = _createAppState(() => now);
    await appState.init();
    await appState.markNewWordLearned();

    now = _day(1);

    expect(appState.todayNewWord!.id, 'w_0002');
    expect(appState.pendingReviewWords.map((w) => w.id), ['w_0001']);
    expect(appState.isNewWordLearned, isFalse);
  });

  test('when every word has been seen and nothing is due, the day is already complete', () async {
    final words = await WordRepository().loadWords();
    _seedProgress({for (final word in words) word.id: _day(5)});

    final appState = await _startOn(0);

    expect(appState.todayNewWord, isNull);
    expect(appState.pendingReviewWords, isEmpty);
    expect(appState.isTodayCompleted, isTrue);
    expect(appState.streak.currentStreak, 1);
  });

  test('quizOptionsFor always includes the correct answer among 4 distinct options', () async {
    final appState = await _startOn(0);

    final word = appState.todayNewWord!;
    final options = appState.quizOptionsFor(word);

    expect(options.length, 4);
    expect(options.toSet().length, 4, reason: 'options must be distinct');
    expect(options, contains(word.trMeaning));
  });

  test('exact alarm permission is requested only when the reminder is turned on', () async {
    final notificationService = _NoopNotificationService();
    final appState = _createAppState(() => _day(0), notificationService);
    await appState.init();
    expect(notificationService.exactAlarmPermissionRequests, 0,
        reason: 'app start must not open the permission page');

    final settings = appState.notificationSettings;
    await appState.updateNotificationSettings(settings.copyWith(enabled: false));
    await appState.updateNotificationSettings(settings.copyWith(enabled: true));
    expect(notificationService.exactAlarmPermissionRequests, 1);

    await appState.updateNotificationSettings(settings.copyWith(hour: 8, minute: 30));
    expect(notificationService.exactAlarmPermissionRequests, 1,
        reason: 'changing the time of an enabled reminder must not ask again');
  });
}
