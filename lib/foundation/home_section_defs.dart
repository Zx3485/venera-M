/// 主页板块的定义表 —— 纯粹的常量与纯函数，**不 import 任何东西**。
///
/// 单独拆出来是为了让 `appdata.dart` 能安全引用默认值而不和
/// `home_sections.dart` 形成循环 import：
///   appdata.dart        → home_section_defs.dart（纯常量，无依赖）
///   home_sections.dart  → home_section_defs.dart + appdata.dart（读设置）
///
/// 加新板块只改这一个文件：[kHomeSectionDefs] 加一条，
/// 再到 `pages/home_page.dart` 的 `buildSection` 补一个 `case`。
const kHomeSectionDefs = <({String key, String name, bool defaultOn})>[
  (key: 'search', name: 'Search Bar', defaultOn: true),
  (key: 'sync', name: 'Sync Data', defaultOn: true),
  (key: 'history', name: 'History', defaultOn: true),
  (key: 'local', name: 'Local', defaultOn: true),
  (key: 'followUpdates', name: 'Follow Updates', defaultOn: true),
  (key: 'comicSource', name: 'Comic Source', defaultOn: true),
  (key: 'imageFavorites', name: 'Image Favorites', defaultOn: true),
  // 书架是 1.6.20 新增的板块，默认打开。
  // 以后若有不想默认出现的板块，把 defaultOn 设成 false 即可。
  (key: 'shelves', name: 'Shelves', defaultOn: true),
];

/// 全部合法的板块键，顺序即默认显示顺序。
List<String> get kHomeSections =>
    [for (var s in kHomeSectionDefs) s.key];

/// 默认显示的板块键（由 [kHomeSectionDefs] 的 `defaultOn` 决定）。
///
/// `appdata.settings['homeSections']` 的初始值引用这里，
/// 避免像 1.6.19 那样「加板块却忘了同步默认值」导致新板块默认不可见。
List<String> get kDefaultHomeSections =>
    [for (var s in kHomeSectionDefs) if (s.defaultOn) s.key];

/// 板块键 → 显示名（英文原文，调用处用 `.tl` 翻译）。
Map<String, String> get kHomeSectionNames =>
    {for (var s in kHomeSectionDefs) s.key: s.name};
