# Windows 本地任务交接 · Study iOS App

更新：2026-10-05。仓库：https://github.com/xiaoxiaoming676-pixel/study-app ，最新已完成跨平台验证的代码提交：`8c4d25f4c7d0819bab8eb35121231a88fa6390d7`；请以仓库实时 main 为准。

本次 Windows 接手新增提交包括 `bdd2dd9ac623117627e0c9850f0fa6a962fa4149`（PowerPoint 教材转换及本地测试）、`37f437059737030be2f4e5e6ccd045259ffa614f`（独立 Windows Flutter 验证工作流）及 `8c4d25f4c7d0819bab8eb35121231a88fa6390d7`（模拟器测试点击时序修复）。详见 `BUILD_PROGRESS.md`。

## 用户目标与设备

第一版优先做出可用的 iPhone 学习 App：PPT/教材导入、任意空白书写笔记并保存、标记或关键词自动挖空（不只红色）、扫描页 OCR、普通男女系统朗读，iPhone 优先兼顾 iPad。用户现在只有 Windows 笔记本和 Android 手机，**没有任何苹果设备**。每一步修复要提交到仓库并更新 `BUILD_PROGRESS.md`。

## 已有代码

基于 Saber pinned commit `5b396a40406c75835741f5c4555bc10ae816f121`，`overlay/` 覆盖上游源码；`.github/workflows/study-ios.yml` 展示应用方式。学习页、PDF 手写/批注、挖空候选、PDFKit/Vision 扫描关键词 OCR、朗读通道、保存和导出已写入代码。最新云端验证通过 9/9 Dart 单元测试、iOS 无签名构建，以及 1/1 项 iPhone 模拟器端到端测试；具体证据见下方第三轮运行。

新版 `Study` 名称与 `com.xiaoxiaoming676.studyapp` 标识已由云端 Mac 构建执行；最新绿色运行产出独立 Study 无签名包。未签名包不能直接安装到 iPhone，用户也没有苹果设备，真机验收尚未进行。App 内直接 PPTX 转换尚未完成；Windows 教材工具在 `overlay/tools/study/`。

## 先前的云端阻塞与解决

GitHub Actions 运行 [37247985115](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37247985115) 首次及重试均在运行器分配前失败：`runner_id=0`、`steps=[]`、约 6–8 秒、计费 0 毫秒。无法从 API 读取此零步骤作业的错误横幅。仓库拥有者登录网页后需查看运行页面顶部的原始提示，再查看 GitHub Settings → Billing / Actions 用量或限制；**不要未经用户决定自行增加预算或付费**。这次失败不能视为源码编译错误。本地核对了工作流 YAML 可解析，以及上游项目包标识替换的数量断言成立。

后续 [macOS 运行 37260329062](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37260329062) 与 [Windows 运行 37265710398](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37265710398) 也都是 0 步、`runner_id=0`、0 计费毫秒，尚无 Flutter 分析或编译结果。未登录的浏览器对私有仓库显示 404，已打开登录页；等用户登录后查看横幅。跨 macOS/Windows 都失败提示可能是账户或仓库级 Actions 限制，但**具体原因尚未确认**。

用户已登录网页并核对：运行页提示“recent account payments have failed or your spending limit needs to be increased”。账户 Billing Overview 显示 **2,000/2,000 Actions 免费分钟用尽**、本月计费 $0；Budgets and alerts 中 Actions 预算为 **$0** 且 Stop usage 为 Yes。免费分钟约 27 天后重置。应以这条已确认信息替代上段的待核查推测；没有修改预算或支付设置。仓库仍为私有。

用户最终确认后，仓库已改为公开，GitHub API 也确认 `visibility=public`。公开前检查当前源码与 28 次提交补丁，未发现密钥格式或曾删除文件；历史提交包含作者邮箱和本机用户名路径，Actions 历史/日志现已可见。当前文档已去掉绝对本机路径，历史记录仍保留。未修改 $0 Actions 预算。

[公开后的 Windows 验证](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37267237712) 已在实际托管运行器上通过：Flutter 学习模块静态检查无问题，9/9 项单元测试通过。[iOS 验证](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37267208722) 静态检查、9/9 项单元测试、无签名编译和归档上传成功，但模拟器端到端测试失败，整条工作流为红色。模拟器实际执行了 PDF 导入、手指书写、保存、OCR、挖空、长期笔记和朗读；测试脚本在关闭并重新打开笔记后点中了不可命中的旧 Tooltip，未完成重开后的 UI 断言。已改为等待可命中的学习按钮，下一轮重跑。步骤列表因 `continue-on-error` 显示 `conclusion=success`，必须查看日志和最终工作流结论。此前的零步骤故障是私有仓库免费分钟用尽所致。

