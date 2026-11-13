import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_module.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/utils/air_schedule.dart';

/// 推荐页顶部的追番摘要：继续观看 + 今日更新。
///
/// 没有数据时整段隐藏，不占用首页空间。
class PopularHomeSections extends StatelessWidget {
  const PopularHomeSections({
    super.key,
    required this.histories,
    required this.collectibles,
    required this.onResume,
    required this.onOpen,
  });

  final List<History> histories;
  final List<CollectedBangumi> collectibles;
  final ValueChanged<History> onResume;
  final ValueChanged<BangumiItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final watching = [...histories]
      ..sort((a, b) => b.lastWatchTime.compareTo(a.lastWatchTime));
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

    if (watching.isEmpty && updates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (watching.isNotEmpty) ...[
          _SectionHeader(title: '继续观看', count: watching.length),
          const SizedBox(height: 10),
          SizedBox(
            height: 262,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: watching.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final history = watching[index];
                return _ContinueWatchingCard(
                  history: history,
                  onTap: () => onResume(history),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (updates.isNotEmpty) ...[
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

class _ContinueWatchingCard extends StatelessWidget {
  const _ContinueWatchingCard({
    required this.history,
    required this.onTap,
  });

  final History history;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final item = history.bangumiItem;
    final title = item.nameCn.isEmpty ? item.name : item.nameCn;
    final total = item.totalEpisodes;
    final watched = history.lastWatchEpisode;
    final estimatedAired = _estimatedAiredEpisodes(item);
    final caughtUp =
        total > 0 && estimatedAired != null && watched >= estimatedAired;
    final completed = total > 0 && watched >= total;
    final progress = caughtUp
        ? (completed
            ? '已看完 · 全 $total 话'
            : '已看完 ${watched.toString().padLeft(2, '0')}')
        : '看到第 $watched 集${total > 0 ? ' · 全 $total 话' : ''}';
    final updateText =
        caughtUp && !completed ? _nextUpdateText(item) : null;

    return SizedBox(
      width: 138,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 138,
              height: 194,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkImgLayer(
                      src: item.images['large'] ?? item.images['common'] ?? '',
                      width: 138,
                      height: 194,
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.45),
                            ],
                            stops: const [0.6, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          caughtUp
                              ? Icons.schedule_rounded
                              : Icons.play_arrow_rounded,
                          size: 19,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              progress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primary,
              ),
            ),
            if (updateText != null) ...[
              const SizedBox(height: 2),
              Text(
                updateText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int? _estimatedAiredEpisodes(BangumiItem item) {
    final start = DateTime.tryParse(item.airDate);
    if (start == null) return null;
    final now = DateTime.now();
    final startDay = DateTime(start.year, start.month, start.day);
    final today = DateTime(now.year, now.month, now.day);
    if (startDay.isAfter(today)) return 0;
    final estimate = today.difference(startDay).inDays ~/ 7 + 1;
    if (item.totalEpisodes > 0) {
      return math.min(estimate, item.totalEpisodes);
    }
    return estimate;
  }

  String _nextUpdateText(BangumiItem item) {
    final next = nextAiringDate(
      airWeekday: item.airWeekday,
      airTime: item.airTime,
    );
    if (next == null) return '等待更新';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(next.year, next.month, next.day);
    final days = target.difference(today).inDays;
    if (days <= 0) return '今天更新';
    if (days == 1) return '明天更新';
    return '还有 $days 天更新';
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
