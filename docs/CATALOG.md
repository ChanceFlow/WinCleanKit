<!-- GENERATED FILE - do not edit by hand.
     Regenerate with:  pwsh -File tools/New-CatalogDoc.ps1
     CI verifies this file is current (tools/New-CatalogDoc.ps1 -Check). -->

[English](CATALOG.md) · [中文](CATALOG.zh-CN.md) · [README](../README.md) · [中文说明](../README.zh-CN.md)

# Action catalog

**74 actions across 6 categories.** Generated from [`catalog/catalog.json`](../catalog/catalog.json).

Every action appears below with its English and Chinese text, its risk level, and the
preset(s) it belongs to. The containment chain `conservative ⊆ balanced ⊆ aggressive` is
enforced by `tests/Test-Catalog.ps1`, so a smaller preset never contains something a larger
one does not.

## Risk levels

| Level | Meaning |
|---|---|
| 🟢 **low / 低** | Reversible preference or a background collector that stops, with no visible change to daily use. |
| 🟡 **medium / 中** | A visible trade-off: a UI element disappears, a convenience feature stops working, or cached content is deleted. |
| 🔴 **high / 高** | Removes a program or blocks a capability. Always opt-in, never in a smaller preset. |

## Presets

| Preset | Actions | Contains |
|---|---|---|
| `conservative` | 45 | only the lowest-trade-off options / 仅取舍最小的项目 |
| `balanced` | 60 | conservative plus everything above / 上一档全部 |
| `aggressive` | 74 | balanced plus everything above (all actions) / 上一档全部（即全部动作） |

## Ads & suggestions — 系统广告与推荐

`ads` · 22 actions

Turns off Microsoft's own promotional surfaces: Start menu recommendations, Settings suggestions, lock-screen Spotlight ads, search-box web suggestions, widget feed, and the desktop 'Learn about this picture' icon.

关闭微软自家推广位：开始菜单推荐、设置页建议、锁屏 Spotlight 广告、搜索框联网推荐、小组件资讯流、桌面“了解此图片”图标。

### `ads.cdm.silent-install` — Forbid silent app installation

**禁止静默自动安装应用**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** This single flag is what lets Windows drop promoted apps into your Start menu without asking. It is the root cause of most 'where did this app come from' bloat.
- **代价 / Cost:** 就是这个开关让 Windows 不询问就往你开始菜单塞推广应用。大多数“这应用哪来的”都是它干的。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SilentInstalledAppsEnabled` = `0` (DWord)

### `ads.cdm.subscribed-content` — Disable subscribed content (recommendations/ads)

**关闭订阅内容(推荐/广告)**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Master switch for all Microsoft-pushed subscribed content on the user account.
- **代价 / Cost:** 微软向该用户账号推送的所有订阅内容总开关。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SubscribedContentEnabled` = `0` (DWord)

### `ads.cdm.spotlight-desktop` — Disable Windows Spotlight desktop ad

**关闭桌面 Spotlight 广告图**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Subscribed content 338389 is the desktop wallpaper/icon Spotlight promotion.
- **代价 / Cost:** 订阅内容 338389 即桌面壁纸/图标形式的 Spotlight 推广。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SubscribedContent\338389` = `0` (DWord)

### `ads.cdm.lockscreen-overlay` — Disable lock screen ad overlay

**关闭锁屏广告浮层**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** The 'fun facts, tips and more' overlay drawn on top of your lock screen picture is an ad surface.
- **代价 / Cost:** 锁屏图片上那层“有趣的事实、提示等”浮层就是广告位。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\RotatingLockScreenOverlayEnabled` = `0` (DWord)

### `ads.cdm.lockscreen-spotlight` — Disable lock screen Spotlight rotation

