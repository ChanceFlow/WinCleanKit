[中文](CONTRIBUTING.zh-CN.md) · [English](CONTRIBUTING.md) · **文档：** [中文说明](README.zh-CN.md) · [用法](docs/USAGE.zh-CN.md) · [安全](docs/SAFETY.zh-CN.md) · [限制](docs/LIMITATIONS.zh-CN.md) · [行动目录](docs/CATALOG.md) · [代码规范](docs/LINTING.md)

# 参与 WinCleanKit 贡献

感谢帮忙。绝大多数贡献只是改一小段 JSON，所以这份说明很短。

## 唯一的一条铁律

**Catalog 是唯一事实来源。** 如果一个行为没有由 [`catalog/catalog.json`](catalog/catalog.json) 里的某个动作描述，它就不属于这个项目。不要在引擎或 `.bat` 里加特例 —— 加数据。

## 准备环境

没有需要构建的东西。

```powershell
git clone https://github.com/ChanceFlow/WinCleanKit.git
cd WinCleanKit
.\tests\Test-Parse.ps1      # 语法：解析器 + 文件编码规则
.\tests\Test-Analyzer.ps1   # 规范：PSScriptAnalyzer
.\tests\Test-Catalog.ps1    # 静态：catalog、安全不变量、编码
.\tests\Test-Engine.ps1     # 行为：预览与选择语义
```

`Test-Analyzer.ps1` 需要先装 `Install-Module PSScriptAnalyzer -Scope CurrentUser`。四套都只读，都不需要管理员权限。非 Windows 机器上可以跑静态那部分。

## 新增一个动作

在 `catalog/catalog.json` 的 `actions` 里追加一个对象。

### 每个动作都必须有

| 字段 | 说明 |
|---|---|
| `id` | `category.something-specific`。**永久稳定** —— 用户会用它写 `-Only`，还原日志也引用它。不要重命名已有 id；新增一个。 |
| `category` | 必须匹配某个 `categories[].id`。 |
| `target` | `registry` · `service` · `task` · `appx` · `path-clean` · `onedrive` |
| `title` / `title_zh` | 祈使句且具体。写「禁用 X」，不要写「优化 X」。 |
| `why` / `why_zh` | **一句话说清它做什么、代价是什么。** 这是用户决策的唯一依据。`why` 写得含糊，等于这条动作是坏的。 |
| `default` | 只有「取舍最小的、启动时默认勾选」的动作才是 `true`。任何会卸载软件、或带明显取舍的动作都必须是 `false`。 |

### 按 target 的专属字段

```jsonc
// registry
{ "hive": "HKCU|HKLM", "key": "Software\\...", "name": "ValueName", "type": "DWord|String", "value": 0 }

// service
{ "name": "DiagTrack", "startType": "Disabled|Manual|Automatic" }

// task
{ "path": "\\Microsoft\\Windows\\SomeFolder\\", "name": "TaskName" }

// appx
{ "name": "Microsoft.Something" }

// path-clean
{ "paths": ["%LOCALAPPDATA%\\Some\\Cache"] }
```

### 硬性要求

测试套件会拒绝违反以下任何一条的 PR：

1. `id` 唯一。
2. 每个 `category` 引用都能解析。
3. 每个动作都有两种语言，并有 `default` 标记。
4. 没有任何卸载软件的动作是 `default: true`。
5. 没有动作针对 `hosts` 文件。
6. 没有动作禁用更新或核心诊断服务（`wuauserv`、`UsoSvc`、`BITS`、`DoSvc`、`DPS`）。
7. 没有动作删除 `TranscodedWallpaper` 或壁纸缓存。

第 6、7 条的存在理由：搞坏 Windows Update 或用户的壁纸不叫减负，那叫 bug。如果你认为该有例外，请在 PR 里论证，我们可以讨论**不变量本身**是否要改。

## 修改引擎

引擎只有一件事要做：执行 catalog，并记录它做了什么。值得保持的不变量：