[第二轮 Windows 验证](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37269586628) 再次通过。[第二轮 iOS 验证](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37269586591) 再次通过分析、9/9 单元测试、无签名编译和上传，但模拟器测试在进入“挖空”标签时点击了仍在页面滑入动画中的控件，坐标超出 iPhone 模拟器屏幕，未到达“自动挖空”，整条工作流仍为红色。已让测试等待“挖空”标签可命中后再点击；第三轮需检查完整日志和最终结论。不能将这两次失败轮次的无签名包作为已验收版。

[第三轮 Windows 验证](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37271995128) 和 [第三轮 iOS 验证](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37271995174) 均**整体绿色通过**。iOS 日志确认静态检查无问题、9/9 单元测试通过、模拟器端到端测试 `+1: All tests passed!`，最后的失败检查跳过；无签名应用 `Runner.app` 52.7 MB，归档 [Study-unsigned-iOS-app](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37271995174/artifacts/11329312423) 22,149,658 字节，有效期至 2026-10-19 06:47 UTC。归档 ZIP 的 GitHub SHA256 为 `69ed0896055ab47dd0543e53c40f35ac44ffdf3580f805c8fbf712250c98eca0`；ZIP 内另有 IPA 自身的 SHA256 清单。模拟器已覆盖导入、书写、挖空、笔记、朗读与重开持久化；仍需将来有设备时做真机验收。

## 本次 Windows 本地结果

任务运行在用户电脑 Documents 目录的 PowerShell；Python 3.10.7 和 PowerPoint 16.0 可用，Git/Flutter 命令不在 PATH。仓库源码通过 GitHub 连接取得；Git 与固定 Saber 源码压缩包的下载因网络慢/中断未完成。已给 `overlay/tools/study/prepare.py` 增加 Windows PowerPoint PDF 转换路径，完整的 Python 教材工具测试 **10/10 通过**，含中文文件名 PPTX 转换、挖空和 PDF 几何/批注测试；Python 语法编译通过。本机未运行 Flutter 静态分析、Dart 测试、Xcode 或 iOS 模拟器。不要把 Windows 教材工具通过视为 App 业务流程通过。

## 在 Windows 本地接手时立即做

1. 确认当前任务使用 **本机 Windows 文件系统/终端**，而非云端 Linux。记录 `pwd` / `Get-Location`、`git --version`、`python --version`、`flutter --version`（若有），不要回显敏感环境变量。
2. 获取公开仓库最新 main，确认 main 包含上面的检查点；若已有工作树，先看 `git status` 并保留用户改动。读 `README.md`、`BUILD_PROGRESS.md`、`INSTALL_WINDOWS.md` 和工作流，按固定 Saber 基线应用 overlay；不要从零重建。
3. 在 Windows 跑能运行的 Python 教材转换测试：`python -m unittest discover -s tools/study -p "test_*.py" -v`（在覆盖后的 Saber 源码中）；如有 Flutter SDK，跑学习模块静态分析及 `flutter test test/study`。若本机无 SDK，判断安装或可用替代途径，先做其他检查。
4. 零步骤作业的网页提示和 2,000/2,000 免费分钟、$0 停用预算已确认；用户已授权公开仓库，最新 Windows/iOS 工作流均绿色通过。继续本地和代码工作；未经用户明确决定不改变预算或支付设置。
5. Windows 无 Xcode，不能本机运行 iOS 模拟器或生成 iOS 正式包；云端 Mac 已完成模拟器业务验证。用户无 iPhone/iPad，暂不安装 Sideloadly、不做个人签名或真机测试。真机验收需将来借用设备或合适的远程真机服务。
6. 修复和测试证据提交仓库，每步更新 `BUILD_PROGRESS.md`。已在模拟器覆盖 PDF 导入/手指书写/保存重开、挖空、笔记、朗读；下一项产品工作是 App 内 PPTX 导入路线与扫描图中样式标记识别，仍需保持真机验收边界。

## 2026-10-05 继续开发补充

[最新 iPhone 模拟器运行 37300523342](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37300523342) 与 [Windows 运行 37300523370](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37300523370) 整体绿色通过。模拟器流程已新增扫描页按 `#F44336` 识别红字 Alpha 并排除黑字 Beta；OCR 颜色是近似候选，仍需人工复核。新无签名包为 [归档 11343632694](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37300523342/artifacts/11343632694)，有效期至 2026-10-19 12:00 UTC。研究并排除会丢失课件版式的 DocReader 路线，离线 PPTX 其他候选及门槛见 [PPTX_EVALUATION.md](PPTX_EVALUATION.md)。iPad 模拟器回归已加入工作流，结果待下一轮；无苹果设备，真机与签名安装仍未完成。

[iPhone + iPad 运行 37319109435](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37319109435) 随后整体绿色通过，两种模拟器的业务测试均为 `+1: All tests passed!`。最新无签名包为 [归档 11351295695](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37319109435/artifacts/11351295695)，有效期至 2026-10-19 14:15 UTC。上段“iPad 待验证”是当时进度，以本段结果为准。真机、签名和 App 内 PPTX 直接导入仍未完成。

