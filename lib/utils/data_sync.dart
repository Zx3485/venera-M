import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:venera/components/components.dart';
import 'package:venera/components/window_frame.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/foundation/appdata.dart';
import 'package:venera/foundation/comic_source/comic_source.dart';
import 'package:venera/foundation/favorites.dart';
import 'package:venera/foundation/log.dart';
import 'package:venera/foundation/res.dart';
import 'package:venera/network/app_dio.dart';
import 'package:venera/utils/data.dart';
import 'package:venera/utils/ext.dart';
import 'package:webdav_client/webdav_client.dart' hide File;
import 'package:venera/utils/translations.dart';

import 'io.dart';

class DataSync with ChangeNotifier {
  DataSync._() {
    if (isEnabled) {
      downloadData();
    }
    LocalFavoritesManager().addListener(onDataChanged);
    ComicSourceManager().addListener(onDataChanged);
    if (App.isDesktop) {
      Future.delayed(const Duration(seconds: 1), () {
        var controller = WindowFrame.of(App.rootContext);
        controller.addCloseListener(_handleWindowClose);
      });
    }
  }

  /// 自动上传的合并窗口。
  ///
  /// 启动、批量收藏、导入存档这类操作会在极短时间里连续触发几十次
  /// [onDataChanged]，以前每一次都真的发一轮 WebDAV 上传，既慢又会互相
  /// 打断（只有一个能真正跑起来，其余被静默丢弃）。现在统一走防抖窗口，
  /// 窗口内的多次变更合并成一次上传。
  static const _kUploadDebounce = Duration(seconds: 2);

  Timer? _uploadDebounce;

  /// 上一次上传还没结束时又来了新改动的补传标记。
  bool _uploadQueued = false;

  /// 大于 0 时丢弃一切自动上传。
  ///
  /// 下载合并期间，本地数据全部来自云端，逐条 notify 触发的回传纯属浪费，
  /// 还会和下载互相等待。用计数器支持嵌套。
  int _suppressUpload = 0;

  /// 数据变化时的统一入口：合并成一次上传。
  ///
  /// 所有自动触发上传的地方（appdata.saveData、ComicSource.saveData、
  /// 阅读器退出、管理器通知）都应该改走这里，而不是直接 [uploadData]。
  void scheduleUpload() {
    if (_suppressUpload > 0) {
      return;
    }
    if (!isEnabled) {
      return;
    }
    // 下载进行中：不丢，先记账，等下载结束再补一轮。
    // （合并本身引起的那部分已被 withoutAutoUpload 抑制，走不到这里。）
    if (isDownloading) {
      _uploadQueued = true;
      return;
    }
    if (isUploading) {
      _uploadQueued = true;
      return;
    }
    _uploadDebounce?.cancel();
    _uploadDebounce = Timer(_kUploadDebounce, () {
      _uploadDebounce = null;
      uploadData();
    });
  }

  /// 取消待发的那一轮上传，但把「确实有改动没发出」记进 [_uploadQueued]。
  ///
  /// 不能只 cancel 了事：例如用户在 2 秒窗口内改了设置，恰好这时又触发了
  /// 下载（回到前台 / 手动点同步），改动必须留到下载结束后补发，否则就丢了。
  void _deferPendingUpload() {
    if (_uploadDebounce != null) {
      _uploadDebounce!.cancel();
      _uploadDebounce = null;
      _uploadQueued = true;
    }
  }

  /// 在 [body] 执行期间抑制自动上传。
  ///
  /// 用于下载合并：期间产生的 saveData / notifyListeners 不应该再推回云端。
  Future<T> withoutAutoUpload<T>(Future<T> Function() body) async {
    _suppressUpload++;
    try {
      return await body();
    } finally {
      _suppressUpload--;
    }
  }

  void onDataChanged() {
    scheduleUpload();
  }

  bool _handleWindowClose() {
    if (_uploadDebounce != null) {
      // 还有没发出去的改动，先冲掉再关窗口。
      _uploadDebounce!.cancel();
      _uploadDebounce = null;
      uploadData();
    }
    if (_isUploading) {
      _showWindowCloseDialog();
      return false;
    }
    return true;
  }

  void _showWindowCloseDialog() async {
    showLoadingDialog(
      App.rootContext,
      cancelButtonText: "Shut Down".tl,
      onCancel: () => exit(0),
      barrierDismissible: false,
      message: "Uploading data...".tl,
    );
    while (_isUploading) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    exit(0);
  }

  static DataSync? instance;

  factory DataSync() => instance ?? (instance = DataSync._());

  bool _isDownloading = false;

