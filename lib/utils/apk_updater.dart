import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/foundation/log.dart';

/// 应用内自动更新：下载 APK 到私有缓存目录，再交给系统安装器。
///
/// 只在 Android 上有效；其他平台返回 false，调用方应回退到浏览器下载。
class ApkUpdater {
  static const _channel = MethodChannel("venera/method_channel");

  /// 下载进度回调：0.0 ~ 1.0，未知总量时传 null。
  static void Function(double? progress)? onProgress;

  /// 更新包放在 app 私有缓存目录的 updates/ 下。
  static Future<Directory> _updateDir() async {
    final dir = await getTemporaryDirectory();
    final d = Directory("${dir.path}/updates");
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return d;
  }

  /// 清掉残留的更新包。装完、失败、下次启动都可以调。
  static Future<void> cleanUp() async {
    try {
      final d = await _updateDir();
      if (!await d.exists()) return;
      await for (final f in d.list()) {
        if (f is File && f.path.endsWith('.apk')) {
          try {
            await f.delete();
            Log.info("Update", "Cleaned ${f.path}");
          } catch (_) {
            // 文件可能还被系统安装器占用，下次再删
          }
        }
      }
    } catch (e) {
      Log.error("Update", "cleanUp failed: $e");
    }
  }

  /// 下载 [url] 并调起安装。成功返回 true。
  ///
  /// 失败原因会写进日志（分类见 [_failReason]），调用方可据此决定提示文案。
  static Future<bool> downloadAndInstall(String url) async {
    if (!App.isAndroid) {
      Log.info("Update", "Not Android, skip in-app install");
      _failReason = "not_android";
      return false;
    }
    // 先清一次，避免旧包干扰
    await cleanUp();
    try {
      final dir = await _updateDir();
      final file = File("${dir.path}/venera-m-update.apk");

      onProgress?.call(0);
      Log.info("Update", "Start download: $url");

      // 用 dart:io 的 HttpClient 直接下，避免经过 AppDio 的拦截器与缓存
      final client = HttpClient();
      try {
        final req = await client.getUrl(Uri.parse(url));
        req.headers.set(HttpHeaders.userAgentHeader, "venera-m");
        // GitHub Releases 的下载会 302 到 objects.githubusercontent.com，
        // HttpClient 默认会跟随重定向，这里显式加大次数以防多层跳转。
        final res = await req.close();
        Log.info("Update", "HTTP ${res.statusCode} from ${res.redirects.length} redirect(s)");
        if (res.statusCode != 200) {
          Log.error("Update", "Download failed: HTTP ${res.statusCode}");
          _failReason = "http_${res.statusCode}";
          return false;
        }
        final total = res.contentLength;
        var received = 0;
        final sink = file.openWrite();
        try {
          await for (final chunk in res) {
            sink.add(chunk);
            received += chunk.length;
            if (total > 0) {
              onProgress?.call(received / total);
            }
          }
        } finally {
          await sink.flush();
          await sink.close();
        }
        Log.info("Update", "Downloaded $received bytes to ${file.path}");
      } finally {
        client.close();
      }

      final len = await file.exists() ? await file.length() : 0;
      if (len < 1024) {
        Log.error("Update", "Downloaded file too small ($len bytes), abort");
        _failReason = "too_small";
        await cleanUp();
        return false;
      }

      onProgress?.call(1);

      final ok = await _channel.invokeMethod<bool>("installApk", {
        "path": file.path,
      });
      Log.info("Update", "installApk returned $ok");

      // 装完立刻尝试删；如果系统安装器还占着文件会失败，
      // 那就等一会儿再删，并保留上次启动时的清理作为兜底。
      if (ok == true) {
        unawaited(_deleteLater(file));
      }
      return ok ?? false;
    } on PlatformException catch (e) {
      _failReason = e.code == "NO_PERMISSION" ? "no_permission" : "platform_${e.code}";
      if (e.code == "NO_PERMISSION") {
        App.rootContext.showMessage(
          message: "Please allow installing unknown apps, then try again.",
        );
      } else {
        Log.error("Update", "Install failed: ${e.code} ${e.message}");
      }
      return false;
    } catch (e, s) {
      _failReason = "exception";
      Log.error("Update", e.toString(), s);
      return false;
    }
  }

  /// 上一次失败的原因，供界面决定跳转还是提示。
  /// 取值：not_android / http_xxx / too_small / no_permission / platform_xxx / exception
  static String? _failReason;
  static String? get lastFailReason => _failReason;

  /// 延迟删除，给系统安装器留出读取时间。
  static Future<void> _deleteLater(File f) async {
    for (final wait in [3, 10, 30]) {
      await Future.delayed(Duration(seconds: wait));
      try {
        if (await f.exists()) {
          await f.delete();
          Log.info("Update", "Deleted update package after install");
          return;
        }
        return;
      } catch (_) {
        // 还占用着，继续等下一轮
      }
    }
    Log.info("Update", "Update package still locked, will retry on next launch");
  }
}
