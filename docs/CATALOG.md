# Action catalog

**74 actions across 6 categories.** This file is generated from
[`catalog/catalog.json`](../catalog/catalog.json) — edit the JSON, not this document.

## Why risk levels matter

| Level | Meaning |
|---|---|
| 🟢 **low** | Reversible preference or a service/task that does not affect daily use. |
| 🟡 **medium** | Has a visible trade-off: a UI element disappears, a convenience feature stops working, or cached content is deleted. |
| 🔴 **high** | Removes a program or blocks a capability. Everything here is opt-in and never in a smaller preset. |

## Presets

| Preset | Actions | Contains |
|---|---|---|
| `conservative` | 45 | only low-trade-off options |
| `balanced` | 60 | conservative plus everything above |
| `aggressive` | 74 | balanced plus everything above (all actions) |

The suite enforces `conservative ⊆ balanced ⊆ aggressive`, so a smaller preset can never
contain something a larger one does not.

## Windows ads & suggestions (`ads`) — 22 actions

Turns off Microsoft's own promotional surfaces: Start menu recommendations, Settings suggestions, lock-screen Spotlight ads, search-box web suggestions, widget feed, and the desktop 'Learn about this picture' icon.

*关闭微软自家推广位：开始菜单推荐、设置页建议、锁屏 Spotlight 广告、搜索框联网推荐、小组件资讯流、桌面“了解此图片”图标。*

### `ads.cdm.silent-install` — Forbid silent app installation

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** This single flag is what lets Windows drop promoted apps into your Start menu without asking. It is the root cause of most 'where did this app come from' bloat.
- *禁止静默自动安装应用* — *就是这个开关让 Windows 不询问就往你开始菜单塞推广应用。大多数“这应用哪来的”都是它干的。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SilentInstalledAppsEnabled` = `0` (DWord)

### `ads.cdm.subscribed-content` — Disable subscribed content (recommendations/ads)

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Master switch for all Microsoft-pushed subscribed content on the user account.
- *关闭订阅内容(推荐/广告)* — *微软向该用户账号推送的所有订阅内容总开关。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SubscribedContentEnabled` = `0` (DWord)

### `ads.cdm.spotlight-desktop` — Disable Windows Spotlight desktop ad

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Subscribed content 338389 is the desktop wallpaper/icon Spotlight promotion.
- *关闭桌面 Spotlight 广告图* — *订阅内容 338389 即桌面壁纸/图标形式的 Spotlight 推广。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SubscribedContent\338389` = `0` (DWord)

### `ads.cdm.lockscreen-overlay` — Disable lock screen ad overlay

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** The 'fun facts, tips and more' overlay drawn on top of your lock screen picture is an ad surface.
- *关闭锁屏广告浮层* — *锁屏图片上那层“有趣的事实、提示等”浮层就是广告位。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\RotatingLockScreenOverlayEnabled` = `0` (DWord)

### `ads.cdm.lockscreen-spotlight` — Disable lock screen Spotlight rotation

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `aggressive`
- **Why:** Stops Windows rotating lock screen images, which is the delivery vehicle for lock screen ads.
- *关闭锁屏 Spotlight 轮播* — *停止锁屏图片轮播——这是锁屏广告的投放载体。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\RotatingLockScreenEnabled` = `0` (DWord)

### `ads.cdm.system-pane-suggestions` — Disable Settings / Start suggestions

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Removes the suggested-apps and tips rows injected into Settings and Start.
- *关闭设置与开始菜单建议* — *移除注入到设置和开始菜单里的推荐应用与提示行。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SystemPaneSuggestionsEnabled` = `0` (DWord)

### `ads.cdm.content-delivery` — Disable content delivery

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Turns off the content-delivery pipeline that carries tips and promotions.
- *关闭内容推送* — *关闭承载提示与推广的内容投递管道。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\ContentDeliveryAllowed` = `0` (DWord)

### `ads.cdm.oem-preinstalled` — Disable OEM preinstalled app promotions

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Blocks OEM-supplied app promotion slots.
- *禁止 OEM 预装应用推广* — *阻止 OEM 提供的应用推广位。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\OemPreInstalledAppsEnabled` = `0` (DWord)

