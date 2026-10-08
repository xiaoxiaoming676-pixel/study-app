# iPhone 安装版路线与首版验收

## 当前唯一主线（2026-10-08）

RC1 `v0.9.0-rc1` 已冻结，双模拟器与 Windows 绿色。GitHub Actions 继续测试并输出 unsigned IPA / simulator ZIP / Windows EXE；Codemagic 负责未来签名与 TestFlight。最新证据见 [RC1_BASELINE.md](RC1_BASELINE.md)，签名前审计见 [SIGNING_AUDIT.md](SIGNING_AUDIT.md)。

用户暂无 Apple Developer Program 会员和可用 iPhone。条件就绪前不启动签名；条件就绪后以首次真实 iPhone 学习、保存、退出、重开为最高里程碑。首份安装不等待真实大文件极限测试全部完成。

下列 2026-10-06 安装路线调查仅保留为历史，**不是当前待选执行方案**；不切换到 Sideloadly、另一家付费真机平台或 GitHub Secrets 签名。BrowserStack 只有上传验证，不能标记为真机通过。

核查日期：2026-10-06。目标设备以 iPhone 为主，兼顾 iPad；用户现在只有 Windows 电脑和 Android 手机，没有苹果设备。源码仓库为本仓库。

## 当前补充（2026-10-06）

后续阶段已在原有 PDF 学习系统上增加 App 内离线 PPTX→PDF 原型。[iOS 绿色运行 37444388719](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37444388719) 的 iPhone/iPad 合成课件转换和视觉比较通过：四页，平均 RGB 误差 2.219/255、最差页 2.916/255；图表页可提取文字召回率为 0，完整质量门槛仍未通过。近期另加的“转换后导入教材、保存重开”测试和模拟器 ZIP 构建尚待最终绿色运行，不能把合成结果外推到真实教材。现有无签名 IPA 仍可下载；新增模拟器 ZIP 旨在上传 Appetize 手动体验，尚未完成归档验证。Windows 教材工具已生成独立 EXE 并在 [云端运行 37471751616](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37471751616) 通过。Apple Developer Program 与签名材料仍缺，因此没有 signed IPA 或 TestFlight 包。

## 已有产物

- [最近完整绿色 iOS 运行](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37444388719)：静态分析、已有 PDF 学习流程、iPhone/iPad 合成 PPTX 离线转换、视觉比较与 Xcode 无签名构建均通过；后续新增功能须以更新运行重新验收。
- [无签名 IPA 归档](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37444388719/artifacts/11404124367)：`Study-unsigned-iOS-app`，2026-10-20 过期；GitHub ZIP SHA256 `a89e525681330ce58744a487badd8273a7946659d019b14021681220794aafdb`。ZIP 内另含 IPA 的 `SHA256.txt`。
- 构建使用独立 Bundle ID `com.xiaoxiaoming676.studyapp` 和显示名 Study；IPA 未签名，不能直接安装到 iPhone。用户没有苹果设备，因此尚未进行真机验收。

## 两条安装路线

| 路线 | 用户要做的事 | 可交付结果 | 限制 |
| --- | --- | --- | --- |
| 将来有设备时自用验证 | Windows 下载 IPA，Sideloadly 连接 iPhone，用自己的 Apple 账号在工具内签名安装；见 [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md) | 可在个人 iPhone 试跑现有 PDF 学习版，验证真实功能 | 需有 iPhone；个人签名可能需要周期性刷新，设备和系统兼容性须实测 |
| 长期测试、分享 | 用户开通 Apple Developer Program（99 美元/年或当地货币），创建本人拥有的 App ID、签名证书、描述文件和 App Store Connect 记录；再将证书与分发密钥放在 GitHub Secrets 或使用受信任云构建平台配置 | 签名 IPA，上传 TestFlight，邀请 iPhone/iPad 测试者 | TestFlight 单次构建最长测试 90 天，外部测试可能经过审核；账号与发布权限仍归用户 |