**关闭锁屏 Spotlight 轮播**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `aggressive`
- **Why / 为什么:** Stops Windows rotating lock screen images, which is the delivery vehicle for lock screen ads.
- **代价 / Cost:** 停止锁屏图片轮播——这是锁屏广告的投放载体。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\RotatingLockScreenEnabled` = `0` (DWord)

### `ads.cdm.system-pane-suggestions` — Disable Settings / Start suggestions

**关闭设置与开始菜单建议**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Removes the suggested-apps and tips rows injected into Settings and Start.
- **代价 / Cost:** 移除注入到设置和开始菜单里的推荐应用与提示行。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SystemPaneSuggestionsEnabled` = `0` (DWord)

### `ads.cdm.content-delivery` — Disable content delivery

**关闭内容推送**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Turns off the content-delivery pipeline that carries tips and promotions.
- **代价 / Cost:** 关闭承载提示与推广的内容投递管道。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\ContentDeliveryAllowed` = `0` (DWord)

### `ads.cdm.oem-preinstalled` — Disable OEM preinstalled app promotions

**禁止 OEM 预装应用推广**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Blocks OEM-supplied app promotion slots.
- **代价 / Cost:** 阻止 OEM 提供的应用推广位。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\OemPreInstalledAppsEnabled` = `0` (DWord)

### `ads.cdm.soft-landing` — Disable soft landing / welcome pages

**关闭欢迎与提示落地页**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Stops the 'look what you can do' landing pages after updates.
- **代价 / Cost:** 停止更新后弹出的“看看你能做什么”落地页。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SoftLandingEnabled` = `0` (DWord)

### `ads.start.iris-recommendations` — Remove Start menu Recommended section ads

**移除开始菜单“推荐”区推广**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Removes promoted apps from the Start menu Recommended area.
- **代价 / Cost:** 移除开始菜单“推荐”区里的推广应用。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_IrisRecommendations` = `0` (DWord)

### `ads.start.track-docs` — Disable recent-file suggestions

**关闭最近使用文件建议**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Stops recently used files being surfaced as suggestions.
- **代价 / Cost:** 不再把最近使用的文件作为建议展示。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_TrackDocs` = `0` (DWord)

### `ads.taskbar.widgets-button` — Hide taskbar Widgets button

**隐藏任务栏小组件按钮**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** The Widgets button opens a feed of news and sponsored content.
- **代价 / Cost:** 小组件按钮打开的是资讯与赞助内容流。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa` = `0` (DWord)

### `ads.taskbar.chat-button` — Hide taskbar Chat (Teams) button

**隐藏任务栏聊天(Teams)按钮**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Removes the preinstalled Chat/Teams promotion from the taskbar.
- **代价 / Cost:** 从任务栏移除预装的聊天/Teams 推广位。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarMn` = `0` (DWord)

### `ads.desktop.learn-about-picture` — Hide desktop 'Learn about this picture' icon

**隐藏桌面“了解此图片”图标**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** The Spotlight desktop icon is a promotional entry point on top of your wallpaper.
- **代价 / Cost:** Spotlight 桌面图标是叠在你壁纸上的推广入口。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel\{2cc5ca98-6485-489a-920e-b3e88a6ccce3}` = `1` (DWord)

### `ads.search.box-suggestions` — Disable search box web suggestions

**关闭搜索框联网推荐**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Stops the search box sending your keystrokes to Bing and rendering sponsored results.
- **代价 / Cost:** 不再把键入内容发往 Bing 并展示赞助结果。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer\DisableSearchBoxSuggestions` = `1` (DWord)

### `ads.settings.hide-home-promos` — Hide Settings home page promos

**隐藏设置首页推广区块**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `registry`  ·  **Presets:** `aggressive`
- **Why / 为什么:** The Settings home page carries promotional cards. Hiding it is a visible UI change.
- **代价 / Cost:** 设置首页带推广卡片。隐藏它会改变你看到的设置界面。
- **Sets:** `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\SettingsPageVisibility` = `hide:home` (String)

### `ads.edge.promo-tabs` — Disable Edge promotional tabs & recommendations

**关闭 Edge 推广标签页与推荐**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Turns off Edge's promotional tab that appears after updates. Does NOT remove or disable the Edge browser itself.
- **代价 / Cost:** 关闭更新后出现的 Edge 推广标签页。不会移除或禁用 Edge 浏览器本身。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\PromotionalTabsEnabled` = `0` (DWord)

