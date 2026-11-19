# B 路线规格：kazumi-personal 深改（主题＋播放页向 Animeko 靠）

状态：待用户拍板视觉令牌后开工。施工方式照旧分工：Muse 写规格＋审 diff，OpenCode 写码，Actions 云构建，用户真机验收。逐页交付，审过一页才写下一页。

## 调研结论（2026-11-19 实测源码）

Animeko「好看」的机制（open-ani/animeko 源码）：
1. 无固定品牌色：种子色（默认 #4F378B 紫）经 HCT 生成整套 MD3 色调（materialkolor dynamicColorScheme）。
2. 详情/选集页按**当前番剧封面图**提取调色板重新生成该页配色（MaterialThemeFromPaletteAndImage + kmpalette）——页面跟着番剧变色。
3. 顶栏/铬层磨砂玻璃（AppChromeFrostedGlass）。

kazumi-personal 现状：
- 已是 MD3＋colorSchemeSeed 架构（lib/app_widget.dart `_buildAppTheme`），默认种子色却是 Colors.green；用户可选种子色（theme_settings_page）。
- 无封面动态取色；无磨砂玻璃；lib/utils/theme.dart 只有 OLED 纯黑变体。
- 播放页 lib/pages/video/video_page.dart 622 行，控制层与页面同文件。

## 第 1 页：全局主题令牌＋详情页动态取色

令牌（数值，施工方不得自由发挥）：
- 默认种子色：#4F378B（Animeko 同款紫）。预设种子色 8 个：#4F378B 紫 / #315C9C 蓝 / #2E6B4F 绿 / #A23B3B 红 / #B06A00 橙 / #7A4E8C 葡萄 / #0F766E 青 / #5B5BD6 靛。
- 深色模式底色走 tonal surface（跟随 ColorScheme.surface），OLED 纯黑保留为可选项（现有 oledDarkTheme 不动）。
- 圆角收编：卡片 12 / 海报 8 / 弹窗 16 / 按钮 stadium；全仓硬编码 BorderRadius 逐步替换为这四档（本页只动详情页范围）。
- 磨砂玻璃：详情页顶栏与播放页控制层 BackdropFilter blur sigma 18，背景 surface 色 72% 不透明度。

详情页动态取色：
- 进入详情页时用 palette_generator 从封面（Bangumi 图片 common 尺寸）提取 dominant/vibrant 色，生成页面级 ColorScheme.fromSeed(seedColor: 提取色, brightness: 当前明暗)，仅作用于详情页子树（Theme 包裹），退出即恢复全局。
- 提取失败/超时（上限 600ms）回退全局种子色，不阻塞页面渲染；结果按 subjectId 缓存到内存 Map。
- 作用范围：顶栏、放送信息卡、剧集网格选中态、按钮；正文文字色保持 onSurface 不染色。

验收：analyze 零新增警告；详情页在 3 部不同封面色调的番（深色/亮色/高饱和各一）下截图对照令牌；不改任何数据逻辑（git diff 只许出现 theme、info_page、bangumi_episode_grid、bangumi_air_info_card 相关文件）。

## 第 2 页：播放页控制层

- 底部渐变罩：高度 120，自下而上黑 60%→0%；顶部渐变罩高度 88，黑 45%→0%。
- 左上：番名 15 w600＋集数 12（白色 80%）；右上只留弹幕开关、设置两键，间距 8。
- 进度条贴底全宽：高 3，缓冲条白色 30%，已播 primary（跟随全局种子色），圆头。
- 中央三键：快退 10s / 播放暂停 56 圆形半透明黑 40% / 快进 10s，键间距 32。
- 弹幕设置改底部抽屉（圆角 16，磨砂同上）：开关、透明度、字号、显示区域、屏蔽词入口，不再跳设置页。
- 手势浮层（亮度/音量/进度）统一为圆角 12、黑 55% 背景、白字 13。
- 只动 video_page.dart 的控制层 widget 与新建 player_control_layer.dart；video_controller 逻辑零改动。

## 第 3 页：其余页面令牌收编

- 首页/追番/搜索：卡片圆角、海报圆角、间距（页边距 16、卡间距 12、区块间距 24）统一到第 1 页令牌；搜索框高 48 圆角 12。
- 不动信息结构（fork 已改好的追番卡、倒计时、角标全部保留）。

## 上游合并预案（选 B 的代价管理）

- 换皮与逻辑分离：新代码尽量进新文件（theme_tokens.dart、player_control_layer.dart、dynamic_theme_scope.dart），对上游文件的改动只做「引用替换」级。
- 固定冲突清单：app_widget.dart、video_page.dart、info_page.dart、theme_settings_page.dart。每次上游发版，先在 merge 试合分支跑一遍，冲突只应出现在这四个文件里；超出即停下报告。
- 版本号改用自有序列（如 3.x），不再跟上游撞号；应用内更新继续指向本仓库。

## A 的底子修复（与 B 并行排期）

1. 签名：生成正式 release keystore，移出 git；密码进 GitHub Secrets（需用户在网页端配合录入一次）；旧 debug 签名版本需卸载重装一次。
2. 已播集数：改查 Bangumi 剧集表（/v0/episodes 或条目 episodes 接口）真实数据，删周推估算。
3. 历史记录：改存规范集号（sort/ep），列表索引仅作当页定位用；迁移旧数据时按现有索引＋集号映射回填。
4. girigiri 的 Kazumi 规则内置一份为默认规则（仓库内置 assets），首次启动自动导入，省手动导入。
