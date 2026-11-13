import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/roads/road_module.dart';
import 'package:kazumi/pages/video/episode_selection_panel.dart';

void main() {
  testWidgets('unifies episode list across roads', (tester) async {
    final roads = [
      Road(
        name: '线路 A',
        data: ['a1', 'a2', 'a3'],
        identifier: ['第1集', '第2集', '第3集'],
      ),
      Road(
        name: '线路 B',
        data: ['b1', 'b2', 'b3', 'b4'],
        identifier: ['第1集', '第2集', '第3集', '第4集'],
      ),
    ];
    final selections = <(int, int)>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 700,
            child: EpisodeSelectionPanel(
              title: '测试番剧',
              roads: roads,
              selectedRoad: 0,
              selectedEpisode: 2,
              downloads: const {},
              onEpisodeSelected: (episode, road) {
                selections.add((episode, road));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 统一集数取所有线路的最大值，而不是按线路分别计数。
    expect(find.text('全部剧集 · 4 集'), findsOneWidget);
    expect(find.text('第4集'), findsOneWidget);
    expect(find.text('3 集'), findsNothing);
    expect(find.text('4 集'), findsNothing);

    // 第 4 集只有线路 B 提供，点击后应自动切到线路 B。
    await tester.ensureVisible(find.text('第4集'));
    await tester.tap(find.text('第4集'));
    await tester.pump();
    expect(selections.last, (4, 1));

    // 切换来源时保持当前集数，只换线路。
    await tester.tap(find.text('播放来源'));
    await tester.pumpAndSettle();
    expect(find.text('选择播放来源'), findsOneWidget);
    await tester.tap(find.text('线路 B'));
    await tester.pump();
    expect(selections.last, (2, 1));
  });

  testWidgets('matches the same episode number when switching roads', (
    tester,
  ) async {
    final roads = [
      Road(
        name: '线路 A',
        data: ['a1', 'a2', 'a3'],
        identifier: ['第1集', '第2集', '第3集'],
      ),
      Road(
        name: '线路 B',
        data: ['b1', 'b2', 'b3'],
        identifier: ['第2集', '第3集', '第4集'],
      ),
    ];
    final selections = <(int, int)>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 700,
            child: EpisodeSelectionPanel(
              title: '测试番剧',
              roads: roads,
              selectedRoad: 0,
              selectedEpisode: 2,
              downloads: const {},
              onEpisodeSelected: (episode, road) {
                selections.add((episode, road));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('全部剧集 · 4 集'), findsOneWidget);

    // 第 4 集在线路 B 的第 3 个位置。
    await tester.ensureVisible(find.text('第4集'));
    await tester.tap(find.text('第4集'));
    await tester.pump();
    expect(selections.last, (3, 1));

    // 当前第 2 集在线路 B 的第 1 个位置，切换来源不能按索引继续用 2。
    await tester.tap(find.text('播放来源'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('线路 B'));
    await tester.pump();
    expect(selections.last, (1, 1));
  });
}
