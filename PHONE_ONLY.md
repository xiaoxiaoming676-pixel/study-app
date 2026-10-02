# 没有电脑时的交付路径

核查日期：2026-10-02。

## 构建和教材准备

GitHub Actions 已在云端 macOS 编译无签名 iOS IPA，不需要用户电脑。构建产物仍需苹果认可的签名和安装渠道；上传一个无签名 IPA 到网页并不能直接安装到 iPhone。

在 iPhone 上，Keynote 可以打开 PPT/PPTX 并导出 PDF；Pages 可以打开 Word 文档并导出 PDF。导出的 PDF 可在学习 App 中导入。公式、字体和版式需核对；这还不是 App 内直接转换。

本项目 iOS 扫描 PDF 本地文字识别已加入源码，并可按指定关键词生成挖空候选坐标；需要模拟器流程和真机验收后才能确认可用。扫描图片中的字体颜色、粗体和下划线尚不能可靠自动判定，页面可手动框选。选择候选时可以删除误识别项。

## 安装路线的硬条件

- 免费 Apple 账号的个人签名有效期 7 天，Apple 官方的个人团队签名在 Xcode 管理；Sideloadly 和 SideStore 等方案首次安装通常需要电脑连接设备。SideStore 仅后续刷新可脱离电脑。
- TestFlight、商店和苹果网站分发需要符合条件的 Apple Developer Program 会员、证书/配置以及 App Store Connect；GitHub Actions 提供 Mac 构建机，不能绕过这些条件。
- 欧盟第三方商店与网页分发也要求开发者会员、苹果公证和许可条件；它们不是给一个新无签名 IPA 免费安装的入口。
- 假如用户的手机已经安装并配置过 SideStore 一类签名工具，可以用手机导入现有 IPA，具体能力依赖设备现状；当前未知。

结论：用户暂时没有电脑，也没有付费开发者账号时，可以继续线上开发和生成无签名 IPA，但无法保证从零开始仅用网页把它签名并装到任意 iPhone。不要把未经证实的共享企业证书、在线代签网站当作可长期使用的正式交付。下次能接触电脑时，可按 [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md) 用个人账号安装；另一条是先开通开发者会员，再走 TestFlight。

参考：[Apple 免费个人团队](https://developer.apple.com/help/account/basics/about-your-developer-account/)、[SideStore 首次安装要求](https://docs.sidestore.io/docs/installation/prerequisites)、[Apple 欧盟网页分发](https://developer.apple.com/support/web-distribution-eu/)、[Apple Keynote iPhone](https://support.apple.com/en-gb/guide/keynote-iphone/tan72232b56/ios)、[Apple Pages iPhone](https://support.apple.com/en-ke/guide/pages-iphone/tancdeedb11c/ios)。
