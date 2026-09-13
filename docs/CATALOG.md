<!-- GENERATED FILE - do not edit by hand.
     Regenerate with:  pwsh -File tools/New-CatalogDoc.ps1
     CI verifies this file is current (tools/New-CatalogDoc.ps1 -Check). -->

[English](CATALOG.md) · [中文](CATALOG.zh-CN.md) · [README](../README.md) · [中文说明](../README.zh-CN.md)

# Action catalog

**74 actions across 6 categories.** Generated from [`catalog/catalog.json`](../catalog/catalog.json).

Every action appears below with its English and Chinese text, what it changes, and
whether it is part of the default selection. `default` marks the small, low-trade-off
set the tool checks when it starts; everything else is opt-in and nothing re-adds an
action you have turned off. Each action's `why` string is where the trade-off is stated.

## Default selection

**45 of 74 actions** are selected when the tool starts. The rest are opt-in: turn on
whatever you actually want, and nothing puts back something you turned off.

## Ads & suggestions — 系统广告与推荐

`ads` · 22 actions

Turns off commercial promotions, sponsored pins, and bloat across Windows 11: Start menu recommendations, lock-screen and desktop Spotlight ad images, Bing search-box trending topics, MSN widget feeds, and Edge default-browser nag prompts. Safe with no impact on core system capabilities.

全面关闭 Windows 11 各处的商业推广与“牛皮癣”。涵盖开始菜单“推荐”应用、锁屏与桌面 Spotlight 赞助壁纸、搜索框必应联网资讯热搜、任务栏小组件信息流以及 Edge 浏览器的捆绑弹窗。安全无副作用，不影响正常系统功能。

### `ads.cdm.silent-install` — Forbid silent app installation

**禁止静默自动安装应用**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Stops ContentDeliveryManager silently downloading and pinning sponsored apps (e.g. TikTok, games) into your Start menu without your consent. Safe with no side effects; does not affect apps you deliberately choose to install from the Store.
- **代价 / Cost:** 阻止云内容提供程序（ContentDeliveryManager）在后台静默下载推广软件。Windows 经常不经提示就在开始菜单里偷偷塞进社交或小游戏应用。关闭后杜绝后台自动偷渡，不影响手动在微软商店安装软件。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SilentInstalledAppsEnabled` = `0` (DWord)

### `ads.cdm.subscribed-content` — Disable subscribed content (recommendations/ads)

**关闭订阅内容(推荐/广告)**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Master switch for all personalized commercial subscription payloads pushed to your user account. Blocks marketing banners and suggestions delivered under the guise of 'tips' or 'daily inspiration'.
- **代价 / Cost:** 微软向当前用户账号推送个性化商业订阅内容的总开关。关闭后直接阻断以“系统提示”、“玩机灵感”、“特别推荐”为名的营销卡片投递。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SubscribedContentEnabled` = `0` (DWord)

### `ads.cdm.spotlight-desktop` — Disable Windows Spotlight desktop ad

**关闭桌面 Spotlight 广告图**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables desktop background Spotlight promotional photos (subscription ID 338389), which push sponsored wallpapers and icons directly onto your desktop workspace.
- **代价 / Cost:** 关闭桌面背景上的 Windows 聚焦推广图。微软利用订阅内容 338389 将带有赞助商推广链接的图片作为桌面壁纸推送。关闭后恢复纯净的自定义壁纸。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SubscribedContent\338389` = `0` (DWord)

### `ads.cdm.lockscreen-overlay` — Disable lock screen ad overlay

**关闭锁屏广告浮层**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables the interactive 'fun facts, tips and tricks' text bubbles rendered on your lock screen, which are promotional hooks to Bing searches and Microsoft services.
- **代价 / Cost:** 关闭锁屏界面上覆盖的“有趣的事实、提示和技巧”交互气泡。表面上是趣味小知识，实则是引导你点击必应搜索或 Edge 服务的广告位。关闭后锁屏界面仅显示干净的时钟与日期。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\RotatingLockScreenOverlayEnabled` = `0` (DWord)

### `ads.cdm.lockscreen-spotlight` — Disable lock screen Spotlight rotation

**关闭锁屏 Spotlight 轮播**

- **Target / 类型:** `registry`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Stops Windows rotating lock-screen Spotlight pictures, which serve as the primary delivery pipeline for sponsored wallpapers. Trade-off: lock screen uses your selected static image instead of rotating online photos.
- **代价 / Cost:** 停止锁屏界面的 Windows 聚焦轮播壁纸。微软借由此轮播管道推送商业赞助图片与必应资讯。取舍：关闭后锁屏将固定为你挑选的单张壁纸，不再每日自动更换网络壁纸。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\RotatingLockScreenEnabled` = `0` (DWord)

### `ads.cdm.system-pane-suggestions` — Disable Settings / Start suggestions

**关闭设置与开始菜单建议**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Removes promotional cards and app recommendations injected into the Settings app and Start menu, such as prompts urging you to subscribe to Game Pass or buy OneDrive storage.
- **代价 / Cost:** 移除注入到“设置”应用主页、侧边栏及开始菜单里的推荐应用卡片。例如不断提示你试用 Game Pass 或 OneDrive 扩容。关闭后设置界面回归工具属性。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SystemPaneSuggestionsEnabled` = `0` (DWord)

### `ads.cdm.content-delivery` — Disable content delivery

**关闭内容推送**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables the background content delivery pipeline that queries Microsoft servers and pulls down promotional payloads, tips, and marketing notifications.
- **代价 / Cost:** 关闭 Windows 云端内容分发系统的通用接收管道。该组件负责定时从微软服务器轮询并拉取最新推广配置。关闭后切断系统拉取新推广位的数据流。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\ContentDeliveryAllowed` = `0` (DWord)

### `ads.cdm.oem-preinstalled` — Disable OEM preinstalled app promotions

**禁止 OEM 预装应用推广**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Blocks sponsored promotion slots provided by PC manufacturers (OEMs), preventing preinstalled partner bloat from pushing software suggestions.
- **代价 / Cost:** 阻止品牌电脑厂商（OEM）与微软合作的应用推广展示槽位。常见于新机预装的应用捆绑推荐。关闭后阻止厂商合作软件的二次推广。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\OemPreInstalledAppsEnabled` = `0` (DWord)

