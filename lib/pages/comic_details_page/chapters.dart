part of 'comic_page.dart';

/// 分组模式的章节格：标题是文字（「第 42 话」），不能缩成数字。
///
/// 结构和 [_ChapterCell] 一致，只是文字允许省略号。
class _ChapterLabelCell extends StatelessWidget {
  const _ChapterLabelCell({
    required this.label,
    required this.visited,
    required this.onTap,
  });

  final String label;
  final bool visited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final rust = kRustColor(context);
    return Material(
      color: visited
          ? scheme.surfaceContainerHigh.toOpacity(0.55)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(kRadiusXs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusXs),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusXs),
            border: Border.all(
              color: scheme.outlineVariant,
              width: kRuleHair,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: visited ? rust : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 章节网格的列数。
///
/// 折叠上限和网格本身必须用同一个算法，否则「显示全部」前后
/// 每行格子数会跳变。手机（约 400dp）换算约 5 列，
/// 一屏能看到 15 话，比原来 2 列 / 48 高的版本多一倍多。
int _chapterGridColumns(double crossAxisExtent) {
  // 扣掉左右各 26 的内边距
  final usable = crossAxisExtent - 52;
  // 目标格宽约 54dp（放得下 3 位数字 + 边距）
  final cols = (usable / 54).floor();
  return cols.clamp(3, 8);
}

/// 只显示数字的章节格。
///
/// 杂志版把「第 42 话」缩减成「42」——省下的横向空间让列数翻倍。
/// 已读用钢红数字 + 淡底标出，而不是整格变灰。
class _ChapterCell extends StatelessWidget {
  const _ChapterCell({
    required this.label,
    required this.visited,
    required this.onTap,
  });

  final String label;
  final bool visited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final rust = kRustColor(context);
    return Material(
      color: visited
          ? scheme.surfaceContainerHigh.toOpacity(0.55)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(kRadiusXs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusXs),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusXs),
            border: Border.all(
              color: scheme.outlineVariant,
              width: kRuleHair,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: visited ? rust : scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComicChapters extends StatelessWidget {
  const _ComicChapters({this.history, required this.groupedMode});

  final History? history;

  final bool groupedMode;

  @override
  Widget build(BuildContext context) {
    return groupedMode
        ? _GroupedComicChapters(history)
        : _NormalComicChapters(history);
  }
}

class _NormalComicChapters extends StatefulWidget {
  const _NormalComicChapters(this.history);

  final History? history;

  @override
  State<_NormalComicChapters> createState() => _NormalComicChaptersState();
}

class _NormalComicChaptersState extends State<_NormalComicChapters> {
  late _ComicPageState state;

  late bool reverse;

  bool showAll = false;

  late History? history;

  late ComicChapters chapters;

  @override
  void initState() {
    super.initState();
    reverse = appdata.settings["reverseChapterOrder"] ?? false;
    history = widget.history;
  }

  @override
  void didChangeDependencies() {
    state = context.findAncestorStateOfType<_ComicPageState>()!;
    chapters = state.comic.chapters!;
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant _NormalComicChapters oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      history = widget.history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constrains) {
        int length = chapters.length;
        bool canShowAll = showAll;
        // 折叠上限：用和网格完全一致的列数算法，否则「显示全部」前后
        // 每行能放的格子数不一样，看起来像跳变。
        final columns = _chapterGridColumns(constrains.crossAxisExtent);
        if (!showAll) {
          length = math.min(length, columns * 8);
          if (length == chapters.length) {
            canShowAll = true;
          }
        }

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: SectionHead(
                'Chapters'.tl,
                trailing: chapters.length > columns * 8
                    ? "${chapters.length}"
                    : null,
                padding: const EdgeInsets.fromLTRB(26, 26, 26, 12),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: EditorialJumpButton(
                        label: reverse ? "${chapters.length} → 1" : "1 → ${chapters.length}",
                        icon: reverse
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        onTap: () {
                          setState(() {
                            reverse = !reverse;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: EditorialJumpButton(
                        label: 'Latest'.tl,
                        icon: Icons.last_page,
                        primary: true,
                        onTap: () => state.read(chapters.length),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                childCount: length,
                (context, i) {
                  if (reverse) {
                    i = chapters.length - i - 1;
                  }
                  final chapterNo = i + 1;
                  // readEpisode 是 Set<String>，原来传的是 int i+1，
                  // 类型不匹配导致「已读变灰」从未生效过。
                  bool visited =
                      (history?.readEpisode ?? {}).contains('$chapterNo');
                  return _ChapterCell(
                    label: chapterNo.toString(),
                    visited: visited,
                    onTap: () => state.read(chapterNo),
                  );
                },
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 1.55,
              ),
            ).sliverPadding(const EdgeInsets.symmetric(horizontal: 26)),
            if (!canShowAll)
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    icon: const Icon(Icons.arrow_drop_down),
                    onPressed: () {
                      setState(() {
                        showAll = true;
                      });
                    },
                    label: Text("${"Show all".tl} (${chapters.length})"),
                  ).paddingTop(12),
                ),
              ),
            const SliverToBoxAdapter(
              child: Divider(),
            ),
          ],
        );
      },
    );
  }
}

class _GroupedComicChapters extends StatefulWidget {
  const _GroupedComicChapters(this.history);

