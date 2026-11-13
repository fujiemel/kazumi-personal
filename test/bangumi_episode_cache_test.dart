import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/bangumi/episode_item.dart';
import 'package:kazumi/services/bangumi/bangumi_episode_cache.dart';

void main() {
  late DateTime now;
  late BangumiEpisodeCache cache;

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    cache = BangumiEpisodeCache(
      ttl: const Duration(minutes: 30),
      clock: () => now,
    );
  });

  EpisodeInfo episode(int number) => EpisodeInfo(
        id: number,
        episode: number,
        type: 0,
        name: 'Episode $number',
        nameCn: '',
      );

  test('caches non-empty episode lists per subject', () {
    cache.put(1, [episode(1), episode(2)]);

    expect(cache.get(1)?.map((e) => e.episode), [1, 2]);
    expect(cache.get(2), isNull);
  });

  test('does not cache empty results', () {
    cache.put(1, const []);

    expect(cache.get(1), isNull);
  });

  test('copies the list so callers cannot mutate the cache', () {
    final episodes = [episode(1)];
    cache.put(1, episodes);
    episodes.add(episode(2));

    expect(cache.get(1)?.length, 1);
  });

  test('expires after ttl', () {
    cache.put(1, [episode(1)]);

    now = now.add(const Duration(minutes: 29));
    expect(cache.get(1), isNotNull);

    now = now.add(const Duration(minutes: 2));
    expect(cache.get(1), isNull);
  });

  test('clear removes all entries', () {
    cache.put(1, [episode(1)]);
    cache.put(2, [episode(2)]);

    cache.clear();

    expect(cache.get(1), isNull);
    expect(cache.get(2), isNull);
  });
}
