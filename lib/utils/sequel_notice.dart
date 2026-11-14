import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/bangumi/bangumi_relation.dart';

/// 一部已经开播、但本地还没有收藏的续作。
class AiredSequel {
  const AiredSequel({
    required this.item,
    required this.airDate,
  });

  final BangumiItem item;
  final DateTime airDate;

  String get title => item.nameCn.isNotEmpty ? item.nameCn : item.name;

  String get airDateLabel => '${airDate.year} 年 ${airDate.month} 月 '
      '${airDate.day} 日开播';
}

/// 从关联条目里挑出最值得提醒的续作。
///
/// 只考虑方向为「续集」、已经开播、且还没被收藏的条目。多季都已开播时，
/// 返回最早的一部，方便按顺序补番。
AiredSequel? selectAiredSequel({
  required Iterable<BangumiRelation> relations,
  required int currentSubjectId,
  required Set<int> collectedIds,
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  AiredSequel? best;
  for (final relation in relations) {
    if (relation.relation != bangumiSequelRelation) continue;

    final item = relation.bangumiItem;
    if (item.id == currentSubjectId || item.type != 2) continue;
    if (collectedIds.contains(item.id)) continue;

    final parsed = DateTime.tryParse(item.airDate);
    if (parsed == null) continue;
    final airDate = _dateOnly(parsed);
    if (airDate.isAfter(today)) continue;

    if (best == null ||
        airDate.isBefore(best.airDate) ||
        (airDate == best.airDate && item.id < best.item.id)) {
      best = AiredSequel(item: item, airDate: airDate);
    }
  }
  return best;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