- **预览是默认行为。** 不加 `-Apply` 不发生任何改动。
- **`-Only` 是权威列表。** 一旦出现，默认集就完全不参与。把它改成并集会破坏界面上的逐项取消勾选。
- **dry run 不动磁盘上的任何东西** —— 不建日志目录，不建备份目录。
- **每次写入都要读回校验。** 有些 Windows 键会「接受写入然后静默丢弃」，这必须被报告，而不是假定成功。
- **绝不强行夺取受保护键的所有权。** 报告拒绝即可。

如果新增了一种 target 类型，请同时补上：`tests/Test-Catalog.ps1` 里的校验分支、引擎里的执行器、生成的还原脚本里的还原分支，以及 `docs/USAGE.md` 里的一行说明。

## 修改 `.bat`

两条编码规则都由测试套件强制，因为弄错会**静默损坏**：

- **`.bat` 必须是 UTF-8 *不带* BOM，且使用 CRLF。** BOM 会在 `@echo off` 之前被打印成乱码；LF 换行会让 `cmd` 出问题。
- **`.ps1` 必须是 UTF-8 *带* BOM。** Windows PowerShell 5.1 会把无 BOM 的脚本按 ANSI 代码页解码，中文会变乱码。

`.gitattributes` 负责保持这些字节稳定。不要让编辑器「顺手修好」它们。

## 文档

`docs/CATALOG.md` 是**生成文件**。不要手工编辑；新增动作后重新生成：

```powershell
pwsh -File tools/New-CatalogDoc.ps1
```

CI 会校验它是最新的（`tools/New-CatalogDoc.ps1 -Check`）。

**中英双语文档规范（必须遵守）：**

- 每份文档顶部都要有一行语言导航，中英两版**互相指向**（单向链接会被 CI 拒绝）。
- 新增英文文档 `X.md` 时，必须同时提供 `X.zh-CN.md`，并在两边都加上导航行。
- 导航行要引用**真实文件名**，不能只在同文件内自我引用。

当前的语言对应关系：

| 英文 | 中文 | 说明 |
|---|---|---|
| [`README.md`](README.md) | [`README.zh-CN.md`](README.zh-CN.md) | 项目总览 |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | [`CONTRIBUTING.zh-CN.md`](CONTRIBUTING.zh-CN.md) | 本页 |
| [`SECURITY.md`](SECURITY.md) | [`SECURITY.zh-CN.md`](SECURITY.zh-CN.md) | 安全政策 |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | [`CODE_OF_CONDUCT.zh-CN.md`](CODE_OF_CONDUCT.zh-CN.md) | 行为准则 |
| [`docs/USAGE.md`](docs/USAGE.md) | [`docs/USAGE.zh-CN.md`](docs/USAGE.zh-CN.md) | 命令行用法 |
| [`docs/SAFETY.md`](docs/SAFETY.md) | [`docs/SAFETY.zh-CN.md`](docs/SAFETY.zh-CN.md) | 安全边界 |
| [`docs/LIMITATIONS.md`](docs/LIMITATIONS.md) | [`docs/LIMITATIONS.zh-CN.md`](docs/LIMITATIONS.zh-CN.md) | 已知限制 |
| [`docs/CATALOG.md`](docs/CATALOG.md) | [`docs/CATALOG.zh-CN.md`](docs/CATALOG.zh-CN.md) | 行动目录（正文双语，中文页为指针） |

有意只保留英文的文档（属于**决策**而非遗漏）：

| 文件 | 原因 |
|---|---|
| [`CHANGELOG.md`](CHANGELOG.md) | 更新日志是技术流水，分语言副本会各自漂移并误导。 |
| [`docs/LINTING.md`](docs/LINTING.md) | 面向贡献者的代码规范说明，按决策仅提供英文。 |
| [`localization/README.md`](localization/README.md) | 这一页本身就讲多语言，只以英文存在。 |