### `ads.edge.default-browser-popup` — Disable 'set Edge as default' popup

**关闭“将 Edge 设为默认”弹窗**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Stops Edge nagging you to become the default browser.
- **代价 / Cost:** 不再反复提示你把 Edge 设为默认浏览器。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\DefaultBrowserSettingEnabled` = `0` (DWord)

### `ads.cloudcontent.consumer-features` — Disable Windows consumer features

**禁止 Windows 消费者功能**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** The machine-wide policy that stops Windows auto-installing promoted apps and games.
- **代价 / Cost:** 机器级策略，阻止 Windows 自动安装推广的应用与游戏。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableWindowsConsumerFeatures` = `1` (DWord)

### `ads.cloudcontent.spotlight-features` — Disable Spotlight features

**禁用 Spotlight 特性**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Machine-wide policy disabling Windows Spotlight promotional surfaces.
- **代价 / Cost:** 机器级策略，禁用 Windows Spotlight 的各推广位。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableWindowsSpotlightFeatures` = `1` (DWord)

### `ads.cloudcontent.third-party-suggestions` — Disable third-party app suggestions

**禁用第三方应用推荐**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Stops Microsoft suggesting third-party apps it is paid to promote.
- **代价 / Cost:** 不再推荐微软收了推广费的第三方应用。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableThirdPartySuggestions` = `1` (DWord)

### `ads.cloudcontent.tailored-experiences` — Opt out of tailored experiences

**退出定制化体验**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Stops your diagnostic data being used to personalise ads and tips.
- **代价 / Cost:** 不再用你的诊断数据来个性化广告与提示。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableTailoredExperiencesWithDiagnosticData` = `1` (DWord)

## Telemetry & diagnostics — 遥测与诊断数据

`telemetry` · 21 actions

Stops diagnostic data collection: the DiagTrack service, compatibility appraiser, CEIP uploads, error reporting and feedback requests.

停止诊断数据采集：DiagTrack 服务、兼容性评估、CEIP 上报、错误报告与反馈请求。

### `telemetry.policy.allow-telemetry` — Set diagnostic data to lowest allowed level

**诊断数据设为最低级别**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Sets AllowTelemetry=0. On Pro/Home Windows reports this as 'Required' — security/quality data still flows. Only Enterprise/Education honours a true zero.
- **代价 / Cost:** 设置 AllowTelemetry=0。在专业版/家庭版上系统会显示为“必需”，安全与质量数据仍会发送。只有 Enterprise/Education 才能真正归零。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry` = `0` (DWord)

### `telemetry.policy.allow-telemetry-legacy` — Set legacy AllowTelemetry to 0

**旧位置 AllowTelemetry 设为 0**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Older builds read the value from the legacy path; setting both is safer.
- **代价 / Cost:** 旧版本从旧路径读取该值，两处都写更保险。
- **Sets:** `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection\AllowTelemetry` = `0` (DWord)

### `telemetry.policy.one-settings` — Disable OneSettings downloads

**禁止 OneSettings 配置下载**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Stops Windows fetching remote configuration payloads used for experiments and staged rollouts.
- **代价 / Cost:** 不再下载用于实验与灰度推送的远程配置载荷。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\DisableOneSettingsDownloads` = `1` (DWord)

### `telemetry.policy.no-feedback-prompts` — Stop Windows asking for feedback

**不再请求反馈**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Suppresses 'give us feedback' notifications.
- **代价 / Cost:** 不再弹出“给我们反馈”的通知。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\DoNotShowFeedbackNotifications` = `1` (DWord)

### `telemetry.appcompat.ait` — Disable Application Impact Telemetry