### `ads.cdm.soft-landing` — Disable soft landing / welcome pages

**关闭欢迎与提示落地页**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Stops the full-screen 'Let's finish setting up your device' and 'Look what you can do' post-update landing screens that push Microsoft 365, OneDrive, and Edge.
- **代价 / Cost:** 关闭大版本系统更新后自动弹出的全屏欢迎屏（“了解你能做什么”）。该界面常在开机时强制接管桌面推销 Microsoft 365 与 Edge。关闭后更新完直接进桌面。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SoftLandingEnabled` = `0` (DWord)

### `ads.start.iris-recommendations` — Remove Start menu Recommended section ads

**移除开始菜单“推荐”区推广**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Clears sponsored app suggestions from the 'Recommended' section of the Windows 11 Start menu (Iris pipeline), showing only your actual recent documents.
- **代价 / Cost:** 移除 Windows 11 开始菜单下方“推荐的项目”区域中的推广内容（Iris 推广管线）。关闭后该区域仅保留你自己真正打开过的最近文件，不再混入赞助应用。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_IrisRecommendations` = `0` (DWord)

### `ads.start.track-docs` — Disable recent-file suggestions

**关闭最近使用文件建议**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables tracking recently opened files for recommendations. Recommended if you share your screen or want to prevent personal documents being exposed in Start and Explorer.
- **代价 / Cost:** 停止记录并展示最近打开的文件列表作为建议。如果你注重个人隐私，不希望在旁人面前打开开始菜单或资源管理器时泄露最近浏览文档，可关闭此项。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_TrackDocs` = `0` (DWord)

### `ads.taskbar.widgets-button` — Hide taskbar Widgets button

**隐藏任务栏小组件按钮**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Hides the Taskbar Widgets button, which loads an MSN entertainment and sponsored clickbait feed that consumes background memory and network bandwidth.
- **代价 / Cost:** 隐藏任务栏左侧（或居中）的“天气/小组件”按钮。点击或鼠标悬停会滑出庞大的 MSN 资讯流、娱乐八卦与赞助广告，且持续占用系统内存与网络带宽。关闭后释放任务栏空间。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa` = `0` (DWord)

### `ads.taskbar.chat-button` — Hide taskbar Chat (Teams) button

**隐藏任务栏聊天(Teams)按钮**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Hides the consumer Teams Chat button permanently pinned to the taskbar. Removes promotional clutter; does not affect Microsoft Teams for Work or School.
- **代价 / Cost:** 隐藏任务栏常驻的“聊天”按钮（基于 Microsoft Teams 消费版）。大多数国内用户并不使用此服务，属于占位推广。关闭后隐藏该图标，不影响企业版 Teams。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarMn` = `0` (DWord)

### `ads.desktop.learn-about-picture` — Hide desktop 'Learn about this picture' icon

**隐藏桌面“了解此图片”图标**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Hides the unremovable 'Learn about this picture' icon pinned to your desktop wallpaper by Spotlight, which launches Edge searches whenever clicked.
- **代价 / Cost:** 隐藏启用聚焦壁纸时强行置顶在桌面右上角的“了解此图片”快捷方式图标。无法常规右键删除，点击即强开 Edge 搜索。此项通过注册表策略将其彻底隐藏。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel\{2cc5ca98-6485-489a-920e-b3e88a6ccce3}` = `1` (DWord)

### `ads.search.box-suggestions` — Disable search box web suggestions

**关闭搜索框联网推荐**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables Bing web search and trending sponsored topics inside the taskbar search box. Keeps your search local, stops keystroke upload to Bing, and makes search instantly responsive.
- **代价 / Cost:** 关闭任务栏搜索框内的联机必应搜索、热搜榜单与赞助推荐。开启时你每次本地搜文件都在向必应上报按键。关闭后搜索框变回纯净的本地文件与应用搜索，响应大幅变快。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer\DisableSearchBoxSuggestions` = `1` (DWord)

### `ads.settings.hide-home-promos` — Hide Settings home page promos

**隐藏设置首页推广区块**

- **Target / 类型:** `registry`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Hides promotional banners (Microsoft 365 trials, OneDrive upsell alerts) from the Settings Home tab. Trade-off: folds the promotional landing area to show clean settings categories directly.
- **代价 / Cost:** 隐藏 Windows 11“设置”应用主页顶部的 Microsoft 365 试用推广、OneDrive 空间预警卡片与常用建议横幅。使设置页恢复整洁布局。取舍：设置主页将被折叠，直接展示系统设置分类。
- **Sets:** `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\SettingsPageVisibility` = `hide:home` (String)

### `ads.edge.promo-tabs` — Disable Edge promotional tabs & recommendations

**关闭 Edge 推广标签页与推荐**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Stops Microsoft Edge opening unsolicited 'What's new' and promotional tabs following Windows updates. Does not uninstall, break, or disable the Edge browser itself.
- **代价 / Cost:** 关闭微软 Edge 浏览器在系统或浏览器更新后自动抢占前台弹出的“体验全新功能”和推广标签页。关闭该策略后 Edge 在启动时不再强弹推销页，浏览器本身功能完好保留。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\PromotionalTabsEnabled` = `0` (DWord)

### `ads.edge.default-browser-popup` — Disable 'set Edge as default' popup

