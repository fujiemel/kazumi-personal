import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/card/bangumi_timeline_card.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_type.dart';

void main() {
  testWidgets('fits a collect badge at large text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: BangumiTimelineCard(
              bangumiItem: _item(),
              showRating: true,
              collectType: CollectType.watching,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('在看'), findsOneWidget);
  });
}

BangumiItem _item() => BangumiItem(
      id: 1,
      type: 2,
      name: 'Sousou no Frieren',
      nameCn: '葬送的芙莉莲',
      summary: '',
      airDate: '2026-10-02',
      airWeekday: 5,
      rank: 10,
      images: const {'large': ''},
      tags: const [],
      alias: const [],
      ratingScore: 9.4,
      votes: 100,
      votesCount: const [],
      info: '全 28 话',
    );