**关闭应用影响遥测(AIT)**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Stops per-application compatibility telemetry reporting.
- **代价 / Cost:** 停止逐应用的兼容性遥测上报。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat\AITEnable` = `0` (DWord)

### `telemetry.appcompat.inventory` — Disable installed-app inventory collection

**关闭已装应用清单采集**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Stops Windows inventorying your installed software for telemetry.
- **代价 / Cost:** 不再为遥测目的清点你安装的软件。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat\DisableInventory` = `1` (DWord)

### `telemetry.appcompat.uar` — Disable User Activity Recording

**关闭用户活动记录**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Stops Windows recording how you use applications.
- **代价 / Cost:** 停止记录你的应用使用行为。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat\DisableUAR` = `1` (DWord)

### `telemetry.ceip` — Turn off Customer Experience Improvement Program

**关闭客户体验改善计划(CEIP)**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Opts the machine out of the CEIP data programme.
- **代价 / Cost:** 让本机退出 CEIP 数据计划。
- **Sets:** `HKLM\SOFTWARE\Microsoft\SQMClient\Windows\CEIPEnable` = `0` (DWord)

### `telemetry.wer.disabled` — Disable Windows Error Reporting

**关闭 Windows 错误报告**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `registry`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** Stops crash reports being sent to Microsoft. Trade-off: crashes will no longer be uploaded for analysis.
- **代价 / Cost:** 不再向微软发送崩溃报告。代价：崩溃不再上传分析。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting\Disabled` = `1` (DWord)

### `telemetry.svc.diagtrack` — Disable DiagTrack service

**禁用 DiagTrack 服务**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `service`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Connected User Experiences and Telemetry — the core service that uploads diagnostic data.
- **代价 / Cost:** “连接用户体验和遥测”——上传诊断数据的核心服务。
- **Sets:** service `DiagTrack` start type to `Disabled`

### `telemetry.svc.dmwappushservice` — Disable dmwappushservice

**禁用 dmwappushservice**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `service`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** WAP push message routing, used by the telemetry pipeline.
- **代价 / Cost:** WAP 推送消息路由，供遥测管道使用。
- **Sets:** service `dmwappushservice` start type to `Disabled`

### `telemetry.svc.wdi` — Disable Windows diagnostic infrastructure services

**禁用 Windows 诊断基础结构服务**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `service`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** WdiServiceHost and WdiSystemHost run diagnostic scenario traces.
- **代价 / Cost:** WdiServiceHost 与 WdiSystemHost 负责运行诊断场景跟踪。
- **Sets:** service `WdiServiceHost` start type to `Disabled`

### `telemetry.svc.wdi-system` — Disable WdiSystemHost service

**禁用 WdiSystemHost 服务**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `service`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Diagnostic system host.
- **代价 / Cost:** 诊断系统宿主。
- **Sets:** service `WdiSystemHost` start type to `Disabled`

### `telemetry.svc.wer` — Disable Windows Error Reporting service

**禁用 Windows 错误报告服务**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `service`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** Stops the error reporting service. Trade-off: no crash reporting at all.
- **代价 / Cost:** 停止错误报告服务。代价：完全没有崩溃上报。
- **Sets:** service `WerSvc` start type to `Disabled`

### `telemetry.svc.pcasvc` — Disable Program Compatibility Assistant service

**禁用程序兼容性助手服务**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `service`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** PCA watches what you run and reports compatibility data. Trade-off: no automatic compatibility fixes.
- **代价 / Cost:** PCA 监视你运行的程序并上报兼容性数据。代价：失去自动兼容性修复。
- **Sets:** service `PcaSvc` start type to `Disabled`

### `telemetry.task.appraiser` — Disable Compatibility Appraiser task

**禁用兼容性评估任务**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `task`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Microsoft Compatibility Appraiser Exp is one of the largest telemetry collectors on Windows.
- **代价 / Cost:** Microsoft Compatibility Appraiser Exp 是 Windows 上采集量最大的遥测任务之一。
- **Disables:** scheduled task `\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp`

