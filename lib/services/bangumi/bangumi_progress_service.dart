import 'package:flutter/foundation.dart';
import 'package:kazumi/modules/bangumi/bangumi_collection.dart';
import 'package:kazumi/request/apis/bangumi_api.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/storage/storage.dart';

typedef BangumiCollectionsFetcher = Future<List<BangumiCollection>> Function();

/// 读取 Bangumi 上每部番的 `ep_status`，用于补齐本地看不到的观看进度。
///
/// 只读取、不写回，也不会自动改动本地历史；追番卡片会提示
/// 「Bangumi 已看到 08」，用户点击才从那一集继续。
class BangumiProgressService extends ChangeNotifier {
  BangumiProgressService({
    Duration ttl = const Duration(minutes: 10),
    DateTime Function()? clock,
    BangumiCollectionsFetcher? fetchCollections,
    bool Function()? isEnabled,
  })  : _ttl = ttl,
        _clock = clock ?? DateTime.now,
        _fetchCollections = fetchCollections ?? _fetchFromApi,
        _isEnabled = isEnabled ?? _enabledBySettings;

  static final BangumiProgressService instance = BangumiProgressService();

  final Duration _ttl;
  final DateTime Function() _clock;
  final BangumiCollectionsFetcher _fetchCollections;
  final bool Function() _isEnabled;

  final Map<int, int> _episodes = {};
  DateTime? _fetchedAt;
  bool _loading = false;

  Map<int, int> get episodes => _episodes;
  bool get isLoading => _loading;

  static bool _enabledBySettings() {
    try {
      if (!GStorage.getSetting(SettingsKeys.bangumiSyncEnable)) return false;
      return GStorage.getSetting(SettingsKeys.bangumiAccessToken)
          .trim()
          .isNotEmpty;
    } catch (_) {
      // Storage is not ready yet (early startup or tests).
      return false;
    }
  }

  static Future<List<BangumiCollection>> _fetchFromApi() async {
    final user = await BangumiApi.getCurrentUser();
    final username = user?.username ?? '';
    if (username.trim().isEmpty) return const [];
    return BangumiApi.getBangumiCollectibles(username: username, limit: 50);
  }

  /// 达到 TTL 才重新请求；[force] 用于手动刷新。
  Future<void> refresh({bool force = false}) async {
    if (_loading) return;
    if (!_isEnabled()) {
      // 关闭同步后旧提示不应继续显示。
      if (_episodes.isNotEmpty) {
        _episodes.clear();
        _fetchedAt = null;
        notifyListeners();
      }
      return;
    }
    if (!force && _fetchedAt != null && _clock().difference(_fetchedAt!) < _ttl) {
      return;
    }

    _loading = true;
    try {
      final collections = await _fetchCollections();
      _episodes
        ..clear()
        ..addEntries(
          collections
              .where((collection) => collection.epStatus > 0)
              .map((collection) => MapEntry(
                    collection.bangumiId,
                    collection.epStatus,
                  )),
        );
      _fetchedAt = _clock();
    } catch (e) {
      // 保留上一次成功的数据，下次进入页面再试。
      KazumiLogger().w('Bangumi: load progress failed', error: e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  void resetForTesting() {
    _episodes.clear();
    _fetchedAt = null;
    _loading = false;
  }
}
