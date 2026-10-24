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
            "system": "System".tl,
            "light": "Light".tl,
            "dark": "Dark".tl,
          },
          onChanged: () async {
            App.forceRebuild();
          },
        ).toSliver(),
        SelectSetting(
          title: "Theme Color".tl,
          settingKey: "color",
          optionTranslation: {
            "system": "System".tl,
            "red": "Red".tl,
            "pink": "Pink".tl,
            "purple": "Purple".tl,
            "green": "Green".tl,
            "orange": "Orange".tl,
            "blue": "Blue".tl,
            "yellow": "Yellow".tl,
            "cyan": "Cyan".tl,
            // 低饱和色
            "mistBlue": "Mist Blue".tl,
            "lilac": "Lilac".tl,
            "sage": "Sage".tl,
            "slate": "Slate".tl,
            "coral": "Coral".tl,
            "matcha": "Matcha".tl,
            "sand": "Sand".tl,
            "dusk": "Dusk".tl,
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
            "default": "Follow System".tl,
            "fade": "Fade".tl,
            "zoom": "Zoom".tl,
            "slideUp": "Slide Up".tl,
            "sharedAxisX": "Slide Horizontal".tl,
            "none": "None".tl,
          },
          onChanged: () async {
            App.forceRebuild();
          },
        ).toSliver(),
        _SwitchSetting(
          title: "Glass Effect".tl,
          settingKey: "glassEffect",
        ).toSliver(),
      ],
    );
  }
}
