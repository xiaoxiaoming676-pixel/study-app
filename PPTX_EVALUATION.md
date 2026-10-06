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
| [aiden0z/pptx-renderer](https://github.com/aiden0z/pptx-renderer) 浏览器渲染 | Apache-2.0；提供可随 App 打包的浏览器 ESM 文件、ZIP 限制、逐页 HTML/SVG 和 PowerPoint 对照测试。当前项目说明已列出有限的 OMML 公式与静态 3D 支持，但不提供完整 EMF/WMF 矢量渲染；文档仍没有现成的 iOS 逐页 PDF 导出和本 App 的坐标映射验收。 | 最值得继续做离线原型的候选：需在 WKWebView 中逐页渲染，再验证 PDF 导出、字体、页数、坐标和内存，不能仅凭项目截图宣称可用。 |
| [docMentis udoc-viewer](https://github.com/docMentis/docmentis-udoc-viewer) WASM 预览 | 声称浏览器内支持 PPTX；核心 WASM 是私有源码和单独授权，默认每次打开文档发送匿名遥测，关闭遥测需特定许可。文档没有适配本 App 的逐页 PDF 导出。 | 当前不接入隐私敏感的离线教材路径；如将来评估，先核对许可、遥测和可导出能力。 |
| [900Slides](https://github.com/900Labs/900Slides) 桌面工具 | 文档称可在桌面本地把 PPTX 导出 PDF，也明确各平台安装和发布产物仍需验证；不是 iOS 应用内的转换组件。 | 对没有 PowerPoint 的电脑可另行评估；本机已有 PowerPoint 转换路径，不改变手机端结论。 |
| Microsoft OneDrive / Graph 转换 | [Microsoft Graph](https://learn.microsoft.com/en-us/graph/api/driveitem-get-content-format?view=graph-rest-beta)列出 PPTX → PDF；需要先把用户文件放到其云端并完成账号授权。 | 用户未选择云端教材存储，不主动上传私有教材。 |
| LibreOffice / unoserver | 可在持续运行的服务端转换；本仓库无经授权的文档服务和存储策略。 | 若将来选择云端路线，须先确定主机、成本、上传同意、保留/删除策略，再做应用接入。 |

## Windows 离线原型核对（2026-10-06）

用本机 PowerPoint 16 生成的三页无敏感样本，分别包含中文红字与矩形、英文文本、中文柱状图。`@aiden0z/pptx-renderer` 1.3.0 在本机 Edge 浏览器离线加载样本并正确报告三页；逐页渲染后由浏览器打印为每页一张 PDF。对照 PowerPoint 导出的 960×540 图片，三页平均 RGB 通道绝对误差约为 1.3、1.2、6.6（满量程 255）；图表颜色、坐标轴和字体有可见差异。浏览器导出的 PDF 每张为一页，普通中英文文本可正确提取（已用 Unicode 码点检查），但图表文本未被 PDF 文本提取器提取，仍要靠 OCR。这个样本证明基本解析和画面输出可行，尚不证明 iOS `WKWebView` 逐页导出、真实课件版式或大文件稳定性。原型位于本机临时目录，不是应用功能，也没有上传用户教材。

## 下一轮离线原型的通过条件

1. 用用户许可的无敏感样本覆盖中文字体、彩色重点、图片、公式、图表、横竖版、重复词与 100 页以上大文件；与 PowerPoint 输出逐页核对。
2. 证明无网络时可在当前最低 iOS 版本运行，转换后 PDF 页数、尺寸、颜色、可选择文字和关键词坐标可靠。
3. 在 iPhone 模拟器中完成 Files 选取、转换、导入、笔迹、挖空、保存重开及导出；限制文件大小、内存与超时，失败时保留原文件并给出可操作提示。
4. 真机性能、系统语音与 Files 交互须待取得苹果设备或满足签名要求的远程真机后验收。

## 固定四页样本与 App 内原型（2026-10-06）

阶段 1 固定合成课件由本机 PowerPoint 16 导出四页参考 PDF；阶段 2 使用 `@aiden0z/pptx-renderer` 1.3.0 的浏览器 ESM，在 Windows Edge 加载与 iOS 原型相同的桥接 HTML。四页（中文文本/形状、表格、柱状图、图片/强调文字）均能逐页绘出。浏览器打印 PDF 与 PowerPoint 参考逐页比较：RGB 平均误差 1.933/255，最差页 2.604/255，宽高比一致。图表页的文字由画布绘出，打印 PDF 不含可提取的图表标签文字，因此该页字符召回率为 0，完整质量门槛失败。视觉平均值不能证明图表语义正确，仍须人工逐页核对。

App 内原型把独立 ESM 和 Apache-2.0 许可文件在构建时打包，运行时只加载本机文件。WKWebView 逐页生成 PDF，再交给现有 PDF 教材系统。输入限制 16 MB，采用渲染器推荐的 ZIP 解析上限，限制 100 页和 150 MB 输出，设 180 秒总超时，支持取消、进程终止和失败提示。字体优先采用 iOS 中文系统字体并回退到通用字体。`WKWebView.createPDF`、离线模块加载、Files 选取与实际导入质量仍需 iPhone/iPad 模拟器验证；Windows Edge 结果不能替代这项验证。真实教材尚未提供，不能报告真实课件准确率或决定切换 Pagus。

2026-10-06 iOS 首轮模拟器失败定位：两条原型运行均成功下载并校验浏览器 ESM、通过 Flutter 分析和原有 PDF 流程，但在 WKWebView 的 `file://` 页面中 ES module 没有执行，导致 `PPTX_MODULE`。这是模块加载失败，不是幻灯片渲染质量结论。采用固定 esbuild 0.25.12 将已校验的 ESM 转成 IIFE，构建时嵌入离线 HTML，使 WebKit 只需加载一个本地文件；附带原包 Apache 许可和打包依赖的许可说明。本机 Edge `file://` 用同一内嵌 HTML 完成四页渲染。iOS 转换、逐页 PDF 和视觉指标须以新模拟器运行复验。

下一轮 [iOS 运行 37434382755](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37434382755) 进入了 iPhone PPTX 测试后的视觉比较，但比较步骤退出码 2，未留下模拟器 PDF 与 JSON 评分归档，整条运行仍红色。现将测试生成的固定合成 PDF 从测试日志分块传出，严格校验完整性后再运行现有 PowerPoint 视觉比较；不依赖测试完成后 App 临时容器是否仍存在。下一轮需检查 iPhone 与 iPad 测试原始结果、输出 PDF、逐页分数和最终运行结论。ZIP 限制进一步收紧为单项 16 MiB、总解压 96 MiB、媒体 64 MiB、并发 2；本机高压缩比越限样本被拦截，正常四页样本仍能打开。真实教材质量和 100 页手机性能尚无证据。

提交 `aada5dc` 的 [iOS 运行 37444388719](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37444388719) 已整体绿色，iPhone、iPad 离线转换测试及 iPhone 视觉比较步骤均成功；模拟器 PDF 与评分见 [合成比较归档 11403134528](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37444388719/artifacts/11403134528)。逐页 RGB MAE 为 2.690、0.730、2.541、2.916（满量程 255），平均 2.219；四页页数与比例均通过。第 3 页图表以画面方式绘出，月份标签肉眼可见，但 PDF 提取文字为零，完整质量检查 `passed=false`。这不影响将 PDF 交给现有学习页浏览和手写，但关键词/挖空能否准确处理图表标签还需验证；不能以视觉分数代替真实教材语义质量。尚无真实教材，暂不据此切换 Pagus 或云端服务。
