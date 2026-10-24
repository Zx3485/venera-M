part of 'components.dart';

class BlurEffect extends StatelessWidget {
  final Widget child;

  final double blur;

  final BorderRadius? borderRadius;

  const BlurEffect({
    required this.child,
    this.borderRadius,
    this.blur = 15,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;

    // 磨砂开关关着：保持原样，只做裁剪，不模糊（省性能、观感不变）
    if (!isGlassEnabled) {
      return ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
            tileMode: TileMode.mirror,
          ),
          child: child,
        ),
      );
    }

    // 磨砂开关打开：在模糊层外面再叠一层极淡的提亮 + 内描边，
    // 让"玻璃"有厚度感。注意不能在这里改不透明度 ——
    // 那由各个调用方自己的 decoration 决定，改这里会连锁影响所有界面。
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          // 比原来更明显一点，但仍克制。超过 40 会糊成色块。
          sigmaX: blur * 1.4,
          sigmaY: blur * 1.4,
          tileMode: TileMode.mirror,
        ),
        child: Stack(
          children: [
            child,
            // 顶部到中部的一层极淡高光，模拟光线掠过玻璃表面
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
                          alpha: context.isDarkMode ? 0.06 : 0.18,
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
    );
  }
}
