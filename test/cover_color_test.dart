import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kazumi/utils/cover_color.dart';

void main() {
  test('pickSeedColor keeps a pure red image red', () {
    final image = img.Image(width: 4, height: 4);
    img.fill(image, color: img.ColorRgb8(220, 30, 30));

    final color = pickSeedColor(image);

    expect(color, isNotNull);
    expect((color!.r * 255).round(), greaterThan(180));
    expect((color.g * 255).round(), lessThan(80));
    expect((color.b * 255).round(), lessThan(80));
  });

  test('pickSeedColor returns a neutral color for a pure gray image', () {
    final image = img.Image(width: 4, height: 4);
    img.fill(image, color: img.ColorRgb8(128, 128, 128));

    final color = pickSeedColor(image);

    expect(color, isNotNull);
    final r = (color!.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    expect((r - g).abs(), lessThan(12));
    expect((g - b).abs(), lessThan(12));
    expect((r - b).abs(), lessThan(12));
  });
}
