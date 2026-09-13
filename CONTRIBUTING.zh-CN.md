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
