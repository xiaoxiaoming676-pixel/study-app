# Study App · 苹果学习软件

面向 iPhone，兼顾 iPad。基于 [Saber](https://github.com/saber-notes/saber) 的固定版本开发，保留 GPL-3.0 许可及上游版权声明。

## 当前可下载版本

[2026-10-05 最新绿色云端构建](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37319109435) 已通过 Flutter 学习模块静态分析、9 项单元测试、iPhone 和 iPad 模拟器学习流程测试（含扫描页按颜色挖空）以及 Xcode 无签名 iOS 构建。[构建产物](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37319109435/artifacts/11351295695) 含 `Study-UNSIGNED.ipa` 与其 SHA256 清单，有效期至 2026-10-19 14:15 UTC。IPA 必须签名后才能安装；目前用户没有苹果设备，尚未进行真机验收，也不是功能完整的正式版。Windows 教材工具的 PowerPoint 转 PDF 及 Python 测试 10/10 通过，App 内 PPTX 直接导入仍未完成。

- Windows 验证与将来有 iPhone 时的自用安装：[INSTALL_WINDOWS.md](INSTALL_WINDOWS.md)。
- 稳定测试与正式交付路径、功能缺口：[RELEASE_OPTIONS.md](RELEASE_OPTIONS.md)。
- 可核对的构建证据：[BUILD_PROGRESS.md](BUILD_PROGRESS.md)。
- 手机内 PPTX 导入路线与质量门槛：[PPTX_EVALUATION.md](PPTX_EVALUATION.md)。
- 暂时没有电脑时的实际限制与 iPhone 文档转换：[PHONE_ONLY.md](PHONE_ONLY.md)。

## 源码与构建

`BASE_COMMIT.txt` 固定上游 Saber 版本；`overlay/` 保存学习功能改动；`.github/workflows/study-ios.yml` 在 macOS runner 上恢复固定上游源码、覆盖改动、测试并构建无签名 IPA。修改 overlay 或工作流并推送 main 会重新构建，也可以在 Actions 手动运行。

保留原始教材文件并备份笔记。当前手机端优先验证 PDF 学习流程；PPTX 需要先在电脑转换为 PDF。更完整的需求和限制见上述交付说明。
