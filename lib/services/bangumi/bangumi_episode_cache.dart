import 'package:kazumi/modules/bangumi/episode_item.dart';

/// 一次会话内的 Bangumi 剧集列表缓存。
///
/// 详情页重复打开时没必要重复请求 `/episodes`；失败结果不写入缓存，
/// 避免一次网络波动让详情页长时间显示空列表。
class BangumiEpisodeCache {
  BangumiEpisodeCache({
    Duration ttl = const Duration(minutes: 30),
    DateTime Function()? clock,
  })  : _ttl = ttl,
        _clock = clock ?? DateTime.now;

  final Duration _ttl;
  final DateTime Function() _clock;
  final Map<int, _CacheEntry> _entries = {};

  List<EpisodeInfo>? get(int subjectId) {
    final entry = _entries[subjectId];
    if (entry == null) return null;
    if (_clock().difference(entry.createdAt) >= _ttl) {
      _entries.remove(subjectId);
      return null;
    }
    return entry.episodes;
  }

  void put(int subjectId, List<EpisodeInfo> episodes) {
    // Empty results can mean "no episodes" or a failed request; do not cache.
    if (episodes.isEmpty) return;
    _entries[subjectId] = _CacheEntry(
      episodes: List<EpisodeInfo>.unmodifiable(episodes),
      createdAt: _clock(),
    );
  }

  void clear() => _entries.clear();
}

class _CacheEntry {
  const _CacheEntry({required this.episodes, required this.createdAt});

  final List<EpisodeInfo> episodes;
  final DateTime createdAt;
}
