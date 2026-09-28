# iPhone 安装版路线与首版验收

核查日期：2026-09-28。用户设备以 iPhone 为主，偶尔 iPad；电脑为 Windows。源码仓库为本仓库。

## 已有产物

- [成功的 GitHub Actions 运行](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/36362400239)：静态分析通过，9/9 学习测试通过，Xcode 无签名构建成功。
- Artifacts：`Study-unsigned-iOS-app`（截至 2026-10-12），其中 IPA 大小 22,250,648 字节，SHA256 `446848005b6c5c678d7d21dfac8f63cfc2b5e606ed7748b8f27260f7fa806571`。
- Bundle ID `com.adilhanney.saber`、显示名 Saber、最低 iOS 15.0；未嵌入 provisioning profile。这个文件不能直接点开在 iPhone 安装。

## 两条安装路线

| 路线 | 用户要做的事 | 可交付结果 | 限制 |
| --- | --- | --- | --- |
| 现在自用验证 | Windows 下载 IPA，Sideloadly 连接 iPhone，用自己的 Apple 账号在工具内签名安装；见 [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md) | 可在个人 iPhone 试跑现有 PDF 学习版，验证真实功能 | 免费个人签名有效期通常 7 天，需重新签名/刷新；设备和系统兼容性须实测 |
| 长期测试、分享 | 用户开通 Apple Developer Program（99 美元/年或当地货币），创建本人拥有的 App ID、签名证书、描述文件和 App Store Connect 记录；再将证书与分发密钥放在 GitHub Secrets 或使用受信任云构建平台配置 | 签名 IPA，上传 TestFlight，邀请 iPhone/iPad 测试者 | TestFlight 单次构建最长测试 90 天，外部测试可能经过审核；账号与发布权限仍归用户 |

开源项目、GitHub Actions、Codemagic、fastlane 可以自动化编译和签名操作，不能替用户生成 Apple 颁发的分发身份。当前无用户签名材料，因此不能声称已产生可直接安装或 TestFlight 的正式 IPA。不要把 Apple ID 密码、双重验证代码、p12 证书或私钥发在聊天中。

参考：[Apple 免费个人团队限制](https://developer.apple.com/help/account/basics/about-your-developer-account/)、[Apple 会员与费用](https://developer.apple.com/programs/whats-included/)、[TestFlight 规则](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)、[GitHub Actions 苹果签名](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications)、[Flutter iOS 发布](https://docs.flutter.dev/deployment/ios)、[Sideloadly 官网](https://sideloadly.io/)。

## “完整版本”的验收口径

目前是可构建、可签名安装尝试的 PDF 学习测试版，不是所有需求已交付。首版完整交付应逐项在目标 iPhone 验证：

- PDF 导入；依据颜色、关键词、加粗/下划线或 PDF 高亮生成挖空候选，支持确认与手动框选，不限红色。
- 手写或键入答案、教材任意空白处批注、保存退出并再次打开、原文/练习/笔记导出。
- 系统中文声音朗读、暂停和继续；iPad 基本布局与笔迹检查。
- 手机内直接导入 PPT/PPTX 与其他目标文档并完成可靠转换或呈现。当前仅有电脑 PPTX→PDF 工具，不能宣称手机端已支持。
- 图片扫描教材要朗读或自动选重点，需要 OCR；当前没有 OCR/语义重点生成。
- 样式/高亮候选的准确性、大教材性能、笔记在重签名或升级后的保留，均需真机和真实教材验证。

下一阶段：先用现有 IPA 完成个人 iPhone PDF 流程实测，记录型号/iOS/失败步骤；修复真机问题和文件导入缺口；确定正式应用名、唯一 Bundle ID 与图标；拿到用户拥有的开发者签名身份后产出 TestFlight 构建。签名流水线须在账号就绪后按实际 Team ID 和描述文件调试，不沿用 Saber 作者的 Team ID。
