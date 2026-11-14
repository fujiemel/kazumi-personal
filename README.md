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

### 追番页
- 改为 Animeko 风格横向卡片
- 显示看到第几集、总集数、更新时间
- 已看完时操作按钮显示具体更新时间：
  - 小于 7 天：`X 天后更新`
  - 7 天及以上：`M 月 D 日更新`
- 「继续观看」先选择播放来源，再按同一集号/进度恢复
- 移除「选集」按钮

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

### 构建与更新
- Android `applicationId` 改为 `com.fujiemel.kazumi`，可与官方版共存
- Gradle 使用 Google / 阿里 / 腾讯镜像
- **应用内更新源改为本仓库的 GitHub Releases**
  - 检查更新：`https://api.github.com/repos/fujiemel/kazumi-personal/releases/latest`
  - 镜像检查：经 `gh-proxy.org` 访问 GitHub API
  - APK 资产名需包含 `android` 和 `.apk`，例如 `Kazumi_android_2.4.3.apk`

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
- Kazumi 图标版权归画师 Yuquanaaa，MiSans 字体版权归小米；本仓库仅个人使用，未获得再分发授权。
- 本项目不存储、不提供任何视频内容；所有内容来自用户自行配置的第三方来源。
