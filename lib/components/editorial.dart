part of 'components.dart';

// ════════════════════════════════════════════════════════════
//  杂志排版组件（Editorial）
//
//  设计语言：层级靠「字号跨度 + 粗细横线 + 等宽编号」表达，
//  不靠卡片、不靠阴影。所有页面共用这几个零件，避免各写一套。
// ════════════════════════════════════════════════════════════

/// 小字标（kicker / eyebrow）：全大写、宽字距，像杂志栏目名。
///
/// 例：`CONTINUE READING`、`11 月 15 日 · 星期六`
class Kicker extends StatelessWidget {
  const Kicker(
    this.text, {
    super.key,
    this.color,
    this.size = kKickerSize,
    this.tracking = kKickerTracking,
    this.weight = FontWeight.w600,
  });

  final String text;
  final Color? color;
  final double size;
  final double tracking;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        letterSpacing: tracking,
        fontWeight: weight,
        color: color ?? context.colorScheme.onSurfaceVariant,
        height: 1.2,
      ),
    );
  }
}

/// 报头：品牌字 + 右侧操作图标 + 下方一条粗横线。
///
/// 这是整套排版最标志性的一块——页面上只有这里用这么粗的线。
class Masthead extends StatelessWidget {
  const Masthead({
    super.key,
    this.title = 'Paperbound',
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(26, 14, 26, 0),
  });

  final String title;
  final List<Widget> actions;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 34,
            child: Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: kMastheadTracking,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                ...actions,
              ],
            ),
          ),
          Container(
            height: kRuleThick,
            color: scheme.onSurface,
          ),
        ],
      ),
    );
  }
}

/// 栏目标题行：左侧中文小标，右侧「· N」或操作文字。
///
/// 比原来的「16.5sp 粗体 + 箭头图标」克制得多——
/// 用字距和小字号拉开层级，而不是靠加粗。
class SectionHead extends StatelessWidget {
  const SectionHead(
    this.title, {
    super.key,
    this.trailing,
    this.trailingWidget,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(26, 26, 26, 12),
  });

  final String title;
  final String? trailing;

  /// 右侧自定义控件（替代 [trailing] 文字，用于图标按钮）。
  final Widget? trailingWidget;

  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          if (trailingWidget != null)
            trailingWidget!
          else if (trailing != null)
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Text(
                trailing!,
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 0.8,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 细分割线（目录用）。
class HairRule extends StatelessWidget {
  const HairRule({super.key, this.indent = 0, this.color});

  final double indent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kRuleHair,
      margin: EdgeInsets.only(left: indent),
      color: color ?? context.colorScheme.outlineVariant,
    );
  }
}

/// 等宽编号（01 / 02 / 03）。
///
/// 用 tabularFigures 保证数字宽度一致，不会左右跳。
class IndexNum extends StatelessWidget {
  const IndexNum(this.value, {super.key, this.color, this.size = kIndexNumSize});

  final String value;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
        color: color ?? context.colorScheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// 直角封面容器。
///
/// 杂志版和原来最大的差别之一：圆角 10 → 直角。
/// 加上一层很轻的硬阴影，像「贴在纸上的一张图」。
///
/// 圆角跟随设置项 cornerStyle：直角档用硬阴影贴纸感，
/// 圆角档用软阴影，避免「圆角配硬阴影」的违和。
class EditorialCover extends StatelessWidget {
  const EditorialCover({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.aspectRatio,
    this.shadow = true,
  });

  final Widget child;
  final double? width;
  final double? height;
  final double? aspectRatio;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    Widget box = Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: kCorner(context),
        boxShadow: shadow ? kCoverShadows(context) : null,
      ),
      child: child,
    );
    if (aspectRatio != null) {
      box = AspectRatio(aspectRatio: aspectRatio!, child: box);
    }
    return box;
  }
}

/// 杂志大标题（首页「晚上好。」那一行）。
///
/// 用衬线体，字号和字重的跨度都很大——这是整套设计最贵的部分，
/// 也是打包 Noto Serif SC 的意义所在。
class DisplayTitle extends StatelessWidget {
  const DisplayTitle(
    this.text, {
    super.key,
    this.size = kDisplaySize,
    this.color,
  });

  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: kSerifStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        height: 1.12,
        color: color ?? context.colorScheme.onSurface,
      ),
    );
  }
}

/// 目录行：编号 + 衬线标题 + 副行 + 右侧小封面。
///
/// 替代原来「44×60 小封面 + 一行标题 + 一条细进度线」的列表行。
class TOCEntry extends StatelessWidget {
  const TOCEntry({
    super.key,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.cover,
    this.dot = false,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 13),
  });

  final String index;
  final String title;
  final String subtitle;
  final Widget cover;

  /// 是否在标题前打一个钢红圆点（表示有新更新）
  final bool dot;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: IndexNum(index),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (dot) ...[
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: kRustColor(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kSerifStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            height: 1.35,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.2,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 34, height: 48, child: cover),
          ],
        ),
      ),
    );
  }
}

