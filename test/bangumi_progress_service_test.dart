import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/bangumi/bangumi_collection.dart';
import 'package:kazumi/modules/bangumi/bangumi_collection_type.dart';
import 'package:kazumi/services/bangumi/bangumi_progress_service.dart';

void main() {
  test('maps ep_status and ignores unstarted subjects', () async {
    var calls = 0;
    final service = BangumiProgressService(
      fetchCollections: () async {
        calls++;
        return [_collection(1, 8), _collection(2, 0), _collection(3, 12)];
      },
      isEnabled: () => true,
    );

    await service.refresh();

    expect(calls, 1);
    expect(service.episodes, {1: 8, 3: 12});
  });

  test('respects the ttl and supports forced refresh', () async {
    var calls = 0;
    var now = DateTime(2026, 11, 14, 12);
    final service = BangumiProgressService(
      ttl: const Duration(minutes: 10),
      clock: () => now,
      fetchCollections: () async {
        calls++;
        return [_collection(1, calls)];
      },
      isEnabled: () => true,
    );

    await service.refresh();
    await service.refresh();
    expect(calls, 1);
    expect(service.episodes[1], 1);

    now = now.add(const Duration(minutes: 11));
    await service.refresh();
    expect(calls, 2);
    expect(service.episodes[1], 2);

    await service.refresh(force: true);
    expect(calls, 3);
  });

  test('keeps previous data when a refresh fails', () async {
    var fail = false;
    final service = BangumiProgressService(
      fetchCollections: () async {
        if (fail) throw StateError('offline');
        return [_collection(1, 5)];
      },
      isEnabled: () => true,
    );
    await service.refresh();
    expect(service.episodes, {1: 5});

    fail = true;
    await service.refresh(force: true);
    expect(service.episodes, {1: 5});
  });

  test('does nothing when Bangumi sync is disabled', () async {
    var calls = 0;
    final service = BangumiProgressService(
      fetchCollections: () async {
        calls++;
        return [_collection(1, 5)];
      },
      isEnabled: () => false,
    );

    await service.refresh();

    expect(calls, 0);
    expect(service.episodes, isEmpty);
  });
}

BangumiCollection _collection(int id, int epStatus) => BangumiCollection(
      id,
      '2024-01-01',
      DateTime(2024, 1, 1),
      BangumiCollectionType.watching,
      'Subject $id',
      '番剧 $id',
      '',
      0,
      12,
      0,
      const {'large': ''},
      const [],
      epStatus: epStatus,
    );
