part of 'settings_page.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  @override
  Widget build(BuildContext context) {
    return SmoothCustomScrollView(
      slivers: [
        SliverAppbar(title: Text("Appearance".tl)),
        SelectSetting(
          title: "Theme Mode".tl,
          settingKey: "theme_mode",
          optionTranslation: {
            "system": "跟随系统".tl,
            "light": "浅色".tl,
            "dark": "深色".tl,
          },
          onChanged: () async {
            App.forceRebuild();
          },
        ).toSliver(),
        SelectSetting(
          title: "Theme Color".tl,
          settingKey: "color",
          optionTranslation: {
            "system": "跟随系统".tl,
            "red": "红".tl,
            "pink": "粉".tl,
            "purple": "紫".tl,
            "green": "绿".tl,
            "orange": "橙".tl,
            "blue": "蓝".tl,
            "yellow": "黄".tl,
            "cyan": "青".tl,
            // 低饱和色
            "mistBlue": "雾霾蓝".tl,
            "lilac": "藕荷紫".tl,
            "sage": "鼠尾草绿".tl,
            "slate": "岩灰".tl,
            "coral": "珊瑚".tl,
            "matcha": "抹茶".tl,
            "sand": "暖沙".tl,
            "dusk": "暮紫".tl,
          },
          onChanged: () async {
            await App.init();
            App.forceRebuild();
          },
        ).toSliver(),
        SelectSetting(
          title: "Page Transition".tl,
          settingKey: "pageTransition",
          optionTranslation: {
            "default": "跟随系统".tl,
            "fade": "淡入淡出".tl,
            "zoom": "缩放".tl,
            "slideUp": "从下往上".tl,
            "sharedAxisX": "水平推进".tl,
            "none": "无动画".tl,
          },
          onChanged: () async {
            App.forceRebuild();
          },
        ).toSliver(),

        // ───────────────── 主页板块 ─────────────────
        _SettingPartTitle(title: "Home Page".tl, icon: Icons.dashboard_customize),
        _PopupWindowSetting(
          title: "Home Page Sections".tl,
          builder: () => const _HomeSectionsEditor(),
        ).toSliver(),
        _PopupWindowSetting(
          title: "Shelves".tl,
          builder: () => const _ShelvesEditor(),
        ).toSliver(),

        // ───────────────── 磨砂玻璃 ─────────────────
        _SettingPartTitle(title: "Glass Effect".tl, icon: Icons.blur_on),
        _SwitchSetting(
          title: "Enable Glass".tl,
          settingKey: "glassEffect",
          subtitle: "开启后浮层与工具栏会模糊背后的内容。"
              "背后有图片或内容时才看得出效果；中低端机可能掉帧。"
              .tl,
        ).toSliver(),
        if (isGlassEnabled) ...[
          _SliderSetting(
            title: "Glass Opacity".tl,
            settingsIndex: "glassOpacity",
            interval: 0.05,
            min: 0.0,
            max: 0.9,
            onChanged: () => setState(() {}),
          ).toSliver(),
          _SliderSetting(
            title: "Glass Blur".tl,
            settingsIndex: "glassBlur",
            interval: 2,
            min: 0,
            max: 60,
            onChanged: () => setState(() {}),
          ).toSliver(),
          _SwitchSetting(
            title: "Glass Highlight".tl,
            settingKey: "glassHighlight",
            subtitle: "在玻璃顶部叠一层由亮到透明的渐变，"
                "模拟光线掠过表面，让质感更像真玻璃。"
                .tl,
          ).toSliver(),
          _SwitchSetting(
            title: "Glass on Reader Toolbar".tl,
            settingKey: "glassInReader",
            subtitle: "阅读器的上下工具栏背景变薄并模糊，能看见背后的漫画。"
                "背后有画面，这里效果最明显。"
                .tl,
          ).toSliver(),
          _SwitchSetting(
            title: "Glass on App Bar".tl,
            settingKey: "glassInAppBar",
            subtitle: "列表页顶部标题栏透明化，滚动时能看到背后的封面。"
                .tl,
          ).toSliver(),
        ],
      ],
    );
  }
}

