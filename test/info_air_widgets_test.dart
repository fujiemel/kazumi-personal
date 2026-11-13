import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/card/bangumi_air_info_card.dart';
import 'package:kazumi/bean/card/bangumi_episode_grid.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/bangumi/episode_item.dart';

void main() {
  testWidgets('broadcast card and episode grid show airing information', (
    tester,
  ) async {
    final episodes = List.generate(28, (index) {
      final number = index + 1;
      final date = number <= 8
          ? DateTime(2020, 1, number)
          : DateTime(2030, 1, number - 8);
      return EpisodeInfo(
        id: number,
        episode: number,
        type: 0,
        name: 'Episode $number',
        nameCn: '',
        airdate:
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      );
    });

    final item = BangumiItem(
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
      totalEpisodes: 28,
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 280,
                  child: BangumiAirInfoCard(bangumiItem: item),
                ),
                const SizedBox(height: 24),
                BangumiEpisodeGrid(episodes: episodes),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('放送信息'), findsOneWidget);
    expect(find.text('每周五'), findsOneWidget);
    expect(find.text('22:00'), findsNWidgets(2));
    expect(find.text('全 28 话'), findsOneWidget);
    expect(find.text('已更新 8 / 28 话'), findsOneWidget);
    expect(find.textContaining('下一话'), findsWidgets);
  });

  testWidgets('marks watched episodes and shows watched count', (tester) async {
    final episodes = List.generate(5, (index) {
      final number = index + 1;
      return EpisodeInfo(
        id: number,
        episode: number,
        type: 0,
        name: 'Episode $number',
        nameCn: '',
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BangumiEpisodeGrid(
            episodes: episodes,
            watchedEpisode: 3,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('全 5 话 · 已看 3 话'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(3));
  });
}