`tests/Test-Docs.ps1` 会检查：链接是否可达、双语对是否齐备且双向、导航行是否在开头、
以及仓库内**是否出现内网地址**。任一不满足都会让 CI 失败。

## 各部分的职责

- **Catalog 是唯一事实来源。** `catalog/catalog.json` 是操作被定义的唯一地方：UI 渲染它、引擎执行它、
  测试校验它、`tools/New-CatalogDoc.ps1` 由它生成文档。代码里不存在 catalog 之外的操作。
- **`.bat` 从不直接碰注册表。** 它只解析意图并委派。因此前端保持可读，引擎可以独立测试。
- **`.ps1` 文件刻意带 UTF-8 BOM。** Windows PowerShell 5.1 会把无 BOM 的脚本按机器 ANSI 代码页解码，
  中文会变乱码；`.gitattributes` 把它们标为 `-text`，避免字节被改写。`Test-Parse.ps1` 会强制检查
  BOM（并且拒绝重复的 BOM）。
- **写入之后必定读回校验。** 少数 Windows 键会「接受写入然后静默丢弃」，所以引擎会读回该值，
  报 `[!!]` 而不是假称成功。
- **发布包按封闭清单生成。** `tools/New-ReleasePackage.ps1` 只要发现某个文件两份清单都没匹配上就直接失败，
  因此新增文件既不会悄悄发给用户，也不会悄悄漏发。

## 两个交互前端

`src/lib/Ui.Logic.ps1` 是状态机：导航、勾选、计划组装、本地化，以及窗口需要的投影。它不碰任何
屏幕 API，两个前端都只是它外面的薄胶水 —— `src/lib/Tui.Render.ps1` + `Tui.Input.ps1` 把它画成字符，
`src/gui/WinCleanKit.gui.ps1` 把它画成控件。增加一个按键或一个按钮，都是去调同一个 `Switch-*` /
`Move-*` 函数，绝不在 UI 层重新做一遍决定。

窗口是以**子进程**方式调用引擎的：传入权威的 `-FromFile` id 清单，跑在后台 runspace 里，
再由一个 UI 定时器把输出抽到进度条上。这与控制台界面做预览时的调用方式完全一致，区别只在进程边界，
而正是它让窗口在 74 条操作面前不卡。

**颜色只有一处定义。** `$script:GuiPalette` 里是浅色与深色两套语义角色（`window`、`card`、
`text`、`muted`、`border`、`controlBorder`、`brand`、`accent`、`success`、`caution`、`danger`、
`selection`），布局代码只问角色、不写颜色。这套词汇与控制台前端的 `$script:Ink` 完全一致 ——
这正是两个界面看起来像同一个产品的原因。在这张表之外写十六进制颜色会让门禁失败；文本对比度低于
4.5:1 也会失败（门禁会真的去算），所以“小改一下颜色”不可能悄悄把字变得看不清。

**窗口是五页，而且执行按钮不在你勾选的那一页上。** `WinCleanKit.gui.ps1` 用一条导航栏盖住五个页面面板
（概览、选择、执行、还原、关于），切换靠 `Show-GuiPage`，每个导航条目标题下都带着该步骤的实时状态。
门禁会盯住这个形状：`runIt` 不允许是“选择页”的子控件。勾选和执行是两个步骤，把它们塞回同一页会让
`Test-Gui.ps1` 失败。

动那个文件之前值得知道的四个坑：

- **事件处理器有自己的作用域。** 共享状态放在 `$script:GuiApp`；在事件处理器里对局部变量赋值，
  下一次点击就没了。它的名字刻意避开 `WinCleanKit.ps1` 的每一个参数：这个文件被点源进那个脚本的
  作用域，而给引擎声明为 `[switch]` 的变量赋别的类型会在运行时抛错 —— `Test-Gui.ps1` 会检查这一点。
- **事件参数在 `$args` 里，不在 `$_` 里。** 对 `Add_*` 处理器来说 `$_` 不是事件对象，
  读 `$_.KeyCode` 会在用户真正按键的那一刻失败。