/// 主页板块编辑器：拖拽排序 + 勾选增删。
///
/// 和 explore_settings 里那些「页面筛选」交互一致，只是这里的条目是
/// 固定的主页板块，不是图源提供的动态页面。
class _HomeSectionsEditor extends StatefulWidget {
  const _HomeSectionsEditor();

  @override
  State<_HomeSectionsEditor> createState() => _HomeSectionsEditorState();
}

class _HomeSectionsEditorState extends State<_HomeSectionsEditor> {
  /// 当前排好的板块键，顺序即显示顺序。
  late List<String> keys;

  var reorderWidgetKey = UniqueKey();

  var scrollController = ScrollController();

  @override
  void initState() {
    keys = currentHomeSections();
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tiles = keys.map(buildItem).toList();

    Widget body = keys.isEmpty
        ? ListView(
            controller: scrollController,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "All sections are hidden. Tap Add in the top right to turn some on."
                      .tl,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          )
        : ReorderableBuilder<String>(
            key: reorderWidgetKey,
            scrollController: scrollController,
            longPressDelay: App.isDesktop
                ? const Duration(milliseconds: 100)
                : const Duration(milliseconds: 500),
            dragChildBoxDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                  spreadRadius: 2,
                ),
              ],
            ),
            onReorder: (reorderFunc) {
              setState(() {
                keys = List.from(reorderFunc(keys));
              });
              save();
            },
            children: tiles,
            builder: (children) {
              return GridView(
                controller: scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisExtent: 48,
                ),
                children: children,
              );
            },
          );

    return PopUpWidgetScaffold(
      title: "Home Page Sections".tl,
      tailing: [
        if (keys.length < kHomeSections.length)
          TextButton.icon(
            label: Text("Add".tl),
            icon: const Icon(Icons.add),
            onPressed: showAddDialog,
          ),
      ],
      body: body,
    );
  }

  Widget buildItem(String key) {
    var removeButton = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        tooltip: "Remove".tl,
        onPressed: () {
          setState(() {
            keys.remove(key);
          });
          save();
        },
        icon: const Icon(Icons.delete_outline),
      ),
    );

    return ListTile(
      key: Key(key),
      title: Text((kHomeSectionNames[key] ?? key).tl),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [removeButton, const Icon(Icons.drag_handle)],
      ),
    );
  }

  void showAddDialog() {
    var canAdd = <String, String>{};
    for (final key in kHomeSections) {
      if (!keys.contains(key)) {
        canAdd[key] = (kHomeSectionNames[key] ?? key).tl;
      }
    }

    var selected = <String>[];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return ContentDialog(
              title: "Add".tl,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: canAdd.entries
                    .map(
                      (e) => CheckboxListTile(
                        value: selected.contains(e.key),
                        title: Text(e.value),
                        key: Key(e.key),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value!) {
                              selected.add(e.key);
                            } else {
                              selected.remove(e.key);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              actions: [
                if (selected.length < canAdd.length)
                  TextButton(
                    child: Text("Select All".tl),
                    onPressed: () {
                      setDialogState(() {
                        selected = canAdd.keys.toList();
                      });
                    },
                  )
                else
                  TextButton(
                    child: Text("Deselect All".tl),
                    onPressed: () {
                      setDialogState(() {
                        selected.clear();
                      });
                    },
                  ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: selected.isNotEmpty
                      ? () {
                          setState(() {
                            // 按 kHomeSections 的默认顺序追加，
                            // 避免勾选顺序不同导致首页排列随机。
                            for (var key in kHomeSections) {
                              if (selected.contains(key) && !keys.contains(key)) {
                                keys.add(key);
                              }
                            }
                          });
                          save();
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text("Add".tl),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void save() {
    appdata.settings['homeSections'] = List<String>.from(keys);
    appdata.saveData();
  }
}

/// 书架管理：挑选哪些收藏夹文件夹显示在主页书架上，并调整顺序。
class _ShelvesEditor extends StatefulWidget {
  const _ShelvesEditor();

  @override
  State<_ShelvesEditor> createState() => _ShelvesEditorState();
}

class _ShelvesEditorState extends State<_ShelvesEditor> {
  late List<String> shelves;

  var reorderWidgetKey = UniqueKey();

  var scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    shelves = currentHomeShelves();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var manager = LocalFavoritesManager();
    var folders = manager.folderNames;
    var tiles = shelves.map(buildItem).toList();

    Widget body;
    if (folders.isEmpty) {
      body = ListView(
        controller: scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "No folders in Favorites yet. Create a folder in Favorites first."
                  .tl,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    } else if (shelves.isEmpty) {
      body = ListView(
        controller: scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "No shelves yet. Tap Add to put a favorites folder on the home page."
                  .tl,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    } else {
      body = ReorderableBuilder<String>(
        key: reorderWidgetKey,
        scrollController: scrollController,
        longPressDelay: App.isDesktop
            ? const Duration(milliseconds: 100)
            : const Duration(milliseconds: 500),
        dragChildBoxDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
              spreadRadius: 2,
            ),
          ],
        ),
        onReorder: (reorderFunc) {
          setState(() {
            shelves = List.from(reorderFunc(shelves));
          });
          save();
        },
        children: tiles,
        builder: (children) {
          return GridView(
            controller: scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisExtent: 56,
            ),
            children: children,
          );
        },
      );
    }

    return PopUpWidgetScaffold(
      title: "Shelves".tl,
      tailing: [
        if (shelves.length < folders.length)
          TextButton.icon(
            label: Text("Add".tl),
            icon: const Icon(Icons.add),
            onPressed: showAddDialog,
          ),
      ],
      body: body,
    );
  }

  Widget buildItem(String folder) {
    return ListTile(
      key: Key(folder),
      title: Text(folder),
      subtitle: Text(
        "@c comics".tlParams({'c': LocalFavoritesManager().folderComics(folder)}),
        style: ts.s12,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: "Remove".tl,
            onPressed: () {
              setState(() {
                shelves.remove(folder);
              });
              save();
            },
            icon: const Icon(Icons.delete_outline),
          ),
          const Icon(Icons.drag_handle),
        ],
      ),
    );
  }

  void showAddDialog() {
    var manager = LocalFavoritesManager();
    var canAdd = manager.folderNames
        .where((f) => !shelves.contains(f))
        .toList();
    if (canAdd.isEmpty) {
      return;
    }
    var selected = <String>[];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return ContentDialog(
              title: "Add".tl,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: canAdd
                    .map(
                      (folder) => CheckboxListTile(
                        value: selected.contains(folder),
                        title: Text(folder),
                        subtitle: Text(
                          "@c comics".tlParams({
                            'c': manager.folderComics(folder),
                          }),
                          style: ts.s12,
                        ),
                        key: Key(folder),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value!) {
                              selected.add(folder);
                            } else {
                              selected.remove(folder);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              actions: [
                if (selected.length < canAdd.length)
                  TextButton(
                    child: Text("Select All".tl),
                    onPressed: () {
                      setDialogState(() {
                        selected = List.from(canAdd);
                      });
                    },
                  )
                else
                  TextButton(
                    child: Text("Deselect All".tl),
                    onPressed: () {
                      setDialogState(() {
                        selected.clear();
                      });
                    },
                  ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: selected.isNotEmpty
                      ? () {
                          setState(() {
                            for (var folder in canAdd) {
                              if (selected.contains(folder) &&
                                  !shelves.contains(folder)) {
                                shelves.add(folder);
                              }
                            }
                          });
                          save();
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text("Add".tl),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void save() {
    appdata.settings['homeShelves'] = List<String>.from(shelves);
    appdata.saveData();
  }
}