开源项目、GitHub Actions、Codemagic、fastlane 可以自动化编译和签名操作，不能替用户生成 Apple 颁发的分发身份。当前无用户签名材料，因此不能声称已产生可直接安装或 TestFlight 的正式 IPA。不要把 Apple ID 密码、双重验证代码、p12 证书或私钥发在聊天中。

无苹果设备时可以另走**远程真机测试**：[BrowserStack](https://www.browserstack.com/docs/app-automate/appium/resign-ios-apps)说明会为其设备自动重签上传的 IPA，[App Live 上传说明](https://www.browserstack.com/docs/app-live/app-source/upload-apps)支持 IPA。2026-10-06 在用户登录的 App Live 中，本项目旧版绿色构建 `aada5dc` 的 `Study-UNSIGNED.ipa`（SHA256 `39527c29a096956d840b418ddcd9c9b408e4e4fbc364e921ffcebd324ed3e52d`）已被平台接受并列为上传应用；启动免费 iPhone 会话时平台显示试用时间已用完，**未观察到安装、打开或功能操作**。上传成功不能推断 unsigned IPA 一定能在平台真机运行。界面当时提示每台设备最多 2 分钟，实际可用时间以账号显示为准；若需完成真机验收，须取得可用测试时段或服务方案。即使平台重签测试成功，也不会产生可安装到用户未来 iPhone 的正式分发包。[AWS Device Farm](https://docs.aws.amazon.com/devicefarm/latest/developerguide/skip-app-re-signing-on-private-devices.html)也会为其设备重签，但[免费试用结束后按分钟计费](https://aws.amazon.com/device-farm/pricing/)，在未核对账户账单限制前不启动。

参考：[Apple 免费个人团队限制](https://developer.apple.com/help/account/basics/about-your-developer-account/)、[Apple 会员与费用](https://developer.apple.com/programs/whats-included/)、[TestFlight 规则](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)、[GitHub Actions 苹果签名](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications)、[Flutter iOS 发布](https://docs.flutter.dev/deployment/ios)、[Sideloadly 官网](https://sideloadly.io/)。

## “完整版本”的验收口径

目前是已通过模拟器核心流程、可构建的 PDF 学习测试版，不是所有需求已交付。首版完整交付仍应在将来取得目标 iPhone 后逐项验证：

- PDF 导入；依据颜色、关键词、加粗/下划线或 PDF 高亮生成挖空候选，支持确认与手动框选，不限红色。
- 手写或键入答案、教材任意空白处批注、保存退出并再次打开、原文/练习/笔记导出。
- 系统中文声音朗读、暂停和继续；iPad 基本布局与笔迹已在模拟器流程通过，真实设备手感和听感仍待验收。
- 手机内直接导入 PPTX 与其他目标文档并完成可靠转换或呈现。当前 iOS 离线 PPTX 原型只在四页合成课件上通过视觉比较；图表文字和真实教材仍未达验收门槛。
- 图片扫描教材已有本地 Vision OCR，可提取文字并按关键词、指定 RGB 颜色、彩色浅底高亮或近似下划线生成挖空候选；合成样本已在 iPhone、iPad 模拟器通过。扫描图中的加粗和语义重点生成仍未完成；下划线、颜色及高亮在真实教材中仍需人工逐项确认。
- 样式/高亮候选的准确性、大教材性能、笔记在重签名或升级后的保留，均需真机和真实教材验证。

下一阶段：完成 PPTX→现有教材系统保存重开、模拟器 ZIP、数据保存回归和 100+ 页性能检查；取得真实教材后再核对扫描样式、图表文字和版面质量。不切换云端转换。将来有 iPhone 时再核对真实 Files 选取、系统语音、笔迹和保存升级体验，记录型号/iOS/失败步骤。签名流水线须在账号就绪后按实际 Team ID 和描述文件调试，不沿用 Saber 作者的 Team ID。
