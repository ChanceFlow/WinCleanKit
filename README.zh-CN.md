# WinCleanKit

**把决定权交还给用户的 Windows 11 减负工具。** 关掉微软的广告与遥测、清掉你从没要过的预装应用 —— 而每一处改动都由你本人拍板。

[![License: MIT](https://img.shields.io/badge/License-MIT-3DA639.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D4.svg)](#环境要求)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE.svg)](#环境要求)
[![Actions](https://img.shields.io/badge/catalog-74%20actions-4B5563.svg)](docs/CATALOG.md)
[![Gates](https://img.shields.io/badge/gates-8%20passing-22C55E.svg)](#仓库结构)

[English](README.md) · **中文说明**  
**文档:** [用法](docs/USAGE.zh-CN.md) ([EN](docs/USAGE.md)) · [安全](docs/SAFETY.zh-CN.md) ([EN](docs/SAFETY.md)) · [限制](docs/LIMITATIONS.zh-CN.md) ([EN](docs/LIMITATIONS.md)) · [行动目录](docs/CATALOG.md) ([中文](docs/CATALOG.zh-CN.md)) · [代码规范](docs/LINTING.md)  
**项目:** [参与贡献](CONTRIBUTING.zh-CN.md) ([EN](CONTRIBUTING.md)) · [安全政策](SECURITY.zh-CN.md) ([EN](SECURITY.md)) · [行为准则](CODE_OF_CONDUCT.zh-CN.md) ([EN](CODE_OF_CONDUCT.md)) · [更新日志](CHANGELOG.md) · [许可证](LICENSE)

---

## 界面长什么样

全屏 TUI，纯键盘操作。方向键移动，`Tab` 切换面板，`空格` 勾选 —— 左下角的双模态详情面板在你动手之前就回答「为什么有这一项」与「这到底会改什么」：

```text
+--------------------------------------------------------------------------------------------+
| WinCleanKit v0.1.0   计划: 45 项                                                           |
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
|                                       | [x] 移除开始菜单“推荐”区推广                       |
+ 详情 · 条目 --------------------------+ [x] 关闭最近使用文件建议                           |
|禁止静默自动安装应用                   | [x] 隐藏任务栏小组件按钮                           |
|阻止云内容提供程序（ContentDeliveryMana| [x] 隐藏任务栏聊天(Teams)按钮                      |
|ger）在后台静默下载推广软件。Windows 经| [x] 隐藏桌面“了解此图片”图标                       |
|常不经提示就在开始菜单里偷偷塞进社交或…| [x] 关闭搜索框联网推荐                             |
|触及: HKCU\Software\Microsoft\Windows\C| [ ] 隐藏设置首页推广区块                           |
|urrentVersion\ContentDeliveryManager\S…| [x] 关闭 Edge 推广标签页与推荐                     |
|                                       | [x] 关闭“将 Edge 设为默认”弹窗                     |
+---------------------------------------+----------------------------------------------------+
| 上下移动  Tab面板  Enter勾选  ?帮助  x执行  q退出                                          |
| 空格勾选，p 预览，x 执行；未确认前不会改动任何东西                                         |
+--------------------------------------------------------------------------------------------+
```

| 按键 | 作用 |
|---|---|
| `↑` / `↓` | 在当前焦点面板内移动光标 |
| `Tab` | 在左侧分类面板与右侧条目面板之间切换焦点 |
| `Enter` | 进入分类；在条目面板中勾选并自动下移一行 |
| `空格` | 勾选 / 取消当前条目 |
| `a` / `n` | 选中 / 清空当前分类下的全部动作 |
| `A` / `N` | 选中 / 清空全表 74 项操作 |
| `l` | 即时切换界面语言（中文 ⇄ English） |
| `p` | 完整预览执行计划（只读，不修改任何系统设置） |
| `x` | 确认执行选中的计划（执行前先在桌面建好还原点） |
| `q` / `Esc` | 安全退出（未确认前不会改变系统任何东西） |
| `?` | 呼出应用内键位说明与帮助 |

TUI **不重复实现**任何保护你的逻辑：预览调用引擎自己的计划渲染，执行时把选中的 id
交回引擎：

```text
   ------------------------------------------------------------------
   WinCleanKit 0.1.0
   ------------------------------------------------------------------
   Selected : 45 action(s)
   Mode     : PREVIEW ONLY

   系统广告与推荐                20 action(s)
     禁止静默自动安装应用
     关闭订阅内容(推荐/广告)
     关闭桌面 Spotlight 广告图
     ...

   遥测与诊断数据                17 action(s)
     设置诊断数据为最低允许级别
     将旧位 AllowTelemetry 设为 0
     ...

   隐私加固                      7 action(s)
     关闭用于定向广告的广告 ID
     ...

   广告图缓存与壁纸              1 action(s)
     删除已下载的 Spotlight 广告图缓存

   Total actions : 45
```

执行时带实时进度计数，且只有**一套**状态词表；含义由文字标记承载，**不依赖颜色**：

```text
   [ok]  [  1/45]   2%  禁止静默自动安装应用 — HKCU\SilentInstalledAppsEnabled = 0
   [--]  [  5/45]  11%  禁用 DiagTrack 服务 — not installed
   [!!]  [ 12/45]  26%  隐藏设置首页推广区块 — key accepted the write but dropped it
   [XX]  [ 40/45]  88%  某动作 — access denied
```

图例：`[ok]` 已生效 · `[dry]` 将生效 · `[--]` 不适用 · `[!!]` 已跳过或受保护 · `[XX]` 失败。

> **终端不支持全屏界面？** 用 `run.bat --simple`（或 `WinCleanKit.ps1 -Tui:$false`）
> 走轻量编号菜单。TUI 遇到非交互或无 ANSI 支持的环境也会自动降级，而不会把控制台转义码乱打进日志。

---

## 为什么还要再做一个？

市面上的去广告脚本基本是一大串 `reg add`，**先执行、后告诉你**干了什么。你不知道改了什么、没法反对其中任何一条、也没有干净的回退路径。

WinCleanKit 反过来设计：

| 原则 | 落到实处的做法 |
|---|---|
| **你说了算** | 安全的基础项（45 项）默认勾好，其余一个空格就能选上。**你没选的，一条都不执行。** |
| **先看见再动手** | 每条操作都带大白话的说明 —— 它改什么、为什么改、代价是什么。 |
| **永远退得回去** | 动任何设置前，先在桌面生成带时间戳的备份文件夹与一键还原脚本。 |
| **广告图是图，不是设置** | 清理下载的锁屏广告图缓存，但绝不碰你当前的壁纸，更不会替你换壁纸。 |
| **你的数据不关它的事** | 不修改 `hosts`、不碰个人文件、绝不靠近你的 OneDrive 数据目录。 |
| **没有隐藏档位或隐式重置** | 取消勾选就一直生效；不存在所谓激进档位会在切换时把你已做的选择推翻。 |

---

## 快速开始

```text
1.  下载或克隆本仓库
2.  双击运行 run.bat                  （终端下亦可直接执行）
3.  按需选择界面语言                  （首次启动提供双语选择：1 中文，2 English；可用 --zh / --en 跳过）
4.  查看计划、按需调整勾选            （空格键切换，Enter 逐项下移）
5.  按 x 键执行计划                   （改动前自动在桌面创建完整还原点）
```

在你于最终确认处输入 `APPLY` 之前**什么都不会发生**；而一轮运行做的第一件事，
就是在桌面写下回滚点。

<a id="环境要求"></a>
> **环境要求**：Windows 10 1809+ / Windows 11 · Windows PowerShell 5.1 或 PowerShell 7+ · 修改机器级设置（`HKLM`）需要管理员权限。
> 即使跑完本工具，Windows 11 专业版/家庭版仍会发送**必需**级诊断数据 —— 这是平台限制，不是设置能绕过的，详见[已知限制](docs/LIMITATIONS.zh-CN.md)。

喜欢用命令行？`src\WinCleanKit.ps1` 就是完整引擎，所有决定都可以通过参数传入 —— 详见[命令行](#命令行)。

### 默认勾选了什么

**没有起步前要先选的档位。** catalog 里标了 `default` 的 **74 项中的 45 项**就是默认集 ——
取舍最小的那些，最坏情况也只是少了个商业推广位或后台采集器 —— 界面打开时正好勾选这些。
其余全部是选装：

| | 项数 | 覆盖内容 |
|---|---|---|
| **默认勾选** | 45 | 系统广告与推荐（20 项）、最安全的遥测开关（17 项）、隐私偏好（7 项）、广告图缓存（1 项）。除广告消失外无任何可见副作用。 |
| **需要自己选** | 29 | 预装应用卸载（19 项）、OneDrive 客户端移除（1 项）、诊断错误报告（4 项），以及有真实取舍的项目（3 项）：定位、设置同步、手写/键入个性化。 |

**加回去这件事不存在。** 关掉一项就是关掉，打开一项也只是一个空格 —— 没有哪一档会在你切换时
把已做的选择推翻。这条分界由 `tests/Test-Catalog.ps1` 强制保证，其中还包括**「卸载软件类的动作
一律不在默认集内」**。

---

## 命令行

`run.bat` 只是 `src\WinCleanKit.ps1` 的提权与启动包装。PowerShell 引擎完全可以独立运行，
便于自动化部署、CI 与无人值守执行。

```powershell
# 以 JSON 输出 catalog 的全部内容
.\src\WinCleanKit.ps1 -ListCatalog

# 预览默认集（不修改任何东西）
.\src\WinCleanKit.ps1 -Plan

# 只预览指定两项，中文界面输出
.\src\WinCleanKit.ps1 -Plan -Only 'ads.cdm.silent-install,apps.maps' -Language zh

# 无人值守执行整个分类
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Only telemetry

# 执行文件里手挑的清单（每行一个 id，支持 # 注释）
.\src\WinCleanKit.ps1 -Apply -NoPrompt -FromFile .\my-selection.txt

# 用默认集，但剔除你不同意的几项
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Skip 'apps.xbox,apps.outlook-new'

# 查看与使用桌面备份还原点
.\src\WinCleanKit.ps1 -ListRestores
.\src\WinCleanKit.ps1 -Restore WinCleanKit-20260913-004942
```

`-Only` 是**权威列表**：一旦传入，默认集完全不参与，选中集合就是你指定的那些。这保证了程序化
调用的绝对可预期性。

完整参数说明见[用法文档](docs/USAGE.zh-CN.md)。

---

## 它能改什么

6 个分类、74 条操作。**每一条都是数据**，写在 [`catalog/catalog.json`](catalog/catalog.json) 里，
而不是埋在过程式脚本里。增删一条操作、改一句说明，都只是改 JSON，UI、引擎与文档会自动跟上。

| 分类 | 总数 | 默认 | 例子 |
|---|---|---|---|
| 系统广告与推荐 | 22 | 20 | 静默装应用、锁屏 Spotlight 广告、开始菜单推荐、小组件资讯流、搜索框联网推荐、Edge 推广标签 |
| 遥测与诊断数据 | 21 | 17 | `DiagTrack`、兼容性评估、CEIP 上报、错误报告、反馈请求 |
| 预装应用 | 19 | 0 | Clipchamp、Dev Home、纸牌、Office Hub、Bing 资讯/天气、Xbox 覆盖层 |
| OneDrive | 1 | 0 | 移除客户端并阻止重装 |
| 隐私加固 | 10 | 7 | 广告 ID、输入个性化、文本/手写隐式采集、定位、设置同步 |
| 广告图缓存与壁纸 | 1 | 1 | 删除已下载的 Spotlight 广告图缓存 |
| **合计** | **74** | **45** | |

每条操作都写明了它改什么、触及哪些注册表/服务、代价是什么以及可逆性。完整清单见[行动目录](docs/CATALOG.zh-CN.md)（双语详情直达 [CATALOG.md](docs/CATALOG.md)）。

### 明确不做的事

以下是设计上**有意不做**的：

- **不修改 `hosts` 文件。** 用 DNS 方式屏蔽微软域名可能破坏 Windows Update、Microsoft Store，在办公机器上还会打断 VPN 与 SSO 登录。
- **不碰个人文件、壁纸、OneDrive 数据目录。**
- **不关闭 Windows Update。** 安全补丁是关键系统基础设施，不是牛皮癣。
- **不整体关闭传递优化服务。** 它是本地与网络更新加速器；其 P2P 上传共享可单独关闭，无需强杀服务。
- **不搞坏 Microsoft Edge。** 只关它的推广标签页与弹窗推荐；不强拆底层 WebView2 依赖的浏览器引擎。

---

## 安全与回滚

动手之前，WinCleanKit 会在桌面自动创建完整的独立还原包：

```text
桌面\WinCleanKit-<时间戳>\
├── backup.json                 全部原始值，逐字节记录
├── Restore-WinCleanKit.ps1     整轮操作的一键还原脚本
└── run.log                     每条操作一行，含生效、跳过与失败记录
```

如需还原之前的改动：

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\WinCleanKit-<时间戳>\Restore-WinCleanKit.ps1"
```

注册表值会被精确还原，服务回到原启动类型，计划任务重新启用。被卸载的 Store 应用不会在后台自动重新下载（还原脚本会列出具体包名，方便你按需在应用商店重新安装）。在**工作机器**上运行前请先读[安全说明](docs/SAFETY.zh-CN.md)。

---

## 仓库结构

```text
WinCleanKit/
├── run.bat                      双击入口（大多数人只需要这个）
├── src/
│   ├── WinCleanKit.bat          交互前端：提权、菜单、确认
│   ├── WinCleanKit.ps1          引擎 + 终端设计系统
│   ├── menu/menu.ps1            菜单数据提供者（让 bat 不必解析 JSON）
│   └── lib/                     TUI 核心实现（纯逻辑、渲染器、输入循环）
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
- **长任务有进度。** 运行过程会打印 `[ 12/45]  26%`，绝不会看起来卡死。
- **不闪屏。** 前端改用光标归位、在原帧上重绘，而不是每屏都 `CLS`；同时保留最近 25 行作为回看。

---

## 参与贡献

新增一条操作通常只是改一小段 JSON。请先读[贡献指南](CONTRIBUTING.zh-CN.md) —— 里面说明了默认集规则，以及一句好的 `why` 说明该长什么样。

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

八道门禁在 CI 中都会跑。当前状态：
- **Test-Parse.ps1**: 59 项通过（PowerShell 语法解析、UTF-8 BOM 约束、单 BOM 校验、批处理启动器规范）
- **Test-Analyzer.ps1**: CLEAN（PSScriptAnalyzer 1.25.0 下 `0 Error / 0 Warning`）
- **Test-Docs.ps1**: 5 项全过（231 条相对链接可达、双语文档互链完备、0 处私有内网地址）
- **New-CatalogDoc.ps1 -Check**: 生成的 `docs/CATALOG.md` 为最新状态
- **Test-Catalog.ps1**: 32 项（模式合法性、安全约束、默认勾选集不变式）
- **Test-Engine.ps1**: 25 项（选择语义、dry-run 纯度、双语输出一致性）
- **Test-Tui.ps1**: 83 项（TUI 导航、选择集、重绘特征戳、语言选择器、滚动视口算法）
- **Test-TuiRender.ps1**: 98 项（防滚动绘制契约、边框几何结构、双模态详情面板、ANSI 控制）

详见[代码规范与门禁说明](docs/LINTING.md)。

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
