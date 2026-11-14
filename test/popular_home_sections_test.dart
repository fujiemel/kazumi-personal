import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_module.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/pages/popular/popular_home_sections.dart';

void main() {
  testWidgets('shows today updates', (tester) async {
    final now = DateTime.now();
    final item = _item(
      airWeekday: now.weekday,
      airDate: _date(now.subtract(const Duration(days: 7))),
    );
    final entry = CollectedBangumi(
      item,
      now,
      CollectType.watching.value,
    );
    BangumiItem? opened;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PopularHomeSections(
              collectibles: [entry],
              onOpen: (value) => opened = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('今日更新'), findsOneWidget);
    expect(find.text('全 12 话'), findsOneWidget);

    await tester.tap(find.text('全 12 话'));
    await tester.pump();
    expect(opened, same(item));
  });

  testWidgets('hides when there are no updates', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PopularHomeSections(
            collectibles: [],
            onOpen: _noopOpen,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('今日更新'), findsNothing);
  });
}

void _noopOpen(BangumiItem item) {}

BangumiItem _item({required int airWeekday, required String airDate}) {
  return BangumiItem(
    id: 1,
    type: 2,
    name: 'Sousou no Frieren',
    nameCn: '葬送的芙莉莲',
    summary: '',
    airDate: airDate,
    airWeekday: airWeekday,
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
    totalEpisodes: 12,
    airTime: '22:00',
  );
}

String _date(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
