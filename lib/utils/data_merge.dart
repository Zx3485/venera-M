import 'package:sqlite3/sqlite3.dart';

/// 合并式同步：把云端解包出来的数据库与本地数据库**按主键合并**，而不是整库替换。
///
/// 早期版本的导入逻辑是「删库 → 换库」，两台设备轮流上传/下载时会互相覆盖
/// 对方的阅读进度和收藏：
///
/// ```
/// 手机读了《A》第 30 话 → 上传
/// 平板读了《B》第 10 话 → 上传（覆盖手机那条）
/// 手机再开机 → 下载 → 《A》第 30 话没了
/// ```
///
/// 合并规则：
/// - `history`：主键 (id, type)。同一本漫画取 `time` 较新的一条用于进度字段；
///   `readEpisode`（已读章节集合）取两边的**并集**，避免丢掉另一台设备读过的章节。
/// - `image_favorites`：主键 (id, source_key)，取 `time` 较新的一条。
/// - 收藏夹各文件夹（每个文件夹是一张表）：主键 (id, type)，取**并集**。
///   本地已有的条目完全保持原样，云端多出来的追加到本地列表末尾。
/// - `folder_order`：保留本地顺序，云端多出来的文件夹追加到末尾。
/// - `folder_sync`：只补缺失的关联，不覆盖本地已有配置。
///
/// 这些函数都在 Isolate 内自建 sqlite 连接，调用前必须先关闭主线程上的
/// HistoryManager / LocalFavoritesManager，调用后重新 init 它们。
library;

/// 合并 `history.db`（含 history 与 image_favorites 两张表）。
void mergeHistoryDatabases({
  required String incomingPath,
  required String localPath,
}) {
  _withDatabases(
    incomingPath: incomingPath,
    localPath: localPath,
    merge: (src, dst) {
      _mergeHistoryTable(src, dst);
      _mergeImageFavoritesTable(src, dst);
    },
  );
}

/// 合并 `local_favorite.db`（folder_order / folder_sync / 每个收藏夹一张表）。
void mergeFavoriteDatabases({
  required String incomingPath,
  required String localPath,
}) {
  _withDatabases(
    incomingPath: incomingPath,
    localPath: localPath,
    merge: _mergeFavoriteDb,
  );
}

// ---------------------------------------------------------------------------
// 通用工具
// ---------------------------------------------------------------------------

void _withDatabases({
  required String incomingPath,
  required String localPath,
  required void Function(Database src, Database dst) merge,
}) {
  var src = sqlite3.open(incomingPath);
  try {
    // 本地库不存在时 sqlite3.open 会新建一个空库，合并过程会自动建表，
    // 效果等同于「首次导入」。
    var dst = sqlite3.open(localPath);
    try {
      merge(src, dst);
    } finally {
      dst.dispose();
    }
  } finally {
    src.dispose();
  }
}

String _quote(String identifier) {
  var escaped = identifier.replaceAll('"', '""');
  return '"' + escaped + '"';
}

bool _tableExists(Database db, String table) {
  var res = db.select(
    "select name from sqlite_master where type = 'table' and name = ?;",
    [table],
  );
  return res.isNotEmpty;
}

List<String> _columnsOf(Database db, String table) {
  return db
      .select("pragma table_info(${_quote(table)});")
      .map((row) => row['name'] as String)
      .toList();
}

/// 从 [src] 复制建表语句到 [dst]（仅在 dst 没有这张表时执行）。
void _ensureTable(Database dst, Database src, String table) {
  if (_tableExists(dst, table)) {
    return;
  }
  var res = src.select(
    "select sql from sqlite_master where type = 'table' and name = ?;",
    [table],
  );
  if (res.isEmpty) {
    return;
  }
  var createSql = res.first['sql'] as String?;
  if (createSql == null) {
    return;
  }
  // 原语句是 create table "xxx"(...)，改成 if not exists 形式更安全。
  var patched = createSql.replaceFirst(
    RegExp(r'^create\s+table\s+', caseSensitive: false),
    'create table if not exists ',
  );
  dst.execute(patched);
}

