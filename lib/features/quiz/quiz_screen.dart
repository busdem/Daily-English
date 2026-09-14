import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/word.dart';
import '../../state/app_state.dart';

const int kQuizSeconds = 10;

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.appState, required this.word});

  final AppState appState;
  final Word word;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<String> _options;
  Timer? _timer;
  int _secondsLeft = kQuizSeconds;
  String? _selected;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _options = widget.appState.quizOptionsFor(widget.word);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        if (!_answered) _submit(null);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _submit(String? option) {
    if (_answered) return;
    _timer?.cancel();
    final correct = option != null && option == widget.word.trMeaning;
    setState(() {
      _selected = option;
      _answered = true;
    });
    widget.appState.submitTodayAnswer(correct);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hızlı Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_answered)
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '$_secondsLeft sn',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    widget.word.word,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Text(
              '"${widget.word.word}" kelimesinin Türkçe anlamı nedir?',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ..._options.map((option) => _OptionTile(
                  option: option,
                  isSelected: _selected == option,
                  isCorrect: option == widget.word.trMeaning,
                  answered: _answered,
                  onTap: () => _submit(option),
                )),
            const Spacer(),
            if (_answered)
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Devam et'),
              ),
          ],
        ),
      ),
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
