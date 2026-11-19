import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/dialog/adaptive_bottom_sheet.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/dialog/dialog_task.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/pages/info/info_controller.dart';
import 'package:kazumi/pages/info/source_sheet.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/services/player/auto_source_service.dart';
import 'package:kazumi/services/plugin/rule_engine_models.dart'
    show RuleCancelToken;
import 'package:kazumi/utils/device.dart';

/// Opens the source picker for a subject.
///
/// [continueEpisodeNumber] carries the canonical episode number from history so
/// the selected source can resume the same episode instead of episode 1.
Future<void> showSourceSheetForBangumi(
  BuildContext context,
  BangumiItem item, {
  int? continueEpisodeNumber,
  int? continuePositionSeconds,
}) async {
  final plugins = inject<PluginsController>();
  if (plugins.pluginList.isEmpty) {
    KazumiDialog.showToast(message: '还没有规则，无法开始观看');
    return;
  }
  final controller = InfoController(inject<CollectController>())
    ..bangumiItem = item;
  await showAdaptiveBottomSheet<void>(
    context: context,
    maxHeightFactor: 0.88,
    builder: (_) => SourceSheet(
      infoController: controller,
      continueEpisodeNumber: continueEpisodeNumber,
      continuePositionSeconds: continuePositionSeconds,
    ),
  );
}

/// Resumes playback by automatically choosing a source before falling back to
/// the manual picker.
Future<void> resumeWithAutoSource(
  BuildContext context,
  KazumiDialogController dialogs,
  BangumiItem item, {
  required int episodeNumber,
  int? positionSeconds,
  String? preferredPluginName,
  String? preferredSrc,
}) async {
  final plugins = inject<PluginsController>();
  if (plugins.pluginList.isEmpty) {
    KazumiDialog.showToast(message: '还没有规则，无法开始观看');
    return;
  }
  await dialogs.run((task) async {
    final token = RuleCancelToken();
    final args = await task.loading(
      message: '正在自动选择播放源',
      barrierDismissible: isDesktop(),
      onCancel: token.cancel,
      action: () => AutoSourceService(inject<PluginsController>()).resolve(
        bangumiItem: item,
        targetEpisode: episodeNumber,
        preferredPluginName: preferredPluginName,
        preferredSrc: preferredSrc,
        positionSeconds: positionSeconds,
        cancelToken: token,
      ),
    );
    if (args != null) {
      task.withContext(
        (ctx) => ctx.pushNamed('/video/', arguments: args),
      );
    } else {
      task.withContext(
        (ctx) => unawaited(
          showSourceSheetForBangumi(
            ctx,
            item,
            continueEpisodeNumber: episodeNumber,
            continuePositionSeconds: positionSeconds,
          ),
        ),
      );
    }
  });
}
