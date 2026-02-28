import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Card Picker (Suit + Rank Dropdowns) ─────────────────────────────────────

/// A card picker using two dropdowns (suit + rank) with an Add button.
/// Much easier to use than free-text input.
class CardPickerWidget extends StatefulWidget {
  final List<String> selected;
  final int maxCards;
  final String label;
  final void Function(String card) onAdd;
  final void Function(String card) onRemove;

  const CardPickerWidget({
    super.key,
    required this.selected,
    required this.maxCards,
    required this.label,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<CardPickerWidget> createState() => _CardPickerWidgetState();
}

class _CardPickerWidgetState extends State<CardPickerWidget> {
  String _suit = 'H';
  String _rank = 'A';

  static const _suits = [
    ('H', '♥ Hearts', AppColors.hearts),
    ('D', '♦ Diamonds', AppColors.hearts),
    ('S', '♠ Spades', AppColors.spades),
    ('C', '♣ Clubs', AppColors.spades),
  ];
  static const _ranks = [
    'A',
    'K',
    'Q',
    'J',
    'T',
    '9',
    '8',
    '7',
    '6',
    '5',
    '4',
    '3',
    '2',
  ];

  String get _card => '$_suit$_rank';
  bool get _alreadyAdded => widget.selected.contains(_card);
  bool get _full => widget.selected.length >= widget.maxCards;

  Color _suitColor(String s) =>
      (s == 'H' || s == 'D') ? AppColors.hearts : AppColors.spades;

  String _suitSymbol(String s) {
    switch (s) {
      case 'H':
        return '♥';
      case 'D':
        return '♦';
      case 'S':
        return '♠';
      default:
        return '♣';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + counter
        Row(
          children: [
            Text(
              widget.label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.selected.length == widget.maxCards
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.selected.length}/${widget.maxCards}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: widget.selected.length == widget.maxCards
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Suit Picker
        Row(
          children: _suits.map((s) {
            final isSelected = _suit == s.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _suit = s.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? s.$3.withValues(alpha: 0.12)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? s.$3 : theme.dividerColor,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _suitSymbol(s.$1),
                      style: TextStyle(
                        fontSize: 22,
                        color: isSelected
                            ? s.$3
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Rank Picker
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _ranks.map((r) {
            final isSelected = _rank == r;
            final color = _suitColor(_suit);
            return InkWell(
              onTap: () => setState(() => _rank = r),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? color : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? color : theme.dividerColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  r,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color:
                        isSelected ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Add Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed:
                (_alreadyAdded || _full) ? null : () => widget.onAdd(_card),
            icon: Icon(
              _full
                  ? Icons.block
                  : _alreadyAdded
                      ? Icons.check_circle_outline
                      : Icons.add_circle_outline,
              size: 18,
            ),
            label: Text(
              _full
                  ? 'Maximum cards reached'
                  : _alreadyAdded
                      ? 'Card already added'
                      : 'Add ${_suitSymbol(_suit)} $_rank',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.3),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _suitColor(_suit),
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.1),
              disabledForegroundColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Selected chips
        if (widget.selected.isEmpty)
          Text(
            _full ? 'All cards added' : 'No cards selected yet',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.selected.map((c) {
              final col = _suitColor(c[0]);
              final sym = _suitSymbol(c[0]);
              final rank = c.substring(1);
              return Chip(
                label: Text(
                  '$sym$rank',
                  style: TextStyle(
                      color: col, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                backgroundColor: col.withValues(alpha: 0.12),
                side: BorderSide(color: col.withValues(alpha: 0.4)),
                deleteIconColor: col.withValues(alpha: 0.7),
                onDeleted: () => widget.onRemove(c),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ─── Card Chip Widget ──────────────────────────────────────────────────────

/// Renders a single playing card as a colored chip (e.g. "HA" → red A♥).
class CardChip extends StatelessWidget {
  final String card;
  final VoidCallback? onRemove;
  final bool compact;

  const CardChip({
    super.key,
    required this.card,
    this.onRemove,
    this.compact = false,
  });

  bool get _isRed {
    if (card.isEmpty) return false;
    return card[0] == 'H' || card[0] == 'D';
  }

  String get _suitSymbol {
    if (card.isEmpty) return '';
    switch (card[0]) {
      case 'H':
        return '♥';
      case 'D':
        return '♦';
      case 'S':
        return '♠';
      case 'C':
        return '♣';
      default:
        return '';
    }
  }

  String get _rankLabel {
    if (card.length < 2) return '';
    return card[1];
  }

  @override
  Widget build(BuildContext context) {
    final color = _isRed ? AppColors.hearts : AppColors.spades;
    final bg = _isRed
        ? AppColors.hearts.withValues(alpha: 0.12)
        : Theme.of(context).colorScheme.surface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_rankLabel$_suitSymbol',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 13 : 16,
              letterSpacing: 0.5,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(8),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Card Input Field ────────────────────────────────────────────────────────

class CardInputField extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> cards;
  final int maxCards;
  final Function(String) onAdd;
  final Function(String) onRemove;

  const CardInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.cards,
    required this.maxCards,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<CardInputField> createState() => _CardInputFieldState();
}

class _CardInputFieldState extends State<CardInputField> {
  final _ctrl = TextEditingController();
  String? _error;

  void _submit(String val) {
    final card = val.trim().toUpperCase();
    if (card.isEmpty) return;
    if (!_isValidCard(card)) {
      setState(() => _error = 'Invalid card: use SUIT+RANK (e.g. HA, S7, CT)');
      return;
    }
    if (widget.cards.contains(card)) {
      setState(() => _error = 'Card already added');
      return;
    }
    if (widget.cards.length >= widget.maxCards) {
      setState(() => _error = 'Maximum ${widget.maxCards} cards');
      return;
    }
    setState(() => _error = null);
    widget.onAdd(card);
    _ctrl.clear();
  }

  bool _isValidCard(String s) {
    if (s.length != 2) return false;
    const suits = {'H', 'S', 'D', 'C'};
    const ranks = {
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'T',
      'J',
      'Q',
      'K',
      'A',
    };
    return suits.contains(s[0]) && ranks.contains(s[1]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.label} (${widget.cards.length}/${widget.maxCards})',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  errorText: _error,
                  prefixIcon: const Icon(Icons.style_rounded),
                ),
                maxLength: 2,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: _submit,
                enabled: widget.cards.length < widget.maxCards,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: widget.cards.length < widget.maxCards
                  ? () => _submit(_ctrl.text)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              child: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        if (widget.cards.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.cards
                .map(
                  (c) => CardChip(card: c, onRemove: () => widget.onRemove(c)),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Gradient Button ─────────────────────────────────────────────────────────

class GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.onPressed == null
                ? null
                : const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: widget.onPressed == null ? Colors.grey.shade700 : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.onPressed != null
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Hand Result Card ────────────────────────────────────────────────────────

class HandResultCard extends StatelessWidget {
  final String category;
  final List<String> bestHand;
  final int strength;
  final String? label;
  final bool highlight;

  const HandResultCard({
    super.key,
    required this.category,
    required this.bestHand,
    required this.strength,
    this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: highlight
            ? LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.15),
                  AppColors.accent.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? AppColors.accent.withValues(alpha: 0.5)
              : Theme.of(context).dividerColor,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: highlight ? AppColors.accent : null,
                          ),
                    ),
                    Text(
                      'Strength: $strength',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
              ),
              if (highlight)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    '🏆 WINNER',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                bestHand.map((c) => CardChip(card: c, compact: true)).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Tile ───────────────────────────────────────────────────────────────

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: c, size: 16),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: c.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: c,
                  letterSpacing: -0.5,
                ),
          ),
        ],
      ),
    );
  }
}