### `ads.cdm.soft-landing` — Disable soft landing / welcome pages

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Stops the 'look what you can do' landing pages after updates.
- *关闭欢迎与提示落地页* — *停止更新后弹出的“看看你能做什么”落地页。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SoftLandingEnabled` = `0` (DWord)

### `ads.start.iris-recommendations` — Remove Start menu Recommended section ads

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Removes promoted apps from the Start menu Recommended area.
- *移除开始菜单“推荐”区推广* — *移除开始菜单“推荐”区里的推广应用。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_IrisRecommendations` = `0` (DWord)

### `ads.start.track-docs` — Disable recent-file suggestions

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Stops recently used files being surfaced as suggestions.
- *关闭最近使用文件建议* — *不再把最近使用的文件作为建议展示。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_TrackDocs` = `0` (DWord)

### `ads.taskbar.widgets-button` — Hide taskbar Widgets button

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** The Widgets button opens a feed of news and sponsored content.
- *隐藏任务栏小组件按钮* — *小组件按钮打开的是资讯与赞助内容流。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa` = `0` (DWord)

### `ads.taskbar.chat-button` — Hide taskbar Chat (Teams) button

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Removes the preinstalled Chat/Teams promotion from the taskbar.
- *隐藏任务栏聊天(Teams)按钮* — *从任务栏移除预装的聊天/Teams 推广位。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarMn` = `0` (DWord)

### `ads.desktop.learn-about-picture` — Hide desktop 'Learn about this picture' icon

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** The Spotlight desktop icon is a promotional entry point on top of your wallpaper.
- *隐藏桌面“了解此图片”图标* — *Spotlight 桌面图标是叠在你壁纸上的推广入口。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel\{2cc5ca98-6485-489a-920e-b3e88a6ccce3}` = `1` (DWord)

### `ads.search.box-suggestions` — Disable search box web suggestions

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Stops the search box sending your keystrokes to Bing and rendering sponsored results.
- *关闭搜索框联网推荐* — *不再把键入内容发往 Bing 并展示赞助结果。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer\DisableSearchBoxSuggestions` = `1` (DWord)

### `ads.settings.hide-home-promos` — Hide Settings home page promos

- **Risk:** 🟡 medium  ·  **Target:** `registry`  ·  **Presets:** `aggressive`
- **Why:** The Settings home page carries promotional cards. Hiding it is a visible UI change.
- *隐藏设置首页推广区块* — *设置首页带推广卡片。隐藏它会改变你看到的设置界面。*
- **Sets:** `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\SettingsPageVisibility` = `hide:home` (String)

### `ads.edge.promo-tabs` — Disable Edge promotional tabs & recommendations

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Turns off Edge's promotional tab that appears after updates. Does NOT remove or disable the Edge browser itself.
- *关闭 Edge 推广标签页与推荐* — *关闭更新后出现的 Edge 推广标签页。不会移除或禁用 Edge 浏览器本身。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\PromotionalTabsEnabled` = `0` (DWord)

### `ads.edge.default-browser-popup` — Disable 'set Edge as default' popup

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Stops Edge nagging you to become the default browser.
- *关闭“将 Edge 设为默认”弹窗* — *不再反复提示你把 Edge 设为默认浏览器。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\DefaultBrowserSettingEnabled` = `0` (DWord)

### `ads.cloudcontent.consumer-features` — Disable Windows consumer features

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** The machine-wide policy that stops Windows auto-installing promoted apps and games.
- *禁止 Windows 消费者功能* — *机器级策略，阻止 Windows 自动安装推广的应用与游戏。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableWindowsConsumerFeatures` = `1` (DWord)

### `ads.cloudcontent.spotlight-features` — Disable Spotlight features

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Machine-wide policy disabling Windows Spotlight promotional surfaces.
- *禁用 Spotlight 特性* — *机器级策略，禁用 Windows Spotlight 的各推广位。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableWindowsSpotlightFeatures` = `1` (DWord)

### `ads.cloudcontent.third-party-suggestions` — Disable third-party app suggestions

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Stops Microsoft suggesting third-party apps it is paid to promote.
- *禁用第三方应用推荐* — *不再推荐微软收了推广费的第三方应用。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableThirdPartySuggestions` = `1` (DWord)

