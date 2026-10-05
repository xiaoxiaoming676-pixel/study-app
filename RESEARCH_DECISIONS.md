# iPhone 教材 App：跨站调研与技术选择

更新：2026-10-05。目标：iPhone 优先，兼顾 iPad，支持导入教材、笔迹、保存重开、挖空、朗读；尽量本地离线处理。用户目前只有 Windows 电脑和 Android 手机，没有苹果设备。

| 路线 | 资料与发现 | 适用性与决定 |
| --- | --- | --- |
| Saber Flutter 开源笔记 | [项目](https://github.com/saber-notes/saber)；现有 PDF 导入、触控笔迹、多页、SBN2 存储与 PDF 导出；已在本仓库叠加学习模式。 | 继续二次开发。核心页面、笔迹和文件存储可复用；需实机验证，保留原项目许可及归属。 |
| 苹果 PDFKit + Vision | [PDFKit](https://developer.apple.com/documentation/pdfkit) 可读可选中文字；[Vision OCR](https://developer.apple.com/documentation/vision/recognizing-text-in-images) 可识别扫描页；[recognizedText.boundingBox](https://developer.apple.com/documentation/vision/vnrecognizedtext/boundingbox(for:)) 可给 OCR 文字位置，但苹果说明 accurate 模式为词级精度。 | 已在 iOS 原生通道加入关键词 OCR 候选、本地读文字和 PDF 样式规则。候选必须人工复核；精细字符级定位不能承诺。 |
| 苹果 AVSpeechSynthesizer | [系统语音](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer) 支持本地朗读与进度。 | 已接入中文声音、速度、暂停与保存位置；模拟器和真机听感待验。 |
| Quick Look 预览 PPTX | [Apple 文档](https://developer.apple.com/documentation/quicklook) 支持预览常见文件，但不提供稳定的逐页 PDF/编辑坐标转换接口。 | 不作为 App 内 PPTX 导入实现。 |
| 手机上 Keynote | [Apple Keynote for iPhone](https://support.apple.com/guide/keynote-iphone/open-a-presentation-tan72232b56/ios) 可打开 PPTX，[导出 PDF](https://support.apple.com/guide/keynote-iphone/export-to-powerpoint-or-another-file-format-tanb5cb64c05/ios) 后用 Files 导入。 | 用户无电脑时可用的过渡路径，需检查字体、公式、版式；不算 App 内直接导入。 |
| LibreOffice 转换服务 | [LibreOffice](https://www.libreoffice.org/) / [unoserver](https://github.com/unoconv/unoserver) 可在服务器端把 PPTX 渲染为 PDF。GitHub Actions 可编译 App，但不是应用运行时的文档服务。 | 如需 App 内一键导入 PPTX 且版式较完整，可另设经过授权、带隐私/存储策略的服务；需要可持续部署与费用。暂不上传教材到未经用户选择的服务器。 |
| 浏览器 PPTX 渲染 | [pptx-renderer](https://github.com/aiden0z/pptx-renderer) Apache 2.0，能读取并在浏览器绘制部分 PowerPoint 内容，但格式覆盖与 PDF 坐标输出不完整。 | 不宜直接当高保真教材转换核心；可后续针对少量受支持演示文稿做试验。 |
| 新发现的离线 PPTX 路线 | [DocReader](https://github.com/germanhl36/DocReader) 虽能输出 PDF，但源码只绘文字框和统一背景，测试只验 PDF 文件头；[offline_document_viewer](https://github.com/huseyiniriss/offline_document_viewer) 主要提供预览；[Pagus](https://github.com/pagus-kit/Pagus) 可输出 SVG，需结合 [WebKit PDF 导出](https://developer.apple.com/documentation/webkit/wkwebview/createpdf%28configuration%3Acompletionhandler%3A%29) 做质量原型。 | 不把文字重绘或预览冒充可书写的完整 PPTX 导入。详细核对与验证门槛见 [PPTX_EVALUATION.md](PPTX_EVALUATION.md)。 |
| iOS 云端测试 | [Flutter integration_test](https://docs.flutter.dev/testing/integration-tests) 可在 GitHub Actions macOS 启动模拟器运行功能流程；[BrowserStack](https://www.browserstack.com/docs/app-automate/appium/resign-ios-apps) 和 [Sauce Labs](https://docs.saucelabs.com/mobile-apps/mobile-faq/) 提供远程真机，上传格式和签名要求须满足。 | [2026-10-06 绿色运行](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37345346944) 已在 iPhone、iPad 模拟器通过导入、笔迹、挖空、扫描页颜色与浅底高亮、笔记、朗读、导出及重开流程；真机平台不能解决无签名应用直接安装到用户手机。 |
| 发布签名 | [Apple 个人团队](https://developer.apple.com/help/account/basics/about-your-developer-account/) 与 [分发文档](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/) 规定签名和 TestFlight 资格；[SideStore](https://docs.sidestore.io/docs/installation/prerequisites/) 首装依赖电脑。 | 用户有 Windows 电脑、无苹果设备与开发者会员；可继续产出无签名构建，暂不能完成真机安装验收或提供可直接安装的 iPhone IPA。 |

## 选择

继续基于 Saber 开发，并保留 PDF、笔迹和离线文件引擎。iPhone、iPad 模拟器端到端流程已通过；真机验收仍待将来有设备和签名条件时进行。PPTX 目前可在 Windows 用本地 PowerPoint 转为 PDF；将来有 iPhone 时也可用 Keynote 导出 PDF。若要求 App 内一步完成且版式较完整，受控 LibreOffice 转换服务是较稳妥的工程方向，但需要持续运行的主机、教材上传前的明确授权、隐私和删除策略；本仓库现阶段没有这类服务或苹果分发签名。扫描图按关键词、指定 RGB 字体颜色及彩色浅底高亮生成 OCR 候选已在双模拟器验证；图中加粗、下划线和语义重点识别仍是后续缺口。

## 开源维护快照（2026-10-03）

Star 和近期推送只说明社区规模与维护迹象，不等于转换准确率或真机可用性。

| 项目 | Star / Fork | 最近推送 | 许可证 | 部署与可复用功能 | 决策 |
| --- | ---: | --- | --- | --- | --- |
| [Saber](https://github.com/saber-notes/saber) | 4,871 / 382 | 2026-10-02 | GPL-3.0 | Flutter + Xcode，构建依赖多；复用 PDF 导入、笔迹、持久化、多页和导出。 | 继续二次开发，社区活跃；发布二进制时按 GPLv3 提供相应源码与许可信息。 |
| [pptx-renderer](https://github.com/aiden0z/pptx-renderer) | 124 / 33 | 2026-09-23 | Apache-2.0 | TypeScript 浏览器渲染，接入 WKWebView 与导出 PDF 仍需开发；版式覆盖待实测。 | 暂不作为高保真 PPTX 核心。 |
| [unoserver](https://github.com/unoconv/unoserver) | 938 / 105 | 2026-06-10 | MIT | Python + LibreOffice 后端，可复用文档转 PDF；需要服务器、队列、文件大小限制与隐私策略。 | 将来做 App 内一键 PPTX 时首选验证。 |
| [libreoffice-unoserver Docker](https://github.com/libreofficedocker/libreoffice-unoserver) | 32 / 13 | 2025-08-18 | Apache-2.0 | 容器部署省去本地安装，但维护较慢，仍需持续运行主机。 | 仅作容器参考。 |
| [libre-convert](https://github.com/Rhgx/libre-convert) | 1 / 1 | 2026-03-13 | 仓库元数据未标明 | 社区极小，需自行核对代码、许可证和稳定性。 | 不依赖。 |

Saber 的 GPL-3.0 是分发约束；本仓库现已公开叠加补丁，若向他人分发完整 App，应按许可证条款准备对应版本的完整源码及告知方式。参考 [GNU GPLv3 第 6 节](https://www.gnu.org/licenses/gpl-3.0.en.html)。
