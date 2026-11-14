import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/bangumi/bangumi_relation.dart';
import 'package:kazumi/request/apis/bangumi_api.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/utils/async_rate_limiter.dart';
import 'package:kazumi/utils/async_serial_queue.dart';
import 'package:kazumi/utils/sequel_notice.dart';

/// 追番列表用的续作检查。
///
/// 结果为 null 表示「最近查过，没有已开播的续作」，同样会缓存，
/// 避免每次回到追番页都重新请求。请求串行发送，减轻 Bangumi 压力。
class SequelNoticeService {
  SequelNoticeService({
    Duration ttl = const Duration(hours: 6),
    Duration requestInterval = const Duration(milliseconds: 700),
    DateTime Function()? clock,
    BangumiRelationFetcher? fetchRelations,
  })  : _ttl = ttl,
        _clock = clock ?? DateTime.now,
        _fetchRelations = fetchRelations ?? BangumiApi.getBangumiRelationsByID,
        _limiter = AsyncRateLimiter(requestInterval);

  static final SequelNoticeService instance = SequelNoticeService();

  final Duration _ttl;
  final DateTime Function() _clock;
  final BangumiRelationFetcher _fetchRelations;
  final AsyncRateLimiter _limiter;
  final Map<int, _NoticeEntry> _entries = {};
  final Map<int, Future<AiredSequel?>> _pending = {};
  final AsyncSerialQueue _queue = AsyncSerialQueue();

  /// 命中缓存时直接返回（可能为 null）。
  AiredSequel? cached(int subjectId) {
    final entry = _entries[subjectId];
    if (entry == null) return null;
    if (_clock().difference(entry.checkedAt) >= _ttl) {
      _entries.remove(subjectId);
      return null;
    }
    return entry.notice;
  }

  Future<AiredSequel?> noticeFor(
    BangumiItem item, {
    required Set<int> collectedIds,
  }) {
    final entry = _entries[item.id];
    if (entry != null && _clock().difference(entry.checkedAt) < _ttl) {
      return Future.value(entry.notice);
    }

    final pending = _pending[item.id];
    if (pending != null) return pending;

    final future = _queue.run(() async {
      try {
        await _limiter.acquire();
        final relations = await _fetchRelations(item.id);
        final notice = selectAiredSequel(
          relations: relations,
          currentSubjectId: item.id,
          collectedIds: collectedIds,
        );
        _entries[item.id] = _NoticeEntry(notice: notice, checkedAt: _clock());
        return notice;
      } catch (e) {
        // 失败结果不缓存，下次进入列表时可以重试。
        KazumiLogger().w('SequelNotice: load relations failed', error: e);
        return null;
      } finally {
        _pending.remove(item.id);
      }
    });
    _pending[item.id] = future;
    return future;
  }

  void clear() {
    _entries.clear();
    _pending.clear();
  }
}

class _NoticeEntry {
  const _NoticeEntry({required this.notice, required this.checkedAt});

  final AiredSequel? notice;
  final DateTime checkedAt;
}