- **PowerShell 自己的只读变量也会撞。** `$home` 是用户目录、不是放面板的地方，赋值会在构建窗口时抛
  `VariableNotWritable`。`Test-Gui.ps1` 会把每个赋值和保留名列表比对（就在引擎参数检查旁边）——
  `$home` 就是这样在用户之前被抓住的。
- **画成按钮的 CheckBox 会低估自己文字的宽度。** `Appearance = 'Button'` 配 `AutoSize` 在真机上把
  `Privacy  7/10` 画成了 `Privacy 7/`；而按钮文字里的 `&` 是助记符，于是目录里的 `Ads & suggestions`
  变成了 `Ads suggestions`。`Format-GuiChip` 改用带 `NoPrefix` 的 `TextRenderer.MeasureText` 自己算宽度，
  门禁也在真实控件上把这两条都测了。

`tests/Test-Gui.ps1` 覆盖投影、两个前端之间的一致性、窗口构建（没有桌面也能构建）以及勾选路径。
它覆盖不到的是窗口长什么样、真实鼠标点击是否正常 —— 那需要在真实会话里人工验证，和控制台的按键循环一样。

## 终端设计系统

控制台输出不是随手写的 `Write-Host`。`src/WinCleanKit.ps1` 统一持有一套配色与一套状态词表，
`src/WinCleanKit.bat` 复用同一组颜色角色，因此前端与引擎看起来是同一个产品。

- **语义色角色，而非硬编码颜色。** `brand`、`accent`、`success`、`caution`、`danger`、`muted`。
  换配色只需改 `$script:Ink` 里的一行。
- **宽度感知对齐。** 中文字形占两个终端列却只算一个字符，PowerShell 自带的 `{0,-20}` 会让中英混排的
  表格参差不齐。`Format-Text` 按显示宽度补齐 —— 这就是为什么两种语言下的计数能对齐到同一列。
- **颜色从来不是唯一信号。** 每种状态都有文字标记（`[ok]`、`[dry]`、`[--]`、`[!!]`、`[XX]`），
  并且当输出被重定向、进入管道或设置了 `NO_COLOR` 时，颜色会降级为纯文本 —— 日志与 CI 采集始终干净。
- **长任务有进度。** 运行过程会打印 `[ 12/45]  26%`，绝不会看起来卡死。
- **不闪屏。** 前端改用光标归位、在原帧上重绘，而不是每屏都 `CLS`；同时保留最近若干行作为回看。
- **全屏界面按 Terminal.Gui 的 NetDriver 方式绘制** —— 逐行绝对定位、不写换行、把屏幕缓冲区钉死到窗口大小 ——
  因为「满宽的一行 + 一个换行」会让窗口每次重绘都滚动。`tools/Test-TuiScroll.ps1` 会在真实窗口里把
  控制台缓冲区读回来比对；为什么这一项只能人工跑，见 [docs/LIMITATIONS.zh-CN.md](docs/LIMITATIONS.zh-CN.md)。

## 提交与 PR

- 一个 PR 只做一件逻辑上的事。
- commit 标题用祈使句，例如 `Add action to disable location services`。
- 说明你在哪个 Windows 版本上验证过，以及观察到的结果。
- 如果你的改动改变了 `default` 默认集，请**明确指出**。这会改变那些从不打开 catalog 的用户实际执行到的东西。
- **提交信息与代码里不要出现内网地址、内网主机名或私有服务地址。** 如果需要引用远端仓库，用公开地址。

## 报告 bug

请附上：Windows 版本与 build（`winver`）、确切的命令或菜单路径、动作 id，以及 `run.log` 的相关行。如果某个动作静默无效，请附上对应的注册表键或服务名，便于直接复核。

安全敏感问题请按 [SECURITY.md](SECURITY.md) 处理。

## 行为准则

参与即受 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) 约束。请彼此尊重。