### `telemetry.task.consolidator` — Disable CEIP Consolidator task

**禁用 CEIP 汇总上传任务**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `task`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Aggregates and uploads Customer Experience Improvement data.
- **代价 / Cost:** 汇总并上传客户体验改善数据。
- **Disables:** scheduled task `\Microsoft\Windows\Customer Experience Improvement Program\Consolidator`

### `telemetry.task.usbceip` — Disable USB CEIP task

**禁用 USB 使用数据采集任务**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `task`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Collects and uploads USB device usage data.
- **代价 / Cost:** 采集并上传 USB 设备使用数据。
- **Disables:** scheduled task `\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip`

### `telemetry.task.dmclient` — Disable feedback upload tasks

**禁用反馈上传任务**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `task`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** DmClient and DmClientOnScenarioDownload upload feedback and scenario data.
- **代价 / Cost:** DmClient 与 DmClientOnScenarioDownload 上传反馈与场景数据。
- **Disables:** scheduled task `\Microsoft\Windows\Feedback\Siuf\DmClient`

### `telemetry.task.marebackup` — Disable MareBackup task

**禁用 MareBackup 任务**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `task`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** Compatibility telemetry reporting task.
- **代价 / Cost:** 兼容性遥测上报任务。
- **Disables:** scheduled task `\Microsoft\Windows\Application Experience\MareBackup`

### `telemetry.task.queuereporting` — Disable error report queue task

**禁用错误报告排队任务**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `task`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Queues error reports for upload.
- **代价 / Cost:** 将错误报告排队等待上传。
- **Disables:** scheduled task `\Microsoft\Windows\Windows Error Reporting\QueueReporting`

## Preinstalled apps — 预装应用

`apps` · 19 actions

Uninstalls consumer UWP apps and revokes their provisioning so they cannot be reinstalled silently. All of them can be reinstalled from the Microsoft Store.

卸载消费类 UWP 应用并撤销预置，防止被静默重装。全部都可以从 Microsoft Store 重新安装。

### `apps.clipchamp` — Uninstall Clipchamp

**卸载 Clipchamp**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** Bundled video editor with a paid tier. Reinstallable from the Store.
- **代价 / Cost:** 捆绑的视频编辑器，含付费档。可从 Store 重装。
- **Uninstalls:** `Clipchamp.Clipchamp` and revokes its provisioning

### `apps.devhome` — Uninstall Dev Home

**卸载 Dev Home**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** Developer dashboard most users never open.
- **代价 / Cost:** 多数人从不打开的开发者仪表盘。
- **Uninstalls:** `Microsoft.Windows.DevHome` and revokes its provisioning

### `apps.power-automate` — Uninstall Power Automate

**卸载 Power Automate**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** Automation host that runs in the background.
- **代价 / Cost:** 后台常驻的自动化宿主。
- **Uninstalls:** `Microsoft.PowerAutomateDesktop` and revokes its provisioning

### `apps.outlook-new` — Uninstall new Outlook (web wrapper)

**卸载新版 Outlook(网页套壳)**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `appx`  ·  **Presets:** `aggressive`
- **Why / 为什么:** The Store Outlook is a web wrapper. SKIP THIS if you use it for mail.
- **代价 / Cost:** Store 版 Outlook 是网页套壳。如果你用它收发邮件，请跳过此项。
- **Uninstalls:** `Microsoft.OutlookForWindows` and revokes its provisioning

### `apps.media-player` — Uninstall Media Player (ZuneMusic)

**卸载媒体播放器(ZuneMusic)**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `appx`  ·  **Presets:** `aggressive`
- **Why / 为什么:** Groove successor with store promotions. SKIP if you play local media with it.
- **代价 / Cost:** Groove 的继任者，带商店推广。如果你用它播放本地媒体，请跳过。
- **Uninstalls:** `Microsoft.ZuneMusic` and revokes its provisioning

