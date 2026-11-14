import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/card/bangumi_air_info_card.dart';
import 'package:kazumi/bean/card/bangumi_episode_grid.dart';
import 'package:kazumi/bean/widget/error_widget.dart';
import 'package:kazumi/bean/widget/empty_state_widget.dart';
import 'package:kazumi/pages/info/info_comments_view.dart';
import 'package:kazumi/bean/card/character_card.dart';
import 'package:kazumi/bean/card/staff_card.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/bangumi/bangumi_relation.dart';
import 'package:kazumi/modules/bangumi/episode_item.dart';
import 'package:kazumi/modules/comments/comment_item.dart';
import 'package:kazumi/modules/characters/character_item.dart';
import 'package:kazumi/modules/staff/staff_item.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/utils/device.dart';
import 'package:kazumi/utils/sequel_notice.dart';

class InfoTabView extends StatefulWidget {
  const InfoTabView({
    super.key,
    required this.commentsQueryTimeout,
    required this.commentsHasLoaded,
    required this.charactersQueryTimeout,
    required this.charactersIsEmpty,
    required this.staffQueryTimeout,
    required this.staffIsEmpty,
    required this.relationsQueryTimeout,
    required this.relationsIsLoading,
    required this.relationsHasLoaded,
    required this.tabController,
    required this.loadMoreComments,
    required this.loadCharacters,
    required this.loadStaff,
    required this.loadRelations,
    required this.bangumiItem,
    required this.commentsList,
    required this.commentsIsLoading,
    required this.onWriteReview,
    required this.characterList,
    required this.staffList,
    required this.relationList,
    required this.episodes,
    required this.episodesLoading,
    required this.watchedEpisode,
    required this.isLoading,
    this.airedSequel,
    this.onCollectSequel,
    this.onOpenSequel,
  });

  final bool commentsQueryTimeout;
  final bool commentsHasLoaded;
  final bool commentsIsLoading;
  final VoidCallback onWriteReview;
  final bool charactersQueryTimeout;
  final bool charactersIsEmpty;
  final bool staffQueryTimeout;
  final bool staffIsEmpty;
  final bool relationsQueryTimeout;
  final bool relationsIsLoading;
  final bool relationsHasLoaded;
  final TabController tabController;
  final Future<void> Function({bool loadMore}) loadMoreComments;
  final Future<void> Function() loadCharacters;
  final Future<void> Function() loadStaff;
  final Future<void> Function() loadRelations;
  final BangumiItem bangumiItem;
  final List<CommentItem> commentsList;
  final List<CharacterItem> characterList;
  final List<StaffFullItem> staffList;
  final List<BangumiRelation> relationList;
  final List<EpisodeInfo> episodes;
  final bool episodesLoading;
  final int watchedEpisode;
  final bool isLoading;
  final AiredSequel? airedSequel;
  final ValueChanged<AiredSequel>? onCollectSequel;
  final ValueChanged<BangumiItem>? onOpenSequel;

  @override
  State<InfoTabView> createState() => _InfoTabViewState();
}

class _InfoTabViewState extends State<InfoTabView> {
  final maxWidth = 950.0;
  bool fullIntro = false;
  bool fullTag = false;

