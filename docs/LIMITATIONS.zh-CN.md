[中文](LIMITATIONS.zh-CN.md) · [English](LIMITATIONS.md) · **文档：** [中文说明](../README.zh-CN.md) · [用法](USAGE.zh-CN.md) · [安全](SAFETY.zh-CN.md) · [限制](LIMITATIONS.zh-CN.md) · [行动目录](CATALOG.md) · [代码规范](LINTING.md)

# 已知限制

如实说明边界。有些是任何工具都跨不过的平台限制，有些是刻意的取舍。

## Windows 版本决定了诊断数据能关到多低

`AllowTelemetry = 0` 只有在 **Enterprise** 和 **Education** 版上才会被完整遵守。在 **专业版** 和 **家庭版** 上，Windows 会把它当作 *必需（Required）*：仍会发送一组精简的安全与质量相关诊断数据，这一点**无法**通过任何设置、策略或第三方工具改变。

WinCleanKit 在专业版/家庭版上**能**做、并且已经做了的：

- 停止采集与上传服务（`DiagTrack`、兼容性评估、CEIP、USB CEIP、反馈上传）
- 停止错误报告与兼容性助手
- 禁止 OneSettings 配置下载
- 把策略设到允许的最低值

这把实际外发量压到了接近平台下限，但**达不到零**。要真正归零，需要 Enterprise/Education 或 Windows LTSC。

查看你的系统实际报告的状态：

```powershell
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name AllowTelemetry
dsregcmd /status   # 在 "DiagnosticData" 处显示生效的诊断数据状态
```

## 部分注册表键与计划任务被 Windows 保护

Windows 会把少数注册表键和计划任务保护起来，即使是管理员也无法修改。在 Windows 11 build 26200 上实测到的例子：

- `HKCU\...\CurrentVersion\Search\BingSearchEnabled` —— 写入返回 *拒绝访问*，尽管所有者就是你自己的账号、ACL 也给了 `FullControl`
- 某些版本上的 `HKLM\SOFTWARE\Policies\Microsoft\Dsh`

引擎会在运行日志里如实记为 `[WARN]`/`[FAIL]`，而**不会**去夺取键的所有权强行写入。强行夺取系统键所有权，正是那种会在日后造成难以排查问题的操作。遇到写入被拒时，请改用等价的界面设置（例如：设置 → 隐私和安全性 → 搜索权限）。

## 功能更新可能会重建计划任务

Windows 大版本更新可能会重新启用遥测任务，或恢复推广内容的默认值。重跑 WinCleanKit 是安全且幂等的 —— 它只会重新应用你选中的项。用 dry run 可以快速看出哪些被改回去了。

## OneDrive 卸载依赖运行环境

`OneDriveSetup.exe /uninstall` 在非交互会话（例如通过 SSH）中会返回 `0x800704C7`（用户取消），因为它需要桌面会话。因此引擎会退而直接删除客户端程序并加策略阻止重装。**数据目录绝不被触碰**，所以它占用的磁盘空间只有在你确认无用并自行删除后才会释放。

## 壁纸不是设置项，所以不"清理"它

如果 Windows 当前正把某张 Spotlight 推广图当作你的桌面壁纸，WinCleanKit 会停止**后续**投递并隐藏推广浮层，但它不会重绘你的桌面。请通过 设置 → 个性化 → 背景 更换当前图片。这是刻意的：一个会悄悄改掉你壁纸的工具，做的正是本项目要反对的事。

## Catalog 以 Windows 11 为先

所有动作都针对 Windows 11（build 26200）编写与测试。多数注册表策略路径在 Windows 10 上同样有效；不存在的服务或任务会被报为 *未安装* 而不是失败。仅 Windows 10 才有的界面（例如"资讯和兴趣"）尚未覆盖。

## 被删除的内容无法还原

还原日志覆盖设置、服务与计划任务。删掉的广告图不会回来，卸载的 Store 应用需要从商店重装 —— 还原脚本会告诉你是哪几个。

## 这不是加固工具

WinCleanKit 减少广告与遥测。它不是安全加固基线，不配置 Defender、防火墙规则、BitLocker 或应用白名单，也不应被当作这类工具使用。
