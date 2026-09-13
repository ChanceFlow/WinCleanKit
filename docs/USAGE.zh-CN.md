[中文](USAGE.zh-CN.md) · [English](USAGE.md) · **文档：** [中文说明](../README.zh-CN.md) · [用法](USAGE.zh-CN.md) · [安全](SAFETY.zh-CN.md) · [限制](LIMITATIONS.zh-CN.md) · [行动目录](CATALOG.md) · [代码规范](LINTING.md)

# 用法

`.bat` 菜单能做的，命令行都能做；而命令行能做的更多。两者是同一个引擎。

```text
src/WinCleanKit.ps1 [选项]
```

改机器级设置（`HKLM`）请用**管理员** PowerShell。只读和用户级操作不提权也能跑，但半途而废通常不是你想要的。

---

## 启动

双击 `run.bat`，或运行 `src\WinCleanKit.bat`。两者都会先提权，再打开全屏界面。

**启动时会先让你选语言。** 那个界面刻意做成双语的：它在语言确定之前就得显示，所以每行都写两遍 —— 先中文，再 English。按 `1` 选中文，`2` 选英文，或者用方向键加回车。进去之后随时可以按 `l` 改。

不想每次都选，就直接在命令行指定：

```bat
run.bat --lang zh
run.bat --lang en
run.bat --zh
run.bat --en
```

| 开关 | 作用 |
|---|---|
| `--lang zh` / `--lang en` | 直接用该语言打开，不显示选择屏。 |
| `--lang=zh` / `--lang=en` | 同上。 |
| `--zh` / `--en` | 同上，短写法。 |
| `--simple` / `--no-tui` | 用数字菜单代替全屏界面，适合自动化与读屏软件。 |

写了无法识别的值会退回选择屏，而不是替你猜一个。

---

## 模式

| 选项 | 作用 |
|---|---|
| *（不加）* | 解析并预览计划，然后停下。 |
| `-Plan` | 同上，显式写出来。 |
| `-Apply` | 执行计划。 |
| `-Apply -DryRun` | 走完整流程、报告将要做什么，但**不修改也不创建任何东西**。 |
| `-ListCatalog` | 以 JSON 输出 catalog 后退出。 |
| `-ListRestores` | 列出桌面上的还原点。 |
| `-Restore <名称>` | 运行某个还原点的脚本。 |
| `-Version` | 输出版本号。 |

**不加 `-Apply` 就永远不会执行。** 默认是 `-Plan`，所以打错字也不会造成改动。

---

## 选择要执行什么

| 选项 | 含义 |
|---|---|
| `-Only <ids 或分类>` | **权威**选择。支持分类 id、精确动作 id、`prefix.*`、逗号分隔的多个。 |
| `-Skip <ids 或分类>` | 从默认集或 `-Only` 的结果里剔除。永远优先。 |
| `-FromFile <路径>` | 每行一个动作 id。空行与 `#` 注释会被忽略。并入 `-Only`。 |

一个选项都不给时，引擎执行 catalog 里的**默认集** —— 也就是标了 `default` 的那 45 项，
都是取舍最小的：广告与推荐、最安全的遥测开关、隐私偏好。其余全部是选装，而且
**任何"卸载软件"的动作都绝不在默认集里**。

最关键的一条规则：**只要出现 `-Only`，默认集就完全不参与。** 选中集合就是你列出的那些。
这正是「逐项取消勾选」能可靠生效的原因 —— 否则默认集会把它悄悄加回来。

```powershell
# 整个分类
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Only telemetry

# 广告规则的一个子集
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Only 'ads'

# 精确 id，混用通配符
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Only 'ads.cdm.silent-install,apps.maps,privacy.*'

# 用默认集，但剔除你不同意的几项
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Skip 'ads.taskbar.widgets-button,telemetry.ceip'

# 从文件读取手挑清单
.\src\WinCleanKit.ps1 -Apply -NoPrompt -FromFile .\my-selection.txt
```

---

## 其他选项

| 选项 | 含义 |
|---|---|
| `-Language en\|zh` | 引擎自身输出的显示语言。默认 `en`。catalog 内同时带两种语言。 |
| `-TuiLanguage en\|zh\|ask` | 全屏界面启动时使用的语言。`ask`（默认）会先显示选择屏。 |
| `-NoPrompt` | 不再询问。无人值守必须加；不加则会被要求输入 `APPLY` 确认。 |
| `-EmitJson` | 在 stdout 输出机器可读的结果对象。 |

`-EmitJson` 的结构：

```json
{ "ok": 44, "skipped": 1, "failed": 0, "journal": "C:\\Users\\you\\Desktop\\WinCleanKit-20260913-004942", "failures": [] }
```

---

## 示例

```powershell
# 先看清楚
.\src\WinCleanKit.ps1 -Plan -Language zh

# 新机器上无人值守：默认集，不询问
.\src\WinCleanKit.ps1 -Apply -NoPrompt

# CI / 批量运维：失败就报错，并保留备份路径
$r = .\src\WinCleanKit.ps1 -Apply -NoPrompt -Skip 'telemetry.ceip' -EmitJson | ConvertFrom-Json
if ($r.failed -gt 0) { throw "清理出现 $($r.failed) 个失败: $($r.failures -join '; ')" }
Write-Host "备份: $($r.journal)"

# 撤销上一次运行
$last = Get-ChildItem "$env:USERPROFILE\Desktop\WinCleanKit-*" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
.\src\WinCleanKit.ps1 -Restore $last.Name
```

---

## 退出码

| 码 | 含义 |
|---|---|
| `0` | 已完成。个别动作可能被**跳过**（不适用或受保护）—— 请看 `skipped` / `failures`。 |
| `1` | 引擎中止（catalog 损坏、选择文件不可读、意外错误）。 |

单个动作出现 `[FAIL]` 不会中止整轮运行；它会被记为受保护/已跳过并出现在 `failures` 里。

---

## 怎么看输出

```
[low ] Disable DiagTrack service                      <- 风险等级
  [ OK ] DiagTrack service — Disabled -> Disabled      <- 已生效
  [skip ] Media Player — not installed                 <- 无需处理
 [WARN] Settings home — key accepted the write but dropped it   <- 受保护键
 [FAIL] Something — access denied                      <- 真正的失败
```

在某些 Windows 版本上，受保护键出现 `[WARN]`/`[FAIL]` 是正常的。Windows 会把少数键和计划任务保护起来，即使管理员也无法修改；引擎会**如实报告**，而不是假装成功。

---

## 添加你自己的动作

一切都是数据。要新增一个动作，编辑 [`catalog/catalog.json`](../catalog/catalog.json)，然后运行 `tests/Test-Catalog.ps1`。schema 与默认集规则见 [CONTRIBUTING.md](../CONTRIBUTING.md)。
