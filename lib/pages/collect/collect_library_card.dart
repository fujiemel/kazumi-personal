part of 'collect_library_view.dart';

class _CollectPosterCard extends StatelessWidget {
  const _CollectPosterCard({
    super.key,
    required this.entry,
    required this.showRating,
    required this.showStatus,
    required this.onOpen,
    required this.onChangeType,
    this.sequelNotice,
  });

  final CollectedBangumi entry;
  final bool showRating;
  final bool showStatus;
  final VoidCallback onOpen;
  final ValueChanged<CollectType>? onChangeType;
  final AiredSequel? sequelNotice;

  static const _coverRatio = 0.65;
  static bool _isCompact(double width) => width < 160;
  static double _titleHeight(TextScaler scaler, {bool compact = false}) =>
      (scaler.scale(compact ? 13 : 14) * 2.7).ceilToDouble();
  static double _detailsHeight(TextScaler scaler) =>
      (scaler.scale(12) * 1.4).ceilToDouble();
  static double _statusHeight(TextScaler scaler) =>
      (scaler.scale(11) * 1.4).ceilToDouble();
  static bool _stackCompactActions(double width, TextScaler scaler,
          {required bool showRating, required bool showStatus}) =>
      (showRating && scaler.scale(12) * 2.5 > width - 56) ||
      (showStatus && scaler.scale(11) * 2 > width - 56);
  static double _compactActionsHeight(double width, TextScaler scaler,
      {required bool showRating, required bool showStatus}) {
    final detailsHeight = (showRating ? _detailsHeight(scaler) : 0.0) +
        (showStatus ? _statusHeight(scaler) : 0.0) +
        (showRating && showStatus ? 2.0 : 0.0);
    return _stackCompactActions(width, scaler,
            showRating: showRating, showStatus: showStatus)
        ? detailsHeight + 48
        : detailsHeight.clamp(48.0, double.infinity);
  }

