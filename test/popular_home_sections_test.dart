import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_module.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/popular/popular_home_sections.dart';

void main() {
  testWidgets('shows continue watching and today updates', (tester) async {
    final now = DateTime.now();
    final item = _item(
      airWeekday: now.weekday,
      airDate:
          '${now.year.toString().padLeft(4, '0')}-${(now.month - 1).clamp(1, 12).toString().padLeft(2, '0')}-01',
    );
    final history = History(
      item,
      3,
      'plugin',
      now,
      'https://example.com/source',
      '第 3 话',
    );
    final entry = CollectedBangumi(
      item,
      now,
      CollectType.watching.value,
    );
    History? resumed;
    BangumiItem? opened;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PopularHomeSections(
              histories: [history],
              collectibles: [entry],
              onResume: (value) => resumed = value,
              onOpen: (value) => opened = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('继续观看'), findsOneWidget);
    expect(find.text('看到第 3 集 · 全 12 话'), findsOneWidget);
    expect(find.text('今日更新'), findsOneWidget);
    expect(find.text('全 12 话'), findsOneWidget);

    await tester.tap(find.text('看到第 3 集 · 全 12 话'));
    await tester.pump();
    expect(resumed, same(history));

    await tester.tap(find.text('全 12 话'));
    await tester.pump();
    expect(opened, same(item));
  });

  testWidgets('hides sections when there is no data', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PopularHomeSections(
            histories: [],
            collectibles: [],
            onResume: _noopResume,
            onOpen: _noopOpen,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('继续观看'), findsNothing);
    expect(find.text('今日更新'), findsNothing);
  });

  testWidgets('shows caught-up status when the latest episode is watched',
      (tester) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 42));
    final item = _item(
      airWeekday: now.weekday,
      airDate: _date(start),
    );
    final history = History(
      item,
      7,
      'plugin',
      now,
      'https://example.com/source',
      '第 7 话',
    );
    final entry = CollectedBangumi(
      item,
      now,
      CollectType.watching.value,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PopularHomeSections(
              histories: [history],
              collectibles: [entry],
              onResume: _noopResume,
              onOpen: _noopOpen,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('已看完 07'), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
  });
}

String _date(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

void _noopResume(History history) {}
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
