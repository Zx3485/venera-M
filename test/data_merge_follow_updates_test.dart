// 追更状态合并的回归测试。
//
// 背景：webdav 同步走「按主键合并」而不是整库替换。合并收藏夹各表时，
// 只要本地已经有这条漫画就整行跳过——连 last_update_time /
// has_new_update / last_check_time 三列一起跳过。后果是一台设备检查出的
// 更新永远到不了另一台，那台设备的「追更」页一直空着。
//
// 这个测试把「云端有更新、本地没有」和「本地更新、云端更旧」两种情况都
// 跑一遍，确保三列按 last_check_time 的新旧正确取舍。
//
// 运行：flutter test test/data_merge_follow_updates_test.dart
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:venera/utils/data_merge.dart';

/// 测试环境没有 sqlite3_flutter_libs 提供的 dll，借用系统自带的。
void _ensureSqlite() {
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }
}

/// 建一个最小的收藏夹库：folder_order / folder_sync / 一个收藏夹表。
Database _createDb(String path, {required String folder}) {
  var db = sqlite3.open(path);
  db.execute('''
    create table folder_order (
      folder_name text primary key,
      order_value int
    );
  ''');
  db.execute('''
    create table folder_sync (
      folder_name text primary key,
      source_key text,
      source_folder text
    );
  ''');
  db.execute('''
    create table "$folder"(
      id text,
      name TEXT,
      author TEXT,
      type int,
      tags TEXT,
      cover_path TEXT,
      time TEXT,
      display_order int,
      translated_tags TEXT,
      last_update_time TEXT,
      has_new_update int,
      last_check_time int,
      primary key (id, type)
    );
  ''');
  db.execute(
    'insert into folder_order (folder_name, order_value) values (?, 0);',
    [folder],
  );
  return db;
}

void _addComic(
  Database db,
  String folder, {
  required String id,
  required int type,
  String? lastUpdateTime,
  int hasNewUpdate = 0,
  int? lastCheckTime,
  String name = 'comic',
}) {
  db.execute(
    'insert into "$folder" '
    '(id, name, author, type, tags, cover_path, time, display_order, '
    'last_update_time, has_new_update, last_check_time) '
    'values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);',
    [
      id, name, 'author', type, 'tag', 'cover', '2026-11-01 00:00:00', 0,
      lastUpdateTime, hasNewUpdate, lastCheckTime,
    ],
  );
}

Map<String, Object?> _readComic(Database db, String folder, String id) {
  var row = db.select(
    'select * from "$folder" where id == ?;',
    [id],
  ).first;
  return {for (var key in row.keys) key: row[key]};
}

