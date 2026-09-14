import 'package:flutter/material.dart';

import 'app.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  appState.init();

  runApp(DailyEnglishApp(appState: appState));
}
