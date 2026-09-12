# WinCleanKit

**把决定权交还给用户的 Windows 11 减负工具。** 关掉微软的广告与遥测、清掉你从没要过的预装应用 —— 而每一处改动都由你本人拍板。

```
  ====================================================================
    WinCleanKit   Windows 11 广告 / 遥测 / 预装清理
  ====================================================================
     当前计划: 共 45 项, 最高风险 [低]   (手动加 0 / 手动减 0)

     1. 选择预设            (conservative / balanced / aggressive)
     2. 按分类选择          (勾选整个分类)
     3. 逐项自定义          (每个动作单独开关)
     4. 预览当前计划        (不修改任何东西)
     5. 执行                (会再次确认，先备份)
     6. 还原                (从桌面还原点恢复)
     7. 切换语言            (当前 zh)
     8. 关于
     0. 退出
```

[English](README.md) · [行动目录](docs/CATALOG.md) · [安全说明](docs/SAFETY.md) · [已知限制](docs/LIMITATIONS.md) · [参与贡献](CONTRIBUTING.md)

---

## 为什么还要再做一个？

市面上的去广告脚本基本是一大串 `reg add`，**先执行、后告诉你**干了什么。你不知道改了什么、没法反对其中任何一条、也没有干净的回退路径。

WinCleanKit 反过来设计：

| 原则 | 落到实处的做法 |
|---|---|
| **你说了算** | 三档预设起步，再按分类、按单条调整。**你没选的，一条都不执行。** |
| **先看见再动手** | 每条操作都带大白话的「为什么」、风险等级，以及独立的预览步骤。 |
| **永远退得回去** | 每次执行都在桌面生成带时间戳的备份 + 一键还原脚本。 |
| **广告图是图，不是设置** | 会删广告图，但绝不碰你的壁纸。 |
| **你的数据不关它的事** | 不修改 `hosts`、不碰个人文件、绝不靠近你的 OneDrive 数据目录。 |

---

## 快速开始

1. 下载或克隆本仓库。
2. 双击 **`src\WinCleanKit.bat`**。
3. 同意 UAC 提权（改机器级设置需要管理员权限）。
4. 选预设 → 看计划 → 执行。

就这么多。在你于最终确认处输入 `APPLY` 之前，**什么都不会发生**。

> **环境要求**：Windows 10 1809+ / Windows 11 · Windows PowerShell 5.1 或 PowerShell 7+ · 修改 `HKLM` 需要管理员权限。
> 即使跑完本工具，Windows 11 专业版/家庭版仍会发送**必需**级诊断数据 —— 这是平台限制，不是设置能绕过的，见[已知限制](docs/LIMITATIONS.md)。

### 三档预设

| 预设 | 项数 | 内容 | 风险 |
|---|---|---|---|
| `conservative` | 45 | 广告、推荐，加上最安全的那部分遥测开关。除广告消失外无可见行为变化。 | 低/中 |
| `balanced` | 60 | 上一档全部，加上错误报告与兼容性助手服务，以及明确不需要的预装应用。 | 低/中 |
| `aggressive` | 74 | 上一档全部，加上有真实取舍的项目：游戏栏、OneDrive、定位、设置同步、新版 Outlook、手机连接。 | 最高到高 |

`conservative ⊂ balanced ⊂ aggressive` 这层包含关系由测试强制保证，因此**小预设永远不会包含大预设没有的东西**。

---

## 命令行

`.bat` 只是 `src\WinCleanKit.ps1` 的前端。引擎可以单独使用，因此脚本化与无人值守都很方便。

```powershell
# 以 JSON 输出 catalog 的全部内容
.\src\WinCleanKit.ps1 -ListCatalog

# 预览某个预设（不修改任何东西）
.\src\WinCleanKit.ps1 -Plan -Preset balanced

# 只预览两条，中文界面
.\src\WinCleanKit.ps1 -Plan -Preset conservative -Only 'ads.cdm.silent-install,apps.maps' -Language zh

# 无人值守执行整个分类
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Preset aggressive -Only telemetry

# 执行文件里手挑的清单（每行一个 id，支持 # 注释）
.\src\WinCleanKit.ps1 -Apply -NoPrompt -FromFile .\my-selection.txt

# 用预设，但剔除你不同意的几项
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Preset balanced -Skip 'apps.xbox,apps.outlook-new'

# 查看与使用还原点
.\src\WinCleanKit.ps1 -ListRestores
.\src\WinCleanKit.ps1 -Restore WinCleanKit-20260913-004942
```

`-Only` 是**权威列表**：一旦传入，选中集合就是你指定的那些，预设只作标签。这正是「逐项取消勾选」能可靠生效的原因。

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
├── src/
│   ├── WinCleanKit.bat          交互前端：提权、菜单、确认
│   ├── WinCleanKit.ps1          引擎：解析 → 预览 → 执行 → 记录
│   └── menu/menu.ps1            菜单数据提供者（让 bat 不必解析 JSON）
├── catalog/catalog.json         全部 74 条操作，以数据形式存在
├── docs/                        目录参考、用法、安全、限制、代码规范
├── tests/                       语法、规范、catalog 与引擎四道门禁
├── .github/workflows/           CI
└── localization/                UI 文案
```

### 设计说明

- **Catalog 是唯一事实来源。** UI 渲染它、引擎执行它、测试校验它。代码里不存在 catalog 之外的操作。
- **`.bat` 从不直接碰注册表。** 它只负责解析意图并委派。因此 UI 保持可读，引擎保持可测。
- **`.ps1` 文件刻意带 UTF-8 BOM。** Windows PowerShell 5.1 会把无 BOM 的脚本按 ANSI 代码页解码，中文界面会变乱码。`.gitattributes` 把它们标为 `-text`，避免任何字节被改写。
- **写入后必定读回校验。** 少数 Windows 键会「接受写入然后静默丢弃」，这类情况会被报为 `[FAIL]`，而不是假成功。

---

## 参与贡献

新增一条操作通常只是改一小段 JSON。请先读 [CONTRIBUTING.md](CONTRIBUTING.md) —— 里面说明了风险等级、预设规则，以及一句好的 `why` 该长什么样。

```powershell
# 语法门禁：PowerShell 解析器 + 文件编码规则
.\tests\Test-Parse.ps1

# 代码规范门禁：PSScriptAnalyzer（需先 Install-Module PSScriptAnalyzer -Scope CurrentUser）
.\tests\Test-Analyzer.ps1

# 数据完整性与行为验证
.\tests\Test-Catalog.ps1
.\tests\Test-Engine.ps1
```

四道门禁在 CI 中都会跑。当前状态：解析器全过、PSScriptAnalyzer
`0 Error / 0 Warning`、Catalog 31 项、Engine 23 项。详见
[LINTING.md](docs/LINTING.md)。

---

## 许可证

[MIT](LICENSE)。随便用、随便 fork、随便发布。不提供任何担保 —— 它会修改系统设置，请看清你选了什么。
