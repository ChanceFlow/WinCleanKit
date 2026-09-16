<!--
  下载包的第一页。写作时假设它位于仓库根目录：打包脚本把它复制成包内的
  README.zh-CN.md，并去掉链接前面多余的 "../"，因此同一份文本在两棵目录树里都成立。
  它刻意不是项目主页 —— 没有徽章、没有 CI 状态、没有贡献指南，也不会链到包里没有的文件。
-->

# WinCleanKit

把决定权还给用户的 Windows 11 减负工具。关掉微软的广告与遥测，清掉你从没要过的预装应用 ——
而且**你没勾选的，一条都不改**。

[English](README.md) · **中文说明**

## 怎么跑

1. 把这个文件夹放在任意位置，桌面即可。
2. 双击 **`run.bat`**，会打开一个窗口。
3. 同意 UAC 提权 —— 改机器级设置需要管理员权限。
4. 选择界面语言，看清单、按需勾选，按 **「执行」**。

环境要求：Windows 10 1809+ 或 Windows 11，Windows PowerShell 5.1 或 PowerShell 7+。

在你确认计划之前**什么都不会发生**；而一轮运行做的第一件事，就是在桌面写下还原点。
想改回原样，运行那个文件夹里的 `Restore-WinCleanKit.ps1`。

## 窗口起不来怎么办

| 情况 | 用什么 |
|---|---|
| 这台机器没有桌面（远程会话、计划任务） | `run.bat --tui` —— 全屏控制台界面 |
| 老旧终端、屏幕阅读器，或你就是想看纯文本 | `run.bat --simple` |
| 想跳过语言选择 | `run.bat --zh` 或 `run.bat --en` |
| 想把整个计划走一遍但什么都不改 | `run.bat --gui --dry-run` |
| 要自动化执行 | `src\WinCleanKit.ps1 -Apply -NoPrompt -Only telemetry` |

## 这个文件夹里有什么

| 路径 | 是什么 |
|---|---|
| `run.bat` | 启动器，双击这个。 |
| `src/` | 工具本体：批处理前端 + PowerShell 引擎。 |
| `catalog/catalog.json` | 全部 74 条操作，以数据形式存在。改一句说明，界面自动跟上。 |
| `docs/` | 用法、安全、已知限制，以及完整行动目录。 |
| `LICENSE` | MIT 许可证。 |

这是**给用户的下载包，不是仓库**。测试套件、文档生成器和 CI 配置都不在这里 ——
那些是给改这个工具的人用的，不是给用这个工具的人用的。

## 动手之前建议先看

| 文档 | 为什么 |
|---|---|
| [docs/USAGE.zh-CN.md](../docs/USAGE.zh-CN.md) | 所有参数，以及两个界面各自的行为。 |
| [docs/SAFETY.zh-CN.md](../docs/SAFETY.zh-CN.md) | 备份了什么、没备份什么、办公机器上要注意什么。 |
| [docs/LIMITATIONS.zh-CN.md](../docs/LIMITATIONS.zh-CN.md) | Windows 会在哪里覆盖本工具，以及它刻意不碰什么。 |
| [docs/CATALOG.md](../docs/CATALOG.md) | 全部 74 条操作，每条都写明原因与触及范围。 |

完整项目（源码、测试、issue 追踪）在 <https://github.com/ChanceFlow/WinCleanKit>。
