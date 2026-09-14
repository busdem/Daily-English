import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/word_progress.dart';

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final String? lastCompletedWordId;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletedDate,
    required this.lastCompletedWordId,
  });

  static const empty = StreakData(
    currentStreak: 0,
    longestStreak: 0,
    lastCompletedDate: null,
    lastCompletedWordId: null,
  );

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
    String? lastCompletedWordId,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      lastCompletedWordId: lastCompletedWordId ?? this.lastCompletedWordId,
    );
  }
}

class NotificationSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const NotificationSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  static const defaults = NotificationSettings(
    enabled: true,
    hour: 19,
    minute: 0,
  );

  NotificationSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

class ProgressRepository {
  static const _progressKey = 'word_progress_map';
  static const _streakKey = 'streak_data';
  static const _notificationKey = 'notification_settings';

  Future<Map<String, WordProgress>> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_progressKey);
    if (raw == null) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        WordProgress.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  Future<void> saveProgress(Map<String, WordProgress> progress) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = progress.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await prefs.setString(_progressKey, jsonEncode(encoded));
  }

  Future<StreakData> loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_streakKey);
    if (raw == null) return StreakData.empty;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return StreakData(
      currentStreak: decoded['current_streak'] as int,
      longestStreak: decoded['longest_streak'] as int,
      lastCompletedDate: decoded['last_completed_date'] == null
          ? null
          : DateTime.parse(decoded['last_completed_date'] as String),
      lastCompletedWordId: decoded['last_completed_word_id'] as String?,
    );
  }

  Future<void> saveStreak(StreakData streak) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = {
      'current_streak': streak.currentStreak,
      'longest_streak': streak.longestStreak,
      'last_completed_date': streak.lastCompletedDate
          ?.toIso8601String()
          .split('T')
          .first,
      'last_completed_word_id': streak.lastCompletedWordId,
    };
    await prefs.setString(_streakKey, jsonEncode(encoded));
  }

  Future<NotificationSettings> loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notificationKey);
    if (raw == null) return NotificationSettings.defaults;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return NotificationSettings(
      enabled: decoded['enabled'] as bool,
      hour: decoded['hour'] as int,
      minute: decoded['minute'] as int,
    );
  }

  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notificationKey,
      jsonEncode({
        'enabled': settings.enabled,
        'hour': settings.hour,
        'minute': settings.minute,
      }),
    );
  }
}
