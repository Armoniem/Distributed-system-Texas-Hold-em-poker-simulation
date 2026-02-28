import 'package:flutter/material.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context),
            const SizedBox(height: 32),
            _buildFeatureGrid(context),
            const SizedBox(height: 32),
            _buildQuickStart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkCard, AppColors.darkSurface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text(
                  '♠♥♦♣',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PokerEval',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                    ),
                    Text(
                      'Enterprise Texas Hold\'em Analyzer',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.darkTextSub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Evaluate hands, compare players, and calculate win probabilities '
            'using a high-performance Go backend with Monte Carlo simulation — '
            'deployed on Google Kubernetes Engine.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.darkTextSub,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _buildBadge('Go + gRPC', Icons.speed_rounded, AppColors.accent),
              const SizedBox(width: 12),
              _buildBadge(
                'Monte Carlo',
                Icons.casino_rounded,
                AppColors.warning,
              ),
              const SizedBox(width: 12),
              _buildBadge('GKE Deployed', Icons.cloud_rounded, AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final cards = [
      _DashCard(
        icon: Icons.style_rounded,
        title: 'Hand Evaluator',
        description:
            'Find the best 5-card hand from 7 cards with hand category and strength score.',
        color: AppColors.primary,
        route: '/evaluate',
      ),
      _DashCard(
        icon: Icons.compare_arrows_rounded,
        title: 'Hand Comparator',
        description:
            'Compare two full player hands head-to-head to see who wins or if it\'s a draw.',
        color: AppColors.accent,
        route: '/compare',
      ),
      _DashCard(
        icon: Icons.analytics_rounded,
        title: 'Win Probability',
        description:
            'Run thousands of Monte Carlo simulations to estimate your win/draw odds.',
        color: AppColors.warning,
        route: '/probability',
      ),
      _DashCard(
        icon: Icons.monitor_heart_rounded,
        title: 'System Status',
        description:
            'Check backend health, API latency, and service connectivity.',
        color: AppColors.info,
        route: '/health',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Features',
          subtitle: 'What PokerEval can do for you',
          icon: Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final cols = constraints.maxWidth > 800 ? 2 : 1;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: constraints.maxWidth > 800 ? 2.2 : 3.0,
              children: cards.map((c) => _FeatureCard(data: c)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickStart(BuildContext context) {
    final examples = [
      _Example(
        title: 'Royal Flush',
        cards: 'HA HK ─ HQ HJ HT D2 C3',
        description: 'Ace-King on a royal board → Royal Flush',
      ),
      _Example(
        title: 'Pocket Aces Pre-Flop',
        cards: 'HA SA (no community)',
        description: '~85% win probability heads-up',
      ),
      _Example(
        title: 'Straight Draw',
        cards: 'H7 H8 ─ H9 HT D2 ...',
        description: 'Evaluate open-ended straight draw equity',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Card Format',
          subtitle: 'SUIT + RANK — two characters per card',
          icon: Icons.help_outline_rounded,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _suitChip('H♥', AppColors.hearts),
                    const SizedBox(width: 8),
                    _suitChip('D♦', AppColors.diamonds),
                    const SizedBox(width: 8),
                    _suitChip(
                      'S♠',
                      AppColors.spades.withValues(alpha: 0.1),
                      textColor: AppColors.darkText,
                    ),
                    const SizedBox(width: 8),
                    _suitChip(
                      'C♣',
                      AppColors.clubs.withValues(alpha: 0.1),
                      textColor: AppColors.darkText,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    'HA',
                    'SK',
                    'DT',
                    'CJ',
                    'H2',
                    'S9',
                    'DA',
                    'CT',
                  ].map((c) => CardChip(card: c, compact: true)).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ranks: 2–9, T=10, J=Jack, Q=Queen, K=King, A=Ace',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...examples.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.casino_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            e.cards,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            e.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _suitChip(String label, Color bg, {Color? textColor}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: textColor ?? Colors.white,
        fontSize: 14,
      ),
    ),
  );
}

class _DashCard {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String route;

  const _DashCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.route,
  });
}

class _FeatureCard extends StatefulWidget {
  final _DashCard data;
  const _FeatureCard({required this.data});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () =>
            Navigator.of(context).pushReplacementNamed(widget.data.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.data.color.withValues(alpha: 0.12)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? widget.data.color.withValues(alpha: 0.5)
                  : Theme.of(context).dividerColor,
              width: _hovered ? 2 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.data.color.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.data.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.data.icon,
                  color: widget.data.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.data.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.data.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: _hovered ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: widget.data.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Example {
  final String title;
  final String cards;
  final String description;

  const _Example({
    required this.title,
    required this.cards,
    required this.description,
  });
}
