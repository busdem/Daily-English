import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_english_app/data/models/word_progress.dart';
import 'package:daily_english_app/features/quiz/quiz_screen.dart';
import 'package:daily_english_app/services/notification_service.dart';
import 'package:daily_english_app/state/app_state.dart';

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> scheduleDailyReminder({required int hour, required int minute}) async {}

  @override
  Future<void> cancelDailyReminder() async {}
}

final _today = DateTime(2026, 10, 20);

Future<AppState> _appStateWithOneDueWord(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'word_progress_map': jsonEncode({
      'w_0001': WordProgress(
        wordId: 'w_0001',
        nextReviewDue: DateTime(2026, 10, 19),
        reviewIntervalDays: 1,
        correctCount: 0,
        incorrectCount: 0,
      ).toJson(),
    }),
  });
  final appState = AppState(
    notificationService: _NoopNotificationService(),
    clock: () => _today,
  );
  await tester.runAsync(appState.init);
  return appState;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a correct answer is recorded and the summary is shown', (tester) async {
    final appState = await _appStateWithOneDueWord(tester);
    final word = appState.pendingReviewWords.single;

    await tester.pumpWidget(MaterialApp(home: QuizScreen(appState: appState)));
    expect(find.text('Tekrar · 1/1'), findsOneWidget);
    expect(find.text(word.word), findsOneWidget);

    await tester.tap(find.text(word.trMeaning));
    await tester.pump();

    final progress = appState.progressMap[word.id]!;
    expect(progress.correctCount, 1);
    expect(progress.incorrectCount, 0);

    await tester.tap(find.text('Bitir'));
    await tester.pump();

    expect(find.text('Tekrarlar tamamlandı'), findsOneWidget);
    expect(find.text('1 / 1 doğru'), findsOneWidget);
  });

  testWidgets('a wrong answer counts as incorrect', (tester) async {
    final appState = await _appStateWithOneDueWord(tester);
    final word = appState.pendingReviewWords.single;
    final wrongOption =
        appState.quizOptionsFor(word).firstWhere((o) => o != word.trMeaning);

    await tester.pumpWidget(MaterialApp(home: QuizScreen(appState: appState)));
    await tester.tap(find.text(wrongOption));
    await tester.pump();

    final progress = appState.progressMap[word.id]!;
    expect(progress.correctCount, 0);
    expect(progress.incorrectCount, 1);
    expect(progress.reviewIntervalDays, 1);

    await tester.tap(find.text('Bitir'));
    await tester.pump();
    expect(find.text('0 / 1 doğru'), findsOneWidget);
  });

  testWidgets('running out of time counts as incorrect', (tester) async {
    final appState = await _appStateWithOneDueWord(tester);
    final word = appState.pendingReviewWords.single;

    await tester.pumpWidget(MaterialApp(home: QuizScreen(appState: appState)));
    await tester.pump(const Duration(seconds: kQuizSeconds));

    final progress = appState.progressMap[word.id]!;
    expect(progress.correctCount, 0);
    expect(progress.incorrectCount, 1);
    expect(find.text('Bitir'), findsOneWidget);
  });
}