  final History? history;

  @override
  State<_GroupedComicChapters> createState() => _GroupedComicChaptersState();
}

class _GroupedComicChaptersState extends State<_GroupedComicChapters>
    with SingleTickerProviderStateMixin {
  late _ComicPageState state;

  late bool reverse;

  bool showAll = false;

  late History? history;

  late ComicChapters chapters;

  late TabController tabController;

  late int index;

  @override
  void initState() {
    super.initState();
    reverse = appdata.settings["reverseChapterOrder"] ?? false;
    history = widget.history;
    if (history?.group != null) {
      index = history!.group! - 1;
    } else {
      index = 0;
    }
  }

  @override
  void didChangeDependencies() {
    state = context.findAncestorStateOfType<_ComicPageState>()!;
    chapters = state.comic.chapters!;
    tabController = TabController(
      initialIndex: index,
      length: chapters.ids.length,
      vsync: this,
    );
    tabController.addListener(onTabChange);
    super.didChangeDependencies();
  }

  void onTabChange() {
    if (index != tabController.index) {
      setState(() {
        index = tabController.index;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _GroupedComicChapters oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      history = widget.history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constrains) {
        var group = chapters.getGroupByIndex(index);
        int length = group.length;
        bool canShowAll = showAll;
        // 和网格用同一个列数算法（原来是写死的 200，和网格的 250 对不上）
        final columns = _chapterGridColumns(constrains.crossAxisExtent);
        if (!showAll) {
          length = math.min(length, columns * 8);
          if (length == group.length) {
            canShowAll = true;
          }
        }

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: SectionHead(
                'Chapters'.tl,
                trailing: "${group.length}",
                padding: const EdgeInsets.fromLTRB(26, 26, 26, 12),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: EditorialJumpButton(
                        label: reverse
                            ? "${group.length} → 1"
                            : "1 → ${group.length}",
                        icon: reverse
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        onTap: () {
                          setState(() {
                            reverse = !reverse;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: EditorialJumpButton(
                        label: 'Latest'.tl,
                        icon: Icons.last_page,
                        primary: true,
                        onTap: () {
                          // 跳到本分组最后一话：先累加前面所有分组的话数
                          var offset = 0;
                          for (var j = 0; j < index; j++) {
                            offset += chapters.getGroupByIndex(j).length;
                          }
                          state.read(offset + group.length);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AppTabBar(
                withUnderLine: false,
                controller: tabController,
                tabs: chapters.groups.map((e) => Tab(text: e)).toList(),
              ),
            ),
            SliverPadding(padding: const EdgeInsets.only(top: 8)),
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                childCount: length,
                (context, i) {
                  if (reverse) {
                    i = group.length - i - 1;
                  }
                  var key = group.keys.elementAt(i);
                  var value = group[key]!;
                  var chapterIndex = 0;
                  for (var j = 0; j < chapters.groupCount; j++) {
                    if (j == index) {
                      chapterIndex += i;
                      break;
                    }
                    chapterIndex += chapters.getGroupByIndex(j).length;
                  }
                  String rawIndex = (chapterIndex + 1).toString();
                  String groupedIndex = "${index + 1}-${i + 1}";
                  bool visited = false;
                  if (history != null) {
                    visited = history!.readEpisode.contains(groupedIndex) ||
                        history!.readEpisode.contains(rawIndex);
                  }
                  // 分组模式的标题是文字（「第 42 话」），不能只显示数字，
                  // 所以这里保留文字格，只统一网格密度和圆角。
                  return _ChapterLabelCell(
                    label: value,
                    visited: visited,
                    onTap: () => state.read(chapterIndex + 1),
                  );
                },
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 1.55,
              ),
            ).sliverPadding(const EdgeInsets.symmetric(horizontal: 26)),
            if (!canShowAll)
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    icon: const Icon(Icons.arrow_drop_down),
                    onPressed: () {
                      setState(() {
                        showAll = true;
                      });
                    },
                    label: Text("${"Show all".tl} (${group.length})"),
                  ).paddingTop(12),
                ),
              ),
            const SliverToBoxAdapter(
              child: Divider(),
            ),
          ],
        );
      },
    );
  }
}