### `ads.cloudcontent.tailored-experiences` — Opt out of tailored experiences

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Stops your diagnostic data being used to personalise ads and tips.
- *退出定制化体验* — *不再用你的诊断数据来个性化广告与提示。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableTailoredExperiencesWithDiagnosticData` = `1` (DWord)

## Telemetry & diagnostic data (`telemetry`) — 21 actions

Stops diagnostic data collection: the DiagTrack service, compatibility appraiser, CEIP uploads, error reporting and feedback requests.

*停止诊断数据采集：DiagTrack 服务、兼容性评估、CEIP 上报、错误报告与反馈请求。*

### `telemetry.policy.allow-telemetry` — Set diagnostic data to lowest allowed level

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Sets AllowTelemetry=0. On Pro/Home Windows reports this as 'Required' — security/quality data still flows. Only Enterprise/Education honours a true zero.
- *诊断数据设为最低级别* — *设置 AllowTelemetry=0。在专业版/家庭版上系统会显示为“必需”，安全与质量数据仍会发送。只有 Enterprise/Education 才能真正归零。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry` = `0` (DWord)

### `telemetry.policy.allow-telemetry-legacy` — Set legacy AllowTelemetry to 0

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Older builds read the value from the legacy path; setting both is safer.
- *旧位置 AllowTelemetry 设为 0* — *旧版本从旧路径读取该值，两处都写更保险。*
- **Sets:** `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection\AllowTelemetry` = `0` (DWord)

### `telemetry.policy.one-settings` — Disable OneSettings downloads

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Stops Windows fetching remote configuration payloads used for experiments and staged rollouts.
- *禁止 OneSettings 配置下载* — *不再下载用于实验与灰度推送的远程配置载荷。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\DisableOneSettingsDownloads` = `1` (DWord)

### `telemetry.policy.no-feedback-prompts` — Stop Windows asking for feedback

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Suppresses 'give us feedback' notifications.
- *不再请求反馈* — *不再弹出“给我们反馈”的通知。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\DoNotShowFeedbackNotifications` = `1` (DWord)

### `telemetry.appcompat.ait` — Disable Application Impact Telemetry

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Stops per-application compatibility telemetry reporting.
- *关闭应用影响遥测(AIT)* — *停止逐应用的兼容性遥测上报。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat\AITEnable` = `0` (DWord)

### `telemetry.appcompat.inventory` — Disable installed-app inventory collection

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Stops Windows inventorying your installed software for telemetry.
- *关闭已装应用清单采集* — *不再为遥测目的清点你安装的软件。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat\DisableInventory` = `1` (DWord)

### `telemetry.appcompat.uar` — Disable User Activity Recording

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Stops Windows recording how you use applications.
- *关闭用户活动记录* — *停止记录你的应用使用行为。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat\DisableUAR` = `1` (DWord)

### `telemetry.ceip` — Turn off Customer Experience Improvement Program

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Opts the machine out of the CEIP data programme.
- *关闭客户体验改善计划(CEIP)* — *让本机退出 CEIP 数据计划。*
- **Sets:** `HKLM\SOFTWARE\Microsoft\SQMClient\Windows\CEIPEnable` = `0` (DWord)

### `telemetry.wer.disabled` — Disable Windows Error Reporting

- **Risk:** 🟡 medium  ·  **Target:** `registry`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** Stops crash reports being sent to Microsoft. Trade-off: crashes will no longer be uploaded for analysis.
- *关闭 Windows 错误报告* — *不再向微软发送崩溃报告。代价：崩溃不再上传分析。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting\Disabled` = `1` (DWord)

### `telemetry.svc.diagtrack` — Disable DiagTrack service

- **Risk:** 🟢 low  ·  **Target:** `service`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Connected User Experiences and Telemetry — the core service that uploads diagnostic data.
- *禁用 DiagTrack 服务* — *“连接用户体验和遥测”——上传诊断数据的核心服务。*
- **Sets:** service `DiagTrack` start type to `Disabled`

### `telemetry.svc.dmwappushservice` — Disable dmwappushservice

- **Risk:** 🟢 low  ·  **Target:** `service`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** WAP push message routing, used by the telemetry pipeline.
- *禁用 dmwappushservice* — *WAP 推送消息路由，供遥测管道使用。*
- **Sets:** service `dmwappushservice` start type to `Disabled`

### `telemetry.svc.wdi` — Disable Windows diagnostic infrastructure services

- **Risk:** 🟢 low  ·  **Target:** `service`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** WdiServiceHost and WdiSystemHost run diagnostic scenario traces.
- *禁用 Windows 诊断基础结构服务* — *WdiServiceHost 与 WdiSystemHost 负责运行诊断场景跟踪。*
- **Sets:** service `WdiServiceHost` start type to `Disabled`

