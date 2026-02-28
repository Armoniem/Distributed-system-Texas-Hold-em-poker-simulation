import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/theme/app_theme.dart';

class ProbabilityPage extends StatefulWidget {
  const ProbabilityPage({super.key});

  @override
  State<ProbabilityPage> createState() => _ProbabilityPageState();
}

class _ProbabilityPageState extends State<ProbabilityPage> {
  final List<String> _hole = [];
  final List<String> _community = [];
  int _numPlayers = 2;
  int _numSims = 10000;

  bool get _canRun => _hole.length == 2;

  void _run() {
    if (!_canRun) return;
    context.read<ApiProvider>().calculateProbability(
          _hole,
          _community,
          _numPlayers,
          _numSims,
        );
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiProvider>();

    return AppShell(
      currentRoute: '/probability',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              icon: Icons.analytics_rounded,
              title: 'Win Probability Calculator',
              subtitle:
                  'Monte Carlo simulation — enter 2 hole cards and 0/3/4/5 community cards',
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
                      label: 'COMMUNITY CARDS (optional — 0, 3, 4 or 5)',
                      selected: _community,
                      maxCards: 5,
                      onAdd: (c) => setState(() => _community.add(c)),
                      onRemove: (c) => setState(() => _community.remove(c)),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    // Controls
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        final twoCol = constraints.maxWidth > 600;
                        final controls = [
                          _SliderControl(
                            label: 'Number of Players',
                            value: _numPlayers.toDouble(),
                            min: 2,
                            max: 9,
                            divisions: 7,
                            displayValue: '$_numPlayers players',
                            onChanged: (v) =>
                                setState(() => _numPlayers = v.round()),
                          ),
                          _SliderControl(
                            label: 'Simulations',
                            value: _numSims.toDouble(),
                            min: 1000,
                            max: 100000,
                            divisions: 99,
                            displayValue: _formatSims(_numSims),
                            onChanged: (v) =>
                                setState(() => _numSims = v.round()),
                          ),
                        ];
                        if (twoCol) {
                          return Row(
                            children: [
                              Expanded(child: controls[0]),
                              const SizedBox(width: 24),
                              Expanded(child: controls[1]),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            controls[0],
                            const SizedBox(height: 16),
                            controls[1],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GradientButton(
                            label: 'Run Simulation',
                            icon: Icons.play_arrow_rounded,
                            onPressed: _canRun ? _run : null,
                            isLoading:
                                api.probabilityStatus == ApiStatus.loading,
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
            if (api.probabilityStatus == ApiStatus.error)
              _ErrorBanner(message: api.probabilityError ?? 'Unknown error'),
            if (api.probabilityStatus == ApiStatus.success &&
                api.probabilityResult != null)
              _ProbResult(result: api.probabilityResult!),
          ],
        ),
      ),
    );
  }

  String _formatSims(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }
}

class _SliderControl extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _SliderControl({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayValue,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}

class _ProbResult extends StatelessWidget {
  final ProbabilityResponse result;

  const _ProbResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final winPct = result.winProbability;
    final drawPct = result.drawProbability;
    final losePct = max(0.0, 100.0 - winPct - drawPct);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Simulation Results',
          icon: Icons.analytics_rounded,
        ),
        const SizedBox(height: 16),
        // Stat tiles row
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'WIN',
                value: '${winPct.toStringAsFixed(1)}%',
                color: AppColors.success,
                icon: Icons.emoji_events_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'DRAW',
                value: '${drawPct.toStringAsFixed(1)}%',
                color: AppColors.warning,
                icon: Icons.handshake_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'LOSE',
                value: '${losePct.toStringAsFixed(1)}%',
                color: AppColors.error,
                icon: Icons.sentiment_dissatisfied_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Pie chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Outcome Distribution',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: winPct,
                          color: AppColors.success,
                          title: '${winPct.toStringAsFixed(1)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          radius: 90,
                        ),
                        if (drawPct > 0.1)
                          PieChartSectionData(
                            value: drawPct,
                            color: AppColors.warning,
                            title: '${drawPct.toStringAsFixed(1)}%',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            radius: 90,
                          ),
                        PieChartSectionData(
                          value: losePct,
                          color: AppColors.error,
                          title: '${losePct.toStringAsFixed(1)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          radius: 90,
                        ),
                      ],
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Legend('Win', AppColors.success),
                    const SizedBox(width: 20),
                    _Legend('Draw', AppColors.warning),
                    const SizedBox(width: 20),
                    _Legend('Lose', AppColors.error),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Simulation stats
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'SIMULATIONS',
                value: result.simulationsRun.toString(),
                color: AppColors.info,
                icon: Icons.loop_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'WINS',
                value: result.winCount.toString(),
                color: AppColors.success,
                icon: Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'DRAWS',
                value: result.drawCount.toString(),
                color: AppColors.warning,
                icon: Icons.remove_circle_outline_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;

  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
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
