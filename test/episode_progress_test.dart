import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/utils/episode_progress.dart';

void main() {
  final now = DateTime.now();

  test('shows not-started label before any progress', () {
    final status = episodeProgressStatus(
      item: _item(airDate: _date(now.subtract(const Duration(days: 14)))),
      watchedEpisode: 0,
    );

    expect(status.label, '未开始 · 全 12 话');
    expect(status.updateLabel, isNull);
  });

  test('shows watched episode when episodes remain', () {
    final status = episodeProgressStatus(
      item: _item(airDate: _date(now.subtract(const Duration(days: 42)))),
      watchedEpisode: 3,
    );

    expect(status.label, '看到第 03 集 · 全 12 话');
    expect(status.caughtUp, isFalse);
    expect(status.updateLabel, isNull);
  });

  test('shows next update when caught up', () {
    final status = episodeProgressStatus(
      item: _item(airDate: _date(now.subtract(const Duration(days: 42)))),
      watchedEpisode: 7,
    );

    expect(status.label, '已看完 07');
    expect(status.caughtUp, isTrue);
    expect(status.updateLabel, isNotNull);
  });

  test('shows completed label for finished shows', () {
    final status = episodeProgressStatus(
      item: _item(airDate: _date(now.subtract(const Duration(days: 84)))),
      watchedEpisode: 12,
    );

    expect(status.label, '已看完 · 全 12 话');
    expect(status.completed, isTrue);
    expect(status.updateLabel, isNull);
  });

  test('handles caught up without total episode count', () {
    final status = episodeProgressStatus(
      item: _item(
        airDate: _date(now.subtract(const Duration(days: 42))),
        totalEpisodes: 0,
      ),
      watchedEpisode: 7,
    );

    expect(status.label, '已看完 07');
    expect(status.updateLabel, isNotNull);
  });

  test('falls back to weekday when air time is missing', () {
    final status = episodeProgressStatus(
      item: _item(
        airDate: _date(now.subtract(const Duration(days: 42))),
        airWeekday: (now.weekday % 7) + 1,
        airTime: '',
      ),
      watchedEpisode: 7,
    );

    expect(status.updateLabel, isNotNull);
    expect(status.updateLabel, isNot('等待更新'));
  });
}

BangumiItem _item({
  required String airDate,
  int totalEpisodes = 12,
  int? airWeekday,
  String airTime = '22:00',
}) {
  return BangumiItem(
    id: 1,
    type: 2,
    name: 'Test',
    nameCn: '测试',
    summary: '',
    airDate: airDate,
    airWeekday: airWeekday ?? DateTime.now().weekday,
    rank: 0,
    images: const {},
    tags: const [],
    alias: const [],
    ratingScore: 0,
    votes: 0,
    votesCount: const [],
    info: '',
    totalEpisodes: totalEpisodes,
    airTime: airTime,
  );
}

String _date(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