**关闭“将 Edge 设为默认”弹窗**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Stops persistent popups and banner notifications urging you to switch your default browser back to Edge when another browser is set as default.
- **代价 / Cost:** 当默认浏览器不是 Edge 时，关闭 Windows 和 Edge 反复弹窗劝阻“建议将 Edge 设为默认以获得最佳体验”。关闭后不再骚扰你切换默认浏览器。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Edge\DefaultBrowserSettingEnabled` = `0` (DWord)

### `ads.cloudcontent.consumer-features` — Disable Windows consumer features

**禁止 Windows 消费者功能**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Machine-wide policy that blocks automatic background installation of third-party consumer apps, games, and trial software. Commonly deployed on enterprise workstations.
- **代价 / Cost:** 计算机级别的云内容消费者体验策略。阻止微软在后台批量推送非核心内置应用（如试玩游戏、流媒体试用客户端）。是企业级系统镜像常用的减负策略。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableWindowsConsumerFeatures` = `1` (DWord)

### `ads.cloudcontent.spotlight-features` — Disable Spotlight features

**禁用 Spotlight 特性**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables Windows Spotlight promotional features at the machine policy level, preventing updates from re-enabling sponsored wallpapers.
- **代价 / Cost:** 在组策略级别全局禁用 Windows Spotlight 的商业推广功能。防止系统更新重置后相关广告图再次被重新激活。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableWindowsSpotlightFeatures` = `1` (DWord)

### `ads.cloudcontent.third-party-suggestions` — Disable third-party app suggestions

**禁用第三方应用推荐**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables third-party app and subscription promotions sponsored by commercial partners, ensuring Windows only suggests essential native utilities.
- **代价 / Cost:** 阻止微软通过 Windows 云服务向当前设备下发带有商业赞助属性的第三方应用推荐与优惠信息。保证系统建议仅包含核心系统使用技巧。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableThirdPartySuggestions` = `1` (DWord)

### `ads.cloudcontent.tailored-experiences` — Opt out of tailored experiences

**退出定制化体验**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Opts out of 'Tailored Experiences', preventing Microsoft from using your diagnostic telemetry and usage patterns to deliver targeted ads and personalized marketing.
- **代价 / Cost:** “针对性体验”功能。微软会将你的诊断数据、应用使用频率与设备配置关联，向你投放精准定制广告。关闭后切断诊断数据与广告推送之间的联动。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableTailoredExperiencesWithDiagnosticData` = `1` (DWord)

## Telemetry & diagnostics — 遥测与诊断数据

`telemetry` · 21 actions

Stops background diagnostic data collection and tracking: the DiagTrack service, compatibility appraiser tasks, CEIP customer experience logs, error reporting pipelines, and feedback nags. Reduces background CPU, disk I/O, and network wakeups while preserving essential Windows updates.

全面收拢系统的诊断数据上传。包括核心遥测服务（DiagTrack）、计划任务（兼容性评估、CEIP 用户体验改善计划）、错误报告上报通道，减轻后台网络与磁盘唤醒，降低隐私暴露，同时完全保留日常安全与质量更新。

### `telemetry.policy.allow-telemetry` — Set diagnostic data to lowest allowed level

**诊断数据设为最低级别**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Sets AllowTelemetry to 0 (Security/Required minimum). Essential security updates and patch delivery continue unaffected, while personal activity logs are stripped from telemetry.
- **代价 / Cost:** 将系统的诊断数据级别调至官方允许的最低档（0=Security/Enterprise 或 1=Basic/Required）。安全补丁与必要更新机制不受任何影响，但大幅削减日常操作特征的上传。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry` = `0` (DWord)

### `telemetry.policy.allow-telemetry-legacy` — Set legacy AllowTelemetry to 0

**旧位置 AllowTelemetry 设为 0**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Applies the AllowTelemetry=0 policy to the legacy registry path read by older Windows builds and compatibility components, ensuring telemetry reduction survives across updates.
- **代价 / Cost:** 针对 Windows 10/11 旧版分支和部分兼容补丁读取的备用注册表路径设置 AllowTelemetry=0，双重锁定确保策略在全版本各更新分支均稳定生效。
- **Sets:** `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection\AllowTelemetry` = `0` (DWord)

### `telemetry.policy.one-settings` — Disable OneSettings downloads

**禁止 OneSettings 配置下载**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Blocks downloading remote OneSettings payloads used by Microsoft for A/B testing and dynamic feature staging, keeping your local system configuration predictable.
- **代价 / Cost:** OneSettings 是微软在后台动态下发 A/B 测试、灰度实验和配置参数的管道。关闭后系统停止下载此类云端动态策略，保持系统配置稳定不漂移。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\DisableOneSettingsDownloads` = `1` (DWord)

### `telemetry.policy.no-feedback-prompts` — Stop Windows asking for feedback

**不再请求反馈**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables intrusive feedback request notifications asking 'How likely are you to recommend Windows 11?' or prompting you to rate recent features.
- **代价 / Cost:** 关闭系统时不时右下角弹出的“你对该功能满意吗？”“给 Windows 11 打分”等满意度调查弹窗。保持日常工作专注不被打扰。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\DoNotShowFeedbackNotifications` = `1` (DWord)

### `telemetry.appcompat.ait` — Disable Application Impact Telemetry

**关闭应用影响遥测(AIT)**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables Application Impact Telemetry (AIT), which monitors launched executables and uploads app compatibility telemetry, reducing software inventory fingerprinting.
- **代价 / Cost:** 应用程序影响遥测（Application Impact Telemetry）。后台扫描你启动的每一个桌面可执行文件，收集崩溃与兼容性指标并上传。关闭可减少对你个人软件库的指纹采集。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat\AITEnable` = `0` (DWord)

### `telemetry.appcompat.inventory` — Disable installed-app inventory collection

**关闭已装应用清单采集**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Blocks the inventory collector from cataloging and transmitting your complete list of installed applications, software versions, and local drivers to Microsoft.
- **代价 / Cost:** 已安装软件清单收集器。系统会定时清点你电脑上安装的所有软件版本、路径与驱动信息并上传给微软。关闭后停止上传个人软件安装清单。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat\DisableInventory` = `1` (DWord)

