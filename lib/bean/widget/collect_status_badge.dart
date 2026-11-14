import 'package:flutter/material.dart';
import 'package:kazumi/modules/collect/collect_type.dart';

/// 收藏状态小徽标，用于搜索、时间表和关联条目。
class CollectStatusBadge extends StatelessWidget {
  const CollectStatusBadge({
    super.key,
    required this.type,
    this.dense = false,
  });

  final CollectType type;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (type) {
      CollectType.watching => colors.primary,
      CollectType.watched => colors.tertiary,
      CollectType.planToWatch => colors.secondary,
      CollectType.onHold => colors.onSurfaceVariant,
      CollectType.abandoned => colors.error,
      CollectType.none => colors.outline,
    };
    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 5, vertical: 1)
          : const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        type.label,
        maxLines: 1,
        style: TextStyle(
          color: color,
          fontSize: dense ? 10 : 11,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
