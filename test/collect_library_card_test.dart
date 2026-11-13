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
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF2A6C8),
            brightness: Brightness.dark,
          ),
        ),
        home: Scaffold(
          body: CollectLibraryView(
            entries: [entry],
            showRating: true,
            onOpen: (_) {},
            onChangeType: (_, _) {},
            canEdit: (_) => true,
            layout: CollectLayout.list,
            onLayoutChanged: (_) {},
            histories: {item.id: history},
            onResume: (_) {},
            onSelectSource: (_) {},          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('看到第 03 集 · 全 12 话'), findsOneWidget);
    expect(find.text('选集'), findsOneWidget);
    expect(find.text('继续观看 03'), findsOneWidget);
  });

  testWidgets('narrow card stacks actions and select still works',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final item = _item();
    final entry = CollectedBangumi(
      item,
      DateTime.now(),
      CollectType.watching.value,
    );
    var selected = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF2A6C8),
            brightness: Brightness.dark,
          ),
        ),
        home: Scaffold(
          body: CollectLibraryView(
            entries: [entry],
            showRating: true,
            onOpen: (_) {},
            onChangeType: (_, _) {},
            canEdit: (_) => true,
            layout: CollectLayout.list,
            onLayoutChanged: (_) {},
            histories: const {},
            onResume: (_) {},
            onSelectSource: (_) => selected = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('选集'));
    await tester.pump();
    expect(selected, isTrue);
  });
}

BangumiItem _item() => BangumiItem(
      id: 400602,
      type: 2,
      name: 'Sousou no Frieren',
      nameCn: '葬送的芙莉莲',
      summary: '测试用简介',
      airDate: '2023-09-29',
      airWeekday: 5,
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
