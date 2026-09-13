# WinCleanKit

**把决定权交还给用户的 Windows 11 减负工具。** 关掉微软的广告与遥测、清掉你从没要过的预装应用 —— 而每一处改动都由你本人拍板。

[![License: MIT](https://img.shields.io/badge/License-MIT-3DA639.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D4.svg)](#环境要求)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE.svg)](#环境要求)
[![Actions](https://img.shields.io/badge/catalog-74%20actions-4B5563.svg)](docs/CATALOG.md)
[![Gates](https://img.shields.io/badge/gates-8%20passing-22C55E.svg)](#仓库结构)

[English](README.md) · **中文说明**  
**文档:** [用法](docs/USAGE.zh-CN.md) ([EN](docs/USAGE.md)) · [安全](docs/SAFETY.zh-CN.md) ([EN](docs/SAFETY.md)) · [限制](docs/LIMITATIONS.zh-CN.md) ([EN](docs/LIMITATIONS.md)) · [行动目录](docs/CATALOG.md) · [代码规范](docs/LINTING.md)  
**项目:** [参与贡献](CONTRIBUTING.zh-CN.md) ([EN](CONTRIBUTING.md)) · [安全政策](SECURITY.zh-CN.md) ([EN](SECURITY.md)) · [行为准则](CODE_OF_CONDUCT.zh-CN.md) ([EN](CODE_OF_CONDUCT.md)) · [更新日志](CHANGELOG.md) · [许可证](LICENSE)

---

## 界面长什么样

全屏 TUI，纯键盘操作。方向键移动，`Tab` 切换面板，`空格` 勾选 —— 右侧面板在你动手之前
就回答「这到底会改什么」：

```text
+--------------------------------------------------------------------------------------------+
| WinCleanKit v0.1.0   计划: 45 项                                                           |
| 最高风险: 中                                                                               |
+--------------------------------------------------------------------------------------------+
+---------------------------------------+----------------------------------------------------+
|-  20/22  系统广告与推荐               |> [x] 禁止静默自动安装应用                          |
|  17/21  遥测与诊断数据                | [x] 关闭订阅内容(推荐/广告)                        |
|   0/19  预装应用                      | [x] 关闭桌面 Spotlight 广告图                      |
|   0/1   OneDrive                      | [x] 关闭锁屏广告浮层                               |
|   7/10  隐私加固                      | [ ] 关闭锁屏 Spotlight 轮播                        |
|   1/1   广告图缓存与壁纸              | [x] 关闭设置与开始菜单建议                         |
|                                       | [x] 关闭内容推送                                   |
|                                       | [x] 禁止 OEM 预装应用推广                          |
|                                       | [x] 关闭欢迎与提示落地页                           |
+ 详情 · 条目 --------------------------+ [x] 移除开始菜单“推荐”区推广                       |
|禁止静默自动安装应用   [低]            | [x] 关闭最近使用文件建议                           |
|阻止云内容提供程序（ContentDeliveryMana| [x] 隐藏任务栏小组件按钮                           |
|ger）在后台静默下载推广软件。Windows 经| [x] 隐藏任务栏聊天(Teams)按钮                      |
|常不经提示就在开始菜单里偷偷塞进社交或…| [x] 隐藏桌面“了解此图片”图标                       |
|触及: HKCU\Software\Microsoft\Windows\C| [x] 关闭搜索框联网推荐                             |
|urrentVersion\ContentDeliveryManager\S…| [ ] 隐藏设置首页推广区块                           |
|                                       | [x] 关闭 Edge 推广标签页与推荐                     |
+---------------------------------------+----------------------------------------------------+
| 上下移动  Tab面板  Enter勾选  ?帮助  x执行  q退出                                          |
| 空格勾选，p 预览，x 执行；未确认前不会改动任何东西                                         |
+--------------------------------------------------------------------------------------------+
```

| 按键 | 作用 |
|---|---|
| `↑` `↓` | 在当前面板内移动 |
| `Tab` | 在分类面板与动作面板之间切换 |
| `Enter` | 进入分类；在动作面板中勾选并下移 |
| `空格` | 勾选 / 取消当前动作 |
| `a` / `n` | 选中 / 取消当前分类全部 |
| `A` / `N` | 选中 / 取消全部 |
| `l` | 切换界面语言（中 / 英） |
| `p` / `x` / `q` | 预览计划 / 执行 / 退出 |
| `?` | 应用内帮助 |

TUI **不重复实现**任何保护你的逻辑：预览调用引擎自己的计划渲染，执行时把选中的 id
交回引擎：

```text
   ------------------------------------------------------------------
   WinCleanKit 0.1.0
   ------------------------------------------------------------------
   Selected : 74 action(s)
   Mode     : PREVIEW ONLY

   Ads & suggestions         22 action(s)
     [low ] Forbid silent app installation
     [low ] Disable subscribed content (recommendations/ads)
     [MED ] Hide Settings home page promos

   Total actions : 74
   Highest risk  : high
```

执行时带进度计数，且只有**一套**状态词表；含义由文字标记承载，**不依赖颜色**：

```text
   [ok]  [  1/74]   1%  禁止静默自动安装应用 — HKCU\SilentInstalledAppsEnabled = 0
   [--]  [  5/74]   6%  卸载 Windows 地图 — not installed
   [!!]  [ 12/74]  16%  隐藏设置首页推广区块 — key accepted the write but dropped it
   [XX]  [ 40/74]  54%  某动作 — access denied
```

图例：`[ok]` 已生效 · `[dry]` 将生效 · `[--]` 不适用 · `[!!]` 已跳过或受保护 · `[XX]` 失败。

> **终端不支持全屏界面？** 用 `run.bat --simple`（或 `WinCleanKit.ps1 -Tui:$false`）
> 走纯文本编号菜单。TUI 自己也会检测并降级，而不会把转义码灌进日志。

## 为什么还要再做一个？

市面上的去广告脚本基本是一大串 `reg add`，**先执行、后告诉你**干了什么。你不知道改了什么、没法反对其中任何一条、也没有干净的回退路径。

WinCleanKit 反过来设计：

| 原则 | 落到实处的做法 |
|---|---|
| **你说了算** | 基础项默认勾好，其余一个空格就能选上。**你没选的，一条都不执行。** |
| **先看见再动手** | 每条操作都带大白话的「为什么」、风险等级，以及独立的预览步骤。 |
| **永远退得回去** | 每次执行都在桌面生成带时间戳的备份 + 一键还原脚本。 |
| **广告图是图，不是设置** | 会删广告图，但绝不碰你的壁纸。 |
| **你的数据不关它的事** | 不修改 `hosts`、不碰个人文件、绝不靠近你的 OneDrive 数据目录。 |

---

## 快速开始

```text
1.  下载或克隆本仓库
2.  双击  run.bat
3.  同意 UAC 提权                （改机器级设置需要管理员权限）
4.  看计划、按需增减勾选 → 输入 APPLY
```

在你于最终确认处输入 `APPLY` 之前**什么都不会发生**；而一轮运行做的第一件事，
就是在桌面写下回滚点。

<a id="环境要求"></a>

> **环境要求**：Windows 10 1809+ / Windows 11 · Windows PowerShell 5.1 或 PowerShell 7+ · 修改 `HKLM` 需要管理员权限。
> 即使跑完本工具，Windows 11 专业版/家庭版仍会发送**必需**级诊断数据 —— 这是平台限制，不是设置能绕过的，见[已知限制](docs/LIMITATIONS.md)。

### 默认勾选了什么

**没有起步前要先选的档位。** catalog 里标了 `default` 的 **74 项中的 45 项**就是默认集 ——
取舍最小的那些，最坏情况也只是少了个推广位或后台采集器 —— 界面打开时正好勾选这些。
其余全部是选装：

| | 项数 | 覆盖内容 |
|---|---|---|
| **默认勾选** | 45 | 广告与推荐、最安全的遥测开关、隐私偏好。除广告消失外没有可见行为变化。 |
| **需要自己选** | 29 | 错误报告与兼容性服务、预装消费类应用，以及有真实取舍的项目：游戏栏、OneDrive、定位、设置同步、新版 Outlook、手机连接。 |

**加回去这件事不存在。** 关掉一项就是关掉，打开一项也只是一个空格 —— 没有哪一档会在你切换时
把已做的选择推翻。这条分界由 `tests/Test-Catalog.ps1` 强制保证，其中还包括「默认集里不含任何
高风险动作」以及「卸载软件类的动作一律不在默认集内」。

---

## 命令行

`.bat` 只是 `src\WinCleanKit.ps1` 的前端。引擎可以单独使用，因此脚本化与无人值守都很方便。

```powershell
# 以 JSON 输出 catalog 的全部内容
.\src\WinCleanKit.ps1 -ListCatalog

# 预览默认集（不修改任何东西）
.\src\WinCleanKit.ps1 -Plan

# 只预览两条，中文界面
.\src\WinCleanKit.ps1 -Plan -Only 'ads.cdm.silent-install,apps.maps' -Language zh

# 无人值守执行整个分类
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Only telemetry

# 执行文件里手挑的清单（每行一个 id，支持 # 注释）
.\src\WinCleanKit.ps1 -Apply -NoPrompt -FromFile .\my-selection.txt

# 用默认集，但剔除你不同意的几项
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Skip 'apps.xbox,apps.outlook-new'

# 查看与使用还原点
.\src\WinCleanKit.ps1 -ListRestores
.\src\WinCleanKit.ps1 -Restore WinCleanKit-20260913-004942
```

`-Only` 是**权威列表**：一旦传入，默认集完全不参与，选中集合就是你指定的那些。这正是「逐项取消勾选」能可靠生效的原因。

完整参数说明见 [docs/USAGE.md](docs/USAGE.md)。

---

## 它能改什么

6 个分类、74 条操作。**每一条都是数据**，写在 [`catalog/catalog.json`](catalog/catalog.json) 里，而不是硬编码逻辑。增删一条操作、改一句说明，都只是改 JSON，UI 和引擎会自动跟上。

| 分类 | 数量 | 例子 |
|---|---|---|
| 系统广告与推荐 | 22 | 静默装应用、锁屏 Spotlight 广告、开始菜单推荐、小组件资讯流、搜索框联网推荐、Edge 推广标签 |
| 遥测与诊断数据 | 21 | `DiagTrack`、兼容性评估、CEIP 上报、错误报告、反馈请求 |
| 预装应用 | 19 | Clipchamp、Dev Home、纸牌、Office Hub、Bing 资讯/天气、Xbox 覆盖层 |
| OneDrive | 1 | 移除客户端并阻止重装 |
| 隐私加固 | 9 | 广告 ID、输入个性化、文本/手写隐式采集、定位、设置同步 |
| 广告图缓存与壁纸 | 1 | 删除已下载的 Spotlight 广告图 |

每条操作都写明了风险、代价和存在理由。完整清单见 [docs/CATALOG.md](docs/CATALOG.md)。

### 明确不做的事

以下是设计上**有意不做**的：

- **不修改 `hosts` 文件。** 用那种方式屏蔽微软域名可能破坏 Windows Update、Store，在办公机器上还会打断 VPN 与 SSO 登录。
- **不碰个人文件、壁纸、OneDrive 数据目录。**
- **不关闭 Windows Update。** 安全补丁不是牛皮癣。
- **不关闭传递优化服务。** 它是更新加速器，不是遥测。（其 P2P 共享可以单独关。）
- **不搞坏 Edge。** 只关它的推广标签页，不卸载浏览器。

---

## 安全与回滚

动手之前，WinCleanKit 会先创建：

```
桌面\WinCleanKit-<时间戳>\
├── backup.json                 全部原始值，逐字节记录
├── Restore-WinCleanKit.ps1     整轮操作的一键还原
└── run.log                     每条操作一行，含跳过与失败
```

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\WinCleanKit-<时间戳>\Restore-WinCleanKit.ps1"
```

注册表值会被精确还原，服务回到原启动类型，计划任务重新启用。被卸载的 Store 应用不会自动重新下载（还原脚本会告诉你该重装哪些）。在**工作机器**上运行前请先读 [docs/SAFETY.md](docs/SAFETY.md)。

---

## 仓库结构

```
WinCleanKit/
├── run.bat                      双击入口（大多数人只需要这个）
├── src/
│   ├── WinCleanKit.bat          交互前端：提权、菜单、确认
│   ├── WinCleanKit.ps1          引擎 + 终端设计系统
│   └── menu/menu.ps1            菜单数据提供者（让 bat 不必解析 JSON）
├── catalog/catalog.json         全部 74 条操作，以数据形式存在
├── docs/                        目录、用法、安全、限制、代码规范
├── tests/                       八道门禁：含 TUI 逻辑与布局
├── tools/                       New-CatalogDoc.ps1（生成双语行动目录）
├── .github/workflows/           CI（在 .gitea/workflows 有镜像）
└── localization/                UI 文案
```

### 设计说明

- **Catalog 是唯一事实来源。** UI 渲染它、引擎执行它、测试校验它。代码里不存在 catalog 之外的操作。
- **`.bat` 从不直接碰注册表。** 它只负责解析意图并委派。因此 UI 保持可读，引擎保持可测。
- **`.ps1` 文件刻意带 UTF-8 BOM。** Windows PowerShell 5.1 会把无 BOM 的脚本按 ANSI 代码页解码，中文界面会变乱码。`.gitattributes` 把它们标为 `-text`，避免任何字节被改写。
- **写入后必定读回校验。** 少数 Windows 键会「接受写入然后静默丢弃」，这类情况会被报为 `[FAIL]`，而不是假成功。

---

#### 终端设计系统

控制台界面不是随手写的 `Write-Host`。`src/WinCleanKit.ps1` 统一持有一套配色与一套状态词表，
`src/WinCleanKit.bat` 复用同一组颜色角色，因此前端与引擎看起来是同一个产品。

- **语义色角色，而非硬编码颜色。** `brand`、`accent`、`success`、`caution`、`danger`、`muted`。
  换配色只需改 `$script:Ink` 里的一行。
- **宽度感知对齐。** 中文字形占两个终端列却只算一个字符，PowerShell 自带的 `{0,-20}`
  会让中英混排的表格参差不齐。`Format-Text` 按显示宽度补齐 —— 这就是为什么分类计数
  在中文和英文下能对齐到同一列。
- **颜色从来不是唯一信号。** 每种状态都有文字标记（`[ok]`、`[dry]`、`[--]`、`[!!]`、`[XX]`），
  并且当输出被重定向、进入管道或设置了 `NO_COLOR` 时，颜色会降级为纯文本 ——
  日志与 CI 采集因此始终干净。
- **长任务有进度。** 74 条动作会打印 `[ 12/74]  16%`，绝不会看起来卡死。
- **不闪屏。** 前端改用光标归位、在原帧上重绘，而不是每屏都 `CLS`；同时保留最近 25 行作为回看。

## 参与贡献

新增一条操作通常只是改一小段 JSON。请先读 [CONTRIBUTING.md](CONTRIBUTING.md) —— 里面说明了风险等级、默认集规则，以及一句好的 `why` 该长什么样。

```powershell
# 语法门禁：PowerShell 解析器 + 文件编码规则
.\tests\Test-Parse.ps1

# 代码规范门禁：PSScriptAnalyzer（需先 Install-Module PSScriptAnalyzer -Scope CurrentUser）
.\tests\Test-Analyzer.ps1

# 文档门禁：链接可达、中英双语成对且双向互链、仓库内无内网地址
.\tests\Test-Docs.ps1

# 生成的行动目录是否为最新
.\tools\New-CatalogDoc.ps1 -Check

# 数据完整性与行为验证
.\tests\Test-Catalog.ps1
.\tests\Test-Engine.ps1

# TUI：逻辑与布局都是纯函数，所以同样受测。
# （按键循环需要真实控制台，由人工验证 —— 见 Tui.Input.ps1。）
.\tests\Test-Tui.ps1
.\tests\Test-TuiRender.ps1
```

八道门禁在 CI 中都会跑。当前状态：解析器 37 项、PSScriptAnalyzer
`0 Error / 0 Warning`、文档 5 项（229 条链接）、Catalog 31 项、Engine 23 项、
TUI 逻辑 55 项、TUI 布局 50 项。详见 [LINTING.md](docs/LINTING.md)。

---

## 许可证

[MIT](LICENSE)。随便用、随便 fork、随便发布。不提供任何担保 —— 它会修改系统设置，请看清你选了什么。

---

## 文档规范

本项目文档中英双语，**每份文档顶部都有语言导航，且两个版本互相指向**。新增文档时必须同时提供
`X.md` 与 `X.zh-CN.md`，否则 `tests/Test-Docs.ps1` 会让 CI 失败。完整对照表与规则见
[CONTRIBUTING.zh-CN.md](CONTRIBUTING.zh-CN.md#中英双语文档规范必须遵守)。

仓库中**不允许出现内网地址**（私有 IP、内网主机名、内网服务端口），代码、文档、提交信息与
remote 配置都算 —— 这条同样由 `Test-Docs.ps1` 自动检查。