Map<String, Object?> _rowToMap(Row row, List<String> columns) {
  return {for (var column in columns) column: row[column]};
}
/// 只保留 [values] 里也存在于 [target] 的列，避免新版多出字段时插入失败。
List<String> _commonColumns(List<String> values, List<String> target) {
  var targetSet = target.toSet();
  return values.where(targetSet.contains).toList();
}

void _insertOrReplace(
  Database db,
  String table,
  List<String> columns,
  Map<String, Object?> row,
) {
  if (columns.isEmpty) {
    return;
  }
  var placeholders = List.filled(columns.length, '?').join(', ');
  db.execute(
    'insert or replace into ${_quote(table)} '
    '(${columns.map(_quote).join(', ')}) values ($placeholders);',
    columns.map((column) => row[column]).toList(),
  );
}

// ---------------------------------------------------------------------------
// history 表
// ---------------------------------------------------------------------------

void _mergeHistoryTable(Database src, Database dst) {
  if (!_tableExists(src, 'history')) {
    return;
  }
  _ensureTable(dst, src, 'history');

  var srcColumns = _columnsOf(src, 'history');
  var columns = _commonColumns(srcColumns, _columnsOf(dst, 'history'));
  if (columns.isEmpty) {
    return;
  }

  dst.execute('BEGIN TRANSACTION;');
  try {
    for (var row in src.select('select * from history;')) {
      var remote = _rowToMap(row, columns);
      var existing = dst.select(
        'select * from history where id == ? and type == ?;',
        [remote['id'], remote['type']],
      );
      if (existing.isEmpty) {
        _insertOrReplace(dst, 'history', columns, remote);
        continue;
      }
      var local = _rowToMap(existing.first, columns);
      var localTime = local['time'] as int? ?? 0;
      var remoteTime = remote['time'] as int? ?? 0;
      // 进度相关字段取较新的一端，已读章节取并集。
      var newer = remoteTime > localTime ? remote : local;
      var older = remoteTime > localTime ? local : remote;
      var merged = Map<String, Object?>.from(newer);
      if (columns.contains('readEpisode')) {
        merged['readEpisode'] = _unionReadEpisode(
          newer['readEpisode'] as String?,
          older['readEpisode'] as String?,
        );
      }
      _insertOrReplace(dst, 'history', columns, merged);
    }
    dst.execute('COMMIT;');
  } catch (e) {
    dst.execute('ROLLBACK;');
    rethrow;
  }
}

/// readEpisode 是以逗号分隔的已读章节集合，两边取并集才不会丢进度。
String _unionReadEpisode(String? a, String? b) {
  var set = <String>{};
  for (var raw in [a, b]) {
    if (raw == null) {
      continue;
    }
    for (var part in raw.split(',')) {
      if (part.isNotEmpty) {
        set.add(part);
      }
    }
  }
  return set.join(',');
}

// ---------------------------------------------------------------------------
// image_favorites 表（也在 history.db 里）
// ---------------------------------------------------------------------------

void _mergeImageFavoritesTable(Database src, Database dst) {
  if (!_tableExists(src, 'image_favorites')) {
    return;
  }
  _ensureTable(dst, src, 'image_favorites');

  var columns = _commonColumns(
    _columnsOf(src, 'image_favorites'),
    _columnsOf(dst, 'image_favorites'),
  );
  if (columns.isEmpty) {
    return;
  }

  dst.execute('BEGIN TRANSACTION;');
  try {
    for (var row in src.select('select * from image_favorites;')) {
      var remote = _rowToMap(row, columns);
      var existing = dst.select(
        'select time from image_favorites where id == ? and source_key == ?;',
        [remote['id'], remote['source_key']],
      );
      if (existing.isEmpty) {
        _insertOrReplace(dst, 'image_favorites', columns, remote);
        continue;
      }
      var localTime = existing.first['time'] as int? ?? 0;
      var remoteTime = remote['time'] as int? ?? 0;
      if (remoteTime > localTime) {
        _insertOrReplace(dst, 'image_favorites', columns, remote);
      }
    }
    dst.execute('COMMIT;');
  } catch (e) {
    dst.execute('ROLLBACK;');
    rethrow;
  }
}

