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

// ───────────────────────── 墨韵 · Ink ─────────────────────────
// 「墨韵极简 + 玻璃」设计语言：
//   版面零卡片、层级靠字重与 hairline 分割线；
//   玻璃只给浮在内容上方的层（标题栏 / 导航 / 弹层）；
//   朱砂红仅做极少量的信号色（更新 / 评分 / 阅读位置）。

/// 墨黑底色（暗色模式页面背景）
const Color kInkDarkBg = Color(0xFF101013);

/// 纸白底色（亮色模式页面背景）
const Color kInkLightBg = Color(0xFFFAFAF8);

/// 墨灰种子色：生成近乎无彩的 colorScheme
const Color kInkSeed = Color(0xFF8A8F98);

/// 钢红种子色：colorScheme.primary / secondary 的来源。
///
/// 杂志版只有一个暖色信号。用它做种子后：
///   - 35 处 `colorScheme.primary`（按钮、Tab 选中、下拉箭头、
///     收藏态、章节选中）自动变成钢红，无需逐个改引用
///   - 明暗两套主题各自生成合适明度，比硬编码 kRustColor 更稳
///   - `tertiary` 走 kInkSeed，保持中性
const Color kRustSeed = Color(0xFFA4522C);

/// 衬线字体（大标题用，回退到无衬线不影响可用性）
const String kSerifFontFamily = 'Noto Serif SC';
const List<String> kSerifFontFallback = [
  'Noto Serif CJK SC',
  'Noto Serif CJK',
  'Source Han Serif SC',
  'Songti SC',
  'SimSun',
];

/// 衬线标题样式
TextStyle kSerifStyle({
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  Color? color,
  double? height,
}) =>
    TextStyle(
      fontFamily: kSerifFontFamily,
      fontFamilyFallback: kSerifFontFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
      height: height,
    );

/// 朱砂色：唯一的暖色信号（更新点、评分星、阅读位置）
Color kSealColor(BuildContext context) =>
    context.isDarkMode ? const Color(0xFFD05A52) : const Color(0xFFB5443C);

// ─────────────── 杂志排版（Editorial）───────────────
//
// 设计语言：层级靠「字号跨度 + 粗细横线 + 等宽编号」表达，
// 不靠卡片、不靠阴影。封面一律直角（杂志贴纸感）。
// 钢红只做信号色，和朱砂同源但更暖，用于「当期」标记。

/// 钢红：杂志版的强调色（当期推荐、已读编号）
Color kRustColor(BuildContext context) =>
    context.isDarkMode ? const Color(0xFFD9805A) : const Color(0xFFA4522C);

/// 报头粗横线的粗细。整页只有这一处用这么粗的线。
const double kRuleThick = 2.5;

/// 报头细横线 / 目录分隔线的粗细。
const double kRuleHair = 1.0;

/// 报头字母间距（全大写小字标那种松散排布）
const double kMastheadTracking = 5.0;

/// 小字标（kicker / eyebrow）字号：全大写 + 宽字距，像杂志栏目名。
const double kKickerSize = 10.0;

/// 小字标字距
const double kKickerTracking = 2.6;

/// 编号列字号（继续阅读前面的 01 02 03）
const double kIndexNumSize = 15.0;

/// 杂志大标题字号（首页「晚上好。」那种）
const double kDisplaySize = 37.0;

// ─────────────── 玻璃胶囊底栏 ───────────────

/// 胶囊底栏本身的高度（不含外边距）。比原来的 58 矮，因为要浮起来。
const double kPillNavHeight = 56.0;

/// 胶囊底栏左右外边距
const double kPillNavMarginH = 24.0;

/// 胶囊底栏离屏幕底部的距离（不含系统手势区）
const double kPillNavMarginBottom = 14.0;

/// 玻璃胶囊底栏的总占位高度 = 高度 + 底部间距。
/// 内容区滚动余量、FAB 避让都按这个值算，改一处即可全局同步。
const double kPillNavReserved =
    kPillNavHeight + kPillNavMarginBottom; // 70

/// 胶囊底栏里单个条目的宽度（图标 + 文字）
const double kPillNavItemWidth = 58.0;

