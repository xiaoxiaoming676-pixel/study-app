# iPhone 安装版路线与首版验收

核查日期：2026-10-06。目标设备以 iPhone 为主，兼顾 iPad；用户现在只有 Windows 电脑和 Android 手机，没有苹果设备。源码仓库为本仓库。

## 已有产物

- [最新绿色 GitHub Actions 运行](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37368501535)：静态分析、9/9 学习单元测试、iPhone 与 iPad 模拟器端到端测试（含扫描页彩色字体、浅底高亮和近似下划线候选、保存 PDF 字节核对、三种学习 PDF 导出页数与重开预览）及 Xcode 无签名构建均通过。更早一轮出现过一次未复现的 PDFium 读取失败，后续绿色轮次未复现，仍保留回归断言。
- [最新归档](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37368501535/artifacts/11381842224)：`Study-unsigned-iOS-app`，22,154,549 字节，有效期至 2026-10-20 00:12 UTC；GitHub 记录的归档 ZIP SHA256 为 `f3adbf5eb13872854c5e40b970933f6ccee1c116894c17f2bf05dcafbb4fa628`。ZIP 内另含 IPA 的 `SHA256.txt`。
- 构建使用独立 Bundle ID `com.xiaoxiaoming676.studyapp` 和显示名 Study；IPA 未签名，不能直接安装到 iPhone。用户没有苹果设备，因此尚未进行真机验收。

## 两条安装路线

| 路线 | 用户要做的事 | 可交付结果 | 限制 |
| --- | --- | --- | --- |
| 将来有设备时自用验证 | Windows 下载 IPA，Sideloadly 连接 iPhone，用自己的 Apple 账号在工具内签名安装；见 [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md) | 可在个人 iPhone 试跑现有 PDF 学习版，验证真实功能 | 需有 iPhone；个人签名可能需要周期性刷新，设备和系统兼容性须实测 |
| 长期测试、分享 | 用户开通 Apple Developer Program（99 美元/年或当地货币），创建本人拥有的 App ID、签名证书、描述文件和 App Store Connect 记录；再将证书与分发密钥放在 GitHub Secrets 或使用受信任云构建平台配置 | 签名 IPA，上传 TestFlight，邀请 iPhone/iPad 测试者 | TestFlight 单次构建最长测试 90 天，外部测试可能经过审核；账号与发布权限仍归用户 |

开源项目、GitHub Actions、Codemagic、fastlane 可以自动化编译和签名操作，不能替用户生成 Apple 颁发的分发身份。当前无用户签名材料，因此不能声称已产生可直接安装或 TestFlight 的正式 IPA。不要把 Apple ID 密码、双重验证代码、p12 证书或私钥发在聊天中。

无苹果设备时可以另走**远程真机测试**：[BrowserStack](https://www.browserstack.com/docs/app-automate/appium/resign-ios-apps)说明会为其设备自动重签上传的 IPA，[App Live 上传说明](https://www.browserstack.com/docs/app-live/app-source/upload-apps)支持 IPA，[试用说明](https://www.browserstack.com/support/faq/plans-pricing/plans/what-do-i-get-with-a-free-trial)列出有限测试时间。需用户自己的服务账号，并把测试包上传到该平台；目前尚未验证本项目的无签名 IPA 是否被接受，也尚未进行远程真机测试。即使测试成功，平台重签也只供平台设备运行，不会产生可安装到用户未来 iPhone 的正式分发包。[AWS Device Farm](https://docs.aws.amazon.com/devicefarm/latest/developerguide/skip-app-re-signing-on-private-devices.html)也会为其设备重签，但[免费试用结束后按分钟计费](https://aws.amazon.com/device-farm/pricing/)，在未核对账户账单限制前不启动。

参考：[Apple 免费个人团队限制](https://developer.apple.com/help/account/basics/about-your-developer-account/)、[Apple 会员与费用](https://developer.apple.com/programs/whats-included/)、[TestFlight 规则](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)、[GitHub Actions 苹果签名](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications)、[Flutter iOS 发布](https://docs.flutter.dev/deployment/ios)、[Sideloadly 官网](https://sideloadly.io/)。

## “完整版本”的验收口径

目前是已通过模拟器核心流程、可构建的 PDF 学习测试版，不是所有需求已交付。首版完整交付仍应在将来取得目标 iPhone 后逐项验证：

- PDF 导入；依据颜色、关键词、加粗/下划线或 PDF 高亮生成挖空候选，支持确认与手动框选，不限红色。
- 手写或键入答案、教材任意空白处批注、保存退出并再次打开、原文/练习/笔记导出。
- 系统中文声音朗读、暂停和继续；iPad 基本布局与笔迹已在模拟器流程通过，真实设备手感和听感仍待验收。
- 手机内直接导入 PPT/PPTX 与其他目标文档并完成可靠转换或呈现。当前仅有电脑 PPTX→PDF 工具，不能宣称手机端已支持。
- 图片扫描教材已有本地 Vision OCR，可提取文字并按关键词、指定 RGB 颜色、彩色浅底高亮或近似下划线生成挖空候选；合成样本已在 iPhone、iPad 模拟器通过。扫描图中的加粗和语义重点生成仍未完成；下划线、颜色及高亮在真实教材中仍需人工逐项确认。
- 样式/高亮候选的准确性、大教材性能、笔记在重签名或升级后的保留，均需真机和真实教材验证。

下一阶段：在没有苹果设备时继续开发 App 内 PPTX 导入路线与扫描图样式识别，并通过云端 iPhone 模拟器回归测试。App 内 PPTX 高保真转换目前缺少可持续部署的转换服务；电脑本地 PowerPoint 转 PDF 工具已可用，不等于手机内直接导入。将来有 iPhone 时再核对真实 Files 选取、系统语音、笔迹和保存升级体验，记录型号/iOS/失败步骤。签名流水线须在账号就绪后按实际 Team ID 和描述文件调试，不沿用 Saber 作者的 Team ID。