  Widget get overviewContent {
    final mainEpisodeCount = widget.episodes.where((e) => e.type == 0).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.airedSequel case final sequel?) ...[
          _AiredSequelBanner(
            sequel: sequel,
            onOpen: widget.onOpenSequel,
            onCollect: widget.onCollectSequel,
          ),
          const SizedBox(height: 20),
        ],
        Text('简介', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final span = TextSpan(text: widget.bangumiItem.summary);
          final tp =
              TextPainter(text: span, textDirection: TextDirection.ltr);
          tp.layout(maxWidth: constraints.maxWidth);
          final numLines = tp.computeLineMetrics().length;
          if (numLines > 7) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  height: fullIntro ? null : 120,
                  width: constraints.maxWidth,
                  child: SelectableText(
                    widget.bangumiItem.summary,
                    textAlign: TextAlign.start,
                    scrollBehavior: const ScrollBehavior().copyWith(
                      scrollbars: false,
                    ),
                    scrollPhysics: NeverScrollableScrollPhysics(),
                    selectionHeightStyle: ui.BoxHeightStyle.max,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      fullIntro = !fullIntro;
                    });
                  },
                  child: Text(fullIntro ? '加载更少' : '加载更多'),
                ),
              ],
            );
          } else {
            return SelectableText(
              widget.bangumiItem.summary,
              textAlign: TextAlign.start,
              scrollPhysics: NeverScrollableScrollPhysics(),
              selectionHeightStyle: ui.BoxHeightStyle.max,
            );
          }
        }),
        if (widget.episodesLoading || widget.episodes.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Text('剧集', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              if (widget.episodes.isNotEmpty)
                Text(
                  '共 $mainEpisodeCount 话',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          BangumiEpisodeGrid(
            episodes: widget.episodes,
            watchedEpisode: widget.watchedEpisode,
            isLoading: widget.episodesLoading,
          ),
        ],
        const SizedBox(height: 20),
        Text('标签', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: isDesktop() ? 8 : 0,
          children: List<Widget>.generate(
              fullTag || widget.bangumiItem.tags.length < 13
                  ? widget.bangumiItem.tags.length
                  : 13, (int index) {
            if (!fullTag && index == 12) {
              return ActionChip(
                label: Text(
                  '更多 +',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary),
                ),
                onPressed: () {
                  setState(() {
                    fullTag = !fullTag;
                  });
                },
              );
            }
            return ActionChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${widget.bangumiItem.tags[index].name} '),
                  Text(
                    '${widget.bangumiItem.tags[index].count}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
              onPressed: () {
                final tagName = Uri.encodeComponent(
                    widget.bangumiItem.tags[index].name);
                context.pushNamed('/search/$tagName');
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget get infoBody {
    final wide = MediaQuery.sizeOf(context).width > 900;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width > maxWidth
              ? maxWidth
              : MediaQuery.sizeOf(context).width - 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: overviewContent),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 280,
                      child:
                          BangumiAirInfoCard(bangumiItem: widget.bangumiItem),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BangumiAirInfoCard(bangumiItem: widget.bangumiItem),
                    const SizedBox(height: 20),
                    overviewContent,
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget get relationsListBody {
    return Builder(
      builder: (BuildContext context) {
        return CustomScrollView(
          scrollBehavior: const ScrollBehavior().copyWith(
            scrollbars: false,
          ),
          key: const PageStorageKey<String>('关联'),
          slivers: <Widget>[
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverLayoutBuilder(
              builder: (context, constraints) {
                if (widget.relationsQueryTimeout) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: GeneralErrorWidget(
                      title: '关联条目加载失败',
                      errMsg: '请检查网络连接后重试。',
                      onRetry: widget.loadRelations,
                    ),
                  );
                }
                if (widget.relationsHasLoaded && widget.relationList.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: GeneralEmptyState(
                      icon: Icons.account_tree_rounded,
                      title: '暂无关联条目',
                    ),
                  );
                }

                final horizontalPadding =
                    ((constraints.crossAxisExtent - maxWidth) / 2)
                        .clamp(16.0, double.infinity)
                        .toDouble();
                final contentWidth =
                    constraints.crossAxisExtent - horizontalPadding * 2;
                final crossAxisCount = contentWidth >= 840
                    ? 3
                    : contentWidth >= 560
                        ? 2
                        : 1;
                final showSkeleton =
                    !widget.relationsHasLoaded || widget.relationsIsLoading;
                final itemCount =
                    showSkeleton ? crossAxisCount : widget.relationList.length;

                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    16,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: StyleString.cardSpace,
                      crossAxisSpacing: StyleString.cardSpace,
                      mainAxisExtent: _RelatedBangumiCardH.cardHeight,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (showSkeleton) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return Skeletonizer.zone(
                                child: Bone(
                                  width: constraints.maxWidth,
                                  height: _RelatedBangumiCardH.cardHeight,
                                  uniRadius: 14,
                                ),
                              );
                            },
                          );
                        }
                        return _RelatedBangumiCardH(
                          relation: widget.relationList[index],
                        );
                      },
                      childCount: itemCount,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget get infoBodyBone {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width > maxWidth
              ? maxWidth
              : MediaQuery.sizeOf(context).width - 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeletonizer.zone(child: Bone.text(fontSize: 18, width: 50)),
              const SizedBox(height: 8),
              Skeletonizer.zone(child: Bone.multiText(lines: 7)),
              const SizedBox(height: 16),
              Skeletonizer.zone(child: Bone.text(fontSize: 18, width: 50)),
              const SizedBox(height: 8),
              if (widget.isLoading)
                Skeletonizer.zone(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: List.generate(
                        4, (_) => Bone.button(uniRadius: 8, height: 32)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget get staffListBody {
    return Builder(
      builder: (BuildContext context) {
        return CustomScrollView(
          scrollBehavior: const ScrollBehavior().copyWith(
            scrollbars: false,
          ),
          key: PageStorageKey<String>('制作人员'),
          slivers: <Widget>[
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverLayoutBuilder(builder: (context, _) {
              if (widget.staffList.isNotEmpty) {
                return SliverList.builder(
                  itemCount: widget.staffList.length,
                  itemBuilder: (context, index) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: MediaQuery.sizeOf(context).width > maxWidth
                              ? maxWidth
                              : MediaQuery.sizeOf(context).width - 32,
                          child: StaffCard(
                            staffFullItem: widget.staffList[index],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              if (widget.staffQueryTimeout) {
                return SliverFillRemaining(
                  child: GeneralErrorWidget(
                    title: '制作人员加载失败',
                    errMsg: '请检查网络连接后重试。',
                    onRetry: widget.loadStaff,
                  ),
                );
              }
              if (widget.staffIsEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: GeneralEmptyState(
                    icon: Icons.groups_rounded,
                    title: '暂无制作人员信息',
                  ),
                );
              }
              return SliverList.builder(
                itemCount: 8,
                itemBuilder: (context, _) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width > maxWidth
                          ? maxWidth
                          : MediaQuery.sizeOf(context).width - 32,
                      child: Skeletonizer.zone(
                        child: ListTile(
                          leading: Bone.circle(size: 36),
                          title: Bone.text(width: 100),
                          subtitle: Bone.text(width: 80),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }

  Widget get charactersListBody {
    return Builder(
      builder: (BuildContext context) {
        return CustomScrollView(
          scrollBehavior: const ScrollBehavior().copyWith(
            scrollbars: false,
          ),
          key: PageStorageKey<String>('角色'),
          slivers: <Widget>[
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverLayoutBuilder(builder: (context, _) {
              if (widget.characterList.isNotEmpty) {
                return SliverList.builder(
                  itemCount: widget.characterList.length,
                  itemBuilder: (context, index) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: MediaQuery.sizeOf(context).width > maxWidth
                              ? maxWidth
                              : MediaQuery.sizeOf(context).width - 32,
                          child: CharacterCard(
                            characterItem: widget.characterList[index],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              if (widget.charactersQueryTimeout) {
                return SliverFillRemaining(
                  child: GeneralErrorWidget(
                    title: '角色列表加载失败',
                    errMsg: '请检查网络连接后重试。',
                    onRetry: widget.loadCharacters,
                  ),
                );
              }
              if (widget.charactersIsEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: GeneralEmptyState(
                    icon: Icons.people_alt_rounded,
                    title: '暂无角色信息',
                  ),
                );
              }
              return SliverList.builder(
                itemCount: 4,
                itemBuilder: (context, _) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width > maxWidth
                          ? maxWidth
                          : MediaQuery.sizeOf(context).width - 32,
                      child: Skeletonizer.zone(
                        child: ListTile(
                          leading: Bone.circle(size: 36),
                          title: Bone.text(width: 100),
                          subtitle: Bone.text(width: 80),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: widget.tabController,
      children: [
        Builder(
          // Resolve the overlap handle inside the NestedScrollView.
          builder: (BuildContext context) {
            return CustomScrollView(
              scrollBehavior: const ScrollBehavior().copyWith(
                scrollbars: false,
              ),
              key: PageStorageKey<String>('概览'),
              slivers: <Widget>[
                SliverOverlapInjector(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                ),
                SliverToBoxAdapter(
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: widget.isLoading ? infoBodyBone : infoBody,
                  ),
                ),
              ],
            );
          },
        ),
        InfoCommentsView(
          interest: widget.bangumiItem.interest,
          comments: widget.commentsList,
          isLoading: widget.commentsIsLoading,
          hasLoaded: widget.commentsHasLoaded,
          hasError: widget.commentsQueryTimeout,
          onReviewTap: widget.onWriteReview,
          onRetry: () => widget.loadMoreComments(loadMore: false),
          onLoadMore: () => widget.loadMoreComments(loadMore: true),
        ),
        charactersListBody,
        relationsListBody,
        staffListBody,
      ],
    );
  }
}

class _RelatedBangumiCardH extends StatelessWidget {
  const _RelatedBangumiCardH({required this.relation});

  static const double cardHeight = 108;
  static const double imageHeight = 92;
  static const double posterAspectRatio = 0.65;

  final BangumiRelation relation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScaler =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1);
    final relationLabel = relation.relation.isEmpty ? '关联' : relation.relation;
    final bangumiItem = relation.toBangumiItem();
    final title = bangumiItem.nameCn.isEmpty
        ? bangumiItem.name.trim()
        : bangumiItem.nameCn.trim();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: () {
          context.pushNamed('/info/', arguments: bangumiItem);
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gap = constraints.maxWidth.clamp(0.0, 10.0).toDouble();
              final maxImageWidth =
                  (constraints.maxWidth - gap).clamp(0.0, 152.0);
              final imageWidth = (constraints.maxWidth * 0.42)
                  .clamp(0.0, maxImageWidth)
                  .toDouble();

              return Row(
                children: [
                  NetworkImgLayer(
                    src: bangumiItem.images['large'] ?? '',
                    width: imageWidth,
                    height: imageHeight,
                    origAspectRatio: posterAspectRatio,
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textScaler: textScaler,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          relationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textScaler: textScaler,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AiredSequelBanner extends StatelessWidget {
  const _AiredSequelBanner({
    required this.sequel,
    this.onOpen,
    this.onCollect,
  });

  final AiredSequel sequel;
  final ValueChanged<BangumiItem>? onOpen;
  final ValueChanged<AiredSequel>? onCollect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen == null ? null : () => onOpen!(sequel.item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Icon(
                Icons.playlist_add_check_circle_rounded,
                color: colors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '续作已开播',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sequel.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sequel.airDateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonal(
                onPressed: onCollect == null ? null : () => onCollect!(sequel),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text('加入在看'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
