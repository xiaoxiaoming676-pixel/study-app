# 第一版 iPhone 安装测试（Windows）

当前提供的是 **无签名验证包**，不是 App Store 或 TestFlight 版本。已通过云端 Flutter 静态分析、9 项测试与 Xcode 构建；真机行为尚未确认。

## 包和校验

- GitHub [构建页面](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/36362400239) 的 Artifacts 中下载 `Study-unsigned-iOS-app`，解压得到 `Study-UNSIGNED.ipa`。
- SHA256：`446848005b6c5c678d7d21dfac8f63cfc2b5e606ed7748b8f27260f7fa806571`。
- 原上游标识暂为 `com.adilhanney.saber`，桌面名称 Saber，图标也仍是上游；正式命名与品牌后续处理，安装时如有冲突可在签名工具中改 bundle ID。首次设定后续更新需保持相同 bundle ID 和 Apple ID，才能覆盖保留本地数据。

## Windows + iPhone 实测路线

1. 在电脑下载 IPA。安装 [Sideloadly 官方 Windows 版本](https://sideloadly.io/)；按照其官网要求安装 Windows 的网页版 iTunes 和 iCloud。
2. 用数据线接上 iPhone，手机点“信任此电脑”。在 Sideloadly 选设备并拖入 IPA。
3. 选择 Apple ID Sideload，在电脑工具的正式界面输入自己的 Apple ID，完成双重验证，然后开始安装。**不要把密码或验证码发给聊天。**
4. iOS 16 及更高版本如提示开发者模式：iPhone 设置 → 隐私与安全性 → 开发者模式，启用并重启。若提示信任开发者，再按手机设置提示处理。
5. 免费 Apple ID 安装的应用有效期通常为 7 天；官方工具支持刷新，但需按其说明连接电脑/配置无线同步。原始教材和笔记另外备份。

参考：[Sideloadly 官方](https://sideloadly.io/)及[常见问题](https://sideloadly.io/faq)、[Apple 免费个人团队限制](https://developer.apple.com/help/account/basics/about-your-developer-account)。

## 第一轮测试

使用一份不含敏感内容的 PDF：导入 → 手动挖空 → 手写或输入答案 → 空白处批注 → 保存退出 → 再打开 → 朗读 → 导出。
记录手机型号、iOS 版本、每步是否成功以及截图。不要删除旧版笔记再尝试更新。

PPTX 在手机内直接转换尚未完成；当前需要先用电脑工具转换为 PDF。
