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

  /// 下载 [url] 并调起安装。成功返回 true。
  ///
  /// 注意：Android 8.0+ 首次使用需要在系统设置里允许「安装未知应用」，
  /// 没授权时原生侧会跳到授权页并抛 NO_PERMISSION，这里返回 false，
  /// 调用方应提示用户再点一次。
  static Future<bool> downloadAndInstall(String url) async {
    if (!App.isAndroid) {
      Log.info("Update", "Not Android, skip in-app install");
      return false;
    }
    try {
      final dir = await getTemporaryDirectory();
      final updateDir = Directory("${dir.path}/updates");
      if (!await updateDir.exists()) {
        await updateDir.create(recursive: true);
      }
      // 固定文件名，重复下载会覆盖，避免缓存堆积
      final file = File("${updateDir.path}/venera-m-update.apk");
      if (await file.exists()) {
        await file.delete();
      }

      onProgress?.call(0);

      // 用 dart:io 的 HttpClient 直接下，避免经过 AppDio 的拦截器与缓存
      final client = HttpClient();
      try {
        final req = await client.getUrl(Uri.parse(url));
        req.headers.set(HttpHeaders.userAgentHeader, "venera-m");
        final res = await req.close();
        if (res.statusCode != 200) {
          Log.error("Update", "Download failed: HTTP ${res.statusCode}");
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

      if (!await file.exists() || await file.length() < 1024) {
        Log.error("Update", "Downloaded file too small, abort");
        return false;
      }

      onProgress?.call(1);

      final ok = await _channel.invokeMethod<bool>("installApk", {
        "path": file.path,
      });
      return ok ?? false;
    } on PlatformException catch (e) {
      if (e.code == "NO_PERMISSION") {
        App.rootContext.showMessage(
          message: "Please allow installing unknown apps, then try again.",
        );
      } else {
        Log.error("Update", "Install failed: ${e.code} ${e.message}");
      }
      return false;
    } catch (e, s) {
      Log.error("Update", e.toString(), s);
      return false;
    }
  }
}
