import 'package:flutter/material.dart';

import '../../data/models/word.dart';
import '../../services/tts_service.dart';
import '../../state/app_state.dart';
import '../quiz/quiz_screen.dart';

class DailyWordScreen extends StatefulWidget {
  const DailyWordScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<DailyWordScreen> createState() => _DailyWordScreenState();
}

class _DailyWordScreenState extends State<DailyWordScreen> {
  final TtsService _tts = TtsService();

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.appState.todayWord;
    if (word == null) {
      return const Center(child: Text('Kelime listesi yüklenemedi.'));
    }

    final kind = widget.appState.todayWordKindForToday();
    final completed = widget.appState.isTodayCompleted;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _KindBadge(kind: kind, completed: completed),
        const SizedBox(height: 12),
        _WordCard(word: word, onSpeak: () => _tts.speak(word.word)),
        const SizedBox(height: 16),
        _ExampleSection(
          title: 'Örnek cümle',
          content: word.exampleNeutral,
        ),
        const SizedBox(height: 12),
        _ExampleSection(
          title: 'Sık yapılan hata',
          content: word.exampleMistakeNote,
          icon: Icons.warning_amber_rounded,
        ),
        const SizedBox(height: 12),
        _ExampleSection(
          title: 'Türkçe nüans',
          content: word.trNuance,
          icon: Icons.translate_rounded,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: completed
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuizScreen(
                        appState: widget.appState,
                        word: word,
                      ),
                    ),
                  ),
          icon: Icon(completed ? Icons.check_circle : Icons.quiz_outlined),
          label: Text(completed ? 'Bugün tamamlandı' : 'Kısa quize başla'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind, required this.completed});

  final TodayWordKind kind;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    switch (kind) {
      case TodayWordKind.newWord:
        label = 'Bugünün yeni kelimesi';
        icon = Icons.fiber_new_rounded;
        break;
      case TodayWordKind.dueReview:
        label = 'Tekrar zamanı geldi';
        icon = Icons.refresh_rounded;
        break;
      case TodayWordKind.practice:
        label = 'Serbest pratik';
        icon = Icons.self_improvement_rounded;
        break;
    }
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(completed ? '$label · tamamlandı' : label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({required this.word, required this.onSpeak});

  final Word word;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    word.word,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up_rounded),
                  tooltip: 'Telaffuzu dinle',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(word.ipa, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(word.cefrLevel),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(word.partOfSpeech),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleSection extends StatelessWidget {
  const _ExampleSection({
    required this.title,
    required this.content,
    this.icon,
  });

  final String title;
  final String content;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(content, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