### `apps.xbox` — Uninstall Xbox app & Game Bar overlay

**卸载 Xbox 应用与 Game Bar 覆盖层**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `appx`  ·  **Presets:** `aggressive`
- **Why / 为什么:** Xbox app, Game Bar overlay, TCUI and identity provider. These are the pieces that pop up over games. SKIP if you use Game Pass, achievements or Game Bar recording.
- **代价 / Cost:** Xbox 应用、Game Bar 覆盖层、TCUI 与身份提供程序——就是在游戏上弹窗的那套。如果你用 Game Pass、成就或 Game Bar 录屏，请跳过。
- **Uninstalls:** `Microsoft.GamingApp` and revokes its provisioning

### `apps.xbox-overlay` — Uninstall Xbox Game Bar overlay (TCUI)

**卸载 Xbox Game Bar 覆盖层(TCUI)**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `appx`  ·  **Presets:** `aggressive`
- **Why / 为什么:** The Xbox overlay shell. SKIP if you use Win+G recording.
- **代价 / Cost:** Xbox 覆盖层外壳。如果你用 Win+G 录屏，请跳过。
- **Uninstalls:** `Microsoft.XboxGamingOverlay` and revokes its provisioning

### `apps.solitaire` — Uninstall Solitaire Collection

**卸载微软纸牌**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** Ships with adverts inside the game.
- **代价 / Cost:** 游戏内自带广告。
- **Uninstalls:** `Microsoft.MicrosoftSolitaireCollection` and revokes its provisioning

### `apps.office-hub` — Uninstall Office Hub placeholder

**卸载 Office Hub 占位应用**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** A Store advert for Microsoft 365, not actual Office.
- **代价 / Cost:** 这是 Microsoft 365 的商店广告，不是真正的 Office。
- **Uninstalls:** `Microsoft.MicrosoftOfficeHub` and revokes its provisioning

### `apps.todos` — Uninstall Microsoft To Do

**卸载 Microsoft To Do**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `appx`  ·  **Presets:** `aggressive`
- **Why / 为什么:** Task app. SKIP if you keep your to-do list here.
- **代价 / Cost:** 待办应用。如果你在这里记待办，请跳过。
- **Uninstalls:** `Microsoft.Todos` and revokes its provisioning

### `apps.feedback-hub` — Uninstall Feedback Hub

**卸载反馈中心**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** Microsoft's feedback collection app.
- **代价 / Cost:** 微软的反馈收集应用。
- **Uninstalls:** `Microsoft.WindowsFeedbackHub` and revokes its provisioning

### `apps.get-help` — Uninstall Get Help

**卸载获取帮助**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** Support contact app most users never open.
- **代价 / Cost:** 多数人从不打开的技术支持应用。
- **Uninstalls:** `Microsoft.GetHelp` and revokes its provisioning

### `apps.your-phone` — Uninstall Phone Link

**卸载手机连接(Phone Link)**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `appx`  ·  **Presets:** `aggressive`
- **Why / 为什么:** Links your phone to the PC. SKIP if you use it.
- **代价 / Cost:** 把手机连到电脑。如果你在用，请跳过。
- **Uninstalls:** `Microsoft.YourPhone` and revokes its provisioning

### `apps.quick-assist` — Uninstall Quick Assist

**卸载快速助手**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `appx`  ·  **Presets:** `aggressive`
- **Why / 为什么:** Remote assistance tool. SKIP if your IT support uses it to help you.
- **代价 / Cost:** 远程协助工具。如果 IT 支持靠它帮你，请跳过。
- **Uninstalls:** `MicrosoftCorporationII.QuickAssist` and revokes its provisioning

### `apps.sticky-notes` — Uninstall Sticky Notes