### `telemetry.svc.wdi-system` — Disable WdiSystemHost service

- **Risk:** 🟢 low  ·  **Target:** `service`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Diagnostic system host.
- *禁用 WdiSystemHost 服务* — *诊断系统宿主。*
- **Sets:** service `WdiSystemHost` start type to `Disabled`

### `telemetry.svc.wer` — Disable Windows Error Reporting service

- **Risk:** 🟡 medium  ·  **Target:** `service`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** Stops the error reporting service. Trade-off: no crash reporting at all.
- *禁用 Windows 错误报告服务* — *停止错误报告服务。代价：完全没有崩溃上报。*
- **Sets:** service `WerSvc` start type to `Disabled`

### `telemetry.svc.pcasvc` — Disable Program Compatibility Assistant service

- **Risk:** 🟡 medium  ·  **Target:** `service`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** PCA watches what you run and reports compatibility data. Trade-off: no automatic compatibility fixes.
- *禁用程序兼容性助手服务* — *PCA 监视你运行的程序并上报兼容性数据。代价：失去自动兼容性修复。*
- **Sets:** service `PcaSvc` start type to `Disabled`

### `telemetry.task.appraiser` — Disable Compatibility Appraiser task

- **Risk:** 🟢 low  ·  **Target:** `task`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Microsoft Compatibility Appraiser Exp is one of the largest telemetry collectors on Windows.
- *禁用兼容性评估任务* — *Microsoft Compatibility Appraiser Exp 是 Windows 上采集量最大的遥测任务之一。*
- **Disables:** scheduled task `\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp`

### `telemetry.task.consolidator` — Disable CEIP Consolidator task

- **Risk:** 🟢 low  ·  **Target:** `task`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Aggregates and uploads Customer Experience Improvement data.
- *禁用 CEIP 汇总上传任务* — *汇总并上传客户体验改善数据。*
- **Disables:** scheduled task `\Microsoft\Windows\Customer Experience Improvement Program\Consolidator`

### `telemetry.task.usbceip` — Disable USB CEIP task

- **Risk:** 🟢 low  ·  **Target:** `task`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Collects and uploads USB device usage data.
- *禁用 USB 使用数据采集任务* — *采集并上传 USB 设备使用数据。*
- **Disables:** scheduled task `\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip`

### `telemetry.task.dmclient` — Disable feedback upload tasks

- **Risk:** 🟢 low  ·  **Target:** `task`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** DmClient and DmClientOnScenarioDownload upload feedback and scenario data.
- *禁用反馈上传任务* — *DmClient 与 DmClientOnScenarioDownload 上传反馈与场景数据。*
- **Disables:** scheduled task `\Microsoft\Windows\Feedback\Siuf\DmClient`

### `telemetry.task.marebackup` — Disable MareBackup task

- **Risk:** 🟢 low  ·  **Target:** `task`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** Compatibility telemetry reporting task.
- *禁用 MareBackup 任务* — *兼容性遥测上报任务。*
- **Disables:** scheduled task `\Microsoft\Windows\Application Experience\MareBackup`

### `telemetry.task.queuereporting` — Disable error report queue task

- **Risk:** 🟢 low  ·  **Target:** `task`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Queues error reports for upload.
- *禁用错误报告排队任务* — *将错误报告排队等待上传。*
- **Disables:** scheduled task `\Microsoft\Windows\Windows Error Reporting\QueueReporting`

## Preinstalled apps (`apps`) — 19 actions

Uninstalls consumer UWP apps and revokes their provisioning so they cannot be reinstalled silently. All of them can be reinstalled from the Microsoft Store.

*卸载消费类 UWP 应用并撤销预置，防止被静默重装。全部都可以从 Microsoft Store 重新安装。*

### `apps.clipchamp` — Uninstall Clipchamp

- **Risk:** 🟢 low  ·  **Target:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** Bundled video editor with a paid tier. Reinstallable from the Store.
- *卸载 Clipchamp* — *捆绑的视频编辑器，含付费档。可从 Store 重装。*
- **Uninstalls:** `Clipchamp.Clipchamp` and revokes its provisioning

### `apps.devhome` — Uninstall Dev Home

- **Risk:** 🟢 low  ·  **Target:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** Developer dashboard most users never open.
- *卸载 Dev Home* — *多数人从不打开的开发者仪表盘。*
- **Uninstalls:** `Microsoft.Windows.DevHome` and revokes its provisioning