### `telemetry.appcompat.uar` — Disable User Activity Recording

**关闭用户活动记录**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Stops the User Activity Record engine logging application usage duration, window switching patterns, and workflow habits for telemetry analysis.
- **代价 / Cost:** 用户活动记录器（User Activity Record）。在后台记录你打开应用的时长、切换频率与活跃状态。关闭后杜绝系统对你工作时段和使用习惯的持续统计。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat\DisableUAR` = `1` (DWord)

### `telemetry.ceip` — Turn off Customer Experience Improvement Program

**关闭客户体验改善计划(CEIP)**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Formally opts out of the Windows Customer Experience Improvement Program (CEIP), disabling background metrics generation and periodic telemetry packaging.
- **代价 / Cost:** 彻底退出 Windows 客户体验改善计划（Customer Experience Improvement Program）。不再为该计划生成匿名机器运行数据与指标包。
- **Sets:** `HKLM\SOFTWARE\Microsoft\SQMClient\Windows\CEIPEnable` = `0` (DWord)

### `telemetry.wer.disabled` — Disable Windows Error Reporting

**关闭 Windows 错误报告**

- **Target / 类型:** `registry`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Stops Windows Error Reporting automatically transmitting crash dumps and memory states to Microsoft servers. Trade-off: crash data will not be uploaded for vendor analysis.
- **代价 / Cost:** 关闭 Windows 错误报告（WER）的自动向外发送机制。当应用闪退或崩溃时，系统不再将内存转储和上下文日志传输给微软服务器。代价：微软不会自动收到你的崩溃日志来修复第三方软件 bug。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting\Disabled` = `1` (DWord)

### `telemetry.svc.diagtrack` — Disable DiagTrack service

**禁用 DiagTrack 服务**

- **Target / 类型:** `service`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables the Connected User Experiences and Telemetry (DiagTrack) service — the primary background collector on Windows. Substantially reduces background disk I/O and RAM usage.
- **代价 / Cost:** “已连接用户体验和遥测”核心服务（Connected User Experiences and Telemetry）。Windows 最主要的遥测后台守护进程，负责打包上传各种数据并常驻占用内存与磁盘 I/O。禁用后立竿见影降低系统闲置开销。
- **Sets:** service `DiagTrack` start type to `Disabled`

### `telemetry.svc.dmwappushservice` — Disable dmwappushservice

**禁用 dmwappushservice**

- **Target / 类型:** `service`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables dmwappushservice (WAP Push Message Routing Service), which routes push payloads for telemetry channels. Safe to disable on standalone desktop and laptop PCs.
- **代价 / Cost:** 设备管理 WAP 推送消息路由服务。主要为 Windows 遥测管道和移动设备管理提供后台路由通道。对于普通家庭或办公 PC 毫无用处，禁用可减少后台端口侦听与唤醒。
- **Sets:** service `dmwappushservice` start type to `Disabled`

### `telemetry.svc.wdi` — Disable Windows diagnostic infrastructure services

**禁用 Windows 诊断基础结构服务**

- **Target / 类型:** `service`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables WdiServiceHost, which executes local diagnostic scenario tracing and performance monitoring. Safe to turn off if you do not rely on automatic diagnostic troubleshooting.
- **代价 / Cost:** Windows 诊断基础结构服务主机（WdiServiceHost）。用于在后台运行诊断方案、跟踪性能问题。如果你不需要系统在后台自动收集系统性能瓶颈日志，可以安全禁用。
- **Sets:** service `WdiServiceHost` start type to `Disabled`

### `telemetry.svc.wdi-system` — Disable WdiSystemHost service

**禁用 WdiSystemHost 服务**

- **Target / 类型:** `service`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables WdiSystemHost, the system-level partner to WdiServiceHost for elevated diagnostic troubleshooting and metric generation. Cuts down passive event logging.
- **代价 / Cost:** 诊断系统宿主服务（WdiSystemHost）。与 WdiServiceHost 协同，以 SYSTEM 权限执行系统级故障诊断与数据记录。禁用后进一步降低系统日志开销。
- **Sets:** service `WdiSystemHost` start type to `Disabled`

### `telemetry.svc.wer` — Disable Windows Error Reporting service

**禁用 Windows 错误报告服务**

- **Target / 类型:** `service`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Disables the Windows Error Reporting Service (WerSvc). Trade-off: Windows will not show the 'Searching for solutions' dialog or queue error reports following application crashes.
- **代价 / Cost:** 禁用 Windows 错误报告系统服务（WerSvc）。负责在程序崩溃或系统出现问题时启动收集与报告流程。代价：禁用后遇到程序崩溃不会弹出“正在查找解决方案”窗口，也不会生成错误上报日志。
- **Sets:** service `WerSvc` start type to `Disabled`

### `telemetry.svc.pcasvc` — Disable Program Compatibility Assistant service

**禁用程序兼容性助手服务**

- **Target / 类型:** `service`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Disables the Program Compatibility Assistant Service (PcaSvc). Trade-off: removes compatibility nag dialogs when running legacy installers, but modern applications are completely unaffected.
- **代价 / Cost:** 程序兼容性助手服务（PcaSvc）。监视旧程序的运行状况，并在检测到可能不兼容时弹出提示并上报数据。代价：老旧过时软件初次安装时可能不会自动弹出“以推荐设置重新安装”向导。现代软件完全不受影响。
- **Sets:** service `PcaSvc` start type to `Disabled`

### `telemetry.task.appraiser` — Disable Compatibility Appraiser task

**禁用兼容性评估任务**