/// 「最后一话 / 继续阅读」这类并排快捷键。
class EditorialJumpButton extends StatelessWidget {
  const EditorialJumpButton({
    super.key,
    required this.label,
    this.onTap,
    this.primary = false,
    this.icon,
    this.flex = 1,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final IconData? icon;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final fg = primary ? scheme.surface : scheme.onSurface;
    final bg = primary ? scheme.onSurface : Colors.transparent;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        borderRadius: kCorner(context, scale: 0.6),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: kCorner(context, scale: 0.6),
            border: Border.all(
              color: primary ? scheme.onSurface : scheme.outlineVariant,
              width: kRuleHair,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: fg,
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

// ════════════════════════════════════════════════════════════
//  杂志化列表行（替代 ListTile）
//
//  Material 的 ListTile 自带 16px 内缩、56px 行高、圆角水波纹，
//  在杂志版面里显得「一块一块」。这里换成：
//    左对齐到页边、上下只有 hairline 一条线、右侧控件贴边、
//    标题用衬线、副标题用小字标。
// ════════════════════════════════════════════════════════════

/// 设置项行：标题 + 可选副标题 + 右侧控件。
///
/// 对应原来的 `ListTile(title:, subtitle:, trailing:)`。
/// 与 ListTile 的差别：无圆角、无内缩卡片感，靠 hairline 分隔。
class EditorialRow extends StatelessWidget {
  const EditorialRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.leading,
    this.dense = false,
    this.serif = true,
    this.showRule = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;

  /// 紧凑行（42px），用于侧栏、抽屉这类高密度列表。
  final bool dense;

  /// 标题是否用衬线体。正文型设置项保持衬线，纯控件标签用无衬线更清楚。
  final bool serif;

  /// 是否画底部 hairline。
  final bool showRule;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final titleStyle = serif
        ? kSerifStyle(
            fontSize: dense ? 14.5 : 15.5,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: scheme.onSurface,
          )
        : TextStyle(
            fontSize: dense ? 14 : 15,
            fontWeight: FontWeight.w500,
            height: 1.3,
            color: scheme.onSurface,
          );
    Widget row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: kPageInset,
        vertical: dense ? 9 : 12,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: titleStyle),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      letterSpacing: 0.1,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
    if (showRule) {
      row = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row,
          Padding(
            padding: const EdgeInsets.only(left: kPageInset),
            child: HairRule(),
          ),
        ],
      );
    }
    if (onTap == null) {
      return row;
    }
    return InkWell(onTap: onTap, child: row);
  }
}

/// 侧栏 / 抽屉里的条目：左侧一条钢红竖线标记选中。
///
/// 替代收藏页、设置页左侧那种「底色块 + 圆角 + 左侧 2px 线」的写法。
class EditorialNavItem extends StatelessWidget {
  const EditorialNavItem({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.count,
    this.icon,
    this.trailing,
    this.indent = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// 右侧计数（收藏夹条目数）。
  final int? count;

  final IconData? icon;
  final Widget? trailing;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: selected ? kRustColor(context) : Colors.transparent,
              width: kRuleThick,
            ),
          ),
        ),
        padding: EdgeInsets.only(
          left: kPageInset + indent - kRuleThick,
          right: 14,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (count != null)
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// 评论区的动作小片：方角细描边 + 图标 + 数字。
///
/// 替代原来 `BorderRadius.circular(16)` 的圆药丸，
/// 与杂志的直角语言一致。
class EditorialActionChip extends StatelessWidget {
  const EditorialActionChip({
    super.key,
    required this.child,
    this.onTap,
    this.active = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final border = active ? kRustColor(context) : scheme.outlineVariant;
    final radius = kCorner(context, scale: 0.5);
    final content = Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: border, width: kRuleHair),
      ),
      child: Center(widthFactor: 1, child: child),
    );
    if (onTap == null) {
      return content;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: content,
    );
  }
}

/// 评论输入条：上下各一条 hairline 夹住，无圆角药丸。
class EditorialInputBar extends StatelessWidget {
  const EditorialInputBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onSend,
    this.sending = false,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant, width: kRuleHair),
        ),
      ),
      padding: EdgeInsets.only(
        left: kPageInset,
        right: 6,
        top: 6,
        bottom: 6 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(fontSize: 14.5, color: scheme.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              minLines: 1,
              maxLines: 5,
            ),
          ),
          if (sending)
            const Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: onSend,
              icon: Icon(Icons.send, size: 19, color: kRustColor(context)),
            ),
        ],
      ),
    );
  }
}

/// 评论区头像：方角（杂志版不用圆形头像）。
class EditorialAvatar extends StatelessWidget {
  const EditorialAvatar({super.key, this.child, this.size = 34});

  final Widget? child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer,
        borderRadius: kCorner(context, scale: 0.5),
      ),
      child: child,
    );
  }
}
