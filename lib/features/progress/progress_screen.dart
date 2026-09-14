import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final totalWords = appState.words.length;
    final learned = appState.wordsLearnedCount;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('İlerlemen', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department_rounded,
                iconColor: Colors.orange,
                value: '${appState.streak.currentStreak}',
                label: 'Güncel seri (gün)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events_rounded,
                iconColor: Colors.amber,
                value: '${appState.streak.longestStreak}',
                label: 'En uzun seri (gün)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green,
          value: '$learned / $totalWords',
          label: 'Öğrenilen kelime',
          wide: true,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.wide = false,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: wide
          ? Row(
              children: [
                Icon(icon, color: iconColor, size: 32),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: theme.textTheme.headlineSmall),
                    Text(label, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                Icon(icon, color: iconColor, size: 32),
                const SizedBox(height: 10),
                Text(value, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}