- **Target / 类型:** `task`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables the Microsoft Compatibility Appraiser scheduled task — notorious for causing 100% disk usage and high CPU spikes during idle periods and boot.
- **代价 / Cost:** 兼容性评估计划任务（Microsoft Compatibility Appraiser）。Windows 系统中唤醒最频繁、CPU/磁盘占用最高的遥测任务之一，常在开机或空闲时导致磁盘占用 100%。禁用后显著改善老机型卡顿。
- **Disables:** scheduled task `\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp`

### `telemetry.task.consolidator` — Disable CEIP Consolidator task

**禁用 CEIP 汇总上传任务**

- **Target / 类型:** `task`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables the CEIP Consolidator task, which wakes periodically to aggregate and package daily user experience and performance logs for upload.
- **代价 / Cost:** 客户体验改善计划数据汇总计划任务（Consolidator）。每天定期唤醒，将收集到的使用习惯、性能指标打包压缩准备发送。禁用后消除每日定时后台唤醒。
- **Disables:** scheduled task `\Microsoft\Windows\Customer Experience Improvement Program\Consolidator`

### `telemetry.task.usbceip` — Disable USB CEIP task

**禁用 USB 使用数据采集任务**

- **Target / 类型:** `task`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables the USB CEIP task, which tracks the hardware IDs and insertion frequencies of connected USB peripherals, flash drives, and external storage.
- **代价 / Cost:** 通用串行总线（USB）使用数据收集任务。记录并上传你插拔 USB 设备（U盘、移动硬盘、键盘鼠标）的硬件 ID 与工作频率。禁用后保障外部存储和外设的连接隐私。
- **Disables:** scheduled task `\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip`

### `telemetry.task.dmclient` — Disable feedback upload tasks

**禁用反馈上传任务**

- **Target / 类型:** `task`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables the DmClient tasks responsible for uploading user feedback logs and fetching remote diagnostic scenarios for background execution.
- **代价 / Cost:** 反馈与场景下载计划任务（DmClient 与 DmClientOnScenarioDownload）。负责检查并上传反馈数据及下载远程诊断场景。个人设备不需要此上传通道。
- **Disables:** scheduled task `\Microsoft\Windows\Feedback\Siuf\DmClient`

### `telemetry.task.marebackup` — Disable MareBackup task

**禁用 MareBackup 任务**

- **Target / 类型:** `task`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Disables the MareBackup maintenance task, which backs up application repository states for compatibility appraiser telemetry.
- **代价 / Cost:** 微软应用程序遥测备份任务（Microsoft Application Repository Exp Backup）。负责在应用更新后备份并上报兼容性评估状态。禁用无副作用。
- **Disables:** scheduled task `\Microsoft\Windows\Application Experience\MareBackup`

### `telemetry.task.queuereporting` — Disable error report queue task

**禁用错误报告排队任务**

- **Target / 类型:** `task`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables the QueueReporting task, which queues pending crash dumps and background error reports for scheduled upload once an internet connection is verified.
- **代价 / Cost:** 错误报告队列发送任务（QueueReporting）。负责将离线时产生的错误报告在后台排队，一旦检测到联网便尝试静默上传。禁用可彻底断开错误报告的重试通道。
- **Disables:** scheduled task `\Microsoft\Windows\Windows Error Reporting\QueueReporting`

## Preinstalled apps — 预装应用

`apps` · 19 actions

Uninstalls bundled consumer, entertainment, and promotional UWP apps, and revokes their system-wide provisioning so they never silently reinstall after Windows updates. All removed apps can be reinstalled for free from the Microsoft Store anytime.

批量卸载 Windows 11 自带的各类消费级、娱乐与推广 UWP 应用，并撤销其系统预置（Provisioned）包，防止新用户登录或系统大版本更新时“诈尸”自动重装。所有被卸载的应用均可在微软应用商店（Microsoft Store）免费装回。

### `apps.clipchamp` — Uninstall Clipchamp

**卸载 Clipchamp**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Bundled video editor with upsell subscriptions and export paywalls. If you use CapCut, DaVinci, or Premiere, uninstalling is safe. Can be reinstalled from the Microsoft Store anytime.
- **代价 / Cost:** 微软收购并预装的轻量级视频剪辑工具。内置大量付费模板与导出限制订阅。如果你习惯使用剪映、PR、达芬奇等专业工具，可放心卸载；需要时可随时在微软商店免费下回。
- **Uninstalls:** `Clipchamp.Clipchamp` and revokes its provisioning

### `apps.devhome` — Uninstall Dev Home

**卸载 Dev Home**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Developer dashboard preinstalled on Windows 11 featuring GitHub widgets and system monitors. Unnecessary for general users and safe to remove.
- **代价 / Cost:** 面向开发者的 Windows 开发人员主页（Dev Home）。集成了 GitHub 小组件与开发环境监测工具。对于非开发者而言纯属后台占位常驻，卸载不会对日常使用造成任何影响。
- **Uninstalls:** `Microsoft.Windows.DevHome` and revokes its provisioning

### `apps.power-automate` — Uninstall Power Automate

**卸载 Power Automate**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Low-code desktop workflow automation tool with background agent services. Safely removable for users who do not run automated desktop scripts.
- **代价 / Cost:** 微软的低代码自动化桌面流程工具。在后台注册了常驻自动化代理服务。普通用户几乎用不到，卸载可释放系统空间并消除后台服务开销。
- **Uninstalls:** `Microsoft.PowerAutomateDesktop` and revokes its provisioning

### `apps.outlook-new` — Uninstall new Outlook (web wrapper)

**卸载新版 Outlook(网页套壳)**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Web-wrapper version of Outlook pushed to replace Windows Mail. Contains banner ads and lacks offline PST support. Trade-off: skip if this is your primary email client.
- **代价 / Cost:** Windows 11 强推的新版 Outlook。本质上是基于 Web 技术的网页套壳应用，界面内嵌广告且无法本地离线缓存 PST/OST 文件。取舍：如果你以此为日常邮箱客户端，请取消勾选。
- **Uninstalls:** `Microsoft.OutlookForWindows` and revokes its provisioning

