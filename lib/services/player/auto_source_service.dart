import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/roads/road_module.dart';
import 'package:kazumi/modules/search/plugin_search_module.dart';
import 'package:kazumi/pages/video/video_playback_args.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/plugin/rule_engine_models.dart'
    show RuleCancelToken;
import 'package:kazumi/utils/episode_match.dart';

/// Tries the last used source first, then probes the user's sources in order
/// until one has the target episode.
class AutoSourceService {
  AutoSourceService(this._pluginsController);

  final PluginsController _pluginsController;

  Future<OnlineVideoPlaybackArgs?> resolve({
    required BangumiItem bangumiItem,
    required int targetEpisode,
    String? preferredPluginName,
    String? preferredSrc,
    int? positionSeconds,
    RuleCancelToken? cancelToken,
  }) async {
    if (_isCancelled(cancelToken)) return null;

    final keyword =
        bangumiItem.nameCn.isNotEmpty ? bangumiItem.nameCn : bangumiItem.name;

    Plugin? preferredPlugin;
    if (preferredPluginName != null &&
        preferredPluginName.isNotEmpty &&
        preferredSrc != null &&
        preferredSrc.isNotEmpty) {
      for (final plugin in _pluginsController.pluginList) {
        if (plugin.name == preferredPluginName) {
          preferredPlugin = plugin;
          break;
        }
      }
      if (preferredPlugin != null) {
        try {
          final roads = await preferredPlugin.queryChapterRoads(
            preferredSrc,
            cancelToken: cancelToken,
          );
          if (_isCancelled(cancelToken)) return null;
          if (roads.isNotEmpty &&
              _hasExactEpisode(roads, targetEpisode)) {
            return OnlineVideoPlaybackArgs(
              bangumiItem: bangumiItem,
              plugin: preferredPlugin,
              title: keyword,
              src: preferredSrc,
              roads: roads,
              episodeNumber: targetEpisode,
              positionSeconds: positionSeconds,
            );
          }
        } catch (error) {
          KazumiLogger().w(
            'AutoSourceService: failed to query preferred source',
            error: error,
          );
        }
      }
    }

    for (final plugin in _pluginsController.pluginList) {
      if (_isCancelled(cancelToken)) return null;
      if (identical(plugin, preferredPlugin)) continue;

      PluginSearchResponse response;
      try {
        response = await plugin.queryBangumi(
          keyword,
          cancelToken: cancelToken,
        );
      } catch (error) {
        KazumiLogger().w(
          'AutoSourceService: failed to search source ${plugin.name}',
          error: error,
        );
        continue;
      }
      if (_isCancelled(cancelToken)) return null;
      if (response.data.isEmpty) continue;

      final item = pickSearchItem(
        response.data,
        [bangumiItem.nameCn, bangumiItem.name],
      );
      if (item == null) continue;

      List<Road> roads;
      try {
        roads = await plugin.queryChapterRoads(
          item.src,
          cancelToken: cancelToken,
        );
      } catch (error) {
        KazumiLogger().w(
          'AutoSourceService: failed to query source ${plugin.name}',
          error: error,
        );
        continue;
      }
      if (_isCancelled(cancelToken)) return null;
      if (roads.isEmpty || !_hasExactEpisode(roads, targetEpisode)) {
        continue;
      }

      return OnlineVideoPlaybackArgs(
        bangumiItem: bangumiItem,
        plugin: plugin,
        title: item.name,
        src: item.src,
        roads: roads,
        episodeNumber: targetEpisode,
        positionSeconds: positionSeconds,
      );
    }

    return null;
  }
}

bool _isCancelled(RuleCancelToken? cancelToken) =>
    cancelToken?.isCancelled ?? false;

bool _hasExactEpisode(List<Road> roads, int targetEpisode) {
  final match = findEpisodeInIdentifiers(
    [for (final road in roads) road.identifier],
    targetEpisode,
  );
  return match?.exact == true;
}

SearchItem? pickSearchItem(List<SearchItem> items, List<String> names) {
  final targets = [
    for (final name in names)
      if (_normalize(name).isNotEmpty) _normalize(name),
  ];

  for (final item in items) {
    final normalized = _normalize(item.name);
    if (normalized.isEmpty) continue;
    if (targets.any((target) => normalized == target)) {
      return item;
    }
  }

  for (final item in items) {
    final normalized = _normalize(item.name);
    if (normalized.isEmpty) continue;
    if (targets.any(
      (target) => normalized.contains(target) || target.contains(normalized),
    )) {
      return item;
    }
  }

  return items.isEmpty ? null : items.first;
}

String _normalize(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
