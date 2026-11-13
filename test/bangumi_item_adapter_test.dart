import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/bangumi/bangumi_tag.dart';

void main() {
  late Directory tempDir;
  late Box<BangumiItem> box;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('kazumi_bangumi_item_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(BangumiItemAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(BangumiTagAdapter());
    }
    box = await Hive.openBox<BangumiItem>('subjects');
  });

  tearDown(() async {
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('persists totalEpisodes and airTime', () async {
    final item = _item(1);
    await box.put(item.id, item);

    final loaded = box.get(item.id);
    expect(loaded, isNotNull);
    expect(loaded!.totalEpisodes, 12);
    expect(loaded.airTime, '22:00');
  });
}

BangumiItem _item(int id) {
  return BangumiItem(
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
    tags: const <BangumiTag>[],
    alias: const [],
    ratingScore: 0,
    votes: 0,
    votesCount: const [],
    info: '',
    totalEpisodes: 12,
    airTime: '22:00',
  );
}