### `apps.media-player` — Uninstall Media Player (ZuneMusic)

**卸载媒体播放器(ZuneMusic)**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Modern Media Player (successor to Groove Music) with Store media hooks. Trade-off: skip if you use it for local playback; recommended to remove if using PotPlayer or VLC.
- **代价 / Cost:** 系统新版媒体播放器（原 Groove 音乐）。界面包含商店音乐推荐与引流。取舍：如果你平时用它播放本地音乐或视频请保留；如已安装 PotPlayer、VLC 等第三方播放器则推荐卸载。
- **Uninstalls:** `Microsoft.ZuneMusic` and revokes its provisioning

### `apps.xbox` — Uninstall Xbox app & Game Bar overlay

**卸载 Xbox 应用与 Game Bar 覆盖层**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Xbox gaming hub, companion app, and identity providers. Trade-off: skip if you subscribe to PC Game Pass, play Xbox Store games, or track achievements. Safe to remove for non-gamers.
- **代价 / Cost:** Xbox 游戏生态核心应用，包含好友列表、游戏库、Xbox 社交服务与身份提供程序。取舍：如果你订阅了 PC Game Pass、需要在电脑上玩 Xbox 游戏或同步 Xbox 成就，请跳过此项！普通非玩家可安全卸载。
- **Uninstalls:** `Microsoft.GamingApp` and revokes its provisioning

### `apps.xbox-overlay` — Uninstall Xbox Game Bar overlay (TCUI)

**卸载 Xbox Game Bar 覆盖层(TCUI)**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Xbox Game Bar TCUI overlay UI invoked with Win+G. Trade-off: skip if you use Win+G to capture gameplay clips, monitor FPS, or record screens.
- **代价 / Cost:** Xbox Game Bar 浮层外壳组件（TCUI）。就是游戏中按 Win+G 弹出的半透明游戏栏。取舍：如果你经常使用 Win+G 快捷键截屏、录屏或监控显卡帧率，请跳过此项；否则可直接卸载。
- **Uninstalls:** `Microsoft.XboxGamingOverlay` and revokes its provisioning

### `apps.solitaire` — Uninstall Solitaire Collection

**卸载微软纸牌**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Microsoft Solitaire Collection, now heavily monetized with full-screen video ads and premium subscriptions. Cleanly removable and reinstallable from the Store.
- **代价 / Cost:** 微软纸牌集合（Microsoft Solitaire Collection）。原本经典的休闲游戏现已被微软植入大量全屏视频广告和月费去广告内购。卸载可净化系统，想玩时可随时在微软商店重新安装。
- **Uninstalls:** `Microsoft.MicrosoftSolitaireCollection` and revokes its provisioning

### `apps.office-hub` — Uninstall Office Hub placeholder

**卸载 Office Hub 占位应用**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Microsoft 365 promotional hub and Store placeholder. Not the real Office suite; exists only to promote subscriptions and redirect to Office Online.
- **代价 / Cost:** “Microsoft 365 / Office”应用占位符。这并不是真正的 Word、Excel 办公套件，而是一个纯粹引导你购买订阅并跳转网页版 Office 的宣传入口。卸载对你本地已安装的 Office 毫无影响。
- **Uninstalls:** `Microsoft.MicrosoftOfficeHub` and revokes its provisioning

### `apps.todos` — Uninstall Microsoft To Do

**卸载 Microsoft To Do**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Microsoft To Do task management app. Trade-off: skip if you sync tasks with Microsoft accounts; safe to remove if using Notion, TickTick, or pen and paper.
- **代价 / Cost:** 微软 Microsoft To Do 待办任务清单应用。取舍：如果你正在使用微软待办来同步日常任务与日程，请跳过；如果你使用滴答清单、Notion 或不用待办应用，可放心卸载。
- **Uninstalls:** `Microsoft.Todos` and revokes its provisioning

### `apps.feedback-hub` — Uninstall Feedback Hub

**卸载反馈中心**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Windows Feedback Hub used to submit system telemetry and bug tickets. Unnecessary for users who just want a stable, uninterrupted workstation.
- **代价 / Cost:** Windows 反馈中心（Feedback Hub）。用于提交系统建议和 bug 报告。对于绝大多数只希望稳定使用系统、不想做微软“志愿测试员”的用户而言完全没有用处，卸载无害。
- **Uninstalls:** `Microsoft.WindowsFeedbackHub` and revokes its provisioning

### `apps.get-help` — Uninstall Get Help

**卸载获取帮助**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** The 'Get Help' troubleshooter app. Primarily serves generic virtual agent responses and support article links; safe to remove.
- **代价 / Cost:** “获取帮助”诊断应用。点击常见设置问题时系统常调起此应用，但其给出的多数是通用的 AI 回复或知识库网页链接。卸载不会影响 Windows 正常使用。
- **Uninstalls:** `Microsoft.GetHelp` and revokes its provisioning

### `apps.your-phone` — Uninstall Phone Link

**卸载手机连接(Phone Link)**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Phone Link app for syncing Android and iOS text messages, calls, and notifications. Trade-off: skip if you use cross-device phone integration.
- **代价 / Cost:** “手机连接”应用（Phone Link）。用于在电脑上同步安卓/苹果手机的通知、短信和照片。取舍：如果你经常在电脑上接打电话或看手机通知，请保留；如果不喜欢电脑连手机，可彻底卸载。
- **Uninstalls:** `Microsoft.YourPhone` and revokes its provisioning

### `apps.quick-assist` — Uninstall Quick Assist

**卸载快速助手**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Quick Assist remote desktop assistance tool using 6-digit session codes. Trade-off: skip if your corporate IT or family members use it to help you remotely.
- **代价 / Cost:** “快速助手”远程桌面协助工具。允许通过 6 位安全代码进行远程桌面共享和技术支持。取舍：如果你的企业 IT 或家人常通过此功能远程协助你修电脑，请跳过；否则可安全卸载。
- **Uninstalls:** `MicrosoftCorporationII.QuickAssist` and revokes its provisioning