  bool get isDownloading => _isDownloading;

  bool _isUploading = false;

  bool get isUploading => _isUploading;

  bool _haveWaitingTask = false;

  String? _lastError;

  String? get lastError => _lastError;

  bool get isEnabled {
    var config = appdata.settings['webdav'];
    var autoSync = appdata.implicitData['webdavAutoSync'] ?? false;
    return autoSync && config is List && config.isNotEmpty;
  }

  List<String>? _validateConfig() {
    var config = appdata.settings['webdav'];
    if (config is! List) {
      return null;
    }
    if (config.isEmpty) {
      return [];
    }
    if (config.length != 3 || config.whereType<String>().length != 3) {
      return null;
    }
    return List.from(config);
  }

  Future<Res<bool>> uploadData() async {
    // 手动/计划外的上传请求直接冲掉待发的防抖，避免紧接着再来一次。
    _uploadDebounce?.cancel();
    _uploadDebounce = null;
    // 正在下载：本轮发不出去，但意图要留下，下载结束会补一轮。
    if (isDownloading) {
      _uploadQueued = true;
      return const Res(true);
    }
    if (_haveWaitingTask) return const Res(true);
    while (isUploading) {
      _haveWaitingTask = true;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _haveWaitingTask = false;
    _isUploading = true;
    _lastError = null;
    notifyListeners();
    try {
      var config = _validateConfig();
      if (config == null) {
        _lastError = 'Invalid WebDAV configuration';
        return const Res.error('Invalid WebDAV configuration');
      }
      if (config.isEmpty) {
        return const Res(true);
      }
      String url = config[0];
      String user = config[1];
      String pass = config[2];

      var client = newClient(
        url,
        user: user,
        password: pass,
        adapter: RHttpAdapter(),
      );

      try {
        // 先列云端目录，取「云端最大版本号」与「本地版本号」的较大值再 +1。
        // 这样两台设备各自自增也不会撞号，文件名能真实反映谁更新。
        var files = await client.readDir('/');
        files = files.where((e) => e.name!.endsWith('.venera')).toList();
        var remoteMax = _maxVersionInFiles(files);
        var localVersion = appdata.settings['dataVersion'];
        var baseVersion = localVersion is int ? localVersion : 0;
        if (remoteMax > baseVersion) {
          baseVersion = remoteMax;
        }
        appdata.settings['dataVersion'] = baseVersion + 1;
        await appdata.saveData(false);
        var data = await exportAppData(
            appdata.settings['disableSyncFields'].toString().isNotEmpty
        );
        var time =
            (DateTime.now().millisecondsSinceEpoch ~/ 86400000).toString();
        var filename = time;
        filename += '-';
        filename += appdata.settings['dataVersion'].toString();
        filename += '.venera';
        var old = files.firstWhereOrNull((e) => e.name!.startsWith("$time-"));
        if (old != null) {
          await client.remove(old.name!);
        }
        if (files.length >= 10) {
          // 同样要用数值比较，否则可能删掉版本号更高的那份。
          files.sort((a, b) => _compareDataFileNames(b.name!, a.name!));
          await client.remove(files.last.name!);
        }
        await client.write(filename, await data.readAsBytes());
        data.deleteIgnoreError();
        Log.info("Upload Data", "Data uploaded successfully");
        return const Res(true);
      } catch (e, s) {
        Log.error("Upload Data", e, s);
        _lastError = e.toString();
        return Res.error(e.toString());
      }
    } finally {
      _isUploading = false;
      notifyListeners();
      // 上传期间又攒下了新改动：补一次，但仍然走防抖，连发只会合一轮。
      if (_uploadQueued) {
        _uploadQueued = false;
        scheduleUpload();
      }
    }
  }

  Future<Res<bool>> downloadData() async {
    if (_haveWaitingTask) return const Res(true);
    while (isDownloading || isUploading) {
      _haveWaitingTask = true;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _haveWaitingTask = false;
    // 真正要开始下载了才挂起待发的上传；放在提前 return 之前的话，
    // 一旦在入口就退出，那一轮上传就再也没人补发。
    _deferPendingUpload();
    _isDownloading = true;
    _lastError = null;
    notifyListeners();
    try {
      var config = _validateConfig();
      if (config == null) {
        _lastError = 'Invalid WebDAV configuration';
        return const Res.error('Invalid WebDAV configuration');
      }
      if (config.isEmpty) {
        return const Res(true);
      }
      String url = config[0];
      String user = config[1];
      String pass = config[2];

      var client = newClient(
        url,
        user: user,
        password: pass,
        adapter: RHttpAdapter(),
      );

      try {
        var files = await client.readDir('/');
        // 只把 .venera 当候选，再按「天数 → 版本号」的**数值**排序。
        // 以前是对整个文件名做字符串降序：同一天里 20431-9 会排在
        // 20431-10 前面（'9' > '1'），于是版本 10 之后永远下载到旧快照，
        // 表现就是「这边改了那边一直看不到」。
        files = files.where((e) => e.name!.endsWith('.venera')).toList();
        files.sort((a, b) => _compareDataFileNames(b.name!, a.name!));
        var file = files.firstOrNull;
        if (file == null) {
          throw 'No data file found';
        }
        var version =
            file.name!.split('-').elementAtOrNull(1)?.split('.').first;
        // 合并模式下不能靠版本号跳过：两台设备各自上传时版本号可能相同，
        // 但内容不同，跳过就会漏掉合并。合并是幂等的，重复跑不会出问题。
        Log.info("Data Sync", "Downloading data from WebDAV server");
        var localFile = File(FilePath.join(App.cachePath, file.name!));
        await client.read2File(file.name!, localFile.path);
        // 合并期间大量 notifyListeners / saveData 会把刚下载的数据原样推回去，
        // 既浪费一轮往返，又可能盖掉另一台设备刚上传的内容。整段抑制。
        await withoutAutoUpload(() => importAppData(localFile, false, true));
        await localFile.delete();
        // 合并完成后把本地版本号抬到云端版本，避免下次重复下载同一个文件；
        // 不主动触发上传，等下一次真实的数据变更再推。
        if (version != null) {
          var remoteVersion = int.tryParse(version);
          var currentVersion = appdata.settings['dataVersion'];
          if (remoteVersion != null &&
              currentVersion is int &&
              remoteVersion > currentVersion) {
            appdata.settings['dataVersion'] = remoteVersion;
            appdata.saveData(false);
          }
        }
        Log.info("Data Sync", "Data downloaded successfully");
        return const Res(true);
      } catch (e, s) {
        Log.error("Data Sync", e, s);
        _lastError = e.toString();
        return Res.error(e.toString());
      }
    } finally {
      _isDownloading = false;
      notifyListeners();
      // 下载前被挂起的本地上传，现在补发（仍然走防抖，只发一轮）。
      // 注意：只有「真实的本地改动」才该走到这里——合并本身已被
      // withoutAutoUpload 抑制，不会把刚拉下来的数据原样推回去。
      if (_uploadQueued) {
        _uploadQueued = false;
        scheduleUpload();
      }
    }
  }

  /// 按「天数 → 版本号」的数值比较两个 `.venera` 文件名。
  ///
  /// 文件名是 `<天数>-<版本号>.venera`。字符串比较在版本号进入两位数后
  /// 会出错（`20431-9` 排到 `20431-10` 之后），导致下载到旧快照。
  /// 解析不出来的退化成字符串比较，不会抛异常。
  static int _compareDataFileNames(String a, String b) {
    var pa = _parseDataFileName(a);
    var pb = _parseDataFileName(b);
    if (pa != null && pb != null) {
      var day = pa.$1.compareTo(pb.$1);
      if (day != 0) {
        return day;
      }
      var ver = pa.$2.compareTo(pb.$2);
      if (ver != 0) {
        return ver;
      }
    }
    return a.compareTo(b);
  }

  static (int, int)? _parseDataFileName(String? name) {
    if (name == null) {
      return null;
    }
    var parts = name.split('-');
    if (parts.length < 2) {
      return null;
    }
    var day = int.tryParse(parts[0]);
    var version = int.tryParse(parts[1].split('.').first);
    if (day == null || version == null) {
      return null;
    }
    return (day, version);
  }

  /// 从云端文件名里取最大的版本号。
  ///
  /// 文件名格式是 `<天数>-<版本号>.venera`，例如 `20431-42.venera`。
  /// 参数用 `dynamic` 接收，因为 webdav_client 的目录项类型在本文件里
  /// 与 dart:io 的 File 同名（已在 import 处 hide），不写死类型更稳。
  /// 解析不出来的一律忽略，不会抛异常。
  static int _maxVersionInFiles(List<dynamic> files) {
    var maxVersion = 0;
    for (var file in files) {
      var name = file.name;
      if (name is! String) {
        continue;
      }
      var parts = name.split('-');
      if (parts.length < 2) {
        continue;
      }
      var versionPart = parts[1].split('.').first;
      var version = int.tryParse(versionPart);
      if (version != null && version > maxVersion) {
        maxVersion = version;
      }
    }
    return maxVersion;
  }
}
