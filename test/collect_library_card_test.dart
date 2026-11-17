import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_layout.dart';
import 'package:kazumi/modules/collect/collect_module.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/collect/collect_library_view.dart';

void main() {
  testWidgets('collect list shows watched episodes and resume action',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final item = _item();
    final entry = CollectedBangumi(
      item,
      DateTime.now(),
      CollectType.watching.value,
    );
    final history = History(
      item,
      3,
      '测试来源',
      DateTime.now(),
      'https://example.com/anime',
      '第 3 话',
    );

    await tester.pumpWidget(
      _app(
        CollectLibraryView(
          entries: [entry],
          showRating: true,
          onOpen: (_) {},
          onChangeType: (_, _) {},
          canEdit: (_) => true,
          layout: CollectLayout.list,
          onLayoutChanged: (_) {},
          histories: {item.id: history},
          onResume: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('看到第 03 集 · 全 12 话'), findsOneWidget);
    expect(find.text('继续观看'), findsOneWidget);
    expect(find.text('继续观看 03'), findsNothing);
    expect(find.textContaining('Bangumi 已看到'), findsNothing);
  });

  testWidgets('shows Bangumi progress when it is ahead of local history',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final item = _item();
    final entry = CollectedBangumi(
      item,
      DateTime.now(),
      CollectType.watching.value,
    );
    final history = History(
      item,
      3,
      '测试来源',
      DateTime.now(),
      'https://example.com/anime',
      '第 3 话',
    );
    int? resumedAt;
    var opened = false;

    await tester.pumpWidget(
      _app(
        CollectLibraryView(
          entries: [entry],
          showRating: true,
          onOpen: (_) => opened = true,
          onChangeType: (_, _) {},
          canEdit: (_) => true,
          layout: CollectLayout.list,
          onLayoutChanged: (_) {},
          histories: {item.id: history},
          remoteEpisodes: {item.id: 8},
          onResumeAtEpisode: (_, episode) => resumedAt = episode,
          onResume: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bangumi 已看到 08 · 从此继续'), findsOneWidget);
    await tester.tap(find.text('Bangumi 已看到 08 · 从此继续'));
    await tester.pump();
    expect(resumedAt, 8);
    expect(opened, isFalse);
  });

  testWidgets('list card does not overflow at large text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final item = _item();
    final entry = CollectedBangumi(
      item,
      DateTime.now(),
      CollectType.watching.value,
    );
    final history = History(
      item,
      3,
      '测试来源',
      DateTime.now(),
      'https://example.com/anime',
      '第 3 话',
    );

    await tester.pumpWidget(
      _app(
        CollectLibraryView(
          entries: [entry],
          showRating: true,
          onOpen: (_) {},
          onChangeType: (_, _) {},
          canEdit: (_) => true,
          layout: CollectLayout.list,
          onLayoutChanged: (_) {},
          histories: {item.id: history},
          remoteEpisodes: {item.id: 8},
          onResumeAtEpisode: (_, _) {},
          onResume: (_) {},
        ),
        textScale: 1.6,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('继续观看'), findsOneWidget);
  });

  testWidgets('hides Bangumi progress when it is not ahead', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final item = _item();
    final entry = CollectedBangumi(
      item,
      DateTime.now(),
      CollectType.watching.value,
    );
    final history = History(
      item,
      6,
      '测试来源',
      DateTime.now(),
      'https://example.com/anime',
      '第 6 话',
    );

    await tester.pumpWidget(
      _app(
        CollectLibraryView(
          entries: [entry],
          showRating: true,
          onOpen: (_) {},
          onChangeType: (_, _) {},
          canEdit: (_) => true,
          layout: CollectLayout.list,
          onLayoutChanged: (_) {},
          histories: {item.id: history},
          remoteEpisodes: {item.id: 5},
          onResumeAtEpisode: (_, _) {},
          onResume: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Bangumi 已看到'), findsNothing);
  });

  testWidgets('caught-up card shows the concrete update time', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final item = _item(
      airDate: _date(now.subtract(const Duration(days: 42))),
    );
    final entry = CollectedBangumi(
      item,
      now,
      CollectType.watching.value,
    );
    final history = History(
      item,
      7,
      '测试来源',
      now,
      'https://example.com/anime',
      '第 7 话',
    );

    await tester.pumpWidget(
      _app(
        CollectLibraryView(
          entries: [entry],
          showRating: true,
          onOpen: (_) {},
          onChangeType: (_, _) {},
          canEdit: (_) => true,
          layout: CollectLayout.list,
          onLayoutChanged: (_) {},
          histories: {item.id: history},
          onResume: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('已看完 07'), findsOneWidget);
    expect(find.textContaining('更新'), findsOneWidget);
    expect(find.textContaining('继续观看'), findsNothing);
  });
}

Widget _app(Widget body, {double textScale = 1.0}) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF2A6C8),
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(body: body),
    );

BangumiItem _item({String airDate = '2023-09-29'}) => BangumiItem(
      id: 400602,
      type: 2,
      name: 'Sousou no Frieren',
      nameCn: '葬送的芙莉莲',
      summary: '测试用简介',
      airDate: airDate,
      airWeekday: DateTime.now().weekday,
      rank: 10,
      images: const {},
      tags: const [],
      alias: const [],
      ratingScore: 9.4,
      votes: 1286,
      votesCount: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      info: '',
      airTime: '22:00',
      totalEpisodes: 12,
    );

String _date(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
