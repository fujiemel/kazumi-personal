import 'dart:math' as math;

import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/utils/air_schedule.dart';

/// Progress shown on collect/continue-watching cards.
class EpisodeProgressStatus {
  const EpisodeProgressStatus({
    required this.label,
    required this.caughtUp,
    required this.completed,
    this.updateLabel,
  });

  final String label;
  final String? updateLabel;
  final bool caughtUp;
  final bool completed;
}

EpisodeProgressStatus episodeProgressStatus({
  required BangumiItem item,
  required int watchedEpisode,
}) {
  final total = item.totalEpisodes;
  final estimated = estimatedAiredEpisodes(item);
  final caughtUp = watchedEpisode > 0 &&
      estimated != null &&
      watchedEpisode >= estimated;
  final completed = total > 0 && watchedEpisode >= total;

  final String label;
  if (watchedEpisode <= 0) {
    label = total > 0 ? '未开始 · 全 $total 话' : '未开始';
  } else if (caughtUp) {
    label = completed
        ? '已看完 · 全 $total 话'
        : '已看完 ${_twoDigits(watchedEpisode)}';
  } else {
    label =
        '看到第 ${_twoDigits(watchedEpisode)} 集${total > 0 ? ' · 全 $total 话' : ''}';
  }

  return EpisodeProgressStatus(
    label: label,
    updateLabel: caughtUp && !completed ? nextUpdateLabel(item) : null,
    caughtUp: caughtUp,
    completed: completed,
  );
}

/// Estimates how many episodes have aired from the first broadcast date.
///
/// Bangumi subject data does not expose the current aired episode, so this is a
/// weekly estimate capped by [BangumiItem.totalEpisodes] when known. Breaks in
/// the broadcast schedule can make it optimistic.
int? estimatedAiredEpisodes(BangumiItem item) {
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

/// Short countdown for the next weekly airing, e.g. 「还有 3 天更新」.
String nextUpdateLabel(BangumiItem item) {
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

String _twoDigits(int value) => value.toString().padLeft(2, '0');