  static double extent(double width, TextScaler scaler,
      {required bool showRating, required bool showStatus}) {
    final footerHeight = _isCompact(width)
        ? 12 +
            _titleHeight(scaler, compact: true) +
            _compactActionsHeight(width, scaler,
                showRating: showRating, showStatus: showStatus)
        : 16 +
            (_titleHeight(scaler) +
                    (showRating || showStatus ? 4 + _detailsHeight(scaler) : 0))
                .clamp(48.0, double.infinity);
    return width / _coverRatio + footerHeight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    final item = entry.bangumiItem;
    final title = CollectLibraryQuery.titleOf(entry);
    final year = DateTime.tryParse(item.airDate)?.year;
    final type = CollectType.fromValue(entry.type);
    final hasRating = showRating && item.ratingScore > 0;
    final showDetails = showStatus || showRating;

    Widget detailLine(String value, {bool status = false}) => SizedBox(
          height: status ? _statusHeight(scaler) : _detailsHeight(scaler),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: status ? 11 : 12,
              height: 1.4,
              color: colors.onSurfaceVariant,
            ),
          ),
        );

    return LayoutBuilder(builder: (context, constraints) {
      final compact = _isCompact(constraints.maxWidth);
      final titleBlock = ExcludeSemantics(
        child: SizedBox(
          height: _titleHeight(scaler, compact: compact),
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: compact ? 13 : 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      final detailsBlock = ExcludeSemantics(
        child: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showRating)
                    detailLine(
                        hasRating ? item.ratingScore.toStringAsFixed(1) : ''),
                  if (showStatus) ...[
                    if (showRating) const SizedBox(height: 2),
                    detailLine(type.label, status: true),
                  ],
                ],
              )
            : detailLine([
                if (hasRating) '${item.ratingScore.toStringAsFixed(1)} 分',
                if (showStatus) type.label,
              ].join(' · ')),
      );
      final menu = _CollectEntryMenu(entry: entry, onChanged: onChangeType);
      final footer = compact
          ? Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: titleBlock,
                  ),
                  SizedBox(
                    height: _compactActionsHeight(constraints.maxWidth, scaler,
                        showRating: showRating, showStatus: showStatus),
                    child: _stackCompactActions(constraints.maxWidth, scaler,
                            showRating: showRating, showStatus: showStatus)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: detailsBlock,
                              ),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: menu,
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8),
                            child: Row(
                              children: [Expanded(child: detailsBlock), menu],
                            ),
                          ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 0, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleBlock,
                        if (showDetails) ...[
                          const SizedBox(height: 4),
                          detailsBlock,
                        ],
                      ],
                    ),
                  ),
                  menu,
                ],
              ),
            );

      return Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          label: [
            title,
            type.label,
            if (year != null) '$year 年',
            if (hasRating) '${item.ratingScore.toStringAsFixed(1)} 分',
            if (sequelNotice != null) '续作 ${sequelNotice!.title} 已开播',
          ].join('，'),
          child: InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExcludeSemantics(
                  child: AspectRatio(
                    aspectRatio: _coverRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _CollectCover(item: item),
                        if (sequelNotice != null)
                          PositionedDirectional(
                            top: 6,
                            start: 6,
                            child: _SequelBadge(
                              label: '续作',
                              tooltip: '续作已开播：${sequelNotice!.title}',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: footer),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _CollectListTile extends StatelessWidget {
  const _CollectListTile({
    super.key,
    required this.entry,
    required this.showRating,
    required this.onOpen,
    required this.onChangeType,
    this.history,
    this.onResume,
    this.sequelNotice,
    this.remoteEpisode,
    this.onResumeAtEpisode,
  });

  final CollectedBangumi entry;
  final bool showRating;
  final VoidCallback onOpen;
  final ValueChanged<CollectType>? onChangeType;
  final History? history;
  final VoidCallback? onResume;
  final AiredSequel? sequelNotice;
  final int? remoteEpisode;
  final ValueChanged<int>? onResumeAtEpisode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final item = entry.bangumiItem;
    final title = CollectLibraryQuery.titleOf(entry);
    final type = CollectType.fromValue(entry.type);
    final watched = history?.lastWatchEpisode ?? 0;
    final totalEpisodes = item.totalEpisodes;
    final remote = remoteEpisode;
    final remoteWatched = remote != null &&
            remote > watched &&
            (totalEpisodes <= 0 || remote <= totalEpisodes)
        ? remote
        : null;
    final progressStatus = episodeProgressStatus(
      item: item,
      watchedEpisode: watched,
    );
    final progress = progressStatus.label;
    final update = progressStatus.caughtUp || progressStatus.completed
        ? null
        : nextAiringLabel(
            airDate: item.airDate,
            airWeekday: item.airWeekday,
            airTime: item.airTime,
          );
    final Widget action;
    if (progressStatus.completed) {
      action = FilledButton.tonalIcon(
        onPressed: null,
        style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
        icon: const Icon(Icons.check_rounded, size: 18),
        label: const Text('已看完'),
      );
    } else if (progressStatus.caughtUp) {
      action = FilledButton.tonalIcon(
        onPressed: null,
        style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
        icon: const Icon(Icons.schedule_rounded, size: 18),
        label: Text(progressStatus.updateLabel ?? '等待更新'),
      );
    } else if (onResume != null) {
      // 进度已经在卡片正文显示，按钮不再重复集数。
      action = FilledButton.tonalIcon(
        onPressed: onResume,
        style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
        icon: const Icon(Icons.play_arrow_rounded, size: 18),
        label: const Text('继续观看'),
      );
    } else {
      action = FilledButton.tonalIcon(
        onPressed: onOpen,
        style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
        icon: const Icon(Icons.play_arrow_rounded, size: 18),
        label: const Text('开始观看'),
      );
    }
    final rating = showRating && item.ratingScore > 0
        ? '${item.ratingScore.toStringAsFixed(1)} 分'
        : null;
    final year = DateTime.tryParse(item.airDate)?.year;
    final meta = [
      if (year != null) '$year 年',
      ?rating,
      type.label,
    ].join(' · ');

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Keep menu and action focus outside the card's navigation tap area.
          Positioned.fill(
            child: Semantics(
              button: true,
              label: [
                title,
                progress,
                ?update,
                if (remoteWatched != null)
                  'Bangumi 已看到 $remoteWatched 集',
                if (sequelNotice != null) '续作 ${sequelNotice!.title} 已开播',
                meta,
              ].join('，'),
              child: InkWell(onTap: onOpen),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 86,
                      height: 128,
                      child: _CollectCover(
                        item: item,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ExcludeSemantics(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _CollectEntryMenu(
                            entry: entry,
                            onChanged: onChangeType,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ExcludeSemantics(
                        child: Text(
                          progress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (update != null) ...[
                        const SizedBox(height: 3),
                        ExcludeSemantics(
                          child: Text(
                            update,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 3),
                      ExcludeSemantics(
                        child: Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (remoteWatched != null) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onResumeAtEpisode == null
                              ? null
                              : () => onResumeAtEpisode!(remoteWatched),
                          child: Row(
                            children: [
                              Icon(
                                Icons.sync_rounded,
                                size: 15,
                                color: colors.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Bangumi 已看到 ${remoteWatched.toString().padLeft(2, '0')} · 从此继续',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.tertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (sequelNotice != null) ...[
                        const SizedBox(height: 4),
                        ExcludeSemantics(
                          child: Row(
                            children: [
                              Icon(
                                Icons.playlist_add_check_circle_rounded,
                                size: 15,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '续作已开播 · ${sequelNotice!.title}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: action,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectCover extends StatelessWidget {
  const _CollectCover({
    required this.item,
    this.borderRadius,
  });
  final BangumiItem item;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Hero(
          tag: item.id,
          transitionOnUserGestures: true,
          flightShuttleBuilder: NetworkImgLayer.heroFlightShuttleBuilder,
          child: NetworkImgLayer(
            src: item.images['large'] ?? item.images['common'] ?? '',
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            borderRadius: borderRadius,
          ),
        ),
      );
}

class _CollectEntryMenu extends StatelessWidget {
  const _CollectEntryMenu({
    required this.entry,
    required this.onChanged,
  });
  final CollectedBangumi entry;
  final ValueChanged<CollectType>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final type = CollectType.fromValue(entry.type);
    final title = CollectLibraryQuery.titleOf(entry);
    return KazumiMenuButton(
      enabled: onChanged != null,
      style: MenuStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        )),
      ),
      menuChildren: [
        for (final status
            in CollectType.values.where((type) => type.isCollected))
          KazumiMenuItem(
            selected: status == type,
            onPressed: onChanged == null || status == type
                ? null
                : () => onChanged!(status),
            label: status.label,
          ),
        const Divider(indent: 16, endIndent: 16),
        KazumiMenuItem(
          onPressed:
              onChanged == null ? null : () => onChanged!(CollectType.none),
          label: '取消收藏',
          destructive: true,
        ),
      ],
      builder: (context, toggle) {
        return IconButton(
          tooltip: '管理《$title》 · ${type.label}',
          onPressed: toggle,
          style: IconButton.styleFrom(
            foregroundColor: colors.onSurfaceVariant,
            minimumSize: const Size(48, 48),
            visualDensity: VisualDensity.standard,
          ),
          icon: const Icon(Icons.more_horiz_rounded, size: 20),
        );
      },
    );
  }
}

class _SequelBadge extends StatelessWidget {
  const _SequelBadge({required this.label, this.tooltip});

  final String label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.onPrimary,
          fontSize: 10,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (tooltip == null) return badge;
    return Tooltip(message: tooltip!, child: badge);
  }
}