// ---------------------------------------------------------------------------
// local_favorite.db
// ---------------------------------------------------------------------------

void _mergeFavoriteDb(Database src, Database dst) {
  var folderTables = src
      .select("select name from sqlite_master where type = 'table';")
      .map((row) => row['name'] as String)
      .where((name) => !name.startsWith('sqlite_'))
      .where((name) => name != 'folder_order' && name != 'folder_sync')
      .toList();

  _mergeFolderOrder(src, dst);
  _mergeFolderSync(src, dst);

  for (var folder in folderTables) {
    _mergeFolderTable(src, dst, folder);
  }
}

void _mergeFolderOrder(Database src, Database dst) {
  if (!_tableExists(src, 'folder_order')) {
    return;
  }
  _ensureTable(dst, src, 'folder_order');
  if (!_tableExists(dst, 'folder_order')) {
    return;
  }
  var nextOrder = _maxInt(dst, 'folder_order', 'order_value') + 1;
  for (var row in src.select('select * from folder_order;')) {
    var name = row['folder_name'];
    var existing = dst.select(
      'select 1 from folder_order where folder_name == ?;',
      [name],
    );
    if (existing.isNotEmpty) {
      continue;
    }
    dst.execute(
      'insert or replace into folder_order (folder_name, order_value) '
      'values (?, ?);',
      [name, nextOrder++],
    );
  }
}

void _mergeFolderSync(Database src, Database dst) {
  if (!_tableExists(src, 'folder_sync')) {
    return;
  }
  _ensureTable(dst, src, 'folder_sync');
  if (!_tableExists(dst, 'folder_sync')) {
    return;
  }
  for (var row in src.select('select * from folder_sync;')) {
    dst.execute(
      'insert or ignore into folder_sync '
      '(folder_name, source_key, source_folder) values (?, ?, ?);',
      [row['folder_name'], row['source_key'], row['source_folder']],
    );
  }
}

void _mergeFolderTable(Database src, Database dst, String folder) {
  _ensureTable(dst, src, folder);
  if (!_tableExists(dst, folder)) {
    return;
  }

  var columns = _commonColumns(
    _columnsOf(src, folder),
    _columnsOf(dst, folder),
  );
  if (columns.isEmpty) {
    return;
  }

  var orderIndex = columns.indexOf('display_order');
  var nextOrder = orderIndex >= 0
      ? _maxInt(dst, folder, 'display_order') + 1
      : 0;

  dst.execute('BEGIN TRANSACTION;');
  try {
    for (var row in src.select('select * from ${_quote(folder)};')) {
      var remote = _rowToMap(row, columns);
      var existing = dst.select(
        'select 1 from ${_quote(folder)} where id == ? and type == ?;',
        [remote['id'], remote['type']],
      );
      if (existing.isNotEmpty) {
        // 本地已经有收藏了，保留本地状态（含排序、标签翻译、封面缓存）。
        continue;
      }
      if (orderIndex >= 0) {
        remote['display_order'] = nextOrder++;
      }
      _insertOrReplace(dst, folder, columns, remote);
    }
    dst.execute('COMMIT;');
  } catch (e) {
    dst.execute('ROLLBACK;');
    rethrow;
  }
}

int _maxInt(Database db, String table, String column) {
  if (!_tableExists(db, table)) {
    return 0;
  }
  var res = db.select(
    'select max(${_quote(column)}) as m from ${_quote(table)};',
  );
  if (res.isEmpty) {
    return 0;
  }
  var value = res.first['m'];
  return value is int ? value : 0;
}
