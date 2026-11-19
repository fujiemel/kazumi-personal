import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:window_manager/window_manager.dart';

import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;
import 'package:kazumi/bean/card/bangumi_info_card.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/dialog/adaptive_bottom_sheet.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/widget/collect_button.dart';
import 'package:kazumi/bean/widget/embedded_native_control_area.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/bangumi/episode_item.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/pages/info/info_actions_menu.dart';
import 'package:kazumi/pages/info/info_controller.dart';
import 'package:kazumi/pages/info/info_tabview.dart';
import 'package:kazumi/pages/info/rating_review_dialog.dart';
import 'package:kazumi/pages/info/source_sheet.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/request/apis/bangumi_api.dart';
import 'package:kazumi/services/bangumi/bangumi_episode_cache.dart';
import 'package:kazumi/services/bangumi/sequel_notice_service.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/platform/desktop_window_config.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/cover_color.dart';
import 'package:kazumi/utils/device.dart';
import 'package:kazumi/utils/history_lookup.dart';
import 'package:kazumi/utils/sequel_notice.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({
    super.key,
    required this.inputBangumiItem,
    required this.infoController,
    required this.pluginsController,
  });

  final BangumiItem inputBangumiItem;
  final InfoController infoController;
  final PluginsController pluginsController;

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage>
    with SingleTickerProviderStateMixin {
  static const List<String> _infoTabs = <String>[
    '概览',
    '吐槽',
    '角色',
    '关联',
    '制作人员',
  ];
  static const Duration _minimumBangumiInfoLoadingDuration =
      Duration(milliseconds: 600);

  InfoController get infoController => widget.infoController;
  late final TabController infoTabController;
  late final bool showRating;

  bool commentsIsLoading = false;
  bool charactersIsLoading = false;
  bool commentsQueryTimeout = false;
  bool commentsHasLoaded = false;
  bool charactersQueryTimeout = false;
  bool charactersIsEmpty = false;
  bool staffIsLoading = false;
  bool staffQueryTimeout = false;
  bool staffIsEmpty = false;
  bool _showBangumiInfoSkeleton = false;
  List<EpisodeInfo> episodeList = [];
  bool episodesLoading = false;
  bool episodesHasLoaded = false;
  Color? _coverSeed;
  bool _coverColorRequested = false;
  AiredSequel? _airedSequel;
  final BangumiEpisodeCache _episodeCache = inject<BangumiEpisodeCache>();
  final HistoryController _historyController = inject<HistoryController>();
  final CollectController _collectController = inject<CollectController>();

  bool get _isShowingBangumiInfoSkeleton =>
      infoController.isLoading || _showBangumiInfoSkeleton;

  bool _needsBangumiInfoRefresh(BangumiItem bangumiItem) {
    final votesCount = bangumiItem.votesCount;
    final missingVoteDistribution =
        votesCount.isEmpty || bangumiItem.votes <= 0 || votesCount.length < 10;
    return bangumiItem.summary == '' || missingVoteDistribution;
  }

  Future<void> loadCharacters() async {
    if (charactersIsLoading) return;
    setState(() {
      charactersIsLoading = true;
      charactersQueryTimeout = false;
      charactersIsEmpty = false;
    });
    try {
      await infoController
          .queryBangumiCharactersByID(infoController.bangumiItem.id);
      if (mounted) {
        setState(() {
          charactersIsLoading = false;
          if (infoController.characterList.isEmpty) {
            charactersIsEmpty = true;
          }
        });
      }
    } catch (e) {
      KazumiLogger().e('InfoPage: failed to load characters', error: e);
      if (mounted) {
        setState(() {
          charactersIsLoading = false;
          charactersQueryTimeout = true;
        });
      }
    }
  }

  Future<void> loadStaff() async {
    if (staffIsLoading) return;
    setState(() {
      staffIsLoading = true;
      staffQueryTimeout = false;
      staffIsEmpty = false;
    });
    try {
      await infoController
          .queryBangumiStaffsByID(infoController.bangumiItem.id);
      if (mounted) {
        setState(() {
          staffIsLoading = false;
          if (infoController.staffList.isEmpty) {
            staffIsEmpty = true;
          }
        });
      }
    } catch (e) {
      KazumiLogger().e('InfoPage: failed to load staff', error: e);
      if (mounted) {
        setState(() {
          staffIsLoading = false;
          staffQueryTimeout = true;
        });
      }
    }
  }

  Future<void> loadRelations() async {
    try {
      await infoController
          .queryBangumiRelationsByID(infoController.bangumiItem.id);
    } catch (e) {
      KazumiLogger().e('InfoPage: failed to load relations', error: e);
    }
  }

  Future<void> loadEpisodes() async {
    if (episodesLoading || episodesHasLoaded) return;
    final subjectId = infoController.bangumiItem.id;
    final cached = _episodeCache.get(subjectId);
    if (cached != null) {
      setState(() {
        episodeList = cached;
        episodesLoading = false;
        episodesHasLoaded = true;
      });
      return;
    }
    episodesLoading = true;
    try {
      final episodes = await BangumiApi.getBangumiEpisodesByID(subjectId).timeout(
        const Duration(seconds: 12),
        onTimeout: () => <EpisodeInfo>[],
      );
      _episodeCache.put(subjectId, episodes);
      if (mounted) {
        setState(() {
          episodeList = episodes;
          episodesLoading = false;
          episodesHasLoaded = true;
        });
      }
    } catch (e) {
      KazumiLogger().e('InfoPage: failed to load episodes', error: e);
      if (mounted) {
        setState(() {
          episodesLoading = false;
        });
      }
    }
  }

  Future<void> loadMoreComments({bool loadMore = false}) async {
    if (commentsIsLoading) return;
    setState(() {
      commentsIsLoading = true;
      commentsQueryTimeout = false;
    });
    try {
      await infoController.queryBangumiCommentsByID(
          infoController.bangumiItem.id,
          refresh: !loadMore);
      if (mounted) {
        setState(() {
          commentsIsLoading = false;
          commentsHasLoaded = true;
        });
      }
    } catch (e) {
      KazumiLogger().e('InfoPage: failed to load comments', error: e);
      if (mounted) {
        setState(() {
          commentsIsLoading = false;
          commentsQueryTimeout = true;
        });
      }
    }
  }

  Future<void> _openReviewEditor() async {
    final token =
        GStorage.getSetting(SettingsKeys.bangumiAccessToken).toString().trim();
    if (token.isEmpty) {
      KazumiDialog.showToast(message: '请先在同步设置中绑定 Bangumi');
      return;
    }
    final localType = infoController.collectController
        .getCollectType(infoController.bangumiItem);
    if (localType == 0) {
      KazumiDialog.showToast(message: '请先追番');
      return;
    }
    final editing =
        infoController.bangumiItem.interest?.hasReviewContent ?? false;
    final submitted = await KazumiDialog.show<bool>(
      context: context,
      builder: (context) => RatingReviewDialog(
        bangumiItem: infoController.bangumiItem,
        onSubmit: (review) =>
            infoController.rateBangumi(review, localType: localType),
      ),
    );
    if (submitted == true && mounted) {
      setState(() {});
      KazumiDialog.showToast(
        context: context,
        message: editing ? '吐槽已更新' : '吐槽已发表',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    infoController.bangumiItem = widget.inputBangumiItem;
    infoController.characterList.clear();
    infoController.clearComments();
    infoController.staffList.clear();
    infoController.clearRelations();
    infoController.pluginSearchResponseList.clear();
    episodeList = [];
    episodesLoading = false;
    episodesHasLoaded = false;
    if (_needsBangumiInfoRefresh(infoController.bangumiItem)) {
      _showBangumiInfoSkeleton = true;
      _loadBangumiInfo();
    }
    infoTabController = TabController(length: _infoTabs.length, vsync: this);
    showRating = GStorage.getSetting(SettingsKeys.showRating);
    infoTabController.addListener(onInfoTabChanged);
    _historyController.init();
    _collectController.loadCollectibles();
    loadEpisodes();
    unawaited(_loadAiredSequel());
    unawaited(_requestCoverColor());
  }

  Future<void> _requestCoverColor() async {
    if (_coverColorRequested) return;
    _coverColorRequested = true;
    final url = infoController.bangumiItem.images['large'] ??
        infoController.bangumiItem.images['common'];
    if (url == null || url.isEmpty) return;
    try {
      final color = await extractCoverSeedColor(url)
          .timeout(const Duration(milliseconds: 600));
      if (!mounted || color == null) return;
      setState(() {
        _coverSeed = color;
      });
    } catch (_) {}
  }

  void onInfoTabChanged() {
    final index = infoTabController.index;
    if (index == 1) {
      onCommentsTabSelected();
    }
    if (index == 2 &&
        infoController.characterList.isEmpty &&
        !charactersIsLoading &&
        !charactersIsEmpty &&
        !charactersQueryTimeout) {
      loadCharacters();
    }
    if (index == 3 && infoController.canLoadRelations) {
      loadRelations();
    }
    if (index == 4 &&
        infoController.staffList.isEmpty &&
        !staffIsLoading &&
        !staffIsEmpty &&
        !staffQueryTimeout) {
      loadStaff();
    }
  }

  Future<void> onCommentsTabSelected() async {
    final interest = infoController.bangumiItem.interest;
    final token =
        GStorage.getSetting(SettingsKeys.bangumiAccessToken).toString().trim();
    if (interest != null && token.isNotEmpty) {
      final updated = await infoController.fillInterestUserProfileIfNeeded();
      if (!mounted) return;
      if (updated) {
        setState(() {});
      }
    }
    if (infoController.commentsList.isEmpty &&
        !commentsIsLoading &&
        !commentsHasLoaded &&
        !commentsQueryTimeout) {
      loadMoreComments();
    }
  }

  @override
  void dispose() {
    infoTabController.removeListener(onInfoTabChanged);
    infoController.characterList.clear();
    infoController.clearComments();
    infoController.staffList.clear();
    infoController.clearRelations();
    infoController.pluginSearchResponseList.clear();
    infoTabController.dispose();
    super.dispose();
  }

  Future<void> _loadBangumiInfo() async {
    final loadingStartedAt = DateTime.now();
    try {
      // Attach metadata without replacing rendered image URLs.
      await infoController.queryBangumiInfoByID(
        infoController.bangumiItem.id,
        type: 'attach',
      );
    } catch (e) {
      KazumiLogger()
          .e('InfoPage: failed to query bangumi info by ID', error: e);
    } finally {
      if (mounted) {
        await _waitForMinimumBangumiInfoLoadingDuration(loadingStartedAt);
      }
      if (mounted) {
        setState(() {
          _showBangumiInfoSkeleton = false;
        });
      }
    }
  }

  Future<void> _loadAiredSequel() async {
    final item = infoController.bangumiItem;
    final notice = await SequelNoticeService.instance.noticeFor(
      item,
      collectedIds: _collectController.collectibles
          .map((entry) => entry.bangumiItem.id)
          .toSet(),
    );
    if (!mounted || infoController.bangumiItem.id != item.id) return;
    if (identical(_airedSequel, notice)) return;
    setState(() => _airedSequel = notice);
  }

  Future<void> _collectAiredSequel(AiredSequel sequel) async {
    await _collectController.addCollect(
      sequel.item,
      type: CollectType.watching.value,
    );
    if (!mounted) return;
    if (_collectController.getCollectType(sequel.item) == 0) return;
    KazumiDialog.showToast(message: '已加入在看：${sequel.title}');
  }

  void _startWatching() {
    if (widget.pluginsController.pluginList.isEmpty) {
      KazumiDialog.showToast(
        message: '还没有规则，无法开始观看',
        showActionButton: true,
        actionLabel: '添加规则',
        onActionPressed: () {
          if (mounted) context.pushNamed('/settings/plugin/');
        },
        duration: const Duration(seconds: 4),
      );
      return;
    }
    showAdaptiveBottomSheet<void>(
      context: context,
      maxHeightFactor: 0.88,
      builder: (_) => SourceSheet(infoController: infoController),
    );
  }

  Future<void> _waitForMinimumBangumiInfoLoadingDuration(
      DateTime loadingStartedAt) async {
    final elapsed = DateTime.now().difference(loadingStartedAt);
    final remaining = _minimumBangumiInfoLoadingDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final pageTheme = _coverSeed == null
        ? baseTheme
        : baseTheme.copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _coverSeed!,
              brightness: baseTheme.brightness,
            ),
          );
    final showWindowButton = DesktopWindowConfig.showWindowButton;
    final topOffset = Platform.isMacOS && showWindowButton ? 22.0 : 0.0;
    return Theme(
      data: pageTheme,
      child: Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar.medium(
                title: EmbeddedNativeControlArea(
                  child: dtb.DragToMoveArea(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        infoController.bangumiItem.nameCn == ''
                            ? infoController.bangumiItem.name
                            : infoController.bangumiItem.nameCn,
                      ),
                    ),
                  ),
                ),
                automaticallyImplyLeading: false,
                scrolledUnderElevation: 0.0,
                leading: EmbeddedNativeControlArea(
                  child: IconButton(
                    onPressed: () {
                      context.maybePop();
                    },
                    icon: Icon(Icons.arrow_back),
                  ),
                ),
                actions: [
                  if (innerBoxIsScrolled)
                    EmbeddedNativeControlArea(
                      child: CollectButton(
                        bangumiItem: infoController.bangumiItem,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  EmbeddedNativeControlArea(
                    child: InfoActionsMenu(
                      bangumiItem: infoController.bangumiItem,
                    ),
                  ),
                  if (isDesktop() && !showWindowButton)
                    CloseButton(onPressed: () => windowManager.close()),
                  SizedBox(width: 8),
                ],
                toolbarHeight: kToolbarHeight + topOffset,
                stretch: true,
                centerTitle: false,
                expandedHeight:
                    308 + kTextTabBarHeight + kToolbarHeight + topOffset,
                collapsedHeight: kTextTabBarHeight +
                    kToolbarHeight +
                    MediaQuery.paddingOf(context).top +
                    topOffset,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Observer(builder: (context) {
                    final showBangumiInfoSkeleton =
                        _isShowingBangumiInfoSkeleton;
                    return Stack(
                      children: [
                        if (!showBangumiInfoSkeleton)
                          Positioned.fill(
                            bottom: kTextTabBarHeight,
                            child: IgnorePointer(
                              child: _InfoHeaderBackground(
                                imageUrl: infoController
                                        .bangumiItem.images['large'] ??
                                    '',
                                overlayColor: pageTheme.colorScheme.surface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        SafeArea(
                          bottom: false,
                          child: EmbeddedNativeControlArea(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, kToolbarHeight, 16, 0),
                                child: BangumiInfoCardV(
                                  bangumiItem: infoController.bangumiItem,
                                  isLoading: showBangumiInfoSkeleton,
                                  showRating: showRating,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                forceElevated: innerBoxIsScrolled,
                bottom: TabBar(
                  controller: infoTabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  dividerHeight: 0,
                  tabs: _infoTabs.map((name) => Tab(text: name)).toList(),
                ),
              ),
            ),
          ];
        },
        body: Observer(builder: (context) {
          final showBangumiInfoSkeleton = _isShowingBangumiInfoSkeleton;
          final latestHistories =
              latestHistoryByBangumi(_historyController.histories);
          final watchedEpisode =
              latestHistories[infoController.bangumiItem.id]?.lastWatchEpisode ??
                  0;
          final collectTypes = <int, CollectType>{
            for (final entry in _collectController.collectibles)
              entry.bangumiItem.id: CollectType.fromValue(entry.type),
          };
          final airedSequel = _airedSequel != null &&
                  !_collectController.collectibles
                      .any((entry) =>
                          entry.bangumiItem.id == _airedSequel!.item.id)
              ? _airedSequel
              : null;
          return InfoTabView(
            tabController: infoTabController,
            bangumiItem: infoController.bangumiItem,
            commentsQueryTimeout: commentsQueryTimeout,
            commentsHasLoaded: commentsHasLoaded,
            charactersQueryTimeout: charactersQueryTimeout,
            charactersIsEmpty: charactersIsEmpty,
            staffQueryTimeout: staffQueryTimeout,
            staffIsEmpty: staffIsEmpty,
            loadMoreComments: loadMoreComments,
            loadCharacters: loadCharacters,
            loadStaff: loadStaff,
            commentsList: infoController.commentsList.toList(growable: false),
            commentsIsLoading: commentsIsLoading,
            onWriteReview: _openReviewEditor,
            characterList: infoController.characterList,
            staffList: infoController.staffList,
            relationList: infoController.relationList,
            relationsIsLoading: infoController.relationsIsLoading,
            relationsQueryTimeout: infoController.relationsQueryTimeout,
            relationsHasLoaded: infoController.relationsHasLoaded,
            loadRelations: loadRelations,
            episodes: episodeList,
            episodesLoading: episodesLoading,
            watchedEpisode: watchedEpisode,
            isLoading: showBangumiInfoSkeleton,
            airedSequel: airedSequel,
            collectTypes: collectTypes,
            onCollectSequel: _collectAiredSequel,
            onOpenSequel: (item) =>
                context.pushNamed('/info/', arguments: item),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: '开始观看',
        onPressed: _startWatching,
        label: const Text('开始观看'),
        icon: const Icon(Icons.play_arrow_rounded),
      ),
      ),
    );
  }
}

class _InfoHeaderBackground extends StatelessWidget {
  const _InfoHeaderBackground({
    required this.imageUrl,
    required this.overlayColor,
  });

  static const double _downsample = 0.5;
  static const double _blurSigma = 18.0;
  static const double _opacity = 0.4;
  static const double _edgeBleed = 32.0;
  static const double _bottomFeatherHeight = 48.0;

  final String imageUrl;
  final Color overlayColor;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width <= 0 || height <= 0) {
          return const SizedBox.shrink();
        }

        final rasterWidth = width * _downsample;
        final rasterHeight = (height + _edgeBleed) * _downsample;

        final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: [0.8, 1],
                  ).createShader(bounds);
                },
                child: Align(
                  alignment: Alignment.topCenter,
                  child: RepaintBoundary(
                    child: Transform.scale(
                      scale: 1 / _downsample,
                      alignment: Alignment.topCenter,
                      filterQuality: FilterQuality.low,
                      child: SizedBox(
                        width: rasterWidth,
                        height: rasterHeight,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: _blurSigma * _downsample,
                            sigmaY: _blurSigma * _downsample,
                          ),
                          child: NetworkImgLayer(
                            src: imageUrl,
                            width: rasterWidth,
                            height: rasterHeight,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            filterQuality: FilterQuality.low,
                            color: Colors.white.withValues(alpha: _opacity),
                            colorBlendMode: BlendMode.modulate,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ColoredBox(color: overlayColor),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _bottomFeatherHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        backgroundColor.withValues(alpha: 0),
                        backgroundColor.withValues(alpha: 0.55),
                        backgroundColor,
                      ],
                      stops: const [0, 0.72, 1],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
