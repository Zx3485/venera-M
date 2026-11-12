import 'package:venera/foundation/appdata.dart';
import 'package:venera/foundation/favorites.dart';

/// 主页「书架」功能的数据层。
///
/// 书架并不会另外存一份漫画——它复用收藏夹的文件夹系统：
/// 每个书架就是一个 [LocalFavoritesManager] 里的文件夹，漫画存在那个文件夹里。
/// 这里只负责记录「哪些文件夹被摆到了主页书架上」以及它们的顺序。
///
/// 这样做的好处：
/// - 书架和收藏夹共享同一份数据，在收藏夹里加/删漫画，书架立刻反映；
/// - 排序、搜索、批量操作等已有能力全部可以直接复用；
/// - 用户不想要书架时，删掉书架只是取消引用，漫画还在收藏夹里，不会丢。

/// 存储在 `appdata.settings['homeShelves']` 里的书架名称列表。
///
/// 列表顺序即主页上的显示顺序。
const kHomeShelvesKey = 'homeShelves';

/// 读取当前书架列表。
///
/// 会过滤掉已经不存在于收藏夹的文件夹名（用户可能在收藏夹里删掉了它），
/// 避免主页上出现指向空文件夹的书架。过滤结果不会立刻写回设置，
/// 真正写入发生在 [saveHomeShelves]。
List<String> currentHomeShelves() {
  var value = appdata.settings[kHomeShelvesKey];
  if (value is! List) {
    return [];
  }
  var manager = LocalFavoritesManager();
  var folders = manager.folderNames;
  var result = <String>[];
  for (var item in value) {
    if (item is String && folders.contains(item) && !result.contains(item)) {
      result.add(item);
    }
  }
  return result;
}

/// 写回书架列表并保存。
void saveHomeShelves(List<String> shelves) {
  appdata.settings[kHomeShelvesKey] = List<String>.from(shelves);
  appdata.saveData();
}

/// 把一个文件夹加到书架末尾。已在书架上则忽略。
/// 返回是否真的添加了。
bool addHomeShelf(String folder) {
  var shelves = currentHomeShelves();
  if (shelves.contains(folder)) {
    return false;
  }
  shelves.add(folder);
  saveHomeShelves(shelves);
  return true;
}

/// 从书架上移除某个文件夹（不影响收藏夹里的内容）。
void removeHomeShelf(String folder) {
  var shelves = currentHomeShelves();
  shelves.remove(folder);
  saveHomeShelves(shelves);
}

/// 调整书架的显示顺序。
void reorderHomeShelves(List<String> shelves) {
  saveHomeShelves(shelves);
}
