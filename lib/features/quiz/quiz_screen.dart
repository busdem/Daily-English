import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/word.dart';
import '../../state/app_state.dart';

const int kQuizSeconds = 10;

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<Word> _queue;
  List<String> _options = const [];
  Timer? _timer;
  int _index = 0;
  int _secondsLeft = kQuizSeconds;
  int _correctCount = 0;
  String? _selected;
  bool _answered = false;

  Word get _word => _queue[_index];
  bool get _finished => _index >= _queue.length;

  @override
  void initState() {
    super.initState();
    _queue = widget.appState.pendingReviewWords;
    if (!_finished) _startQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startQuestion() {
    _timer?.cancel();
    _options = widget.appState.quizOptionsFor(_word);
    _secondsLeft = kQuizSeconds;
    _selected = null;
    _answered = false;
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (!mounted) return;
    setState(() => _secondsLeft--);
    if (_secondsLeft <= 0) _submit(null);
  }

  void _submit(String? option) {
    if (_answered) return;
    _timer?.cancel();
    final correct = option != null && option == _word.trMeaning;
    setState(() {
      _selected = option;
      _answered = true;
      if (correct) _correctCount++;
    });
    widget.appState.submitReviewAnswer(_word, correct);
  }

  void _next() {
    setState(() {
      _index++;
      if (_finished) {
        _timer?.cancel();
      } else {
        _startQuestion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _finished ? 'Tekrar özeti' : 'Tekrar · ${_index + 1}/${_queue.length}',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _finished ? _buildSummary(context) : _buildQuestion(context),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _index + 1 >= _queue.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 28,
          child: _answered
              ? null
              : Row(
                  children: [
                    Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('$_secondsLeft sn', style: theme.textTheme.titleMedium),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        Text(
          _word.word,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text('Türkçe anlamı nedir?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 24),
        ..._options.map(
          (option) => _OptionTile(
            option: option,
            isSelected: _selected == option,
            isCorrect: option == _word.trMeaning,
            answered: _answered,
            onTap: () => _submit(option),
          ),
        ),
        const Spacer(),
        if (_answered)
          FilledButton(
            onPressed: _next,
            child: Text(isLast ? 'Bitir' : 'Sonraki'),
          ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final theme = Theme.of(context);
    final dayDone = widget.appState.isTodayCompleted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Icon(
          Icons.emoji_events_rounded,
          size: 72,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Tekrarlar tamamlandı',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          '$_correctCount / ${_queue.length} doğru',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Text(
          dayDone
              ? 'Günün görevi tamam, serin devam ediyor.'
              : 'Bugünün yeni kelimesini öğrenmeyi unutma.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.isCorrect,
    required this.answered,
    required this.onTap,
  });

  final String option;
  final bool isSelected;
  final bool isCorrect;
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color? background;
    Color? borderColor;
    if (answered) {
      if (isCorrect) {
        background = Colors.green.withValues(alpha: 0.15);
        borderColor = Colors.green;
      } else if (isSelected) {
        background = Colors.red.withValues(alpha: 0.15);
        borderColor = Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: answered ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: background ??
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor ?? Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(child: Text(option, style: theme.textTheme.bodyLarge)),
              if (answered && isCorrect)
                const Icon(Icons.check_circle, color: Colors.green),
              if (answered && isSelected && !isCorrect)
                const Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}
