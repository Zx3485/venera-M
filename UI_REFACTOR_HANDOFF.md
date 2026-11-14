# venera-M UI 精致化重构 · 交接文档

> 写给下一个接手的 AI / 开发者。读完这份即可了解本次重构的完整上下文。
> 日期：2026-11-14 · 分支：`ui-refactor` · 提交：`cfe207b`

---

## 一、背景与决策

- 项目：Venera 漫画阅读器的 fork（Flutter，`pubspec.yaml` 锁定 `flutter: 3.41.4`），仓库 `Zx3485/venera-M`。
- 用户需求：「重构整个 UI，越精致越好」，经确认视觉方向为 **强化玻璃拟态**（在已有磨砂 + Material 3 基础上全面收敛细节，而非推翻重做）。
- 约束：只动视觉与组件层，**不改任何业务逻辑 / 网络 / 存储层**；用户设置项语义全部保留。

## 二、代码改动总览

24 个文件，+696 / -291 行，全部在 `lib/`（跨平台共用 Dart 层，APK / Windows / 桌面 Linux 全部生效）。

### 1. 设计 Token 体系（新地基）

`lib/components/consts.dart` 重写，全项目样式禁止再写裸字面量：

| Token | 值 |
|---|---|
| 圆角 | `kRadiusXs=6 / kRadiusS=10 / kRadiusM=14 / kRadiusL=20 / kRadiusPill=999`，配套 `kBRXs/kBRS/kBRM/kBRL/kBRPill` 常量 |
| 间距 | `kSpaceXs=4 / S=8 / M=12 / L=16 / Xl=24 / 2Xl=32` |
| 动效 | `kDurationFast=150ms / Normal=220ms / Slow=320ms`，曲线 `kCurve=Curves.easeOutCubic`、`kCurveEmphasized` |
| 描边 | `kBorderHairline=0.8`（全项目唯一描边宽度） |
| 阴影 | `kOverlayShadows(brightness)` 双层阴影函数（暗色更深更贴脸），替代散落的单层阴影和「白色阴影」hack |
| 玻璃描边 | `kGlassBorderColor(isDark)` |

兼容性：旧的 `_fastAnimationDuration` 保留为 `kDurationFast` 的别名，components 库内引用不破。

### 2. 低饱和语义色板（替代 Material 原色彩虹）

同文件内 `_buildSoftSwatch(int base)` 从单一基色生成 MaterialColor 十档 swatch（100 档提亮 45%、800 档压暗 34%），配合既有的 `context.useTextColor()` / `useBackgroundColor()`（亮色取 800、暗色取 100）实现深浅主题自适应。

- `kSoftAmber`（阅读/继续）、`kSoftTeal`（下载/历史）、`kSoftRed`（点赞/顶）、`kSoftPurple`（收藏）、`kSoftGreen`（评论）、`kSoftBlue`（分享/踩）、`kSoftPink` / `kSoftIndigo`（标签点缀）
- 色相与 `lib/main.dart` 里 fork 自带的 8 个柔和主题色（雾霾蓝/藕荷紫/鼠尾草绿…）同族
- 已替换：comic_page 动作按钮 7 色、buildTag 标签 10 色、comments_page/chapter_comments 投票色、home_page 同步进度条渐变（改为主题色 lerp）、home_page 错误图标（改 colorScheme.error）、reader 重试按钮（改 primary）、reader 低电量图标（改 colorScheme.error）

### 3. 主题系统补全（`lib/main.dart` getTheme）

原来只配了 colorScheme + 字体，M3 默认组件与自绘组件风格脱节。现补齐：

`dialogTheme`（surfaceContainerHigh + kBRL + barrier 0.5 黑）、`popupMenuTheme` / `menuTheme`（elevation 0、kBRM、outlineVariant 0.5 描边、去 surfaceTint）、`cardTheme`（elevation 0 / surfaceContainerLow / kBRM）、`chipTheme`、`sliderTheme`（track 6 / thumb 11）、`scrollbarTheme`（pill 圆角、hover 6px/常态 4px、onSurface 0.28）、`dividerTheme`（outlineVariant 0.4）、`listTileTheme`（kBRM）、InkSparkle splash（亮色）。

