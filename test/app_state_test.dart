import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

AppState _createAppState([NotificationService? notificationService]) =>
    AppState(notificationService: notificationService ?? _NoopNotificationService());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a correct answer increments correctCount and does not touch incorrectCount', () async {
    final appState = _createAppState();
    await appState.init();

    final word = appState.todayWord;
    expect(word, isNotNull);

    await appState.submitTodayAnswer(true);

    final progress = appState.progressMap[word!.id];
    expect(progress, isNotNull);
    expect(progress!.correctCount, 1);
    expect(progress.incorrectCount, 0);
    expect(appState.wordsLearnedCount, 1);
  });

  test('an incorrect answer increments incorrectCount and resets the interval', () async {
    final appState = _createAppState();
    await appState.init();

    final word = appState.todayWord;
    expect(word, isNotNull);

    await appState.submitTodayAnswer(false);

    final progress = appState.progressMap[word!.id];
    expect(progress, isNotNull);
    expect(progress!.correctCount, 0);
    expect(progress.incorrectCount, 1);
    expect(progress.reviewIntervalDays, 1);
    expect(appState.wordsLearnedCount, 0);
  });

  test('quizOptionsFor always includes the correct answer among 4 distinct options', () async {
    final appState = _createAppState();
    await appState.init();

    final word = appState.todayWord!;
    final options = appState.quizOptionsFor(word);

    expect(options.length, 4);
    expect(options.toSet().length, 4, reason: 'options must be distinct');
    expect(options, contains(word.trMeaning));
  });

  test('exact alarm permission is requested only when the reminder is turned on', () async {
    final notificationService = _NoopNotificationService();
    final appState = _createAppState(notificationService);
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
