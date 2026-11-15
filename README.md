<div align="center">

# Paperbound

**一个用 Flutter 写的跨平台漫画阅读器**

![version](https://img.shields.io/badge/version-1.8.0-a4522c?style=flat-square)
![flutter](https://img.shields.io/badge/Flutter-3.41-02569B?style=flat-square&logo=flutter&logoColor=white)
![dart](https://img.shields.io/badge/Dart-%3E%3D3.8-0175C2?style=flat-square&logo=dart&logoColor=white)
![license](https://img.shields.io/badge/license-GPL--3.0-a4522c?style=flat-square)

</div>

---

## 这是什么

Paperbound 是从 [venera](https://github.com/venera-app/venera) 派生的一份个人分支，
把界面重做成**杂志排版**的样子：不用卡片、不用阴影堆叠，
层级靠字号跨度、粗细横线和等宽编号表达，整屏看起来更像一本印刷品而不是一个 App。

功能层面保持上游的能力：多图源、收藏、下载、历史、WebDAV 同步、JS 引擎扩展。

> 上游 venera 已停止维护（作者原话：精力有限，欢迎 fork）。
> 这个分支是为自用长期维护的，会继续修 bug 和改界面。

## 视觉语言

- **衬线正文** —— 内嵌 Noto Serif SC（400/700），标题和大字号都用衬线
- **直角优先** —— 封面默认直角配硬阴影，像贴在纸上的一张图
- **钢红信号色** —— `#A4522C`，全应用唯一的暖色，只用于「有新内容 / 当前选中」
- **hairline 分隔** —— 列表不用卡片，用 1px 细线切分
- **悬浮玻璃胶囊** —— 底部导航是一枚浮起来的椭圆玻璃片
- **等宽编号** —— `01 / 02 / 03` 用 tabular figures，不会左右跳

配色是**固定的**，不提供主题色选项。想换风格的话可以调圆角：

| 档位 | 观感 |
|---|---|
| 直角 · 杂志原味 | 默认，最像印刷品 |
| 小圆角 · 温和 | 接近常规 App |
| 大圆角 · 圆润 | 明显柔和 |

## 平台

| 平台 | 状态 |
|---|---|
| Android | 主要目标，CI 出 APK |
| Windows | 可构建 |
| Linux / Debian | 可构建 |
| macOS | 可构建 |
| iOS | 可构建（未签名） |

## 构建

需要 Flutter 3.41（Dart ≥ 3.8）**和 Rust**。

Rust 不是可选项：`rhttp`（网络层）和 `flutter_qjs`（图源 JS 引擎）都是 Rust 插件，
没有工具链会直接编译失败。仓库根目录的 `rust-toolchain.toml` 固定了 **1.85.1**
和三个 Android target，装好 [rustup](https://rustup.rs/) 在项目根目录执行 `rustup show`
就会自动拉齐。

```bash
flutter pub get
flutter build apk --release        # Android
flutter build windows --release    # Windows
```

Android 需要签名配置才能覆盖安装：把 keystore 放到 `android/app/key.jks`，
并在 `android/app/key.properties` 里注明。CI 的做法是把两者存成仓库 Secret
（`KEYSTORE_BASE64`、`KEYSTORE_PROPS`），构建时还原。

改完代码后建议先跑一遍静态检查，CI 也只拦 error 级：

```bash
dart analyze lib
```

## 下载

- **正式版**：见 [Releases](https://github.com/Zx3485/venera-M/releases)，推送 `master` 会自动发版
- **开发版**：见 [Actions](https://github.com/Zx3485/venera-M/actions) 里各次运行的 Artifacts

一次构建会产出 4 个 APK，选 `arm64-v8a` 那个就行（21MB，2017 年后的手机都是这个）。
通用包 `venera-1.8.0.apk` 有 50MB，是三个架构的合并版，装不上时才用它。

## 目录结构

```
lib/
  components/     自绘组件库，含 editorial.dart（杂志排版零件）
  foundation/     数据层：设置、收藏、历史、同步、图源管理
  pages/          各页面
  network/        HTTP 与图源请求
  utils/          工具函数
assets/
  fonts/          Noto Serif SC 子集（400/700，共 6.5MB）
  init.js         JS 引擎的 API 库（图源脚本依赖它）
docs/
  ui-refactor/    这次重构的进度交接与设计说明
```

## 说明

这是自用分支，改动方向偏个人审美，不保证与上游同步节奏一致。
提 issue 之前请先确认问题是否也存在于上游。

## 许可

[GPL-3.0](LICENSE)。派生自 venera，同样遵循 GPL-3.0。
字体使用 [SIL Open Font License](assets/fonts/OFL.txt)。
