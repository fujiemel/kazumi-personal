import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/utils/episode_match.dart';

void main() {
  group('findEpisodeInIdentifiers', () {
    test('finds an exact match', () {
      final match = findEpisodeInIdentifiers([
        ['第1话', '第2话', '第3话'],
      ], 2);

      expect(match, isNotNull);
      expect(match!.roadIndex, 0);
      expect(match.listIndex, 2);
      expect(match.exact, isTrue);
    });

    test('skips identifiers that parse to zero', () {
      final match = findEpisodeInIdentifiers([
        ['SP', '第1话', '第2话'],
      ], 1);

      expect(match, isNotNull);
      expect(match!.listIndex, 2);
      expect(match.exact, isTrue);
    });

    test('falls back to the closest higher episode', () {
      final match = findEpisodeInIdentifiers([
        ['第1话', '第3话'],
      ], 2);

      expect(match, isNotNull);
      expect(match!.parsedNumber, 3);
      expect(match.exact, isFalse);
    });

    test('falls back to the closest lower episode', () {
      final match = findEpisodeInIdentifiers([
        ['第1话', '第2话'],
      ], 5);

      expect(match, isNotNull);
      expect(match!.parsedNumber, 2);
      expect(match.exact, isFalse);
    });

    test('prefers the requested road when it has an exact match', () {
      final match = findEpisodeInIdentifiers([
        ['第1话', '第2话'],
        ['第1话', '第2话'],
      ], 2, preferredRoad: 1);

      expect(match, isNotNull);
      expect(match!.roadIndex, 1);
      expect(match.exact, isTrue);
    });

    test('returns null when there are no candidates', () {
      final match = findEpisodeInIdentifiers([
        ['特别篇'],
      ], 1);

      expect(match, isNull);
    });
  });
}
