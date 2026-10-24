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
const _kLatestApi =
    "https://api.github.com/repos/$_kRepoOwner/$_kRepoName/releases/latest";

/// 查 GitHub Releases 最新版，比本机新就返回 release 信息（含 APK 直链）。
/// 与原来的差别：不再拉 pubspec.yaml 只比版本号，而是直接读 Release，
/// 这样点「更新」能直接拿到 APK 下载地址，不用自己去页面里翻。
Future<Map<String, dynamic>?> fetchLatestRelease() async {
  try {
    var res = await AppDio().get(
      _kLatestApi,
      options: Options(
        headers: {
          'Accept': 'application/vnd.github+json',
          'User-Agent': "venera-m",
        },
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (res.statusCode != 200) {
      Log.info("Check Update", "GitHub API ${res.statusCode}: ${res.data}");
      return null;
    }
    var data = res.data;
    if (data is! Map) return null;

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
  } catch (e, s) {
    Log.error("Check Update", e.toString(), s);
    return null;
  }
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
                  onPressed: () {
                    Navigator.pop(context);
                    launchUrlString(apkUrl ?? _kReleasePage);
                  },
                  child: Text("Update".tl),
                ),
              ],
            );
          });
    } else if (showMessageIfNoUpdate) {
      App.rootContext.showMessage(message: "No new version available".tl);
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
