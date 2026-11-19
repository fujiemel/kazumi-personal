import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/utils/media.dart';

void main() {
  group('extractEpisodeNumber', () {
    test('parses canonical episode markers', () {
      expect(extractEpisodeNumber('第12话'), 12);
      expect(extractEpisodeNumber('第2季第12话'), 12);
      expect(extractEpisodeNumber('EP12'), 12);
      expect(extractEpisodeNumber('12'), 12);
      expect(extractEpisodeNumber('第12话 完'), 12);
    });

    test('returns zero for specials and season-only titles', () {
      expect(extractEpisodeNumber('SP1'), 0);
      expect(extractEpisodeNumber('特别篇'), 0);
      expect(extractEpisodeNumber('第2季'), 0);
      expect(extractEpisodeNumber('番外篇'), 0);
      expect(extractEpisodeNumber('OVA3'), 0);
    });
  });
}
