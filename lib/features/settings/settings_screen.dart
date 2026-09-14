import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.appState});

  final AppState appState;

  Future<void> _pickTime(BuildContext context) async {
    final settings = appState.notificationSettings;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
    );
    if (picked == null) return;
    await appState.updateNotificationSettings(
      settings.copyWith(hour: picked.hour, minute: picked.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = appState.notificationSettings;
    final timeLabel =
        '${settings.hour.toString().padLeft(2, '0')}:${settings.minute.toString().padLeft(2, '0')}';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Ayarlar', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Günlük hatırlatma'),
          subtitle: const Text('Her gün belirlenen saatte bildirim gönder'),
          value: settings.enabled,
          onChanged: (value) => appState.updateNotificationSettings(
            settings.copyWith(enabled: value),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: settings.enabled,
          leading: const Icon(Icons.schedule_rounded),
          title: const Text('Hatırlatma saati'),
          subtitle: Text(timeLabel),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: settings.enabled ? () => _pickTime(context) : null,
        ),
      ],
    );
  }
}
