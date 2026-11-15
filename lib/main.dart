import 'dart:async';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:venera/foundation/log.dart';
import 'package:venera/pages/auth_page.dart';
import 'package:venera/pages/main_page.dart';
import 'package:venera/utils/io.dart';
import 'package:window_manager/window_manager.dart';
import 'components/components.dart';
import 'components/window_frame.dart';
import 'foundation/app.dart';
import 'foundation/appdata.dart';
import 'headless.dart';
import 'init.dart';

void main(List<String> args) {
  if (args.contains('--headless')) {
    runHeadlessMode(args);
    return;
  }
  if (runWebViewTitleBarWidget(args)) return;
  overrideIO(() {
    runZonedGuarded(() async {
      WidgetsFlutterBinding.ensureInitialized();
      await init();
      runApp(const MyApp());
      if (App.isDesktop) {
        await windowManager.ensureInitialized();
        windowManager.waitUntilReadyToShow().then((_) async {
          await windowManager.setTitleBarStyle(
            TitleBarStyle.hidden,
            windowButtonVisibility: App.isMacOS,
          );
          if (App.isLinux) {
            await windowManager.setBackgroundColor(Colors.transparent);
          }
          await windowManager.setMinimumSize(const Size(500, 600));
          var placement = await WindowPlacement.loadFromFile();
          if (App.isLinux) {
            await windowManager.show();
            await placement.applyToWindow();
          } else {
            await placement.applyToWindow();
            await windowManager.show();
          }

          WindowPlacement.loop();
        });
      }
    }, (error, stack) {
      Log.error("Unhandled Exception", error, stack);
    });
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    App.registerForceRebuild(forceRebuild);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.addObserver(this);
    checkUpdates();
    super.initState();
  }

  bool isAuthPageActive = false;

  OverlayEntry? hideContentOverlay;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!App.isMobile || !appdata.settings['authorizationRequired']) {
      return;
    }
    if (state == AppLifecycleState.inactive && hideContentOverlay == null) {
      hideContentOverlay = OverlayEntry(
        builder: (context) {
          return Positioned.fill(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: App.rootContext.colorScheme.surface,
            ),
          );
        },
      );
      Overlay.of(App.rootContext).insert(hideContentOverlay!);
    } else if (hideContentOverlay != null &&
        state == AppLifecycleState.resumed) {
      hideContentOverlay!.remove();
      hideContentOverlay = null;
    }
    if (state == AppLifecycleState.hidden &&
        !isAuthPageActive &&
        !IO.isSelectingFiles) {
      isAuthPageActive = true;
      App.rootContext.to(
        () => AuthPage(
          onSuccessfulAuth: () {
            App.rootContext.pop();
            isAuthPageActive = false;
          },
        ),
      );
    }
    super.didChangeAppLifecycleState(state);
  }

  void forceRebuild() {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
    setState(() {});
  }

  // 杂志版配色固定：钢红种子生成强调色，墨灰负责中性色。
  // 用户不再需要选主色。旧的 translateColorSetting() 已移除；
  // 设置键 color 保留仅为兼容旧配置（不再读取）。
  //
  // 为什么用钢红做 primary 种子：
  //   全应用有 35 处 colorScheme.primary、8 处 secondary，
  //   集中在按钮、Tab 选中态、下拉箭头、收藏态、章节选中态。
  //   这些正好都是「交互强调」的语义，把种子换成钢红后
  //   它们自动变成钢红，无需逐个改引用；
  //   而且明暗两套主题会各自生成合适的明度，
  //   不像硬编码 kRustColor 那样在暗色下偏暗。
  ThemeData getTheme(Brightness brightness) {
    String? font;
    List<String>? fallback;
    if (App.isLinux || App.isWindows) {
      font = 'Noto Sans CJK';
      fallback = [
        'Segoe UI',
        'Noto Sans SC',
        'Noto Sans TC',
        'Noto Sans',
        'Microsoft YaHei',
        'PingFang SC',
        'Arial',
        'sans-serif'
      ];
    }
    var scheme = SeedColorScheme.fromSeeds(
      primaryKey: kRustSeed,
      secondaryKey: kRustSeed,
      tertiaryKey: kInkSeed,
      brightness: brightness,
      tones: FlexTones.vividBackground(brightness),
    );
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      colorScheme: scheme,
      fontFamily: font,
      fontFamilyFallback: fallback,
      // ── 组件级主题：让 M3 默认组件与自绘组件共享同一套视觉语言 ──
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kCornerRadiusFromSetting()),
        ),
        barrierColor: Colors.black.withValues(alpha: 0.5),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kCornerRadiusFromSetting()),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kCornerRadiusFromSetting()),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kCornerRadiusFromSetting()),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kCornerRadiusFromSetting() * 0.4),
        ),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 6,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 11),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(kRadiusPill),
        thickness: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.hovered) ? 6.0 : 4.0),
        thumbColor: WidgetStatePropertyAll(
          scheme.onSurface.withValues(alpha: 0.28),
        ),
        crossAxisMargin: 2,
        mainAxisMargin: 4,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
        ),
      ),
      listTileTheme: ListTileThemeData(
        // 跟随外观设置的圆角风格。
        // 原来固定 kBRM=14，导致用户选「直角」时设置页仍是圆的。
        // getTheme 是静态方法没有 BuildContext，直接读 settings。
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kCornerRadiusFromSetting()),
        ),
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      splashFactory: isDark ? InkRipple.splashFactory : InkSparkle.splashFactory,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (appdata.settings['authorizationRequired']) {
      home = AuthPage(
        onSuccessfulAuth: () {
          App.rootContext.toReplacement(() => const MainPage());
        },
      );
    } else {
      home = const MainPage();
    }
    // 配色固定为墨色种子：不再读 settings['color']，
    // 也不再跟随系统动态取色（DynamicColorBuilder）——
    // 杂志版的调性是「纸与墨」，任何彩色主色都会破坏它。
    // 唯一暖色信号是 kRustColor（钢红）。
    return MaterialApp(
      title: "Paperbound",
      home: home,
      debugShowCheckedModeBanner: false,
      theme: getTheme(Brightness.light),
      navigatorKey: App.rootNavigatorKey,
      darkTheme: getTheme(Brightness.dark),
      themeMode: switch (appdata.settings['theme_mode']) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system
        },
        color: Colors.transparent,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: () {
          var lang = appdata.settings['language'];
          if (lang == 'system') {
            return null;
          }
          return switch (lang) {
            'zh-CN' => const Locale('zh', 'CN'),
            'zh-TW' => const Locale('zh', 'TW'),
            'en-US' => const Locale('en'),
            _ => null
          };
        }(),
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('zh', 'TW'),
          Locale('en'),
        ],
        builder: (context, widget) {
          ErrorWidget.builder = (details) {
            Log.error("Unhandled Exception",
                "${details.exception}\n${details.stack}");
            return Material(
              child: Center(
                child: Text(details.exception.toString()),
              ),
            );
          };
          if (widget != null) {
            /// 如果无法检测到状态栏高度设定指定高度
            /// https://github.com/flutter/flutter/issues/161086
            var isPaddingCheckError =
                MediaQuery.of(context).viewPadding.top <= 0 ||
                MediaQuery.of(context).viewPadding.top > 200;

            if (isPaddingCheckError && Platform.isAndroid) {
              widget = MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    viewPadding: const EdgeInsets.only(
                      top: 15,
                      bottom: 15,
                    ),
                    padding: const EdgeInsets.only(
                      top: 15,
                      bottom: 15,
                    ),
                  ),
                  child: widget);
            }

            widget = OverlayWidget(widget);
            if (App.isDesktop) {
              widget = Shortcuts(
                shortcuts: {
                  LogicalKeySet(LogicalKeyboardKey.escape): VoidCallbackIntent(
                    App.pop,
                  ),
                },
                child: MouseBackDetector(
                  onTapDown: App.pop,
                  child: WindowFrame(widget),
                ),
              );
            }
            return _SystemUiProvider(Material(
              color: App.isLinux ? Colors.transparent : null,
              child: widget,
            ));
          }
          throw ('widget is null');
        },
      );
  }
}

class _SystemUiProvider extends StatelessWidget {
  const _SystemUiProvider(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    var brightness = Theme.of(context).brightness;
    SystemUiOverlayStyle systemUiStyle;
    if (brightness == Brightness.light) {
      systemUiStyle = SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      );
    } else {
      systemUiStyle = SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiStyle,
      child: child,
    );
  }
}