### 4. 玻璃系统强化（`lib/components/glass.dart`）

- **GlassCard 暗色填充**：原来 `Colors.white * opacity*0.6` 在暗色下泛灰雾 → 改为 `colorScheme.surface` 填充（`math.max(opacity, 0.25)` 下限）
- **新增 `floating` 参数**：叠加 `kOverlayShadows`，用于独立悬浮面板；`adaptiveGlass()` 同步支持（注意它是**顶层函数没有 context**，暗色判断改读 `theme_mode` 设置 + `platformBrightness`）
- **接入死设置 `glassInAppBar`**：`lib/components/appbar.dart` 的 Appbar 与 SliverAppbar delegate 原来写死 `surface 0.86` 底色，现按 `glassInAppBar ? (0.86 - glassOpacity*0.8).clamp(0.25,0.86) : 0.86` 减薄（公式与 reader/scaffold.dart 既有做法一致），SliverAppbar 的模糊半径也改读 glassBlur。**此设置项此前在设置页有开关但从未生效。**

### 5. 弹层四件套统一

| 文件 | 改动 |
|---|---|
| `menu.dart` | 圆角 4→kBRS、统一玻璃描边+双层阴影、条目圆角 kBRXs、转场 fade+scale(0.95) |
| `message.dart` | **Toast 重写为 StatefulWidget**：GlobalKey + `dismiss()` 淡出动画（reverse 完成后才移除 OverlayEntry），此前瞬间闪现；ContentDialog 圆角 8→kBRL、底色 surfaceContainerHigh、去 elevation、AnimatedSize 用 Token |
| `pop_up_widget.dart` | 删暗色白色阴影 hack → kOverlayShadows、圆角 12→kBRL、转场 fade+上浮+scale(0.96)、350ms→kDurationSlow |
| `side_bar.dart` | 同上：删白色阴影 hack、左缘圆角 16→kRadiusL、300ms→kDurationSlow |
| `flyout.dart` | FlyoutContent 圆角/描边 Token 化、标题 w600-0.3 字距、转场加 fade |
| `select.dart` | 删硬编码菜单色 `0xFFF6F6F6`/`0xFF1E1E1E` → `surfaceContainerHigh` + kBRM + 描边，触发器圆角 4→kBRXs |

### 6. 核心组件

- **`comic.dart` ComicTile**（全项目漫画网格唯一出口，7+ 处复用）：双模式封面阴影统一为 `black 0.14 / blur 5 / offset(0,2)`；圆角统一 kBRS（封面）与 kBRM（detailed 点击域）；brief 标题 `clip` 硬切→`ellipsis` + height 1.25；收藏角标 Colors.green→colorScheme.primary、历史角标→black 0.6（进度画笔仍白色）；角标组加轻投影；标签 chip 间距 4/3→kSpaceS/kSpaceS、radius 8→kBRXs、内边距 4→6；语言徽章改 pill 形
- **`appbar.dart`**：标题统一 `fontSize 20 / w600 / letterSpacing -0.3`（Appbar、SliverAppbar 两处）；tab 底线与搜索栏分隔线减淡到 0.4-0.5 alpha + hairline
- **`button.dart`**：Button 改完整药丸（kBRPill，原 16 固定）、文字 w500、AnimatedContainer/AnimatedSize 用 Token+曲线、outlined 描边 hairline+0.6 alpha、HoverBox 动效 Token
- **`loading.dart`**：FiveDotLoadingAnimation 彩虹五点 → `primary→tertiary` 五级 Color.lerp 渐变；LoadingState / MultiPageLoadingState 的首屏裸转圈 → FiveDot；`comic.dart` ComicList 两处裸转圈 → FiveDot
- **`navigation_bar.dart`**：顶栏标题 18/bold → 20/w600/-0.3
- **`custom_slider.dart`**：删 `surface.withRed(10)` 碰巧取色 → `onSurfaceVariant 0.55`
- **`settings_page.dart`**：分类选中态从「左直角 2px 条」改为「圆角容器 kBRS + 3px 圆头指示条 AnimatedContainer 弹出」（仍 Windows 设置风格但更精致）

### 7. 页面层

