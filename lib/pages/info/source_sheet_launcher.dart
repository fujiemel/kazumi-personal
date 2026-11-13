import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/dialog/adaptive_bottom_sheet.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/pages/info/info_controller.dart';
import 'package:kazumi/pages/info/source_sheet.dart';
import 'package:kazumi/plugins/plugins_controller.dart';

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
