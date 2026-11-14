import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/request/config/api_endpoints.dart';
import 'package:kazumi/services/update/update_download_source.dart';
import 'package:kazumi/services/update/update_downloader.dart';

void main() {
  test('prefers an explicit mirror download url', () {
    final asset = {
      'mirror_download_url': 'https://mirror.example/app.apk',
      'browser_download_url': 'https://github.com/example/app.apk',
    };

    expect(
      getUpdateDownloadUrlFromAsset(asset, UpdateDownloadSource.mirror),
      'https://mirror.example/app.apk',
    );
  });

  test('falls back to the GitHub asset through gh-proxy', () {
    final asset = {
      'browser_download_url': 'https://github.com/example/app.apk',
    };

    expect(
      getUpdateDownloadUrlFromAsset(asset, UpdateDownloadSource.mirror),
      '${ApiEndpoints.ghProxyMirror}https://github.com/example/app.apk',
    );
  });

  test('uses the GitHub asset directly', () {
    final asset = {
      'browser_download_url': 'https://github.com/example/app.apk',
    };

    expect(
      getUpdateDownloadUrlFromAsset(asset, UpdateDownloadSource.github),
      'https://github.com/example/app.apk',
    );
  });

  test('returns an empty string when no download url exists', () {
    expect(getUpdateDownloadUrlFromAsset(null, UpdateDownloadSource.mirror), '');
    expect(getUpdateDownloadUrlFromAsset(const {}, UpdateDownloadSource.github), '');
  });
}