// ─────────────── 圆角风格（用户可切）───────────────
//
// 杂志排版本来的语言是直角（贴在纸上的一张图），但有人更喜欢圆角的柔和。
// 做成设置项而不是写死，免得替用户做审美决定。
//
// 设置键 cornerStyle：
//   'square'  直角 —— 杂志原味（默认）
//   'soft'    小圆角 —— 温和，接近原来的观感
//   'round'   大圆角 —— 明显圆润

/// 圆角风格对应的基准半径（不需要 BuildContext 的版本）。
///
/// 供 `getTheme()` 这类静态上下文使用——它拿不到 BuildContext，
/// 但 `appdata.settings` 随时可读。有 context 的地方请用 [kCornerRadius]。
double kCornerRadiusFromSetting() {
  final style = appdata.settings['cornerStyle'];
  return switch (style) {
    'square' => 0.0,
    'round' => 18.0,
    _ => 10.0, // soft，也是缺省
  };
}

/// 圆角风格对应的基准半径。
///
/// 各处组件都从 [kCornerRadius] 取半径，再按自己的层级缩放：
/// 封面用 1.0 倍，章节格/按钮用 0.6 倍，胶囊底栏固定全圆不参与。
double kCornerRadius(BuildContext context) => kCornerRadiusFromSetting();

/// 按基准半径缩放后的圆角。
///
/// [scale] 控制这一处比基准更方还是更圆：
///   1.0 = 和基准一致（封面、面板）
///   0.6 = 更收敛（章节格、小按钮）
///   0.0 = 强制直角（分割线附近的元素）
BorderRadius kCorner(BuildContext context, {double scale = 1.0}) {
  final r = kCornerRadius(context) * scale;
  return BorderRadius.circular(r);
}

/// 圆角风格在「直角」档位下，是否要顺带收紧描边/阴影。
///
/// 直角风格靠硬阴影表达层级；圆角风格用软阴影更协调。
bool kIsSquareCorner(BuildContext context) =>
    (appdata.settings['cornerStyle'] ?? 'square') == 'square';

/// 封面类元素的阴影：直角用硬阴影（贴纸感），圆角用软阴影。
List<BoxShadow> kCoverShadows(BuildContext context) {
  final dark = context.isDarkMode;
  if (kIsSquareCorner(context)) {
    return [
      BoxShadow(
        color: Colors.black.toOpacity(dark ? 0.34 : 0.16),
        offset: const Offset(4, 4),
        blurRadius: 0,
      ),
    ];
  }
  return [
    BoxShadow(
      color: Colors.black.toOpacity(dark ? 0.42 : 0.18),
      offset: const Offset(0, 3),
      blurRadius: 8,
    ),
  ];
}

// ─────────────── 页面边距（全应用统一）───────────────
//
// 原来各页各写一套：首页 20、收藏页 16、设置页 ListTile 默认、
// 章节区 26。改成统一规则后，跨页面切换时左右留白不再跳。
//
//   kPagePadding      页面内容的左右留白（26）
//   kPagePaddingWide  宽屏时的留白
//   kSectionGap       板块之间的竖直间距（28）
//   kItemGap          列表项之间的竖直间距（6）

/// 页面内容左右留白。全应用统一用它，不要再写 16 / 20 / 24。
const double kPageInset = 26.0;

/// 板块之间的间距。
const double kSectionGap = 28.0;

/// 列表项之间的间距。
const double kItemGap = 6.0;

/// 页面内容的标准 padding（左右 kPageInset）。
const EdgeInsets kPagePadding = EdgeInsets.symmetric(horizontal: kPageInset);

/// 栏目标题行的标准 padding：上 kSectionGap，下 10。
const EdgeInsets kSectionHeadPadding =
    EdgeInsets.fromLTRB(kPageInset, kSectionGap, kPageInset, 10);

/// 页面底部滚动余量：悬浮胶囊底栏 + 一点呼吸空间。
///
/// 页面自己不要再用 `padding.bottom + 80` 这类魔数，
/// 统一走这里，胶囊高度一变就全局同步。
double kPageBottomInset(BuildContext context) =>
    kPillNavReserved + MediaQuery.of(context).padding.bottom + 16;



