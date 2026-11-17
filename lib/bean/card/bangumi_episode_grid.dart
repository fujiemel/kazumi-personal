import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kazumi/modules/bangumi/episode_item.dart';

/// 参考 Animeko 的剧集网格：已放送、下一话与未放送状态一目了然。
class BangumiEpisodeGrid extends StatelessWidget {
  const BangumiEpisodeGrid({
    super.key,
    required this.episodes,
    this.watchedEpisode = 0,
    this.isLoading = false,
  });

  final List<EpisodeInfo> episodes;
  final int watchedEpisode;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (isLoading) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < 12; i++)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
        ],
      );
    }

    final mainEpisodes = episodes.where((e) => e.type == 0).toList()
      ..sort((a, b) => a.episode.compareTo(b.episode));
    if (mainEpisodes.isEmpty) return const SizedBox.shrink();

    final today = _today();
    final datedEpisodes = <DateTime?>[
      for (final episode in mainEpisodes) _episodeDate(episode),
    ];
    final hasDates = datedEpisodes.any((date) => date != null);
    final nextIndex = datedEpisodes.indexWhere(
      (date) => date != null && !date.isBefore(today),
    );
    final airedCount = datedEpisodes
        .where((date) => date != null && !date.isAfter(today))
        .length;
    final watchedCount = math.min(
      watchedEpisode < 0 ? 0 : watchedEpisode,
      mainEpisodes.length,
    );
    final progress = hasDates
        ? '已更新 $airedCount / ${mainEpisodes.length} 话'
        : '全 ${mainEpisodes.length} 话';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < mainEpisodes.length; i++)
              _EpisodeTile(
                episode: mainEpisodes[i],
                date: datedEpisodes[i],
                isNext: i == nextIndex,
                isWatched:
                    watchedCount > 0 && mainEpisodes[i].episode <= watchedCount,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            _MetaText(
              watchedCount > 0 ? '$progress · 已看 $watchedCount 话' : progress,
            ),
            if (nextIndex >= 0) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.update_rounded, size: 14, color: colors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '下一话 ${_dateLabel(datedEpisodes[nextIndex]!)}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: colors.primary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime? _episodeDate(EpisodeInfo episode) {
    final parsed = DateTime.tryParse(episode.airdate);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String _dateLabel(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${date.month} 月 ${date.day} 日 ${weekdays[(date.weekday - 1) % 7]}';
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.date,
    required this.isNext,
    required this.isWatched,
  });

  final EpisodeInfo episode;
  final DateTime? date;
  final bool isNext;
  final bool isWatched;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final today = BangumiEpisodeGrid._today();
    final isAired = date != null && !date!.isAfter(today);
    final isFuture = date != null && date!.isAfter(today);

    final Color background;
    final Color foreground;
    final Color border;
    if (isNext) {
      background = colors.primary;
      foreground = colors.onPrimary;
      border = colors.primary;
    } else if (isWatched) {
      background = colors.primary.withValues(alpha: 0.10);
      foreground = colors.primary;
      border = colors.primary.withValues(alpha: 0.28);
    } else if (isAired) {
      background = colors.surfaceContainerHighest;
      foreground = colors.onSurfaceVariant;
      border = colors.surfaceContainerHighest;
    } else if (isFuture) {
      background = Colors.transparent;
      foreground = colors.onSurface;
      border = colors.outlineVariant;
    } else {
      background = colors.surfaceContainerLow;
      foreground = colors.onSurfaceVariant;
      border = colors.surfaceContainerHighest;
    }

    final label = date == null
        ? '第 ${episode.episode} 话'
        : '第 ${episode.episode} 话 · ${BangumiEpisodeGrid._dateLabel(date!)}';
    final title = episode.nameCn.isNotEmpty
        ? episode.nameCn
        : (episode.name.isNotEmpty ? episode.name : '');
    final tooltip = [
      label,
      if (title.isNotEmpty) title,
      if (isWatched) '已看',
    ].join('\n');

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: Container(
        width: 50,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  episode.episode.toInt().toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (date != null)
                  Text(
                    '${date!.month}/${date!.day}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      height: 1.1,
                      color: foreground.withValues(alpha: 0.75),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            if (isWatched)
              Positioned(
                right: 3,
                bottom: 2,
                child: Icon(
                  Icons.check_rounded,
                  size: 10,
                  color: isNext ? colors.onPrimary : colors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
    );
  }
}
