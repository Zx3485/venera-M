part of 'components.dart';

// ═══════════════════════════════════════════════════════════════
//  venera 设计语言 · Design Tokens
//  圆角 / 间距 / 动效 / 描边 / 玻璃 全部从这里取值。
//  页面与组件里禁止再写裸的 4/8/12/16、160ms 等字面量。
// ═══════════════════════════════════════════════════════════════

// ───────────────────────── 圆角 ─────────────────────────
/// 小元素：角标、徽章、chip 内嵌
const double kRadiusXs = 6;

/// 封面、输入框、列表项内嵌块
const double kRadiusS = 10;

/// 卡片、板块容器、导航项
const double kRadiusM = 14;

/// 弹层、对话框、玻璃面板
const double kRadiusL = 20;

/// 药丸形
const double kRadiusPill = 999;

const BorderRadius kBRXs = BorderRadius.all(Radius.circular(kRadiusXs));
const BorderRadius kBRS = BorderRadius.all(Radius.circular(kRadiusS));
const BorderRadius kBRM = BorderRadius.all(Radius.circular(kRadiusM));
const BorderRadius kBRL = BorderRadius.all(Radius.circular(kRadiusL));
const BorderRadius kBRPill = BorderRadius.all(Radius.circular(kRadiusPill));

// ───────────────────────── 间距 ─────────────────────────
const double kSpaceXs = 4;
const double kSpaceS = 8;
const double kSpaceM = 12;
const double kSpaceL = 16;
const double kSpaceXl = 24;
const double kSpace2Xl = 32;

// ───────────────────────── 动效 ─────────────────────────
/// 微交互：hover、按压、指示条
const Duration kDurationFast = Duration(milliseconds: 150);

/// 常规：组件状态切换、折叠展开
const Duration kDurationNormal = Duration(milliseconds: 220);

/// 大位移：弹层、抽屉、页面转场
const Duration kDurationSlow = Duration(milliseconds: 320);

/// 统一缓出曲线（绝大多数动画）
const Curve kCurve = Curves.easeOutCubic;

/// 强调曲线（大位移、双向动画）
const Curve kCurveEmphasized = Curves.easeInOutCubicEmphasized;

/// 兼容旧引用：原 160ms 收敛到 fast 档
const _fastAnimationDuration = kDurationFast;

// ───────────────────────── 描边 ─────────────────────────
/// 唯一描边宽度：玻璃边缘、卡片描边都用它
const double kBorderHairline = 0.8;

// ───────────────────────── 玻璃 ─────────────────────────
const double kGlassBlurDefault = 20;
const double kGlassOpacityDefault = 0.18;

/// 悬浮层（弹窗 / 侧栏 / 玻璃面板）的统一阴影。
/// 暗色模式下用更深的双层阴影制造「贴脸悬浮」感，
/// 取代散落各处的 Colors.white.withAlpha hack。
List<BoxShadow> kOverlayShadows(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.5),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.14),
      blurRadius: 22,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}

/// 悬浮玻璃层边缘描边色：亮色用白描边模拟玻璃棱光，暗色用极淡白。
Color kGlassBorderColor(bool isDark) =>
    Colors.white.withValues(alpha: isDark ? 0.10 : 0.45);

// ───────────────────────── 语义动作色 ─────────────────────────
// 低饱和色板，配合 context.useTextColor 在深浅主题自动取明暗档。
// 色相与「设置 → 颜色」里的柔和主题色一致，
// 替代 Material 原色（红/黄/绿/蓝…）在暗色模式下的过艳表现。

MaterialColor _buildSoftSwatch(int base) {
  final c = Color.fromARGB(
    (base >> 24) & 0xFF,
    (base >> 16) & 0xFF,
    (base >> 8) & 0xFF,
    base & 0xFF,
  );
  Color shade(double t, Color target) => Color.lerp(c, target, t)!;
  return MaterialColor(base, {
    50: shade(0.70, Colors.white),
    100: shade(0.50, Colors.white),
    200: shade(0.35, Colors.white),
    300: shade(0.18, Colors.white),
    400: c,
    500: c,
    600: shade(0.12, Colors.black),
    700: shade(0.24, Colors.black),
    800: shade(0.34, Colors.black),
    900: shade(0.48, Colors.black),
  });
}

/// 阅读 / 继续阅读
final MaterialColor kSoftAmber = _buildSoftSwatch(0xFFC08A3E);

/// 下载 / 阅读历史
final MaterialColor kSoftTeal = _buildSoftSwatch(0xFF4E9AA8);

/// 点赞 / 顶
final MaterialColor kSoftRed = _buildSoftSwatch(0xFFD06A6A);

/// 收藏
final MaterialColor kSoftPurple = _buildSoftSwatch(0xFF9B84A8);

/// 评论
final MaterialColor kSoftGreen = _buildSoftSwatch(0xFF7A9A7E);

/// 分享 / 踩
final MaterialColor kSoftBlue = _buildSoftSwatch(0xFF6B8CAE);

/// 标签点缀
final MaterialColor kSoftPink = _buildSoftSwatch(0xFFC77E9E);

/// 标签点缀
final MaterialColor kSoftIndigo = _buildSoftSwatch(0xFF7E86B8);