### `apps.sticky-notes` — Uninstall Sticky Notes

**卸载便笺**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Sticky Notes desktop note-taking app. Trade-off: skip if you pin sticky notes to your desktop; safe to remove if using third-party note apps.
- **代价 / Cost:** 桌面“便笺”应用。取舍：如果你习惯在 Windows 桌面上贴彩色便签记录临时备忘，请跳过此项；如果已有更专业的笔记工具，可安全卸载。
- **Uninstalls:** `Microsoft.MicrosoftStickyNotes` and revokes its provisioning

### `apps.maps` — Uninstall Windows Maps

**卸载 Windows 地图**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Offline desktop Windows Maps application. Rarely used on desktop PCs compared to web navigation; safe to uninstall.
- **代价 / Cost:** Windows 内置离线地图应用。在台式机和笔记本上极少有人打开，且数据更新滞后。卸载后如需查地图可随时在浏览器使用网页版或手机高德/百度地图。
- **Uninstalls:** `Microsoft.WindowsMaps` and revokes its provisioning

### `apps.bing-news` — Uninstall Bing News

**卸载 Bing 资讯**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Microsoft Bing News app. Contains clickbait feeds and ad placements; commonly bundled silently. Safe to remove.
- **代价 / Cost:** 微软必应资讯应用。充斥娱乐八卦、算法推荐与广告赞助新闻，常常随系统更新被静默安装。卸载可杜绝低质新闻弹窗骚扰。
- **Uninstalls:** `Microsoft.BingNews` and revokes its provisioning

### `apps.bing-weather` — Uninstall Bing Weather

**卸载 Bing 天气**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Microsoft Bing Weather application with embedded ads and Bing links. Safe to uninstall if you check weather via your phone or browser.
- **代价 / Cost:** 微软必应天气应用。界面充斥必应推广与资讯卡片。取舍：如果你不依赖该 UWP 查看天气预报，推荐卸载净化系统。
- **Uninstalls:** `Microsoft.BingWeather` and revokes its provisioning

### `apps.bing-search` — Uninstall Bing Search app

**卸载 Bing 搜索应用**

- **Target / 类型:** `appx`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Bing search web wrapper app that redirects local desktop queries into Bing services. Safe to remove without affecting native local search.
- **代价 / Cost:** 微软必应桌面搜索套壳应用。用于将桌面搜索请求强制引流到必应生态，卸载后不影响浏览器和系统本地文件搜索。
- **Uninstalls:** `Microsoft.BingSearch` and revokes its provisioning

## OneDrive — OneDrive

`onedrive` · 1 actions

Removes the bundled OneDrive sync client and sets machine policies to block silent background reinstall. Your local user data folders (Documents, Pictures, Desktop) are NEVER deleted or modified in any way.

彻底移除 Windows 11 深度绑定的 OneDrive 客户端程序并配置系统策略阻止其自动重装。你的本地个人数据目录（文档、图片、桌面等）在整个过程中【绝不会】受到任何触碰或删除。

### `onedrive.uninstall` — Remove OneDrive client and block reinstall

**移除 OneDrive 客户端并阻止重装**

- **Target / 类型:** `onedrive`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Uninstalls the background OneDrive sync client, removes the pinned OneDrive tree item from File Explorer, and applies the DisableFileSyncNGSC policy to block automated re-deployment. Your files remain untouched on disk.
- **代价 / Cost:** 删除系统常驻的 OneDrive 同步客户端本体，清理资源管理器左侧导航栏的 OneDrive 固钉图标，并通过组策略设置 DisableFileSyncNGSC 彻底阻止系统在更新后再次自动下载重装。你的本地文件原封不动保存在原位置。
- **Removes:** the OneDrive client binaries and blocks reinstall. The data folder is never touched.

## Privacy — 隐私加固

`privacy` · 10 actions

Hardens user privacy by restricting cross-app profiling, cloud keystroke harvesting, ink sampling, background location tracking, account settings sync, and Delivery Optimization P2P upload bandwidth usage.

收紧系统的跨应用追踪与隐式数据采集合规性。包括广告标识符画像、输入法云端按键采集、手写笔迹隐式采样、系统定位授权、微软账号设置云端同步以及传递优化 P2P 上传限制。

### `privacy.advertising-id` — Turn off advertising ID

**关闭广告标识符**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables the unique Advertising ID assigned to each user profile, preventing apps and advertisers from building cross-application tracking profiles for targeted advertising.
- **代价 / Cost:** 关闭 Windows 为每个用户分配的唯一商业广告标识符（Advertising ID）。第三方应用和网页将无法再利用此唯一 ID 追踪你的跨软件使用轨迹来生成精准商业广告画像。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo\Enabled` = `0` (DWord)

### `privacy.input-personalization` — Disable input personalization

**关闭输入个性化**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Turns off inking and typing personalization, stopping Windows harvesting your keystroke patterns and handwriting samples to train cloud dictionaries. Local typing remains normal.
- **代价 / Cost:** 关闭输入个性化与手写识别数据收集。Windows 默认会在后台收集你的键盘按键序列和笔迹用于训练云端词库。关闭后输入法仍在本地正常打字与联想，但不再向微软云端上传按键习惯。
- **Sets:** `HKCU\Software\Microsoft\Input\TIPC\Enabled` = `0` (DWord)

### `privacy.implicit-text-collection` — Block implicit text collection

**阻止文本隐式采集**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Blocks Windows diagnostic components from silently sampling typed text fragments, protecting sensitive input from being uploaded alongside crash dumps.
- **代价 / Cost:** 阻止 Windows 诊断组件在后台静默采样和提取你键入的文本片段。关闭后增强密码、敏感文本输入时的安全性，防止输入内容随错误报告泄漏。
- **Sets:** `HKCU\Software\Microsoft\InputPersonalization\RestrictImplicitTextCollection` = `1` (DWord)

### `privacy.implicit-ink-collection` — Block implicit handwriting collection

**阻止手写隐式采集**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Prevents Windows silently logging handwriting samples and digital pen stroke characteristics when drawing or writing with a stylus.
- **代价 / Cost:** 阻止系统在使用触控笔或数位板绘图、书写时静默记录和分析你的笔迹特征。保护手写签名和私密图文不被后台采集。
- **Sets:** `HKCU\Software\Microsoft\InputPersonalization\RestrictImplicitInkCollection` = `1` (DWord)

### `privacy.handwriting-sharing` — Stop handwriting data sharing

**停止手写数据共享**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Disables sharing handwriting recognition error data and pen stroke telemetry with Microsoft engineering teams.
- **代价 / Cost:** 禁止将手写识别错误数据共享给微软开发团队。确保个人手写笔记和商业草稿的私密性。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC\PreventHandwritingDataSharing` = `1` (DWord)

