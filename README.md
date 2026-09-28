# Study App · 苹果学习软件

面向 iPhone，兼顾 iPad。基于 [Saber](https://github.com/saber-notes/saber) 的固定版本开发，保留 GPL-3.0 许可及上游版权声明。

## 当前可下载版本

[2026-09-28 云端构建](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/36362400239) 已通过 Flutter 学习模块静态分析、9 项测试和 Xcode 无签名 iOS 构建。Artifacts 中的 `Study-unsigned-iOS-app` 含 `Study-UNSIGNED.ipa`。该 IPA 需要使用个人 Apple 账号签名才能在 iPhone 安装；它尚未经真机验收，也不是功能完整的正式版。

- Windows + iPhone 自用安装：[INSTALL_WINDOWS.md](INSTALL_WINDOWS.md)。
- 稳定测试与正式交付路径、功能缺口：[RELEASE_OPTIONS.md](RELEASE_OPTIONS.md)。
- 可核对的构建证据：[BUILD_PROGRESS.md](BUILD_PROGRESS.md)。

## 源码与构建

`BASE_COMMIT.txt` 固定上游 Saber 版本；`overlay/` 保存学习功能改动；`.github/workflows/study-ios.yml` 在 macOS runner 上恢复固定上游源码、覆盖改动、测试并构建无签名 IPA。修改 overlay 或工作流并推送 main 会重新构建，也可以在 Actions 手动运行。

保留原始教材文件并备份笔记。当前手机端优先验证 PDF 学习流程；PPTX 需要先在电脑转换为 PDF。更完整的需求和限制见上述交付说明。
