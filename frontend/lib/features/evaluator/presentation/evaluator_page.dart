import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/theme/app_theme.dart';

class EvaluatorPage extends StatefulWidget {
  const EvaluatorPage({super.key});

  @override
  State<EvaluatorPage> createState() => _EvaluatorPageState();
}

class _EvaluatorPageState extends State<EvaluatorPage> {
  final List<String> _hole = [];
  final List<String> _community = [];

  void _evaluate() {
    if (_hole.length != 2 || _community.length != 5) return;
    context.read<ApiProvider>().evaluateHand(_hole, _community);
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiProvider>();
    final canEval = _hole.length == 2 && _community.length == 5;

    return AppShell(
      currentRoute: '/evaluate',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              icon: Icons.style_rounded,
              title: 'Hand Evaluator',
              subtitle:
                  'Enter 2 hole cards + 5 community cards to find the best 5-card hand',
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardPickerWidget(
                      label: 'YOUR HOLE CARDS',
                      selected: _hole,
                      maxCards: 2,
                      onAdd: (c) => setState(() => _hole.add(c)),
                      onRemove: (c) => setState(() => _hole.remove(c)),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    CardPickerWidget(
                      label: 'COMMUNITY CARDS (0, 3, 4, or 5)',
                      selected: _community,
                      maxCards: 5,
                      onAdd: (c) => setState(() => _community.add(c)),
                      onRemove: (c) => setState(() => _community.remove(c)),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: GradientButton(
                            label: 'Evaluate Hand',
                            icon: Icons.auto_awesome_rounded,
                            onPressed: canEval ? _evaluate : null,
                            isLoading: api.evaluateStatus == ApiStatus.loading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Clear',
                          onPressed: () => setState(() {
                            _hole.clear();
                            _community.clear();
                          }),
                          style: IconButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (api.evaluateStatus == ApiStatus.error)
              _ErrorBanner(message: api.evaluateError ?? 'Unknown error'),
            if (api.evaluateStatus == ApiStatus.success &&
                api.evaluateResult != null)
              _EvalResult(result: api.evaluateResult!),
          ],
        ),
      ),
    );
  }
}

class _EvalResult extends StatelessWidget {
  final EvaluateHandResponse result;

  const _EvalResult({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Result', icon: Icons.emoji_events_rounded),
        const SizedBox(height: 16),
        HandResultCard(
          category: result.category,
          bestHand: result.bestHand,
          strength: result.strength,
          highlight: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'HAND',
                value: result.category,
                color: AppColors.primary,
                icon: Icons.style_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: 'STRENGTH',
                value: result.strength.toString(),
                color: AppColors.accent,
                icon: Icons.bar_chart_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