void main() {
  setUpAll(_ensureSqlite);

  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('merge_test_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  const folder = '追更';

  test('云端检查得更晚时，追更状态应该合并到本地', () {
    var incomingPath = '${tmp.path}/incoming.db';
    var localPath = '${tmp.path}/local.db';

    // 云端：这条在 2026-11-21 检查过，发现有更新
    var incoming = _createDb(incomingPath, folder: folder);
    _addComic(
      incoming,
      folder,
      id: 'brain-hole',
      type: 1,
      lastUpdateTime: '2026-11-21',
      hasNewUpdate: 1,
      lastCheckTime: 2000,
    );
    incoming.dispose();

    // 本地：同一条，但从没检查过（本地新收藏，或从没联网成功过）
    var local = _createDb(localPath, folder: folder);
    _addComic(local, folder, id: 'brain-hole', type: 1);
    local.dispose();

    mergeFavoriteDatabases(incomingPath: incomingPath, localPath: localPath);

    local = sqlite3.open(localPath);
    var row = _readComic(local, folder, 'brain-hole');
    local.dispose();

    expect(row['last_update_time'], '2026-11-21',
        reason: '云端的更新日期必须写进本地');
    expect(row['has_new_update'], 1, reason: '云端标记的「有新更新」必须带过来');
    expect(row['last_check_time'], 2000, reason: '检查时间也要一起带过来');
  });

  test('本地检查得更晚时，不能被云端旧状态覆盖', () {
    var incomingPath = '${tmp.path}/incoming.db';
    var localPath = '${tmp.path}/local.db';

    // 云端：旧状态，2026-11-19
    var incoming = _createDb(incomingPath, folder: folder);
    _addComic(
      incoming,
      folder,
      id: 'comic-a',
      type: 1,
      lastUpdateTime: '2026-11-19',
      hasNewUpdate: 1,
      lastCheckTime: 1000,
    );
    incoming.dispose();

    // 本地：已经读过（has_new_update=0），且检查时间更新
    var local = _createDb(localPath, folder: folder);
    _addComic(
      local,
      folder,
      id: 'comic-a',
      type: 1,
      lastUpdateTime: '2026-11-20',
      hasNewUpdate: 0,
      lastCheckTime: 3000,
    );
    local.dispose();

    mergeFavoriteDatabases(incomingPath: incomingPath, localPath: localPath);

    local = sqlite3.open(localPath);
    var row = _readComic(local, folder, 'comic-a');
    local.dispose();

    expect(row['has_new_update'], 0, reason: '本地已经读过了，不能让云端旧状态盖回去');
    expect(row['last_update_time'], '2026-11-20', reason: '本地的更新日期更新，要保留');
    expect(row['last_check_time'], 3000, reason: '检查时间保留本地');
  });

  test('云端从没检查过时，不要冲掉本地的追更状态', () {
    var incomingPath = '${tmp.path}/incoming.db';
    var localPath = '${tmp.path}/local.db';

    // 云端：从没检查过（last_check_time 为 null）
    var incoming = _createDb(incomingPath, folder: folder);
    _addComic(incoming, folder, id: 'comic-b', type: 1);
    incoming.dispose();

    var local = _createDb(localPath, folder: folder);
    _addComic(
      local,
      folder,
      id: 'comic-b',
      type: 1,
      lastUpdateTime: '2026-11-20',
      hasNewUpdate: 1,
      lastCheckTime: 3000,
    );
    local.dispose();

    mergeFavoriteDatabases(incomingPath: incomingPath, localPath: localPath);

    local = sqlite3.open(localPath);
    var row = _readComic(local, folder, 'comic-b');
    local.dispose();

    expect(row['has_new_update'], 1, reason: '云端没有信息，本地状态必须原样保留');
    expect(row['last_check_time'], 3000);
  });

  test('检查时间打平时，谁看到的更新日期更晚就用谁', () {
    var incomingPath = '${tmp.path}/incoming.db';
    var localPath = '${tmp.path}/local.db';

    // 同一天检查过，但云端看到了更晚的更新日期。
    var incoming = _createDb(incomingPath, folder: folder);
    _addComic(
      incoming,
      folder,
      id: 'comic-c',
      type: 1,
      lastUpdateTime: '2026-11-21',
      hasNewUpdate: 1,
      lastCheckTime: 5000,
    );
    incoming.dispose();

    var local = _createDb(localPath, folder: folder);
    _addComic(
      local,
      folder,
      id: 'comic-c',
      type: 1,
      lastUpdateTime: '2026-11-19',
      hasNewUpdate: 0,
      lastCheckTime: 5000,
    );
    local.dispose();

    mergeFavoriteDatabases(incomingPath: incomingPath, localPath: localPath);

    local = sqlite3.open(localPath);
    var row = _readComic(local, folder, 'comic-c');
    local.dispose();

    expect(row['last_update_time'], '2026-11-21');
    expect(row['has_new_update'], 1,
        reason: '云端看到的是更新的日期，说明本地落后了');
  });

  test('检查时间打平且更新日期也相同时，保留本地已读状态', () {
    var incomingPath = '${tmp.path}/incoming.db';
    var localPath = '${tmp.path}/local.db';

    var incoming = _createDb(incomingPath, folder: folder);
    _addComic(
      incoming,
      folder,
      id: 'comic-d',
      type: 1,
      lastUpdateTime: '2026-11-21',
      hasNewUpdate: 1,
      lastCheckTime: 5000,
    );
    incoming.dispose();

    // 本地同一个更新日期，但已经读过（清零）。
    var local = _createDb(localPath, folder: folder);
    _addComic(
      local,
      folder,
      id: 'comic-d',
      type: 1,
      lastUpdateTime: '2026-11-21',
      hasNewUpdate: 0,
      lastCheckTime: 5000,
    );
    local.dispose();

    mergeFavoriteDatabases(incomingPath: incomingPath, localPath: localPath);

    local = sqlite3.open(localPath);
    var row = _readComic(local, folder, 'comic-d');
    local.dispose();

    expect(row['has_new_update'], 0,
        reason: '同一批更新，本地已经读过了，不应该又被标成未读');
  });

  test('本地收藏夹表是旧 schema 时，追更三列要能补出来', () {
    var incomingPath = '${tmp.path}/incoming.db';
    var localPath = '${tmp.path}/local.db';

    var incoming = _createDb(incomingPath, folder: folder);
    _addComic(
      incoming,
      folder,
      id: 'comic-e',
      type: 1,
      lastUpdateTime: '2026-11-21',
      hasNewUpdate: 1,
      lastCheckTime: 2000,
    );
    incoming.dispose();

    // 本地是旧版本的库，追更三列不存在。
    var local = sqlite3.open(localPath);
    local.execute('''
      create table folder_order (
        folder_name text primary key,
        order_value int
      );
    ''');
    local.execute('''
      create table folder_sync (
        folder_name text primary key,
        source_key text,
        source_folder text
      );
    ''');
    local.execute('''
      create table "$folder"(
        id text,
        name TEXT,
        author TEXT,
        type int,
        tags TEXT,
        cover_path TEXT,
        time TEXT,
        display_order int,
        translated_tags TEXT,
        primary key (id, type)
      );
    ''');
    local.execute(
      'insert into "$folder" '
      '(id, name, author, type, tags, cover_path, time, display_order) '
      'values (?, ?, ?, ?, ?, ?, ?, ?);',
      ['comic-e', 'comic', 'author', 1, 'tag', 'cover', '2026-11-01 00:00:00', 0],
    );
    local.dispose();

    mergeFavoriteDatabases(incomingPath: incomingPath, localPath: localPath);

    local = sqlite3.open(localPath);
    var row = _readComic(local, folder, 'comic-e');
    local.dispose();

    expect(row['last_update_time'], '2026-11-21',
        reason: '旧库要先补列，否则云端的追更状态会被整个丢掉');
    expect(row['has_new_update'], 1);
  });

  test('在另一台设备读完后，这台设备的「有更新」也要清掉', () {
    var incomingPath = '${tmp.path}/incoming.db';
    var localPath = '${tmp.path}/local.db';

    // 设备 A：读过了，has_new_update 被清零。
    // 注意 markAsRead 过去只改这一列，两个时间戳原样不动——这正是 bug 所在：
    // 清零点没有留下任何时间证据，合并时无法判断哪边更新。
    var incoming = _createDb(incomingPath, folder: folder);
    _addComic(
      incoming,
      folder,
      id: 'comic-read-elsewhere',
      type: 1,
      lastUpdateTime: '2026-11-21',
      hasNewUpdate: 0, // 读过了
      lastCheckTime: 4000,
    );
    incoming.dispose();

    // 设备 B：还没读，还标着有更新，而且它的检查时间"看起来"更晚。
    var local = _createDb(localPath, folder: folder);
    _addComic(
      local,
      folder,
      id: 'comic-read-elsewhere',
      type: 1,
      lastUpdateTime: '2026-11-21',
      hasNewUpdate: 1,
      lastCheckTime: 4000,
    );
    local.dispose();

    mergeFavoriteDatabases(incomingPath: incomingPath, localPath: localPath);

    local = sqlite3.open(localPath);
    var row = _readComic(local, folder, 'comic-read-elsewhere');
    local.dispose();

    expect(row['has_new_update'], 0,
        reason: '另一台已经读完了，这台不该再提示有更新');
  });

  test('已读推进时间戳后走正常分支：云端更晚的已读状态要采纳', () {
    var incomingPath = '${tmp.path}/incoming.db';
    var localPath = '${tmp.path}/local.db';

    // 设备 A 读完时 markAsRead 推进了 last_check_time → 比 B 更新。
    var incoming = _createDb(incomingPath, folder: folder);
    _addComic(
      incoming,
      folder,
      id: 'comic-main-path',
      type: 1,
      lastUpdateTime: '2026-11-21',
      hasNewUpdate: 0,
      lastCheckTime: 9000, // 读完的时刻，比 B 的检查时间晚
    );
    incoming.dispose();

    // 设备 B：只知道检查出更新，还不知道 A 读过了。
    var local = _createDb(localPath, folder: folder);
    _addComic(
      local,
      folder,
      id: 'comic-main-path',
      type: 1,
      lastUpdateTime: '2026-11-21',
      hasNewUpdate: 1,
      lastCheckTime: 8000,
    );
    local.dispose();

    mergeFavoriteDatabases(incomingPath: incomingPath, localPath: localPath);

    local = sqlite3.open(localPath);
    var row = _readComic(local, folder, 'comic-main-path');
    local.dispose();

    expect(row['has_new_update'], 0, reason: '云端是更新一轮的状态，红点要清掉');
    expect(row['last_check_time'], 9000, reason: '时间戳要跟着推进');
  });

  test('本地读过之后云端又出了新章节，新更新不能被本地已读压掉', () {
    var incomingPath = '${tmp.path}/incoming.db';
    var localPath = '${tmp.path}/local.db';

    // 云端：又出了一话，更新时间更晚。
    var incoming = _createDb(incomingPath, folder: folder);
    _addComic(
      incoming,
      folder,
      id: 'comic-new-chapter',
      type: 1,
      lastUpdateTime: '2026-11-22', // 新章节
      hasNewUpdate: 1,
      lastCheckTime: 7000,
    );
    incoming.dispose();

    // 本地：刚读完上一话，markAsRead 把时间戳推到 9000（比云端还晚），
    // 但 last_update_time 还停在 2026-11-21。
    var local = _createDb(localPath, folder: folder);
    _addComic(
      local,
      folder,
      id: 'comic-new-chapter',
      type: 1,
      lastUpdateTime: '2026-11-21',
      hasNewUpdate: 0,
      lastCheckTime: 9000,
    );
    local.dispose();

    mergeFavoriteDatabases(incomingPath: incomingPath, localPath: localPath);

    local = sqlite3.open(localPath);
    var row = _readComic(local, folder, 'comic-new-chapter');
    local.dispose();

    expect(row['last_update_time'], '2026-11-22',
        reason: '云端的更新时间更晚，说明有新章节');
    expect(row['has_new_update'], 1,
        reason: '本地「读过」只代表读过上一话，不能把新章节的红点也压掉');
  });

  test('云端新收藏的漫画仍然要能合并进来', () {
    var incomingPath = '${tmp.path}/incoming.db';
    var localPath = '${tmp.path}/local.db';

    var incoming = _createDb(incomingPath, folder: folder);
    _addComic(
      incoming,
      folder,
      id: 'only-remote',
      type: 1,
      lastUpdateTime: '2026-11-21',
      hasNewUpdate: 1,
      lastCheckTime: 2000,
    );
    incoming.dispose();

    var local = _createDb(localPath, folder: folder);
    local.dispose();

    mergeFavoriteDatabases(incomingPath: incomingPath, localPath: localPath);

    local = sqlite3.open(localPath);
    var row = _readComic(local, folder, 'only-remote');
    local.dispose();

    expect(row['last_update_time'], '2026-11-21');
    expect(row['has_new_update'], 1);
  });
}
