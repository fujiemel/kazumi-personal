import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/bangumi/bangumi_relation.dart';
import 'package:kazumi/services/bangumi/sequel_notice_service.dart';
import 'package:kazumi/utils/sequel_notice.dart';

void main() {
  final now = DateTime(2026, 11, 14);

  test('returns the earliest aired sequel that is not collected', () {
    final relations = [
      _relation('续集', _item(2, airDate: '2026-10-01')),
      _relation('续集', _item(3, airDate: '2024-04-01')),
      _relation('前传', _item(4, airDate: '2020-01-01')),
    ];

    final notice = selectAiredSequel(
      relations: relations,
      currentSubjectId: 1,
      collectedIds: const {},
      now: now,
    );

    expect(notice?.item.id, 3);
    expect(notice?.airDateLabel, '2024 年 4 月 1 日开播');
  });

  test('ignores unaired, collected, prequel and self relations', () {
    final relations = [
      _relation('续集', _item(2, airDate: '2026-12-01')),
      _relation('续集', _item(3, airDate: '2026-01-01')),
      _relation('续集', _item(1, airDate: '2026-01-01')),
      _relation('前传', _item(4, airDate: '2020-01-01')),
    ];

    expect(
      selectAiredSequel(
        relations: relations,
        currentSubjectId: 1,
        collectedIds: {3},
        now: now,
      ),
      isNull,
    );
  });

  test('treats the air date itself as aired', () {
    final relations = [
      _relation('续集', _item(2, airDate: '2026-11-14')),
    ];

    expect(
      selectAiredSequel(
        relations: relations,
        currentSubjectId: 1,
        collectedIds: const {},
        now: now,
      )?.item.id,
      2,
    );
  });

  test('parses the air date from relation json', () {
    final relation = BangumiRelation.fromJson({
      'id': 9,
      'type': 2,
      'name': 'Sequel',
      'name_cn': '续作',
      'relation': '续集',
      'date': '2025-07-06',
      'short_summary': '简介',
    });

    expect(relation.bangumiItem.airDate, '2025-07-06');
    expect(relation.bangumiItem.summary, '简介');
    expect(relation.relation, '续集');
  });

  test('caches empty results for the ttl', () async {
    var calls = 0;
    var clock = DateTime(2026, 11, 14, 12);
    final service = SequelNoticeService(
      ttl: const Duration(hours: 1),
      clock: () => clock,
      fetchRelations: (id) async {
        calls++;
        return const [];
      },
    );
    final item = _item(1, airDate: '2020-01-01');

    expect(await service.noticeFor(item, collectedIds: const {}), isNull);
    expect(await service.noticeFor(item, collectedIds: const {}), isNull);
    expect(calls, 1);

    clock = clock.add(const Duration(hours: 2));
    await service.noticeFor(item, collectedIds: const {});
    expect(calls, 2);
  });

  test('deduplicates concurrent requests for one subject', () async {
    var calls = 0;
    final service = SequelNoticeService(
      fetchRelations: (id) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return [_relation('续集', _item(2, airDate: '2024-04-01'))];
      },
    );
    final item = _item(1, airDate: '2020-01-01');

    final results = await Future.wait([
      service.noticeFor(item, collectedIds: const {}),
      service.noticeFor(item, collectedIds: const {}),
    ]);

    expect(calls, 1);
    expect(results.map((notice) => notice?.item.id), [2, 2]);
  });
}

BangumiRelation _relation(String relation, BangumiItem item) =>
    BangumiRelation(relation: relation, bangumiItem: item);

BangumiItem _item(int id, {required String airDate}) => BangumiItem(
      id: id,
      type: 2,
      name: 'Subject $id',
      nameCn: '番剧 $id',
      summary: '',
      airDate: airDate,
      airWeekday: 0,
      rank: 0,
      images: const {},
      tags: const [],
      alias: const [],
      ratingScore: 0,
      votes: 0,
      votesCount: const [],
      info: '',
    );