用户在电脑端的新本地任务可以引用本文件，并要求直接继续实施。

## 2026-10-06 凌晨进度

[运行 37334090670](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37334090670) 在 iPhone、iPad 双模拟器整体绿色通过，覆盖已保存 PDF 与导入源逐字节相同，以及原文版、挖空版、笔记答题版三种 PDF 导出。上一轮曾在 PDFium 加载时失败一次，本轮未复现，后续继续观察。[最新绿色无签名归档 11356863783](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37334090670/artifacts/11356863783)，有效期至 2026-10-19 16:12 UTC。Windows 本地教材工具再次 10/10 通过。正在新增扫描页彩色浅底高亮候选与模拟器对照测试，尚待云端验证。用户仍无苹果设备；App 内 PPTX 一键导入、签名和真机验收仍未完成。

[更新后的 iPhone + iPad 运行 37345346944](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37345346944) 已整体绿色通过，两次业务测试均为 `+1: All tests passed!`，覆盖扫描页彩色浅底高亮、三种导出 PDF 的重新打开与页数、保存 PDF 字节比对，以及关闭重开后的教材预览。对应 [Windows 运行 37345347141](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37345347141) 绿色通过。当前最新绿色 [无签名归档 11360794709](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37345346944/artifacts/11360794709) 有效期至 2026-10-19 17:27 UTC。前一次高亮运行中 iPhone 通过、iPad 因测试弹窗点击时机失败，本轮已修正并通过。扫描图加粗/下划线、App 内直接 PPTX、真机和正式签名仍是限制。

扫描页近似下划线识别与 iPhone/iPad 合成样本断言已提交为 `7281401e54badcee1a9eaa81fd8ce20e15286d13`。对应 [iOS 运行 37368501535](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37368501535) 和 [Windows 运行 37368501599](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37368501599) 首次尝试均排队约 15 分钟后在分配运行器前被取消，`steps=null`，不是代码测试结果；当时 [GitHub Actions 官方状态](https://www.githubstatus.com/) 报告运行器分配延迟。已发起重跑，需查最新尝试及日志。最后可信绿色版本仍为上一段的 `37345346944`，不要把待验证下划线版本作为已验收版。Windows 另以三页无敏感合成 PPTX 测过 `@aiden0z/pptx-renderer` 1.3.0 与本机 PowerPoint PDF，基础文字/形状画面接近，图表有差异；尚未在 iOS 接入或验证，具体见 `PPTX_EVALUATION.md`。

更新：上述两条作业的第二次尝试也在排队约 15 分钟后以 `cancelled`、`steps=null` 结束。GitHub 官方事故在 20:39 UTC 更新为托管运行器分配造成作业失败和延迟。不要把这四次零步骤结果当作源码失败；目前不再重复排队。待官方事故恢复后重新运行这两个作业并逐条核对编译、iPhone/iPad 模拟器日志与最终工作流结论。若要给用户下载，仍只推荐 `37345346944` 的绿色无签名包。

最终更新：GitHub 服务恢复后，以上两个运行的第 3 次尝试均**整体绿色通过**。iOS 运行 `37368501535` 的日志包含 Flutter 静态检查无问题、9/9 单元测试、iPhone 与 iPad 各一次 `+1: All tests passed!`、Xcode 无签名构建和归档；Windows 运行 `37368501599` 静态检查及 9/9 单元测试通过。下划线候选合成样本现已在双模拟器验证。当前最新可信无签名包是 [归档 11381842224](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37368501535/artifacts/11381842224)，有效期至 2026-10-20 00:12 UTC，ZIP SHA256 `f3adbf5eb13872854c5e40b970933f6ccee1c116894c17f2bf05dcafbb4fa628`。前段待重跑/推荐旧包的文字仅为历史进度，以本段结果为准。下一阶段仍是 App 内 PPTX 直接导入、扫描页加粗/语义重点、真实教材准确率、大文件性能、真机与签名交付；用户目前无苹果设备。
2026-10-06 后续：Windows 端新增 `start_study_tool.cmd` 与 `overlay/tools/study/gui.py`，复用原有 `prepare.py`，可通过窗口选择课件和规则并生成不覆盖旧结果的三份文件。PowerPoint 转换在已有 POWERPNT 进程时不再退出整个应用；本机 10/10 工具测试、已有 PowerPoint 会话保留检查及 GUI 合成 PDF 完整生成检查通过。代码与进度见本仓库最新 main。此项只简化电脑准备教材的步骤，尚不等于 iPhone App 内直接导入 PPTX；云端 Flutter/iOS 构建若尚未针对该提交运行，以前次绿色版为准。
