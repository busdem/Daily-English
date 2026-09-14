import 'package:flutter/material.dart';

import 'features/daily_word/daily_word_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/settings/settings_screen.dart';
import 'state/app_state.dart';

const Color kSeedColor = Color(0xFF2F6F4F);
const Color kScaffoldBackground = Color(0xFFF7F5EF);

class DailyEnglishApp extends StatelessWidget {
  const DailyEnglishApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Daily English',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: kSeedColor,
            scaffoldBackgroundColor: kScaffoldBackground,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: kSeedColor,
            brightness: Brightness.dark,
          ),
          home: appState.isLoading
              ? const _LoadingScreen()
              : HomeShell(appState: appState),
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.appState});

  final AppState appState;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DailyWordScreen(appState: widget.appState),
      ProgressScreen(appState: widget.appState),
      SettingsScreen(appState: widget.appState),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Bugün',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'İlerleme',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
