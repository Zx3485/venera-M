part of 'settings_page.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  @override
  Widget build(BuildContext context) {
    return SmoothCustomScrollView(
      slivers: [
        SliverAppbar(title: Text("Appearance".tl)),
        SelectSetting(
          title: "Theme Mode".tl,
          settingKey: "theme_mode",
          optionTranslation: {
            "system": "跟随系统".tl,
            "light": "浅色".tl,
            "dark": "深色".tl,
          },
          onChanged: () async {
            App.forceRebuild();
          },
        ).toSliver(),
        SelectSetting(
          title: "Theme Color".tl,
          settingKey: "color",
          optionTranslation: {
            "system": "跟随系统".tl,
            "red": "红".tl,
            "pink": "粉".tl,
            "purple": "紫".tl,
            "green": "绿".tl,
            "orange": "橙".tl,
            "blue": "蓝".tl,
            "yellow": "黄".tl,
            "cyan": "青".tl,
            // 低饱和色
            "mistBlue": "雾霾蓝".tl,
            "lilac": "藕荷紫".tl,
            "sage": "鼠尾草绿".tl,
            "slate": "岩灰".tl,
            "coral": "珊瑚".tl,
            "matcha": "抹茶".tl,
            "sand": "暖沙".tl,
            "dusk": "暮紫".tl,
          },
          onChanged: () async {
            await App.init();
            App.forceRebuild();
          },
        ).toSliver(),
        SelectSetting(
          title: "Page Transition".tl,
          settingKey: "pageTransition",
          optionTranslation: {
            "default": "跟随系统".tl,
            "fade": "淡入淡出".tl,
            "zoom": "缩放".tl,
            "slideUp": "从下往上".tl,
            "sharedAxisX": "水平推进".tl,
            "none": "无动画".tl,
          },
          onChanged: () async {
            App.forceRebuild();
          },
        ).toSliver(),

        // ───────────────── 磨砂玻璃 ─────────────────
        _SettingPartTitle(title: "Glass Effect".tl, icon: Icons.blur_on).toSliver(),
        _SwitchSetting(
          title: "Enable Glass".tl,
          settingKey: "glassEffect",
          subtitle: "开启后浮层与工具栏会模糊背后的内容。"
              "背后有图片或内容时才看得出效果；中低端机可能掉帧。"
              .tl,
        ).toSliver(),
        if (isGlassEnabled) ...[
          _SliderSetting(
            title: "Glass Opacity".tl,
            settingsIndex: "glassOpacity",
            interval: 0.05,
            min: 0.0,
            max: 0.9,
            onChanged: () => setState(() {}),
          ).toSliver(),
          _SliderSetting(
            title: "Glass Blur".tl,
            settingsIndex: "glassBlur",
            interval: 2,
            min: 0,
            max: 60,
            onChanged: () => setState(() {}),
          ).toSliver(),
          _SwitchSetting(
            title: "Glass Highlight".tl,
            settingKey: "glassHighlight",
            subtitle: "在玻璃顶部叠一层由亮到透明的渐变，"
                "模拟光线掠过表面，让质感更像真玻璃。"
                .tl,
          ).toSliver(),
          _SwitchSetting(
            title: "Glass on Reader Toolbar".tl,
            settingKey: "glassInReader",
            subtitle: "阅读器的上下工具栏背景变薄并模糊，能看见背后的漫画。"
                "背后有画面，这里效果最明显。"
                .tl,
          ).toSliver(),
          _SwitchSetting(
            title: "Glass on App Bar".tl,
            settingKey: "glassInAppBar",
            subtitle: "列表页顶部标题栏透明化，滚动时能看到背后的封面。"
                .tl,
          ).toSliver(),
        ],
      ],
    );
  }
}
