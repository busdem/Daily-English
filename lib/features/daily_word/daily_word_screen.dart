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

  void _openReview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(appState: widget.appState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final theme = Theme.of(context);
    final newWord = appState.todayNewWord;
    final completed = appState.isTodayCompleted;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Bugünün görevleri',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (completed)
              const Chip(
                avatar: Icon(Icons.check_circle, size: 18),
                label: Text('Tamamlandı'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 16),
        _ReviewCard(
          total: appState.reviewTotalToday,
          done: appState.reviewDoneToday,
          onStart: _openReview,
        ),
        const SizedBox(height: 20),
        if (newWord == null)
          const _AllWordsSeenCard()
        else
          ..._newWordSection(newWord, appState.isNewWordLearned),
      ],
    );
  }

  List<Widget> _newWordSection(Word word, bool learned) {
    return [
      const Chip(
        avatar: Icon(Icons.fiber_new_rounded, size: 18),
        label: Text('Bugünün yeni kelimesi'),
        visualDensity: VisualDensity.compact,
      ),
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
        onPressed: learned ? null : widget.appState.markNewWordLearned,
        icon: Icon(learned ? Icons.check_circle : Icons.check_circle_outline),
        label: Text(learned ? 'Öğrenildi' : 'Öğrendim'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      if (learned)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Bu kelimeyi yarın tekrar edeceğiz.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ];
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.total,
    required this.done,
    required this.onStart,
  });

  final int total;
  final int done;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = total - done;

    final IconData icon;
    final String title;
    final String subtitle;
    if (total == 0) {
      icon = Icons.event_available_rounded;
      title = 'Bugün tekrar yok';
      subtitle = 'Öğrendiğin kelimeler sırası gelince burada karşına çıkar.';
    } else if (remaining == 0) {
      icon = Icons.check_circle_rounded;
      title = 'Tekrarlar tamamlandı';
      subtitle = '$total kelime tekrar edildi.';
    } else {
      icon = Icons.refresh_rounded;
      title = 'Günün tekrarları';
      subtitle = '$remaining kelime seni bekliyor.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          if (remaining > 0) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Tekrara başla'),
            ),
          ],
        ],
      ),
    );
  }
}

class _AllWordsSeenCard extends StatelessWidget {
  const _AllWordsSeenCard();

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
      child: Text(
        'Tüm kelimeleri gördün. Artık sadece tekrarlar var.',
        style: theme.textTheme.bodyMedium,
      ),
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
