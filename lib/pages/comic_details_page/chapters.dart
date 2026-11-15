part of 'comic_page.dart';

/// 鍒嗙粍妯″紡鐨勭珷鑺傛牸锛氭爣棰樻槸鏂囧瓧锛堛€岀 42 璇濄€嶏級锛屼笉鑳界缉鎴愭暟瀛椼€?
///
/// 缁撴瀯鍜?[_ChapterCell] 涓€鑷达紝鍙槸鏂囧瓧鍏佽鐪佺暐鍙枫€?
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
      borderRadius: kCorner(context, scale: 0.6),
      child: InkWell(
        onTap: onTap,
        borderRadius: kCorner(context, scale: 0.6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: kCorner(context, scale: 0.6),
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

/// 绔犺妭缃戞牸鐨勫垪鏁般€?
///
/// 鎶樺彔涓婇檺鍜岀綉鏍兼湰韬繀椤荤敤鍚屼竴涓畻娉曪紝鍚﹀垯銆屾樉绀哄叏閮ㄣ€嶅墠鍚?
/// 姣忚鏍煎瓙鏁颁細璺冲彉銆傛墜鏈猴紙绾?400dp锛夋崲绠楃害 5 鍒楋紝
/// 涓€灞忚兘鐪嬪埌 15 璇濓紝姣斿師鏉?2 鍒?/ 48 楂樼殑鐗堟湰澶氫竴鍊嶅銆?
int _chapterGridColumns(double crossAxisExtent) {
  // 鎵ｆ帀宸﹀彸鍚?26 鐨勫唴杈硅窛
  final usable = crossAxisExtent - 52;
  // 鐩爣鏍煎绾?54dp锛堟斁寰椾笅 3 浣嶆暟瀛?+ 杈硅窛锛?
  final cols = (usable / 54).floor();
  return cols.clamp(3, 8);
}

/// 鍙樉绀烘暟瀛楃殑绔犺妭鏍笺€?
///
/// 鏉傚織鐗堟妸銆岀 42 璇濄€嶇缉鍑忔垚銆?2銆嶁€斺€旂渷涓嬬殑妯悜绌洪棿璁╁垪鏁扮炕鍊嶃€?
/// 宸茶鐢ㄩ挗绾㈡暟瀛?+ 娣″簳鏍囧嚭锛岃€屼笉鏄暣鏍煎彉鐏般€?
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
      borderRadius: kCorner(context, scale: 0.6),
      child: InkWell(
        onTap: onTap,
        borderRadius: kCorner(context, scale: 0.6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: kCorner(context, scale: 0.6),
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
        // 鎶樺彔涓婇檺锛氱敤鍜岀綉鏍煎畬鍏ㄤ竴鑷寸殑鍒楁暟绠楁硶锛屽惁鍒欍€屾樉绀哄叏閮ㄣ€嶅墠鍚?
        // 姣忚鑳芥斁鐨勬牸瀛愭暟涓嶄竴鏍凤紝鐪嬭捣鏉ュ儚璺冲彉銆?
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
                        label: reverse ? "${chapters.length} 鈫?1" : "1 鈫?${chapters.length}",
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
                  // readEpisode 鏄?Set<String>锛屽師鏉ヤ紶鐨勬槸 int i+1锛?
                  // 绫诲瀷涓嶅尮閰嶅鑷淬€屽凡璇诲彉鐏般€嶄粠鏈敓鏁堣繃銆?
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
        // 鍜岀綉鏍肩敤鍚屼竴涓垪鏁扮畻娉曪紙鍘熸潵鏄啓姝荤殑 200锛屽拰缃戞牸鐨?250 瀵逛笉涓婏級
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
                            ? "${group.length} 鈫?1"
                            : "1 鈫?${group.length}",
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
                          // 璺冲埌鏈垎缁勬渶鍚庝竴璇濓細鍏堢疮鍔犲墠闈㈡墍鏈夊垎缁勭殑璇濇暟
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
                  // 鍒嗙粍妯″紡鐨勬爣棰樻槸鏂囧瓧锛堛€岀 42 璇濄€嶏級锛屼笉鑳藉彧鏄剧ず鏁板瓧锛?
                  // 鎵€浠ヨ繖閲屼繚鐣欐枃瀛楁牸锛屽彧缁熶竴缃戞牸瀵嗗害鍜屽渾瑙掋€?
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
