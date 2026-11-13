import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/utils/history_lookup.dart';

void main() {
  test('keeps the latest history per bangumi', () {
    final first = _item(1);
    final second = _item(2);
    final older = _history(first, DateTime(2026, 1, 1));
    final newer = _history(first, DateTime(2026, 1, 2));
    final other = _history(second, DateTime(2026, 1, 3));

    final result = latestHistoryByBangumi([older, newer, other]);

    expect(result.length, 2);
    expect(result[1], same(newer));
    expect(result[2], same(other));
  });

  test('returns an empty map for no history', () {
    expect(latestHistoryByBangumi(const []), isEmpty);
  });
}

History _history(BangumiItem item, DateTime time) => History(
      item,
      1,
      'plugin',
      time,
      'https://example.com/source',
      '第 1 话',
    );

BangumiItem _item(int id) => BangumiItem(
      id: id,
      type: 2,
      name: 'subject $id',
      nameCn: '条目 $id',
      summary: '',
      airDate: '2026-01-01',
      airWeekday: 4,
      rank: 0,
      images: const {
        'large': '',
        'common': '',
        'medium': '',
        'small': '',
        'grid': '',
      },
      tags: const [],
      alias: const [],
      ratingScore: 0,
      votes: 0,
      votesCount: const [],
      info: '',
    );
