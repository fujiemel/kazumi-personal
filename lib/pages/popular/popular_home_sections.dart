import 'package:flutter/material.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_module.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/utils/air_schedule.dart';

/// 推荐页顶部的今日更新摘要。
class PopularHomeSections extends StatelessWidget {
  const PopularHomeSections({
    super.key,
    required this.collectibles,
    required this.onOpen,
  });

  final List<CollectedBangumi> collectibles;
  final ValueChanged<BangumiItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    final updates = collectibles
        .where((entry) =>
            entry.type == CollectType.watching.value &&
            entry.bangumiItem.airWeekday == today)
        .map((entry) => entry.bangumiItem)
        .where((item) =>
            nextAiringLabel(
              airDate: item.airDate,
              airWeekday: item.airWeekday,
              airTime: item.airTime,
            ) !=
            null)
        .toList()
      ..sort((a, b) => a.airTime.compareTo(b.airTime));

    if (updates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: '今日更新', count: updates.length),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final item in updates)
                _TodayUpdateRow(
                  item: item,
                  onTap: () => onOpen(item),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayUpdateRow extends StatelessWidget {
  const _TodayUpdateRow({required this.item, required this.onTap});

  final BangumiItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = item.nameCn.isEmpty ? item.name : item.nameCn;
    final update = nextAiringLabel(
      airDate: item.airDate,
      airWeekday: item.airWeekday,
      airTime: item.airTime,
    );
    final total = item.totalEpisodes;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                item.airTime.isEmpty ? '--:--' : item.airTime,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: NetworkImgLayer(
                src: item.images['large'] ?? item.images['common'] ?? '',
                width: 40,
                height: 54,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '全 $total 话',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              update?.replaceAll(' 更新', '') ?? '',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
