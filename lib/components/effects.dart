part of 'components.dart';

/// 背景模糊容器。所有可调参数都从「设置 → 外观」读：
///   glassBlur      模糊半径
///   glassHighlight 是否叠加顶部高光
///
/// 注意：这里**不控制填充不透明度**，那由各个调用方自己的 decoration 决定，
/// 否则一改会连锁影响所有界面。
class BlurEffect extends StatelessWidget {
  final Widget child;

  /// 覆盖全局模糊值；null 用设置里的 glassBlur。
  final double? blur;

  final BorderRadius? borderRadius;

  const BlurEffect({
    required this.child,
    this.borderRadius,
    this.blur,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    // 磨砂关着时退回原来的固定值（15），保持旧观感不变
    final sigma = blur ?? (isGlassEnabled ? glassBlur : 15.0);
    // 高光只在磨砂开启且用户没关掉时才加
    final showHighlight = isGlassEnabled && glassHighlight;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.mirror,
        ),
        child: showHighlight
            ? Stack(
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
              )
            : child,
      ),
    );
  }
}