**卸载便笺**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `appx`  ·  **Presets:** `aggressive`
- **Why / 为什么:** SKIP if you keep notes on your desktop.
- **代价 / Cost:** 如果你在桌面上记便签，请跳过。
- **Uninstalls:** `Microsoft.MicrosoftStickyNotes` and revokes its provisioning

### `apps.maps` — Uninstall Windows Maps

**卸载 Windows 地图**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** Offline map app almost nobody opens on a desktop.
- **代价 / Cost:** 台式机上几乎没人打开的离线地图。
- **Uninstalls:** `Microsoft.WindowsMaps` and revokes its provisioning

### `apps.bing-news` — Uninstall Bing News

**卸载 Bing 资讯**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** Ad-funded news feed, usually arrives via silent install.
- **代价 / Cost:** 靠广告变现的资讯流，通常经静默安装落地。
- **Uninstalls:** `Microsoft.BingNews` and revokes its provisioning

### `apps.bing-weather` — Uninstall Bing Weather

**卸载 Bing 天气**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** Ad-funded weather app, usually arrives via silent install.
- **代价 / Cost:** 靠广告变现的天气应用，通常经静默安装落地。
- **Uninstalls:** `Microsoft.BingWeather` and revokes its provisioning

### `apps.bing-search` — Uninstall Bing Search app

**卸载 Bing 搜索应用**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why / 为什么:** Web-search wrapper injected into the Start menu.
- **代价 / Cost:** 注入开始菜单的网页搜索套壳。
- **Uninstalls:** `Microsoft.BingSearch` and revokes its provisioning

## OneDrive — OneDrive

`onedrive` · 1 actions

Removes the OneDrive client binaries and blocks reinstall. Your OneDrive data folder is NEVER touched.

移除 OneDrive 客户端程序并阻止重装。你的 OneDrive 数据目录【绝不会】被触碰。

### `onedrive.uninstall` — Remove OneDrive client and block reinstall

**移除 OneDrive 客户端并阻止重装**

- **Risk / 风险:** 🔴 high / 高  ·  **Target / 类型:** `onedrive`  ·  **Presets:** `aggressive`
- **Why / 为什么:** Deletes the OneDrive binaries and sets a machine policy that blocks sync and reinstall. YOUR DATA FOLDER IS NEVER TOUCHED — it stays on disk exactly as it is, and nothing is uploaded or deleted.
- **代价 / Cost:** 删除 OneDrive 程序本体并设置机器级策略阻止同步与重装。你的数据目录【绝不会】被触碰——原样留在磁盘上，不会上传也不会删除。
- **Removes:** the OneDrive client binaries and blocks reinstall. The data folder is never touched.

## Privacy — 隐私加固

`privacy` · 10 actions

Advertising ID, input personalization, implicit text/ink collection, location, settings sync and per-app diagnostic access.

广告标识符、输入个性化、文本/手写隐式采集、定位、设置同步、应用诊断信息访问权限。

### `privacy.advertising-id` — Turn off advertising ID

**关闭广告标识符**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Apps can no longer use a per-user advertising identifier to profile you.
- **代价 / Cost:** 应用无法再用每用户广告标识符对你画像。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo\Enabled` = `0` (DWord)

### `privacy.input-personalization` — Disable input personalization

**关闭输入个性化**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Stops typing/inking data being collected to build a personal dictionary in the cloud.
- **代价 / Cost:** 不再采集键入/手写数据用于构建云端个人词典。
- **Sets:** `HKCU\Software\Microsoft\Input\TIPC\Enabled` = `0` (DWord)

### `privacy.implicit-text-collection` — Block implicit text collection

**阻止文本隐式采集**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Prevents Windows silently sampling your typing.
- **代价 / Cost:** 阻止 Windows 静默采样你的输入内容。
- **Sets:** `HKCU\Software\Microsoft\InputPersonalization\RestrictImplicitTextCollection` = `1` (DWord)

### `privacy.implicit-ink-collection` — Block implicit handwriting collection

**阻止手写隐式采集**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Prevents Windows sampling your handwriting.
- **代价 / Cost:** 阻止 Windows 采样你的手写笔迹。
- **Sets:** `HKCU\Software\Microsoft\InputPersonalization\RestrictImplicitInkCollection` = `1` (DWord)

### `privacy.handwriting-sharing` — Stop handwriting data sharing

**停止手写数据共享**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Blocks handwriting recognition data being shared with Microsoft.
- **代价 / Cost:** 阻止手写识别数据被共享给微软。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC\PreventHandwritingDataSharing` = `1` (DWord)