### `apps.power-automate` — Uninstall Power Automate

- **Risk:** 🟢 low  ·  **Target:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** Automation host that runs in the background.
- *卸载 Power Automate* — *后台常驻的自动化宿主。*
- **Uninstalls:** `Microsoft.PowerAutomateDesktop` and revokes its provisioning

### `apps.outlook-new` — Uninstall new Outlook (web wrapper)

- **Risk:** 🟡 medium  ·  **Target:** `appx`  ·  **Presets:** `aggressive`
- **Why:** The Store Outlook is a web wrapper. SKIP THIS if you use it for mail.
- *卸载新版 Outlook(网页套壳)* — *Store 版 Outlook 是网页套壳。如果你用它收发邮件，请跳过此项。*
- **Uninstalls:** `Microsoft.OutlookForWindows` and revokes its provisioning

### `apps.media-player` — Uninstall Media Player (ZuneMusic)

- **Risk:** 🟡 medium  ·  **Target:** `appx`  ·  **Presets:** `aggressive`
- **Why:** Groove successor with store promotions. SKIP if you play local media with it.
- *卸载媒体播放器(ZuneMusic)* — *Groove 的继任者，带商店推广。如果你用它播放本地媒体，请跳过。*
- **Uninstalls:** `Microsoft.ZuneMusic` and revokes its provisioning

### `apps.xbox` — Uninstall Xbox app & Game Bar overlay

- **Risk:** 🟡 medium  ·  **Target:** `appx`  ·  **Presets:** `aggressive`
- **Why:** Xbox app, Game Bar overlay, TCUI and identity provider. These are the pieces that pop up over games. SKIP if you use Game Pass, achievements or Game Bar recording.
- *卸载 Xbox 应用与 Game Bar 覆盖层* — *Xbox 应用、Game Bar 覆盖层、TCUI 与身份提供程序——就是在游戏上弹窗的那套。如果你用 Game Pass、成就或 Game Bar 录屏，请跳过。*
- **Uninstalls:** `Microsoft.GamingApp` and revokes its provisioning

### `apps.xbox-overlay` — Uninstall Xbox Game Bar overlay (TCUI)

- **Risk:** 🟡 medium  ·  **Target:** `appx`  ·  **Presets:** `aggressive`
- **Why:** The Xbox overlay shell. SKIP if you use Win+G recording.
- *卸载 Xbox Game Bar 覆盖层(TCUI)* — *Xbox 覆盖层外壳。如果你用 Win+G 录屏，请跳过。*
- **Uninstalls:** `Microsoft.XboxGamingOverlay` and revokes its provisioning

### `apps.solitaire` — Uninstall Solitaire Collection

- **Risk:** 🟢 low  ·  **Target:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** Ships with adverts inside the game.
- *卸载微软纸牌* — *游戏内自带广告。*
- **Uninstalls:** `Microsoft.MicrosoftSolitaireCollection` and revokes its provisioning

### `apps.office-hub` — Uninstall Office Hub placeholder

- **Risk:** 🟢 low  ·  **Target:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** A Store advert for Microsoft 365, not actual Office.
- *卸载 Office Hub 占位应用* — *这是 Microsoft 365 的商店广告，不是真正的 Office。*
- **Uninstalls:** `Microsoft.MicrosoftOfficeHub` and revokes its provisioning

### `apps.todos` — Uninstall Microsoft To Do

- **Risk:** 🟡 medium  ·  **Target:** `appx`  ·  **Presets:** `aggressive`
- **Why:** Task app. SKIP if you keep your to-do list here.
- *卸载 Microsoft To Do* — *待办应用。如果你在这里记待办，请跳过。*
- **Uninstalls:** `Microsoft.Todos` and revokes its provisioning

### `apps.feedback-hub` — Uninstall Feedback Hub

- **Risk:** 🟢 low  ·  **Target:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** Microsoft's feedback collection app.
- *卸载反馈中心* — *微软的反馈收集应用。*
- **Uninstalls:** `Microsoft.WindowsFeedbackHub` and revokes its provisioning

### `apps.get-help` — Uninstall Get Help

- **Risk:** 🟢 low  ·  **Target:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** Support contact app most users never open.
- *卸载获取帮助* — *多数人从不打开的技术支持应用。*
- **Uninstalls:** `Microsoft.GetHelp` and revokes its provisioning

