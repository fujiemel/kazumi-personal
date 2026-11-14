# Kazumi 个人改造版

这是基于 [Kazumi](https://github.com/Predidit/Kazumi) 的个人使用版本，参考 Animeko 的详情页、选集与追番体验做了裁剪和增强。

- 远程仓库：`https://github.com/fujiemel/kazumi-personal`（公开，仅用于下载和更新）
- 安装包：仓库的 Releases 页面，由 GitHub Actions 自动构建

## 分支与备份

- 分支：`personal/animeko-style`（推送到远程 `main`）
- 标签：`personal-v1` ~ `personal-v4`、版本标签 `2.4.3`
- 单文件备份：`../kazumi-personal.bundle`

## 主要改动

### 详情页
- 放送信息卡：放送开始、更新星期、更新时间、话数、下一话倒计时
- 剧集网格：已放送 / 下一话 / 未放送 / 已看状态
- 剧集列表缓存（30 分钟 TTL）
- `totalEpisodes`、`airTime` 持久化到 Hive

### 追番页
- Animeko 风格横向卡片
- 显示看到第几集、总集数、更新时间
- 已看完时操作按钮变为具体更新时间（小于 7 天显示天数，否则显示日期）
- 「继续观看」先选来源，再按同一集号/进度恢复

### 推荐页
- 顶部「今日更新」
- 不再显示「继续观看」

### 详情页
- 概览顺序：简介 → 剧集 → 标签
- 放送信息卡、剧集网格、已看状态

### 播放页
- 不同线路共用一套集数
- 按解析出的集号对齐，而不是按列表索引
- 切线路时自动找同一集号
- 继续观看支持跨来源恢复同一集和播放进度

### 构建
- Android `applicationId`：`com.fujiemel.kazumi`，可与官方版共存
- Gradle 镜像：`dl.google.com` + 阿里 / 腾讯
- 产物：`../dist/kazumi-2.4.3-arm64-fujiemel.apk`
- 固定 debug 签名：`android/app/debug.keystore`，保证本地构建和 CI 构建可以覆盖安装

## 构建环境

- Flutter 3.47.9
- OpenJDK 21
- Android SDK 36 / Build Tools 36
- NDK 28.2.13676358
- CMake 3.22.1

```bash
export JAVA_HOME="$HOME/development/jdk-21.0.2"
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$HOME/development/flutter/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

flutter pub get
flutter test
flutter build apk --release --target-platform android-arm64
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## 已知限制

- 历史记录仍保存“列表索引”；线路集数有偏移时，卡片进度文字可能和规范集号不一致。
- 当前已播集数是由首播日期按周估算的，遇到停播/拆季会偏乐观。
- APK 为 arm64-v8a、Debug 签名，仅适合个人安装，不能上架应用商店。
- 应用内更新依赖 GitHub Releases；没有新版本标签时不会提示更新。

## 许可证

基于 Kazumi（GPL-3.0）。本仓库保留原项目许可证与版权声明。