- `home_page.dart`：6 处板块卡片（历史/本地/同步/空态等）描边减淡 + 加 `surfaceContainerLow 0.55` 极淡填充 + kBRS 圆角；显示模式切换 chip 描边减淡
- `explore_page.dart`：板块标题 w500→w600/-0.3
- `comic_page.dart`：动作按钮/标签/投票色全部换语义色板（见 §2）
- 阅读器页码/电量的「描边 Text」技术保留（onSurface 字形 + onInverseSurface 描边，语义自洽），只换掉了其中的硬编码色

### 8. 明确没动的（有意保留）

- 页面转场系统（`foundation/app_page_route.dart`）：fork 已有 5 种用户可选转场（fade/zoom/slideUp/sharedAxisX/none + 平台默认），无需再统一
- 阅读器 Icon 的 9-Shadow 描边技术（Icon 无法 stroke，这是标准做法）
- 窗口关闭按钮的红色 hover（OS 惯例）
- 阅读器覆盖文字不加玻璃（BackdropFilter 叠在全屏图片上帧率风险）
- 列表项级联入场动画（百级网格性能风险）

## 三、验证状态

- `flutter analyze`：**0 error / 0 warning**，仅 9 条 info 级弃用提示（全部为上游存量：TickerMode.of ×2、Share/shareXFiles ×6、字符串拼接 ×1，均不在本次改动引入）
- 已推送 `ui-refactor` 分支 → CI `build-apk.yml` 自动构建中（特性分支只出 Artifact，**不发 Release**，工作流 132 行写死 `github.ref == 'refs/heads/master'` 才发布）
- **未做实机视觉走查**（本机无 Android 环境、Windows 构建被开发者模式卡住），待用户装机确认

## 四、踩坑记录（重要！）

1. **`num.clamp()` 返回 num 不是 double**：`(0.86 - x*0.8).clamp(0.25, 0.86)` 传给 `double` 参数会报错，必须 `.toDouble()`（appbar.dart 两处）或改用 `math.max`（glass.dart）。改动涉及 clamp 时务必检查。
2. **顶层函数没有 BuildContext**：`adaptiveGlass` 是顶层函数，不能 `context.isDarkMode`，改读 `appdata.settings['theme_mode']` + `WidgetsBinding.instance.platformDispatcher.platformBrightness`。
3. **`flutter pub get` 在无开发者模式的 Windows 上会失败**于插件 symlink 环节（"Building with plugins requires symlink support"），但**依赖解析已完成**，`flutter analyze --no-pub` 不受影响。APK 构建不需要开发者模式（symlink 只卡 Windows 桌面目标）。
4. 本地构建环境缺失：无 Android SDK / JDK17（现有 Java 11）/ Rust（`rust-toolchain.toml` 锁 1.85.1 + 3 个 Android target）。本地装齐约 2.5-3.5 GB 下载 / 8-10 GB 磁盘。Flutter SDK 已装在 `C:\Game\AIWork\tools\flutter-3.41.4`（用 flutter-io.cn 镜像）。
5. CI 的 analyze 门禁（build-apk.yml L97-116）只拦 `error •` 行，info/warning 不判失败。

## 五、待办 / 候选

1. **装机视觉走查**（等 CI Artifact 或用户开启开发者模式后本地 Windows 构建）
2. 用户若反馈具体页面问题，按 §六 的 Token 体系调整即可，不要再写裸字面量
3. 候选增强（未做）：GlassCard floating 用于首页搜索条、设置页详情转场对齐 Token、字体内置化（pubspec fonts: 被注释，桌面端依赖系统 Noto Sans CJK，未装时回退链不可控）

## 六、改动文件清单

```
lib/components/   consts.dart(重写) glass.dart(重写) menu.dart(重写) message.dart(重写)
                  appbar.dart button.dart comic.dart flyout.dart loading.dart
                  navigation_bar.dart pop_up_widget.dart select.dart side_bar.dart
                  custom_slider.dart
lib/pages/        home_page.dart explore_page.dart settings/settings_page.dart
                  comic_details_page/comic_page.dart comments_page.dart comments_preview.dart
                  reader/scaffold.dart reader/comic_image.dart reader/chapter_comments.dart
lib/main.dart
```

回退方式：`git checkout master -- lib/` 或 `git revert cfe207b`（master 未受影响）。
