import 'package:kazumi/modules/history/history_module.dart';

/// 按番剧 ID 取最近一条历史记录。
///
/// 同一部番可能同时有在线/缓存、多个来源的历史；这里统一按 lastWatchTime
/// 取最新一条，供追番页与推荐页复用。
Map<int, History> latestHistoryByBangumi(Iterable<History> histories) {
  final latest = <int, History>{};
  for (final history in histories) {
    final id = history.bangumiItem.id;
    final current = latest[id];
    if (current == null ||
        history.lastWatchTime.isAfter(current.lastWatchTime)) {
      latest[id] = history;
    }
  }
  return latest;
}
