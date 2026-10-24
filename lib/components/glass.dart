part of 'components.dart';

/// iOS 风格的磨砂玻璃容器。
///
/// 由三层叠出来：
///   1. BackdropFilter 模糊背后的内容（关键，没它只是一块半透明布）
///   2. 半透明填充色 —— 决定"玻璃"偏冷还是偏暖
///   3. 顶部 1px 高光边框 —— iOS 那种"玻璃边缘反光"的错觉来源
///
/// ⚠ 背后必须有内容（图片、渐变、其他颜色块）才看得出来。
///   背后是纯色时只会变成一块略灰的蒙版。
/// ⚠ BackdropFilter 是实时采样，中低端机上开销明显，量大时要关掉。
class GlassCard extends StatelessWidget {
  final Widget child;

  /// 模糊强度。iOS 常见区间 10~30，超过 40 会糊成一片。
  final double blur;

  final BorderRadius? borderRadius;

  /// 玻璃填充的不透明度。0.10~0.25 之间比较像真玻璃，
  /// 太高会变成实心卡片，太低会看不清文字。
  final double opacity;

  /// 是否画那圈顶部高光描边。
  final bool showBorder;

  final EdgeInsetsGeometry? padding;

  final Clip clipBehavior;

  const GlassCard({
    required this.child,
    this.blur = 20,
    this.borderRadius,
    this.opacity = 0.18,
    this.showBorder = true,
    this.padding,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDark = context.isDarkMode;
    final radius = borderRadius ?? BorderRadius.circular(16);

    // 暗色下用白玻璃，亮色下用白玻璃偏灰，都能压住背景又不脏
    final base = isDark ? Colors.white : Colors.white;
    final fill = base.withValues(alpha: isDark ? opacity * 0.6 : opacity + 0.35);

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    Widget glass = ClipRRect(
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.mirror,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: showBorder
                ? Border.all(
                    // 顶部亮、底部暗，模拟光线从上打下来
                    color: (isDark ? Colors.white : Colors.white)
                        .withValues(alpha: isDark ? 0.14 : 0.55),
                    width: 0.8,
                  )
                : null,
          ),
          child: content,
        ),
      ),
    );

    // 一层极淡的投影，让玻璃"浮"起来，而不是贴在背景上
    if (isDark) {
      glass = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: glass,
      );
    }

    return glass;
  }
}

/// 磨砂效果总开关。为 true 时 GlassCard 才真的模糊；
/// 关闭时退化成普通半透明卡片（省性能）。
bool get isGlassEnabled => appdata.settings['glassEffect'] == true;

/// 按开关生成磨砂或普通背景。
/// 用法：需要玻璃质感的地方包一层 [adaptiveGlass]。
Widget adaptiveGlass({
  required Widget child,
  double blur = 20,
  BorderRadius? borderRadius,
  double opacity = 0.18,
  EdgeInsetsGeometry? padding,
}) {
  if (!isGlassEnabled) {
    return Container(
      decoration: BoxDecoration(
        color: appdata.settings['theme_mode'] == 'dark'
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      padding: padding,
      child: child,
    );
  }
  return GlassCard(
    blur: blur,
    borderRadius: borderRadius,
    opacity: opacity,
    padding: padding,
    child: child,
  );
}