### `apps.your-phone` — Uninstall Phone Link

- **Risk:** 🟡 medium  ·  **Target:** `appx`  ·  **Presets:** `aggressive`
- **Why:** Links your phone to the PC. SKIP if you use it.
- *卸载手机连接(Phone Link)* — *把手机连到电脑。如果你在用，请跳过。*
- **Uninstalls:** `Microsoft.YourPhone` and revokes its provisioning

### `apps.quick-assist` — Uninstall Quick Assist

- **Risk:** 🟡 medium  ·  **Target:** `appx`  ·  **Presets:** `aggressive`
- **Why:** Remote assistance tool. SKIP if your IT support uses it to help you.
- *卸载快速助手* — *远程协助工具。如果 IT 支持靠它帮你，请跳过。*
- **Uninstalls:** `MicrosoftCorporationII.QuickAssist` and revokes its provisioning

### `apps.sticky-notes` — Uninstall Sticky Notes

- **Risk:** 🟡 medium  ·  **Target:** `appx`  ·  **Presets:** `aggressive`
- **Why:** SKIP if you keep notes on your desktop.
- *卸载便笺* — *如果你在桌面上记便签，请跳过。*
- **Uninstalls:** `Microsoft.MicrosoftStickyNotes` and revokes its provisioning

### `apps.maps` — Uninstall Windows Maps

- **Risk:** 🟢 low  ·  **Target:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** Offline map app almost nobody opens on a desktop.
- *卸载 Windows 地图* — *台式机上几乎没人打开的离线地图。*
- **Uninstalls:** `Microsoft.WindowsMaps` and revokes its provisioning

### `apps.bing-news` — Uninstall Bing News

- **Risk:** 🟢 low  ·  **Target:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** Ad-funded news feed, usually arrives via silent install.
- *卸载 Bing 资讯* — *靠广告变现的资讯流，通常经静默安装落地。*
- **Uninstalls:** `Microsoft.BingNews` and revokes its provisioning

### `apps.bing-weather` — Uninstall Bing Weather

- **Risk:** 🟢 low  ·  **Target:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** Ad-funded weather app, usually arrives via silent install.
- *卸载 Bing 天气* — *靠广告变现的天气应用，通常经静默安装落地。*
- **Uninstalls:** `Microsoft.BingWeather` and revokes its provisioning

### `apps.bing-search` — Uninstall Bing Search app

- **Risk:** 🟢 low  ·  **Target:** `appx`  ·  **Presets:** `balanced`, `aggressive`
- **Why:** Web-search wrapper injected into the Start menu.
- *卸载 Bing 搜索应用* — *注入开始菜单的网页搜索套壳。*
- **Uninstalls:** `Microsoft.BingSearch` and revokes its provisioning

## OneDrive (`onedrive`) — 1 actions

Removes the OneDrive client binaries and blocks reinstall. Your OneDrive data folder is NEVER touched.

*移除 OneDrive 客户端程序并阻止重装。你的 OneDrive 数据目录【绝不会】被触碰。*

### `onedrive.uninstall` — Remove OneDrive client and block reinstall

- **Risk:** 🔴 high  ·  **Target:** `onedrive`  ·  **Presets:** `aggressive`
- **Why:** Deletes the OneDrive binaries and sets a machine policy that blocks sync and reinstall. YOUR DATA FOLDER IS NEVER TOUCHED — it stays on disk exactly as it is, and nothing is uploaded or deleted.
- *移除 OneDrive 客户端并阻止重装* — *删除 OneDrive 程序本体并设置机器级策略阻止同步与重装。你的数据目录【绝不会】被触碰——原样留在磁盘上，不会上传也不会删除。*
- **Removes:** OneDrive client binaries, blocks reinstall. The data folder is untouched.

## Privacy hardening (`privacy`) — 10 actions

Advertising ID, input personalization, implicit text/ink collection, location, settings sync and per-app diagnostic access.

*广告标识符、输入个性化、文本/手写隐式采集、定位、设置同步、应用诊断信息访问权限。*

