import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

String decodeVideoSource(String iframeUrl) {
  final decodedUrl = Uri.decodeFull(iframeUrl);
  final regExp = RegExp(
    r'(http[s]?://.*?\.m3u8)|(http[s]?://.*?\.mp4)',
    caseSensitive: false,
  );

  final uri = Uri.parse(decodedUrl);
  final params = uri.queryParameters;

  var matchedUrl = iframeUrl;
  params.forEach((key, value) {
    if (regExp.hasMatch(value)) {
      matchedUrl = value;
      return;
    }
  });

  return Uri.encodeFull(matchedUrl);
}

int extractEpisodeNumber(String input) {
  final episodeMatches = RegExp(r'第(\d+)[话集]').allMatches(input);
  if (episodeMatches.isNotEmpty) {
    final lastMatch = episodeMatches.last;
    return int.tryParse(lastMatch.group(1)!) ?? 0;
  }

  final upperInput = input.toUpperCase();
  if (upperInput.contains('SP') ||
      input.contains('特别篇') ||
      input.contains('番外') ||
      upperInput.contains('OVA') ||
      upperInput.contains('OAD')) {
    return 0;
  }

  final remaining = input.replaceAll(RegExp(r'第\d+季'), '');
  final match = RegExp(r'(\d+)').firstMatch(remaining);
  if (match != null && match.group(1) != null) {
    return int.tryParse(match.group(1)!) ?? 0;
  }

  return 0;
}

Future<String> getPlayerTempPath() async {
  final directory = await getTemporaryDirectory();
  return directory.path;
}

String buildShadersAbsolutePath(String baseDirectory, List<String> shaders) {
  final absolutePaths = shaders.map((shader) {
    return path.join(baseDirectory, shader);
  }).toList();
  if (Platform.isWindows) {
    return absolutePaths.join(';');
  }
  return absolutePaths.join(':');
}