### `privacy.location` — Disable location services

**关闭定位服务**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `registry`  ·  **Presets:** `aggressive`
- **Why / 为什么:** Turns off system location. Trade-off: Maps, weather and 'find my device' become less useful.
- **代价 / Cost:** 关闭系统定位。代价：地图、天气、“查找我的设备”等功能受限。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors\DisableLocation` = `1` (DWord)

### `privacy.settings-sync` — Disable settings sync to Microsoft account

**关闭设置同步到微软账号**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `registry`  ·  **Presets:** `aggressive`
- **Why / 为什么:** Stops your personalisation settings syncing to the cloud. Trade-off: settings no longer follow you to other PCs.
- **代价 / Cost:** 不再把个性化设置同步到云端。代价：换电脑时设置不再跟随。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\SettingSync\SyncPolicy` = `0` (DWord)

### `privacy.app-diagnostic-access` — Block apps reading diagnostic information

**禁止应用读取诊断信息**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Per-app permission: no app may read diagnostic data about your device.
- **代价 / Cost:** 逐应用权限：任何应用都不得读取你设备的诊断数据。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy\LetAppsAccessDiagnosticInformation` = `2` (DWord)

### `privacy.feedback-frequency` — Never ask for feedback

**永不请求反馈**

- **Risk / 风险:** 🟢 low / 低  ·  **Target / 类型:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Sets the feedback request cadence to zero.
- **代价 / Cost:** 把反馈请求频率设为 0。
- **Sets:** `HKCU\Software\Microsoft\Siuf\Rules\NumberOfSIUFInPeriod` = `0` (DWord)

### `privacy.delivery-optimization-no-p2p` — Stop Delivery Optimization peer-to-peer sharing

**关闭传递优化 P2P 共享**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `registry`  ·  **Presets:** `aggressive`
- **Why / 为什么:** Your PC stops uploading update fragments to strangers. Trade-off: slightly slower updates. The service itself is kept enabled.
- **代价 / Cost:** 你的电脑不再向陌生人上传更新分片。代价：更新可能略慢。服务本身保留启用。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization\DODownloadMode` = `0` (DWord)

## Ad cache & wallpaper — 广告图缓存与壁纸

`cache` · 1 actions

Deletes already-downloaded Spotlight ad images. Refuses to touch your current wallpaper or its transcoded copy.

删除已下载的 Spotlight 广告图。不会触碰你当前的壁纸及其转码副本。

### `cache.spotlight-images` — Delete downloaded Spotlight ad images

**删除已下载的 Spotlight 广告图**

- **Risk / 风险:** 🟡 medium / 中  ·  **Target / 类型:** `path-clean`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why / 为什么:** Removes already-downloaded promotional images. It does NOT touch your wallpaper or its transcoded copy.
- **代价 / Cost:** 删除已下载的推广图片。不会触碰你的壁纸及其转码副本。
- **Deletes cached files in:**
  - `%LOCALAPPDATA%\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets`
  - `%LOCALAPPDATA%\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\StagedAssets`
  - `%LOCALAPPDATA%\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\TargetedContentCache`
  - `%LOCALAPPDATA%\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Tips`

---

[English](CATALOG.md) · [中文](CATALOG.zh-CN.md) · [README](../README.md) · [中文说明](../README.zh-CN.md)

Generated from `catalog/catalog.json` by `tools/New-CatalogDoc.ps1`. Do not edit by hand.

