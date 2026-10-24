part of 'components.dart';

// ───────────────────────── 磨砂玻璃 ─────────────────────────
// 全部参数都从 appdata.settings 读，用户可在「设置 → 外观」里调：
//   glassEffect    总开关
//   glassOpacity   填充不透明度 0.0~0.9
//   glassBlur      模糊半径 0~60
//   glassHighlight 顶部高光渐变
//   glassInReader  阅读器工具栏是否用磨砂
//   glassInAppBar  列表页标题栏是否用磨砂

/// 磨砂效果总开关。
bool get isGlassEnabled => appdata.settings['glassEffect'] == true;

/// 填充不透明度。做了夹取，防止旧配置里的越界值把界面搞坏。
double get glassOpacity {
  final v = appdata.settings['glassOpacity'];
  final d = v is num ? v.toDouble() : 0.18;
  return d.clamp(0.0, 0.9);
}

/// 模糊半径。
double get glassBlur {
  final v = appdata.settings['glassBlur'];
  final d = v is num ? v.toDouble() : 20.0;
  return d.clamp(0.0, 60.0);
}

/// 是否叠加顶部高光。
bool get glassHighlight => appdata.settings['glassHighlight'] == true;

/// 阅读器工具栏是否用磨砂。
bool get glassInReader =>
    isGlassEnabled && appdata.settings['glassInReader'] == true;

/// 列表页标题栏是否用磨砂。
bool get glassInAppBar =>
    isGlassEnabled && appdata.settings['glassInAppBar'] == true;

/// iOS 风格的磨砂玻璃容器。
///
/// 三层叠出来：
///   1. BackdropFilter 模糊背后的内容（没它只是一块半透明布）
///   2. 半透明填充色 —— 决定"玻璃"偏冷还是偏暖
///   3. 顶部渐变高光 —— iOS 那种"玻璃边缘反光"的错觉来源
///
/// ⚠ 背后必须有内容（图片、渐变、其他色块）才看得出来。
///   背后是纯色时只会变成一块略灰的蒙版。
class GlassCard extends StatelessWidget {
  final Widget child;

  /// 覆盖全局模糊值；null 用设置里的。
  final double? blurOverride;

  final BorderRadius? borderRadius;

  /// 覆盖全局不透明度；null 用设置里的。
  final double? opacityOverride;

  /// 覆盖全局高光开关；null 用设置里的。
  final bool? highlightOverride;

  final EdgeInsetsGeometry? padding;

  final Clip clipBehavior;

  const GlassCard({
    required this.child,
    this.blurOverride,
    this.borderRadius,
    this.opacityOverride,
    this.highlightOverride,
    this.padding,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final radius = borderRadius ?? BorderRadius.circular(16);
    final sigma = blurOverride ?? glassBlur;
    final opacity = opacityOverride ?? glassOpacity;
    final showHighlight = highlightOverride ?? glassHighlight;

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return ClipRRect(
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.mirror,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: isDark ? opacity * 0.6 : opacity,
            ),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.45),
              width: 0.8,
            ),
          ),
          child: Stack(
            children: [
              content,
              if (showHighlight)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(
                              alpha: isDark ? 0.06 : 0.16,
                            ),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 按开关生成磨砂或普通背景。
/// 需要玻璃质感的地方包一层，关掉时自动退化成实心卡片。
Widget adaptiveGlass({
  required Widget child,
  double? blur,
  BorderRadius? borderRadius,
  double? opacity,
  EdgeInsetsGeometry? padding,
  Color? fallbackColor,
}) {
  if (!isGlassEnabled) {
    return Container(
      decoration: BoxDecoration(
        color: fallbackColor ??
            (appdata.settings['theme_mode'] == 'dark'
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.85)),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      padding: padding,
      child: child,
    );
  }
  return GlassCard(
    blurOverride: blur,
    borderRadius: borderRadius,
    opacityOverride: opacity,
    padding: padding,
    child: child,
  );
}
