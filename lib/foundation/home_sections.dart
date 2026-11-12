import 'package:venera/foundation/appdata.dart';

/// 主页可用板块的键，数组顺序即默认显示顺序。
///
/// 想加新板块时：在这里加一个键，在 [kHomeSectionNames] 加显示名，
/// 再到 `home_page.dart` 的 `buildHomeSection` 里补一条 `switch` 分支即可。
const kHomeSections = <String>[
  'search',
  'sync',
  'history',
  'local',
  'followUpdates',
  'comicSource',
  'imageFavorites',
  'shelves',
];

/// 板块键 → 显示名（英文原文，调用处用 `.tl` 翻译）。
const kHomeSectionNames = <String, String>{
  'search': 'Search Bar',
  'sync': 'Sync Data',
  'history': 'History',
  'local': 'Local',
  'followUpdates': 'Follow Updates',
  'comicSource': 'Comic Source',
  'imageFavorites': 'Image Favorites',
  'shelves': 'Shelves',
};

/// 读取当前生效的板块顺序。
///
/// 设置里存的可能是旧版本留下的、含未知键或重复项的列表，这里统一清洗：
/// 只保留 [kHomeSections] 认识的键并去重，保持用户排定的顺序。
///
/// 返回空列表表示用户把所有板块都关掉了（调用方负责显示提示）。
List<String> currentHomeSections() {
  var value = appdata.settings['homeSections'];
  if (value is! List) {
    // 设置缺失或类型不对，回退默认，避免首页直接空白。
    return List<String>.from(kHomeSections);
  }
  var result = <String>[];
  for (var item in value) {
    if (item is String &&
        kHomeSections.contains(item) &&
        !result.contains(item)) {
      result.add(item);
    }
  }
  return result;
}
