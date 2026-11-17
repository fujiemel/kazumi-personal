import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/services/storage/storage.dart';

/// 当前收藏状态，按 Bangumi 条目 ID 索引。
///
/// 搜索、时间表和关联列表只需要读一次，传 map 给卡片比每个卡片各自查询更轻。
Map<int, CollectType> collectTypesById() {
  final result = <int, CollectType>{};
  try {
    for (final entry in GStorage.collectibles.values) {
      final type = CollectType.fromValue(entry.type);
      if (type.isCollected) {
        result[entry.bangumiItem.id] = type;
      }
    }
  } catch (_) {
    // 页面可能在存储初始化完成前被构建，返回空集合即可。
  }
  return result;
}
