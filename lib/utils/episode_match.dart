import 'package:kazumi/utils/media.dart';

class EpisodeMatch {
  const EpisodeMatch({
    required this.roadIndex,
    required this.listIndex,
    required this.parsedNumber,
    required this.exact,
  });

  final int roadIndex;
  final int listIndex;
  final int parsedNumber;
  final bool exact;
}

EpisodeMatch? findEpisodeInIdentifiers(
  List<List<String>> roadsIdentifiers,
  int canonical, {
  int? preferredRoad,
}) {
  if (canonical < 1) {
    return null;
  }

  if (preferredRoad != null &&
      preferredRoad >= 0 &&
      preferredRoad < roadsIdentifiers.length) {
    final preferredIdentifiers = roadsIdentifiers[preferredRoad];
    for (var index = 0; index < preferredIdentifiers.length; index++) {
      final parsed = extractEpisodeNumber(preferredIdentifiers[index]);
      if (parsed == canonical) {
        return EpisodeMatch(
          roadIndex: preferredRoad,
          listIndex: index + 1,
          parsedNumber: parsed,
          exact: true,
        );
      }
    }
  }

  EpisodeMatch? exactMatch;
  _Candidate? bestAbove;
  _Candidate? bestBelow;

  for (var roadIndex = 0;
      roadIndex < roadsIdentifiers.length;
      roadIndex++) {
    final identifiers = roadsIdentifiers[roadIndex];
    for (var index = 0; index < identifiers.length; index++) {
      final parsed = extractEpisodeNumber(identifiers[index]);
      if (parsed <= 0) {
        continue;
      }
      if (parsed == canonical) {
        exactMatch ??= EpisodeMatch(
          roadIndex: roadIndex,
          listIndex: index + 1,
          parsedNumber: parsed,
          exact: true,
        );
      } else if (parsed > canonical) {
        if (bestAbove == null || parsed < bestAbove.parsedNumber) {
          bestAbove = _Candidate(
            roadIndex: roadIndex,
            listIndex: index + 1,
            parsedNumber: parsed,
          );
        }
      } else {
        if (bestBelow == null || parsed > bestBelow.parsedNumber) {
          bestBelow = _Candidate(
            roadIndex: roadIndex,
            listIndex: index + 1,
            parsedNumber: parsed,
          );
        }
      }
    }
  }

  if (exactMatch != null) {
    return exactMatch;
  }

  final fallback = bestAbove ?? bestBelow;
  if (fallback == null) {
    return null;
  }
  return EpisodeMatch(
    roadIndex: fallback.roadIndex,
    listIndex: fallback.listIndex,
    parsedNumber: fallback.parsedNumber,
    exact: false,
  );
}

class _Candidate {
  const _Candidate({
    required this.roadIndex,
    required this.listIndex,
    required this.parsedNumber,
  });

  final int roadIndex;
  final int listIndex;
  final int parsedNumber;
}