### `privacy.location` — Disable location services

**关闭定位服务**

- **Target / 类型:** `registry`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Disables the global Windows Location Service. Trade-off: weather, maps, and 'Find My Device' will not receive automatic GPS/Wi-Fi positioning, but prevents continuous location tracking.
- **代价 / Cost:** 关闭 Windows 全局定位服务。取舍：关闭后系统和应用无法获取你的地理坐标，天气自动定点、地图导航以及“查找我的设备”将无法自动定位（需手动输入城市），但可彻底消除日常定位监控与基站上报。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors\DisableLocation` = `1` (DWord)

### `privacy.settings-sync` — Disable settings sync to Microsoft account

**关闭设置同步到微软账号**

- **Target / 类型:** `registry`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Disables syncing system settings, wallpaper, and credentials to your Microsoft account. Trade-off: preferences will not automatically follow you across multiple PCs.
- **代价 / Cost:** 关闭将系统个性化设置、壁纸、语言首选项和凭据自动同步到微软云端账号的功能。取舍：多台 Windows 电脑之间不再自动同步外观与密码，换新电脑需手动配置，但避免了个人偏好留存在云端。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\SettingSync\SyncPolicy` = `0` (DWord)

### `privacy.app-diagnostic-access` — Block apps reading diagnostic information

**禁止应用读取诊断信息**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Revokes global permissions allowing Windows Store apps to read diagnostic details and hardware inventory from other applications on your system.
- **代价 / Cost:** 配置统一权限策略：禁止 Store 应用读取你设备的其他硬件配置和诊断详情。防止流氓应用以诊断为借口窥探你的硬件配置与系统进程列表。
- **Sets:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy\LetAppsAccessDiagnosticInformation` = `2` (DWord)

### `privacy.feedback-frequency` — Never ask for feedback

**永不请求反馈**

- **Target / 类型:** `registry`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Forces the Windows feedback prompt frequency policy to 0, permanently stopping notifications that request feedback or opinions on system updates.
- **代价 / Cost:** 在组策略中将系统向你索取使用反馈的触发频率强制归零（DoNotShowFeedbackNotifications）。彻底终结系统各种“向我们提供反馈”的提醒通知。
- **Sets:** `HKCU\Software\Microsoft\Siuf\Rules\NumberOfSIUFInPeriod` = `0` (DWord)

### `privacy.delivery-optimization-no-p2p` — Stop Delivery Optimization peer-to-peer sharing

**关闭传递优化 P2P 共享**

- **Target / 类型:** `registry`  ·  **Default / 默认:** no / 否
- **Why / 为什么:** Restricts Windows Delivery Optimization from uploading update packages to random strangers across the Internet (P2P seeding), conserving your upstream bandwidth.
- **代价 / Cost:** 关闭“传递优化”（Delivery Optimization）的公网 P2P 上传功能。默认情况下，你的电脑会在后台将已下载的 Windows 更新包静默上传给其他互联网用户（做种占用你的上传带宽）。关闭后系统仍能从微软官方正常下载更新，但不再拿你的宽带做种。
- **Sets:** `HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization\DODownloadMode` = `0` (DWord)

## Ad cache & wallpaper — 广告图缓存与壁纸

`cache` · 1 actions

Safely clears pre-downloaded Spotlight ad picture caches in AppData. Verified with strict assertions to NEVER delete or modify your current active wallpaper or its transcoded copy.

安全清理系统中已下载但未被使用的各类商业推广壁纸与广告图缓存。经过严格白名单校验，【绝不会】触碰或误删你当前正在使用的壁纸文件及其缩放转码副本。

### `cache.spotlight-images` — Delete downloaded Spotlight ad images

**删除已下载的 Spotlight 广告图**

- **Target / 类型:** `path-clean`  ·  **Default / 默认:** yes / 是
- **Why / 为什么:** Purges cached Spotlight ad pictures accumulated inside AppData's ContentDeliveryManager image store. Enforces strict safety assertions: will never touch your active wallpaper or its transcoded copy.
- **代价 / Cost:** 彻底扫描并清理位于 AppData 目录下的 ContentDeliveryManager 离线广告图缓存池（通常积累数百张数 MB 大小的商业赞助图片）。代码带保护断言：若路径匹配当前已激活的壁纸或其转码副本（TranscodedWallpaper）则立即熔断跳过。
- **Deletes cached files in:**
  - `%LOCALAPPDATA%\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets`
  - `%LOCALAPPDATA%\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\StagedAssets`
  - `%LOCALAPPDATA%\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\TargetedContentCache`
  - `%LOCALAPPDATA%\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Tips`

---

[English](CATALOG.md) · [中文](CATALOG.zh-CN.md) · [README](../README.md) · [中文说明](../README.zh-CN.md)

Generated from `catalog/catalog.json` by `tools/New-CatalogDoc.ps1`. Do not edit by hand.