### `privacy.advertising-id` — Turn off advertising ID

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Apps can no longer use a per-user advertising identifier to profile you.
- *关闭广告标识符* — *应用无法再用每用户广告标识符对你画像。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo\Enabled` = `0` (DWord)

### `privacy.input-personalization` — Disable input personalization

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Stops typing/inking data being collected to build a personal dictionary in the cloud.
- *关闭输入个性化* — *不再采集键入/手写数据用于构建云端个人词典。*
- **Sets:** `HKCU\Software\Microsoft\Input\TIPC\Enabled` = `0` (DWord)

### `privacy.implicit-text-collection` — Block implicit text collection

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Prevents Windows silently sampling your typing.
- *阻止文本隐式采集* — *阻止 Windows 静默采样你的输入内容。*
- **Sets:** `HKCU\Software\Microsoft\InputPersonalization\RestrictImplicitTextCollection` = `1` (DWord)

### `privacy.implicit-ink-collection` — Block implicit handwriting collection

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Prevents Windows sampling your handwriting.
- *阻止手写隐式采集* — *阻止 Windows 采样你的手写笔迹。*
- **Sets:** `HKCU\Software\Microsoft\InputPersonalization\RestrictImplicitInkCollection` = `1` (DWord)

### `privacy.handwriting-sharing` — Stop handwriting data sharing

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Blocks handwriting recognition data being shared with Microsoft.
- *停止手写数据共享* — *阻止手写识别数据被共享给微软。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC\PreventHandwritingDataSharing` = `1` (DWord)

### `privacy.location` — Disable location services

- **Risk:** 🟡 medium  ·  **Target:** `registry`  ·  **Presets:** `aggressive`
- **Why:** Turns off system location. Trade-off: Maps, weather and 'find my device' become less useful.
- *关闭定位服务* — *关闭系统定位。代价：地图、天气、“查找我的设备”等功能受限。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors\DisableLocation` = `1` (DWord)

### `privacy.settings-sync` — Disable settings sync to Microsoft account

- **Risk:** 🟡 medium  ·  **Target:** `registry`  ·  **Presets:** `aggressive`
- **Why:** Stops your personalisation settings syncing to the cloud. Trade-off: settings no longer follow you to other PCs.
- *关闭设置同步到微软账号* — *不再把个性化设置同步到云端。代价：换电脑时设置不再跟随。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\SettingSync\SyncPolicy` = `0` (DWord)

### `privacy.app-diagnostic-access` — Block apps reading diagnostic information

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Per-app permission: no app may read diagnostic data about your device.
- *禁止应用读取诊断信息* — *逐应用权限：任何应用都不得读取你设备的诊断数据。*
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy\LetAppsAccessDiagnosticInformation` = `2` (DWord)

### `privacy.feedback-frequency` — Never ask for feedback

- **Risk:** 🟢 low  ·  **Target:** `registry`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Sets the feedback request cadence to zero.
- *永不请求反馈* — *把反馈请求频率设为 0。*
- **Sets:** `HKCU\Software\Microsoft\Siuf\Rules\NumberOfSIUFInPeriod` = `0` (DWord)

### `privacy.delivery-optimization-no-p2p` — Stop Delivery Optimization peer-to-peer sharing

- **Risk:** 🟡 medium  ·  **Target:** `registry`  ·  **Presets:** `aggressive`
- **Why:** Your PC stops uploading update fragments to strangers. Trade-off: slightly slower updates. The service itself is kept enabled.
- *关闭传递优化 P2P 共享* — *你的电脑不再向陌生人上传更新分片。代价：更新可能略慢。服务本身保留启用。*
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization\DODownloadMode` = `0` (DWord)

## Ad image cache & wallpaper (`cache`) — 1 actions

Deletes already-downloaded Spotlight ad images. Refuses to touch your current wallpaper or its transcoded copy.

*删除已下载的 Spotlight 广告图。不会触碰你当前的壁纸及其转码副本。*

### `cache.spotlight-images` — Delete downloaded Spotlight ad images

- **Risk:** 🟡 medium  ·  **Target:** `path-clean`  ·  **Presets:** `conservative`, `balanced`, `aggressive`
- **Why:** Removes already-downloaded promotional images. It does NOT touch your wallpaper or its transcoded copy.
- *删除已下载的 Spotlight 广告图* — *删除已下载的推广图片。不会触碰你的壁纸及其转码副本。*
- **Deletes cached files in:**
  - `%LOCALAPPDATA%\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets`
  - `%LOCALAPPDATA%\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\StagedAssets`
  - `%LOCALAPPDATA%\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\TargetedContentCache`
  - `%LOCALAPPDATA%\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Tips`

---

Generated from `catalog/catalog.json`. Do not edit by hand.
