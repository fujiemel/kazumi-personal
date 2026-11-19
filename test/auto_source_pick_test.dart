import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/search/plugin_search_module.dart';
import 'package:kazumi/services/player/auto_source_service.dart';

SearchItem _item(String name) => SearchItem(name: name, src: 'src');

void main() {
  group('pickSearchItem', () {
    test('prefers an exact normalized name match', () {
      final items = [_item('其他番'), _item('葬送的芙莉莲')];

      expect(pickSearchItem(items, ['葬送的芙莉莲']), same(items[1]));
    });

    test('falls back to a containing name match', () {
      final items = [_item('芙莉莲 第二季')];

      expect(pickSearchItem(items, ['芙莉莲']), same(items[0]));
    });

    test('falls back to the first item when nothing matches', () {
      final items = [_item('甲'), _item('乙')];

      expect(pickSearchItem(items, ['丙']), same(items[0]));
    });

    test('returns null for an empty list', () {
      expect(pickSearchItem(<SearchItem>[], ['丙']), isNull);
    });
  });
}
