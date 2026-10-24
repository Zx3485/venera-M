part of 'settings_page.dart';

class AboutSettings extends StatefulWidget {
  const AboutSettings({super.key});

  @override
  State<AboutSettings> createState() => _AboutSettingsState();
}

class _AboutSettingsState extends State<AboutSettings> {
  bool isCheckingUpdate = false;

  @override
  Widget build(BuildContext context) {
    return SmoothCustomScrollView(
      slivers: [
        SliverAppbar(title: Text("About".tl)),
        SizedBox(
          height: 112,
          width: double.infinity,
          child: Center(
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(136),
              ),
              clipBehavior: Clip.antiAlias,
              child: const Image(
                image: AssetImage("assets/app_icon.png"),
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ).paddingTop(16).toSliver(),
        Column(
          children: [
            const SizedBox(height: 8),
            Text(
              "V${App.version}",
              style: const TextStyle(fontSize: 16),
            ),
            Text("Venera-M".tl),
            Text(
              "更新功能测试版 · Update test build".tl,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
        ).toSliver(),
        ListTile(
          title: Text("Check for updates".tl),
          trailing: Button.filled(
            isLoading: isCheckingUpdate,
            child: Text("Check".tl),
            onPressed: () {
              setState(() {
                isCheckingUpdate = true;
              });
              checkUpdateUi().then((value) {
                setState(() {
                  isCheckingUpdate = false;
                });
              });
            },
          ).fixHeight(32),
        ).toSliver(),
        _SwitchSetting(
          title: "Check for updates on startup".tl,
          settingKey: "checkUpdateOnStart",
        ).toSliver(),
      ],
    );
  }
}

/// 自动更新指向自己的仓库。
const _kRepoOwner = "Zx3485";
const _kRepoName = "venera-M";
const _kReleasePage = "https://github.com/$_kRepoOwner/$_kRepoName/releases";
/// 网页版 latest，会 302 到 /releases/tag/vX.Y.Z —— 不消耗 API 配额。
const _kLatestHtml = "https://github.com/$_kRepoOwner/$_kRepoName/releases/latest";

/// 上一次检查更新的失败原因，供界面提示。
/// 取值：null（成功或无需更新）/ rate_limited / http_xxx / network / parse
String? lastCheckUpdateError;

/// 查 GitHub Releases 最新版，比本机新就返回 release 信息（含 APK 直链）。
///
/// 两条路，按顺序试：
///   1. GitHub API /releases/latest —— 能拿到 assets 直链，但**匿名每小时只有 60 次**
///   2. 网页 /releases/latest —— 跟随 302 从 URL 里读 tag，**不吃 API 配额**
/// 第 1 条限流时自动退到第 2 条，这样即使 API 没额度也能发现新版本。
Future<Map<String, dynamic>?> fetchLatestRelease() async {
  lastCheckUpdateError = null;

  // ── 路线 1：API ──
  try {
    var res = await AppDio().get(
      "https://api.github.com/repos/$_kRepoOwner/$_kRepoName/releases/latest",
      options: Options(
        headers: {
          'Accept': 'application/vnd.github+json',
          'User-Agent': "venera-m",
        },
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (res.statusCode == 200) {
      var data = res.data;
      if (data is Map) {
        final r = _parseApiRelease(data);
        if (r != null) return r;
        // 版本不比本机新，直接返回 null（不需要再试网页）
        return null;
      }
    } else // 403/429 或 5xx，退到网页路线
    if (res.statusCode == 403 || res.statusCode == 429) {
      lastCheckUpdateError = "rate_limited";
      Log.info("Check Update", "API 限流，改走网页路线");
    } else {
      lastCheckUpdateError = "http_${res.statusCode}";
      Log.info("Check Update", "API ${res.statusCode}，改走网页路线");
    }
  } catch (e, s) {
    lastCheckUpdateError = "network";
    Log.error("Check Update", "API 失败: $e\n$s");
  }

  // ── 路线 2：网页重定向（不吃 API 配额）──
  try {
    final version = await _fetchLatestTagFromHtml();
    if (version == null) {
      lastCheckUpdateError ??= "parse";
      return null;
    }
    if (!_compareVersion(version, App.version)) return null;
    // 拿不到 assets 直链，只能跳 Release 页
    return {
      "version": version,
      "apkUrl": null,
      "pageUrl": "$_kReleasePage/tag/v$version",
      "body": "",
    };
  } catch (e, s) {
    lastCheckUpdateError ??= "network";
    Log.error("Check Update", "网页路线失败: $e\n$s");
    return null;
  }
}

/// 从网页版 /releases/latest 的 302 重定向里读出 tag。
/// 返回去掉 v 前缀的版本号，例如 "1.6.9"。
Future<String?> _fetchLatestTagFromHtml() async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(_kLatestHtml));
    req.headers.set(HttpHeaders.userAgentHeader, "venera-m");
    // 关键：不自动跟随重定向，我们要自己读 Location
    req.followRedirects = false;
    final res = await req.close();
    // 丢弃响应体，避免占内存
    await res.drain<void>();

    String? location = res.headers.value(HttpHeaders.locationHeader);
    // 有的网络环境会给 200 + 正文（不重定向），那就从当前 URL 判断
    if (location == null || location.isEmpty) {
      if (res.statusCode == 200) {
        // 已是最新时某些情况下直接 200 到 /releases（无 tag），视为无法判断
        return null;
      }
      return null;
    }
    final m = RegExp(r'/tag/v?([0-9]+(?:\.[0-9]+)*)').firstMatch(location);
    if (m == null) return null;
    return m.group(1);
  } finally {
    client.close();
  }
}

/// 解析 GitHub API 的 release JSON。
Map<String, dynamic>? _parseApiRelease(Map data) {
  var tag = data["tag_name"]?.toString() ?? "";
  var version = tag.startsWith("v") ? tag.substring(1) : tag;
  if (version.isEmpty) return null;
  version = version.split("+").first;
  if (!_compareVersion(version, App.version)) return null;

  // 优先挑 arm64 的包，挑不到就用第一个 apk
  String? apkUrl;
  final assets = data["assets"];
  if (assets is List) {
    final apks = assets
        .where((a) =>
            a is Map && (a["name"]?.toString() ?? "").endsWith(".apk"))
        .toList();
    if (apks.isNotEmpty) {
      final arm64 = apks
          .where((a) => a["name"].toString().toLowerCase().contains("arm64"))
          .toList();
      apkUrl = (arm64.isNotEmpty ? arm64.first : apks.first)
          ["browser_download_url"]
          ?.toString();
    }
  }

  return {
    "version": version,
    "apkUrl": apkUrl,
    "pageUrl": data["html_url"]?.toString() ?? _kReleasePage,
    "body": data["body"]?.toString() ?? "",
  };
}

Future<bool> checkUpdate() async {
  return await fetchLatestRelease() != null;
}

Future<void> checkUpdateUi([bool showMessageIfNoUpdate = true, bool delay = false]) async {
  try {
    final release = await fetchLatestRelease();
    if (release != null) {
      if (delay) {
        await Future.delayed(const Duration(seconds: 2));
      }
      final apkUrl = release["apkUrl"] as String?;
      showDialog(
          context: App.rootContext,
          builder: (context) {
            return ContentDialog(
              title: "New version available".tl,
              content: Text(
                apkUrl != null
                    ? "A new version (V${release["version"]}) is available. "
                        "Download the APK now?"
                        .tl
                    : "A new version (V${release["version"]}) is available. "
                        "Open the release page?"
                        .tl,
              ).paddingHorizontal(16),
              actions: [
                Button.text(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (apkUrl == null) {
                      // Release 里没找到 apk 资源，只能去页面手动下
                      launchUrlString(_kReleasePage);
                      return;
                    }
                    App.rootContext.showMessage(
                      message: "Downloading update...".tl,
                    );
                    final ok = await ApkUpdater.downloadAndInstall(apkUrl);
                    if (ok) {
                      // 安装器已拉起，剩下交给系统
                      return;
                    }
                    // 失败时按原因区分，不再无脑跳浏览器：
                    // 未授权「安装未知应用」已经跳了系统设置页，只提示；
                    // 其他原因才打开 Release 页面兜底。
                    final reason = ApkUpdater.lastFailReason ?? "";
                    if (reason == "no_permission") {
                      App.rootContext.showMessage(
                        message:
                            "Allow installing unknown apps, then retry.".tl,
                      );
                      return;
                    }
                    App.rootContext.showMessage(
                      message: "In-app update failed ($reason), opening page."
                          .tl,
                    );
                    launchUrlString(_kReleasePage);
                  },
                  child: Text("Update".tl),
                ),
              ],
            );
          });
    } else if (showMessageIfNoUpdate) {
      // 区分「确实没有新版本」和「查询失败」—— 之前两者都显示同一句话，
      // 导致限流时也告诉用户"已是最新"，无从排查。
      final err = lastCheckUpdateError;
      if (err == null) {
        App.rootContext.showMessage(message: "No new version available".tl);
      } else if (err == "rate_limited") {
        App.rootContext.showMessage(
          message: "GitHub rate limited, try again later.".tl,
        );
      } else if (err == "network") {
        App.rootContext.showMessage(
          message: "Network error, check your connection.".tl,
        );
      } else {
        App.rootContext.showMessage(
          message: "Update check failed ($err)".tl,
        );
      }
    }
  } catch (e, s) {
    Log.error("Check Update", e.toString(), s);
  }
}

/// return true if version1 > version2
bool _compareVersion(String version1, String version2) {
  var v1 = version1.split(".");
  var v2 = version2.split(".");
  for (var i = 0; i < v1.length; i++) {
    if (int.parse(v1[i]) > int.parse(v2[i])) {
      return true;
    }
    if (int.parse(v1[i]) < int.parse(v2[i])) {
      return false;
    }
  }
  return false;
}
