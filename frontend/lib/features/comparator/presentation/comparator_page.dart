import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/theme/app_theme.dart';

// ─── Comparator Page ─────────────────────────────────────────────────────────

class ComparatorPage extends StatefulWidget {
  const ComparatorPage({super.key});

  @override
  State<ComparatorPage> createState() => _ComparatorPageState();
}

class _ComparatorPageState extends State<ComparatorPage> {
  final List<String> _hole1 = [];
  final List<String> _hole2 = [];
  final List<String> _community = []; // shared by both players

  bool get _canCompare =>
      _hole1.length == 2 && _hole2.length == 2 && _community.length == 5;

  void _compare() {
    if (!_canCompare) return;
    // Both players share the same community cards
    context.read<ApiProvider>().compareHands(
          _hole1,
          _community,
          _hole2,
          _community,
        );
  }

  void _clear() => setState(() {
        _hole1.clear();
        _hole2.clear();
        _community.clear();
      });

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiProvider>();

    return AppShell(
      currentRoute: '/compare',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.compare_arrows_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hand Comparator',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Both players share the same 5 community cards',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Clear all',
                  onPressed: _clear,
                  style: IconButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Shared Community Cards ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'SHARED COMMUNITY CARDS  (exactly 5)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _community.length == 5
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_community.length}/5',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: _community.length == 5
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CardPickerWidget(
                      label: 'Pick a card and press Add',
                      selected: _community,
                      maxCards: 5,
                      onAdd: (c) => setState(() => _community.add(c)),
                      onRemove: (c) => setState(() => _community.remove(c)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Player Hole Cards Side by Side ──
            LayoutBuilder(
              builder: (ctx, constraints) {
                final twoCol = constraints.maxWidth > 640;
                final p1 = _PlayerHoleCard(
                  number: 1,
                  hole: _hole1,
                  onAdd: (c) => setState(() => _hole1.add(c)),
                  onRemove: (c) => setState(() => _hole1.remove(c)),
                );
                final p2 = _PlayerHoleCard(
                  number: 2,
                  hole: _hole2,
                  onAdd: (c) => setState(() => _hole2.add(c)),
                  onRemove: (c) => setState(() => _hole2.remove(c)),
                );
                if (twoCol) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: p1),
                      const SizedBox(width: 16),
                      Expanded(child: p2),
                    ],
                  );
                }
                return Column(children: [
                  p1,
                  const SizedBox(height: 12),
                  p2,
                ]);
              },
            ),
            const SizedBox(height: 20),

            // ── Compare Button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _canCompare ? _compare : null,
                icon: api.compareStatus == ApiStatus.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.compare_arrows_rounded),
                label: Text(
                  _canCompare
                      ? 'Compare Hands'
                      : 'Add 2 hole cards per player + 5 community cards',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Results ──
            if (api.compareStatus == ApiStatus.error)
              _ErrorBanner(message: api.compareError ?? 'Unknown error'),
            if (api.compareStatus == ApiStatus.success &&
                api.compareResult != null)
              _CompareResult(result: api.compareResult!),
          ],
        ),
      ),
    );
  }
}

// ─── Player hole card picker ──────────────────────────────────────────────────

class _PlayerHoleCard extends StatelessWidget {
  final int number;
  final List<String> hole;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  const _PlayerHoleCard({
    required this.number,
    required this.hole,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = number == 1 ? AppColors.primary : AppColors.accent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.6)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Player $number Hole Cards',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hole.length == 2
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${hole.length}/2',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: hole.length == 2
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CardPickerWidget(
              label: 'Hole cards (exactly 2)',
              selected: hole,
              maxCards: 2,
              onAdd: onAdd,
              onRemove: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Result widgets ───────────────────────────────────────────────────────────

class _CompareResult extends StatelessWidget {
  final CompareHandsResponse result;
  const _CompareResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final isDraw = result.winner == 'draw';
    final winnerLabel = isDraw
        ? '🤝 Split Pot — Draw!'
        : '🏆 ${result.winner == "player1" ? "Player 1" : "Player 2"} Wins!';
    final bannerColor = isDraw ? AppColors.warning : AppColors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Winner banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                bannerColor.withValues(alpha: 0.2),
                bannerColor.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: bannerColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              winnerLabel,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: bannerColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Hand result cards
        LayoutBuilder(
          builder: (ctx, constraints) {
            final twoCol = constraints.maxWidth > 600;
            final cards = [
              _HandCard(
                label: 'PLAYER 1',
                category: result.hand1.category,
                bestHand: result.hand1.bestHand,
                winner: result.winner == 'player1',
                color: AppColors.primary,
              ),
              _HandCard(
                label: 'PLAYER 2',
                category: result.hand2.category,
                bestHand: result.hand2.bestHand,
                winner: result.winner == 'player2',
                color: AppColors.accent,
              ),
            ];
            if (twoCol) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                ],
              );
            }
            return Column(
                children: [cards[0], const SizedBox(height: 12), cards[1]]);
          },
        ),
      ],
    );
  }
}

class _HandCard extends StatelessWidget {
  final String label;
  final String category;
  final List<String> bestHand;
  final bool winner;
  final Color color;

  const _HandCard({
    required this.label,
    required this.category,
    required this.bestHand,
    required this.winner,
    required this.color,
  });

  String _suitSymbol(String c) {
    switch (c[0]) {
      case 'H':
        return '♥';
      case 'D':
        return '♦';
      case 'S':
        return '♠';
      case 'C':
        return '♣';
      default:
        return c[0];
    }
  }

  Color _suitColor(String c) =>
      (c[0] == 'H' || c[0] == 'D') ? AppColors.hearts : AppColors.spades;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: winner
              ? [
                  AppColors.accent.withValues(alpha: 0.15),
                  AppColors.accent.withValues(alpha: 0.03),
                ]
              : [
                  theme.cardTheme.color ?? Colors.transparent,
                  theme.cardTheme.color ?? Colors.transparent,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: winner
              ? AppColors.accent.withValues(alpha: 0.6)
              : theme.dividerColor,
          width: winner ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1.0,
                  color: color,
                ),
              ),
              const Spacer(),
              if (winner) const Text('🏆', style: TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: bestHand.map((c) {
              final sym = _suitSymbol(c);
              final rank = c.substring(1);
              final col = _suitColor(c);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: col.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: col.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$sym$rank',
                  style: TextStyle(
                    color: col,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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
