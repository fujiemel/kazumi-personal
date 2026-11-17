# Kazumi 个人自用版

> **仅个人自用。** 本仓库是 [Kazumi](https://github.com/Predidit/Kazumi) 的非官方个人改造版，不对外分发、不提供视频或规则资源、不用于商业用途，与 Kazumi 原作者无关。
>
> 仓库公开仅用于下载安装包和检查更新；图标、字体等第三方资源版权归原作者，若权利人反对将移除相关资源。

## 来源与致谢

| 角色 | 项目 | 说明 |
|---|---|---|
| 原项目 | [Predidit/Kazumi](https://github.com/Predidit/Kazumi) | 本仓库基于 Kazumi `2.4.3` 修改，遵循 GPL-3.0 |
| 借鉴项目 | [open-ani/animeko](https://github.com/open-ani/animeko) | 仅参考详情页、剧集网格、追番卡片和播放器交互，未复制其 AGPL 代码 |

Kazumi 原项目说明、平台支持和完整文档见 [README.upstream.md](README.upstream.md)。

## 修改项

### 详情页
- 新增放送信息卡：放送开始、更新星期、更新时间、话数、下一话倒计时
- 剧集网格支持已放送 / 下一话 / 未放送 / 已看状态
- 概览顺序调整为：简介 → 剧集 → 标签
- Bangumi 剧集列表增加 30 分钟缓存
- `totalEpisodes`、`airTime` 持久化到 Hive
- 续作已开播时显示提示，可一键加入「在看」
- 剧集网格显示每集放送日期
- 关联条目显示本地收藏状态（在看 / 看过等）

### 追番页
- 改为 Animeko 风格横向卡片
- 显示看到第几集、总集数、更新时间
- 追到最新但未完结时，操作按钮显示具体更新时间：
  - 小于 7 天：`X 天后更新`
  - 7 天及以上：`M 月 D 日更新`
- 完结后按钮变为「从头观看」，进度行不再重复集数
- 「继续观看」先选择播放来源，再按同一集号/进度恢复
- 移除「选集」按钮
- 已开播的续作会在卡片上提示

### 推荐页
- 顶部只保留「今日更新」
- 移除「继续观看」

### 播放器
- 不同线路共用一套集数
- 按解析出的集号对齐，而不是按列表索引
- 切换线路时自动定位到同一集号
- 继续观看支持跨来源恢复同一集和播放进度

### 历史记录
- 在线记录继续播放时先选择来源；离线记录仍走本地播放

### 搜索与时间表
- 搜索结果、时间表卡片标注本地收藏状态，避免重复追番

### Bangumi 同步
- 同步想看 / 在看 / 看过状态
- 回写「看到第几集」（每集看完 90% 后静默更新）
- 读取 Bangumi 上的观看进度，比本地新时提示「从第 N 集继续」

### 构建与更新
- Android `applicationId` 改为 `com.fujiemel.kazumi`，可与官方版共存
- 自制图标：粉发 + 星星发夹，和官方版一眼区分
- Gradle 使用 Google / 阿里 / 腾讯镜像
- **应用内更新源改为本仓库的 GitHub Releases**
  - 检查更新：`https://api.github.com/repos/fujiemel/kazumi-personal/releases/latest`
  - 镜像检查：经 `gh-proxy.org` 访问 GitHub API
  - APK 资产名需包含 `android` 和 `.apk`，例如 `Kazumi_android_2.4.5.apk`

## 下载与安装

安装包由 GitHub Actions 自动构建，发布在：

**https://github.com/fujiemel/kazumi-personal/releases**

- **Android**：下载 `Kazumi_android_<版本>.apk`，在手机上允许“安装未知应用”后安装。
  - 仅提供 `arm64-v8a` 版本，适用于绝大多数近几年的安卓手机。
  - 包名为 `com.fujiemel.kazumi`，可以和官方 Kazumi 同时安装。
- **Windows**：下载 `Kazumi_windows_<版本>.zip`，解压后运行 `kazumi.exe`。

应用内「检查更新」会读取本仓库的 Releases，检测到新版本后可直接下载安装。

## 发布新版本

1. 修改 `pubspec.yaml` 的 `version:`，例如 `2.4.6+20406`
2. 提交并推送 `main`
3. 创建并推送同名标签：`git tag 2.4.6 && git push personal 2.4.6`
4. GitHub Actions 自动构建 APK 和 ZIP，并发布到 Releases

注意：标签名要与 `version:` 前半段一致，应用内更新按标签名比较版本；一次只推一个标签，否则 GitHub 可能不触发构建。

## 构建

环境、命令和已知限制见 [PERSONAL.md](PERSONAL.md)。

```bash
export JAVA_HOME="$HOME/development/jdk-21.0.2"
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$HOME/development/flutter/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

flutter pub get
flutter test
flutter build apk --release --target-platform android-arm64
```

## 许可证与资源

- 代码基于 Kazumi，遵循 **GPL-3.0**，保留原项目版权与许可证。
- 借鉴的 Animeko 采用 **AGPL-3.0**；本仓库未复制其代码。
- 本仓库使用自制图标（`assets/images/logo/logo_personal.svg`），未使用原项目图标。
- MiSans 字体版权归小米；本仓库仅个人使用，未获得再分发授权。
- 本项目不存储、不提供任何视频内容；所有内容来自用户自行配置的第三方来源。
