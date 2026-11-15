part of 'favorites_page.dart';

class _LeftBar extends StatefulWidget {
  const _LeftBar({this.favPage, this.onSelected, this.withAppbar = false});

  final _FavoritesPageState? favPage;

  final VoidCallback? onSelected;

  final bool withAppbar;

  @override
  State<_LeftBar> createState() => _LeftBarState();
}

class _LeftBarState extends State<_LeftBar> implements FolderList {
  late _FavoritesPageState favPage;

  var folders = <String>[];

  var networkFolders = <String>[];

  void findNetworkFolders() {
    networkFolders.clear();
    var all = ComicSource.all()
        .where((e) => e.favoriteData != null)
        .map((e) => e.favoriteData!.key)
        .toList();
    var settings = appdata.settings['favorites'] as List;
    for (var p in settings) {
      if (all.contains(p) && !networkFolders.contains(p)) {
        networkFolders.add(p);
      }
    }
  }

  @override
  void initState() {
    favPage = widget.favPage ??
        context.findAncestorStateOfType<_FavoritesPageState>()!;
    favPage.folderList = this;
    folders = LocalFavoritesManager().folderNames;
    findNetworkFolders();
    appdata.settings.addListener(updateFolders);
    LocalFavoritesManager().addListener(updateFolders);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    appdata.settings.removeListener(updateFolders);
    LocalFavoritesManager().removeListener(updateFolders);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: context.colorScheme.outlineVariant,
            width: kRuleHair,
          ),
        ),
      ),
      child: Column(
        children: [
          if (widget.withAppbar)
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const CloseButton(),
                  const SizedBox(width: 8),
                  Text(
                    "Folders".tl,
                    style: kSerifStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ).paddingTop(context.padding.top),
          Expanded(
            child: ListView.builder(
              padding: widget.withAppbar
                  ? EdgeInsets.zero
                  : EdgeInsets.only(
                      top: context.padding.top + 8,
                      bottom: kPageBottomInset(context) - kPillNavReserved,
                    ),
              itemCount: folders.length + networkFolders.length + 3,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return buildLocalTitle();
                }
                index--;
                if (index == 0) {
                  return buildLocalFolder(_localAllFolderLabel);
                }
                index--;
                if (index < folders.length) {
                  return buildLocalFolder(folders[index]);
                }
                index -= folders.length;
                if (index == 0) {
                  return buildNetworkTitle();
                }
                index--;
                return buildNetworkFolder(networkFolders[index]);
              },
            ),
          )
        ],
      ),
    );
  }

  /// 栏目标题：全大写小字标 + 右侧菜单，下方一条 hairline。
  Widget _buildSectionHeader(String title, Widget trailing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 34,
          child: Row(
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: kKickerTracking,
                  fontWeight: FontWeight.w700,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              trailing,
            ],
          ).paddingHorizontal(kPageInset),
        ),
        Padding(
          padding: const EdgeInsets.only(left: kPageInset),
          child: HairRule(),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget buildLocalTitle() {
    return _buildSectionHeader(
      "Local".tl,
      MenuButton(
        entries: [
          MenuEntry(
            icon: Icons.add,
            text: 'Create Folder'.tl,
            onClick: () {
              newFolder().then((value) {
                setState(() {
                  folders = LocalFavoritesManager().folderNames;
                });
              });
            },
          ),
          MenuEntry(
            icon: Icons.reorder,
            text: 'Sort'.tl,
            onClick: () {
              sortFolders().then((value) {
                setState(() {
                  folders = LocalFavoritesManager().folderNames;
                });
              });
            },
          ),
        ],
      ),
    ).paddingTop(6);
  }

  Widget buildNetworkTitle() {
    return _buildSectionHeader(
      "Network".tl,
      IconButton(
        iconSize: 17,
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.settings),
        onPressed: () {
          showPopUpWidget(
            App.rootContext,
            setFavoritesPagesWidget(),
          );
        },
      ),
    ).paddingTop(kSectionGap - 12);
  }

  Widget buildLocalFolder(String name) {
    bool isSelected = name == favPage.folder && !favPage.isNetwork;
    int count = 0;
    if (name == _localAllFolderLabel) {
      count = LocalFavoritesManager().totalComics;
    } else {
      count = LocalFavoritesManager().folderComics(name);
    }
    var folderName = name == _localAllFolderLabel
        ? "All".tl
        : getFavoriteDataOrNull(name)?.title ?? name;
    return EditorialNavItem(
      label: folderName,
      selected: isSelected,
      count: count,
      onTap: () {
        if (isSelected) {
          return;
        }
        favPage.setFolder(false, name);
        widget.onSelected?.call();
      },
    );
  }

  Widget buildNetworkFolder(String key) {
    var data = getFavoriteDataOrNull(key);
    if (data == null) {
      return const SizedBox();
    }
    bool isSelected = key == favPage.folder && favPage.isNetwork;
    return EditorialNavItem(
      label: data.title,
      selected: isSelected,
      onTap: () {
        if (isSelected) {
          return;
        }
        favPage.setFolder(true, key);
        widget.onSelected?.call();
      },
    );
  }

  @override
  void update() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void updateFolders() {
    if (!mounted) return;
    setState(() {
      folders = LocalFavoritesManager().folderNames;
      findNetworkFolders();
    });
  }
}
