import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:kazumi/services/network/proxy_aware_image_cache_manager.dart';

final Map<String, Color> _coverColorCache = {};

Color? pickSeedColor(img.Image image) {
  if (image.width <= 0 || image.height <= 0) return null;

  var sumR = 0.0;
  var sumG = 0.0;
  var sumB = 0.0;
  var pixelCount = 0;

  var weightedR = 0.0;
  var weightedG = 0.0;
  var weightedB = 0.0;
  var totalWeight = 0.0;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      sumR += r;
      sumG += g;
      sumB += b;
      pixelCount++;

      final hsv = HSVColor.fromColor(Color.fromARGB(255, r, g, b));
      if (hsv.value < 0.08 || hsv.value > 0.97) continue;

      final weight = hsv.saturation * hsv.saturation + 0.05;
      weightedR += r * weight;
      weightedG += g * weight;
      weightedB += b * weight;
      totalWeight += weight;
    }
  }

  if (pixelCount == 0) return null;

  final double averageR;
  final double averageG;
  final double averageB;
  if (totalWeight == 0) {
    averageR = sumR / pixelCount;
    averageG = sumG / pixelCount;
    averageB = sumB / pixelCount;
  } else {
    averageR = weightedR / totalWeight;
    averageG = weightedG / totalWeight;
    averageB = weightedB / totalWeight;
  }

  return Color.fromARGB(
    255,
    averageR.round(),
    averageG.round(),
    averageB.round(),
  );
}

Future<Color?> extractCoverSeedColor(String url) async {
  final cached = _coverColorCache[url];
  if (cached != null) return cached;

  try {
    final file = await ProxyAwareImageCacheManager.instance.getSingleFile(url);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    final resized = img.copyResize(
      image,
      width: 24,
      interpolation: img.Interpolation.average,
    );
    final color = pickSeedColor(resized);
    if (color != null) {
      _coverColorCache[url] = color;
    }
    return color;
  } catch (_) {
    return null;
  }
}
