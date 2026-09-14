import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_english_app/app.dart';
import 'package:daily_english_app/state/app_state.dart';

void main() {
  testWidgets('shows a loading indicator before AppState finishes init', (
    WidgetTester tester,
  ) async {
    final appState = AppState();

    await tester.pumpWidget(DailyEnglishApp(appState: appState));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
