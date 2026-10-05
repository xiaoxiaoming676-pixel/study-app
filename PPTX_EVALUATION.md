# 手机内 PPTX 导入路线核对（2026-10-05）

目标是让课件在 iPhone 上成为可书写、可挖空、可保存重开的教材。仅能预览幻灯片，还不能满足这个目标；必须生成版式可核对、页数稳定、坐标可供挖空的 PDF，或对现有学习引擎做等价适配。

| 路线 | 已核对能力 | 当前结论 |
| --- | --- | --- |
| Windows PowerPoint → PDF | 本机已安装 PowerPoint 16；`overlay/tools/study/prepare.py` 实际转换及中文路径测试已通过。 | 当前可用的本地路径，无需上传教材。导出的 PDF 仍要与原课件对照。 |
| iPhone Keynote 打开 PPTX → 导出 PDF | [Apple 的打开说明](https://support.apple.com/guide/keynote-iphone/open-a-presentation-tan72232b56/ios)与[导出说明](https://support.apple.com/guide/keynote-iphone/export-to-powerpoint-or-another-file-format-tanb5cb64c05/ios)给出用户操作。 | 将来有 iPhone 时可手动完成，当前无法实机验证，且不属于本 App 内一键导入。 |
| Quick Look | [Apple 文档](https://developer.apple.com/documentation/quicklook/)明确 Office 文件预览，但未提供将 PPTX 按页变成可编辑 PDF 教材的接口。 | 可用于浏览，不能直接接入现有 PDF 挖空/笔迹存储流程。 |
| [DocReader](https://github.com/germanhl36/DocReader) 原生 Swift | 源码中的 `OOXMLSlideParser` 仅抽取文字框；`SlidePageRenderer` 把所有页绘为固定深色底、白字、两种固定字体；测试只断言输出以 `%PDF` 开头。要求 iOS 16+，而现有 App 最低 iOS 15。 | 会丢失课件图片、公式、图表、主题与字体，不集成到正式教材路径。 |
| [offline_document_viewer](https://github.com/huseyiniriss/offline_document_viewer) | 内置 PPTXjs 的离线 Flutter 预览，文档说明对图表和自动缩字有限制；未提供导出可直接用于本 App 的逐页 PDF API。 | 可以研究预览适配，先用真实课件核对清晰度、性能与 PDF 导出，再考虑接入。 |
| [Pagus](https://github.com/pagus-kit/Pagus) + WebKit | 可在浏览器内把 PPTX 解析为 SVG/DOM；[WKWebView.createPDF](https://developer.apple.com/documentation/webkit/wkwebview/createpdf%28configuration%3Acompletionhandler%3A%29)可导出网页 PDF。Pagus 使用 `<foreignObject>` 和字体替换，复杂公式及版式需要实测。 | 有希望形成离线转换原型，但目前尚未验证多页纸张尺寸、文字可选性、字体、公式与内存；不可直接称为高保真导入。 |
| [office-kit/pptx](https://github.com/office-kit/pptx) 浏览器预览 | 能读 PPTX 并用伴随预览包输出 SVG/PNG；项目自己的说明明确其预览并非像素精确，建议印刷级输出使用 PowerPoint 或 LibreOffice。尚无本 App 所需的离线多页 PDF 与坐标验收。 | 可作为离线原型候选，不直接替换现有教材导入。 |
| [900Slides](https://github.com/900Labs/900Slides) 桌面工具 | 文档称可在桌面本地把 PPTX 导出 PDF，也明确各平台安装和发布产物仍需验证；不是 iOS 应用内的转换组件。 | 对没有 PowerPoint 的电脑可另行评估；本机已有 PowerPoint 转换路径，不改变手机端结论。 |
| Microsoft OneDrive / Graph 转换 | [Microsoft Graph](https://learn.microsoft.com/en-us/graph/api/driveitem-get-content-format?view=graph-rest-beta)列出 PPTX → PDF；需要先把用户文件放到其云端并完成账号授权。 | 用户未选择云端教材存储，不主动上传私有教材。 |
| LibreOffice / unoserver | 可在持续运行的服务端转换；本仓库无经授权的文档服务和存储策略。 | 若将来选择云端路线，须先确定主机、成本、上传同意、保留/删除策略，再做应用接入。 |

## 下一轮离线原型的通过条件

1. 用用户许可的无敏感样本覆盖中文字体、彩色重点、图片、公式、图表、横竖版、重复词与 100 页以上大文件；与 PowerPoint 输出逐页核对。
2. 证明无网络时可在当前最低 iOS 版本运行，转换后 PDF 页数、尺寸、颜色、可选择文字和关键词坐标可靠。
3. 在 iPhone 模拟器中完成 Files 选取、转换、导入、笔迹、挖空、保存重开及导出；限制文件大小、内存与超时，失败时保留原文件并给出可操作提示。
4. 真机性能、系统语音与 Files 交互须待取得苹果设备或满足签名要求的远程真机后验收。
