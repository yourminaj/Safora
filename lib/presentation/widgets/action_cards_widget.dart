import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/action_cards_data.dart';
import '../../../core/constants/alert_types.dart';

/// Widget that renders action cards for a given alert type.
///
/// Shows step-by-step survival instructions with urgency-based colors:
/// - Red = Immediate (do this NOW)
/// - Amber = Follow-up (after immediate danger passes)
/// - Blue = Preparatory (for future events)
class ActionCardsWidget extends StatelessWidget {
  const ActionCardsWidget({super.key, required this.alertType});

  final AlertType alertType;

  @override
  Widget build(BuildContext context) {
    final cards = ActionCardsData.forType(alertType);

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'What To Do',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
            ),
          ),
        ),
        ...cards.map((card) => _ActionCardTile(card: card)),
      ],
    );
  }
}

class _ActionCardTile extends StatefulWidget {
  const _ActionCardTile({required this.card});

  final ActionCard card;

  @override
  State<_ActionCardTile> createState() => _ActionCardTileState();
}

class _ActionCardTileState extends State<_ActionCardTile> {
  bool _expanded = true;
  final Set<int> _checkedSteps = {};

  Color get _urgencyColor {
    return switch (widget.card.urgency) {
      ActionUrgency.immediate => AppColors.danger,
      ActionUrgency.followUp => AppColors.warning,
      ActionUrgency.preparatory => AppColors.secondary,
    };
  }

  String get _urgencyLabel {
    return switch (widget.card.urgency) {
      ActionUrgency.immediate => 'DO NOW',
      ActionUrgency.followUp => 'FOLLOW-UP',
      ActionUrgency.preparatory => 'PREPARE',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _urgencyColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header with urgency badge.
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Urgency badge.
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _urgencyColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _urgencyLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.card.title,
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          // Steps list.
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Column(
                children: widget.card.steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final checked = _checkedSteps.contains(index);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (checked) {
                          _checkedSteps.remove(index);
                        } else {
                          _checkedSteps.add(index);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            checked
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 20,
                            color: checked
                                ? AppColors.success
                                : Colors.white54,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step,
                              style: AppTypography.bodySmall.copyWith(
                                color: checked
                                    ? Colors.white38
                                    : Colors.white.withValues(alpha: 0.9),
                                decoration: checked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
