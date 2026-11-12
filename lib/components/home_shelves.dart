import 'package:flutter/material.dart';
import 'package:venera/components/components.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/foundation/appdata.dart';
// context.to / context.colorScheme 来自 foundation/context.dart 的扩展，必须显式导入。
import 'package:venera/foundation/context.dart';
import 'package:venera/foundation/favorites.dart';
import 'package:venera/foundation/home_shelves.dart';
import 'package:venera/pages/comic_details_page/comic_page.dart';
import 'package:venera/utils/translations.dart';

/// 主页「书架」板块。
///
/// 每个书架是一个横向滚动的漫画条，数据直接来自收藏夹的文件夹，
/// 所以在收藏夹里增删漫画会立刻反映到这里，不需要额外的同步逻辑。
class HomeShelves extends StatefulWidget {
  const HomeShelves({super.key});

  @override
  State<HomeShelves> createState() => _HomeShelvesState();
}

class _HomeShelvesState extends State<HomeShelves> {
  @override
  void initState() {
    super.initState();
    // 书架顺序/内容变化时重建。
    appdata.settings.addListener(onChanged);
    LocalFavoritesManager().addListener(onChanged);
  }

  @override
  void dispose() {
    appdata.settings.removeListener(onChanged);
    LocalFavoritesManager().removeListener(onChanged);
    super.dispose();
  }

  void onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var shelves = currentHomeShelves();
    if (shelves.isEmpty) {
      // 还没上架任何书架：显示引导 + 添加入口。
      return SliverToBoxAdapter(child: _EmptyShelvesCard());
    }
    // 主页的 slivers 列表里每一项必须是一个 sliver。
    // 用 SliverList 承载各书架，每个 child 是普通 widget（_ShelfCard）。
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _ShelfCard(folder: shelves[index]),
        childCount: shelves.length,
      ),
    );
  }
}

/// 单个书架：标题栏 + 横向漫画列表（普通 widget，供 SliverList 使用）。
class _ShelfCard extends StatefulWidget {
  const _ShelfCard({required this.folder});

  final String folder;

  @override
  State<_ShelfCard> createState() => _ShelfCardState();
}

class _ShelfCardState extends State<_ShelfCard> {
  List<FavoriteItem>? _comics;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    var manager = LocalFavoritesManager();
    if (!manager.existsFolder(widget.folder)) {
      _comics = [];
      return;
    }
    var count = manager.folderComics(widget.folder);
    if (count >= 500) {
      manager.getFolderComicsAsync(widget.folder).then((value) {
        if (mounted) {
          setState(() => _comics = value);
        }
      });
    } else {
      _comics = manager.getFolderComics(widget.folder);
    }
  }

  @override
  Widget build(BuildContext context) {
    var comics = _comics ?? [];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.6,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                Center(
                  child: Text(widget.folder, style: ts.s18),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(comics.length.toString(), style: ts.s12),
                ),
                const Spacer(),
                _MenuButton(folder: widget.folder, onChanged: _load),
              ],
            ),
          ).paddingHorizontal(16),
          if (comics.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 18,
                    color: context.colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This shelf is empty. Add comics from Favorites.".tl,
                      style: ts.s12,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 136,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: comics.length,
                itemBuilder: (context, index) {
                  var comic = comics[index];
                  var heroID = comic.id.hashCode ^ comic.type.value;
                  return SimpleComicTile(
                    comic: comic,
                    heroID: heroID,
                    onTap: () {
                      context.to(
                        () => ComicPage(
                          id: comic.id,
                          sourceKey: comic.sourceKey,
                          cover: comic.cover,
                          title: comic.title,
                          heroID: heroID,
                        ),
                      );
                    },
                  ).paddingHorizontal(8).paddingVertical(2);
                },
              ),
            ).paddingHorizontal(8).paddingBottom(16),
        ],
      ),
    );
  }
}

/// 书架右上角菜单：改名 / 从书架移除。
class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.folder, required this.onChanged});

  final String folder;

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) {
        if (value == 'remove') {
          removeHomeShelf(folder);
          onChanged();
        } else if (value == 'rename') {
          _showRenameDialog(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'rename',
          child: Text("Rename".tl),
        ),
        PopupMenuItem(
          value: 'remove',
          child: Text("Remove from shelves".tl),
        ),
      ],
    );
  }

  void _showRenameDialog(BuildContext context) {
    var controller = TextEditingController(text: folder);
    showDialog(
      context: App.rootContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Rename".tl),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: "Name".tl,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel".tl),
            ),
            FilledButton(
              onPressed: () {
                var newName = controller.text.trim();
                if (newName.isNotEmpty && newName != folder) {
                  try {
                    LocalFavoritesManager().rename(folder, newName);
                    // 书架引用的是文件夹名，改名后要同步更新引用，
                    // 否则这个书架会指向一个不存在的文件夹。
                    var shelves = currentHomeShelves();
                    var i = shelves.indexOf(folder);
                    if (i >= 0) {
                      shelves[i] = newName;
                      saveHomeShelves(shelves);
                    }
                    onChanged();
                  } catch (e) {
                    // rename 在重名或名字含引号时会抛异常，
                    // 忽略即可，界面保持原名。
                  }
                }
                Navigator.pop(dialogContext);
              },
              child: Text("OK".tl),
            ),
          ],
        );
      },
    );
  }
}

/// 一个书架都没有时，给个添加入口，否则用户不知道这功能怎么开。
class _EmptyShelvesCard extends StatelessWidget {
  const _EmptyShelvesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.6,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                Center(
                  child: Text("Shelves".tl, style: ts.s18),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: Text("Add".tl),
                  onPressed: () => showAddShelfDialog(context),
                ),
              ],
            ),
          ).paddingHorizontal(16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 18,
                  color: context.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "No shelves yet. Create one and pick a favorites folder for it."
                        .tl,
                    style: ts.s12,
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

/// 添加书架：从收藏夹里挑一个还没上架的文件夹。
Future<void> showAddShelfDialog(BuildContext context) async {
  var manager = LocalFavoritesManager();
  var shelves = currentHomeShelves();
  var candidates =
      manager.folderNames.where((f) => !shelves.contains(f)).toList();

  if (candidates.isEmpty) {
    showDialogMessage(
      App.rootContext,
      "Shelves".tl,
      manager.folderNames.isEmpty
          ? "No folders in Favorites yet. Create a folder in Favorites first."
              .tl
          : "All folders are already on the shelves.".tl,
    );
    return;
  }

  var picked = await showDialog<String>(
    context: App.rootContext,
    builder: (dialogContext) {
      return SimpleDialog(
        title: Text("Add to shelves".tl),
        children: [
          for (var folder in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, folder),
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(folder)),
                  Text(
                    manager.folderComics(folder).toString(),
                    style: ts.s12,
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );

  if (picked != null) {
    addHomeShelf(picked);
  }
}
