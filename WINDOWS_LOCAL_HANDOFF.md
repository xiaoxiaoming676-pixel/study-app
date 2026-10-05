# Windows 本地任务交接 · Study iOS App

更新：2026-10-05。仓库：https://github.com/xiaoxiaoming676-pixel/study-app ，上一个已核验的开发检查点：`7454f5076c87976d1c49609bf0d6fd396eea78c9`；请以仓库实时 main 为准。

本次 Windows 接手新增提交：`bdd2dd9ac623117627e0c9850f0fa6a962fa4149`（PowerPoint 教材转换及本地测试）、`37f437059737030be2f4e5e6ccd045259ffa614f`（独立 Windows Flutter 验证工作流）。详见 `BUILD_PROGRESS.md`。

## 用户目标与设备

第一版优先做出可用的 iPhone 学习 App：PPT/教材导入、任意空白书写笔记并保存、标记或关键词自动挖空（不只红色）、扫描页 OCR、普通男女系统朗读，iPhone 优先兼顾 iPad。用户现在只有 Windows 笔记本和 Android 手机，**没有任何苹果设备**。每一步修复要提交到仓库并更新 `BUILD_PROGRESS.md`。

## 已有代码

基于 Saber pinned commit `5b396a40406c75835741f5c4555bc10ae816f121`，`overlay/` 覆盖上游源码；`.github/workflows/study-ios.yml` 展示应用方式。学习页、PDF 手写/批注、挖空候选、PDFKit/Vision 扫描关键词 OCR、朗读通道、保存和导出已写入代码。此前通过 9/9 Dart 单元测试和 iOS 无签名构建。模拟器集成测试尚未整条通过；最近一次业务测试败在测试脚本使用未注册的 `TestTextInput.hide()`，已改为 `FocusManager.instance.primaryFocus?.unfocus()`，待重跑。

新版 `Study` 名称与 `com.xiaoxiaoming676.studyapp` 标识写在工作流应用步骤，**尚未由云端运行器执行并验证**。旧 IPA 仍叫 Saber 且未签名，不是可安装交付版。App 内直接 PPTX 转换尚未完成；Windows 教材工具在 `overlay/tools/study/`。

## 当前云端阻塞

GitHub Actions 运行 [37247985115](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37247985115) 首次及重试均在运行器分配前失败：`runner_id=0`、`steps=[]`、约 6–8 秒、计费 0 毫秒。无法从 API 读取此零步骤作业的错误横幅。仓库拥有者登录网页后需查看运行页面顶部的原始提示，再查看 GitHub Settings → Billing / Actions 用量或限制；**不要未经用户决定自行增加预算或付费**。这次失败不能视为源码编译错误。本地核对了工作流 YAML 可解析，以及上游项目包标识替换的数量断言成立。

后续 [macOS 运行 37260329062](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37260329062) 与 [Windows 运行 37265710398](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37265710398) 也都是 0 步、`runner_id=0`、0 计费毫秒，尚无 Flutter 分析或编译结果。未登录的浏览器对私有仓库显示 404，已打开登录页；等用户登录后查看横幅。跨 macOS/Windows 都失败提示可能是账户或仓库级 Actions 限制，但**具体原因尚未确认**。

用户已登录网页并核对：运行页提示“recent account payments have failed or your spending limit needs to be increased”。账户 Billing Overview 显示 **2,000/2,000 Actions 免费分钟用尽**、本月计费 $0；Budgets and alerts 中 Actions 预算为 **$0** 且 Stop usage 为 Yes。免费分钟约 27 天后重置。应以这条已确认信息替代上段的待核查推测；没有修改预算或支付设置。仓库仍为私有。

用户选择公开仓库以使用免费的标准 GitHub 托管运行器，操作待最终确认。公开前检查当前源码与 28 次提交补丁，未发现密钥格式或曾删除文件；历史提交包含作者邮箱和本机用户名路径，Actions 历史/日志公开后也会可见。当前文档已去掉绝对本机路径，历史记录仍保留。不修改 $0 Actions 预算。

## 本次 Windows 本地结果

任务运行在用户电脑 Documents 目录的 PowerShell；Python 3.10.7 和 PowerPoint 16.0 可用，Git/Flutter 命令不在 PATH。仓库源码通过 GitHub 连接取得；Git 与固定 Saber 源码压缩包的下载因网络慢/中断未完成。已给 `overlay/tools/study/prepare.py` 增加 Windows PowerPoint PDF 转换路径，完整的 Python 教材工具测试 **10/10 通过**，含中文文件名 PPTX 转换、挖空和 PDF 几何/批注测试；Python 语法编译通过。本机未运行 Flutter 静态分析、Dart 测试、Xcode 或 iOS 模拟器。不要把 Windows 教材工具通过视为 App 业务流程通过。

## 在 Windows 本地接手时立即做

1. 确认当前任务使用 **本机 Windows 文件系统/终端**，而非云端 Linux。记录 `pwd` / `Get-Location`、`git --version`、`python --version`、`flutter --version`（若有），不要回显敏感环境变量。
2. 获取私有仓库最新 main，确认 main 包含上面的检查点；若已有工作树，先看 `git status` 并保留用户改动。读 `README.md`、`BUILD_PROGRESS.md`、`INSTALL_WINDOWS.md` 和工作流，按固定 Saber 基线应用 overlay；不要从零重建。
3. 在 Windows 跑能运行的 Python 教材转换测试：`python -m unittest discover -s tools/study -p "test_*.py" -v`（在覆盖后的 Saber 源码中）；如有 Flutter SDK，跑学习模块静态分析及 `flutter test test/study`。若本机无 SDK，判断安装或可用替代途径，先做其他检查。
4. 零步骤作业的网页提示和 2,000/2,000 免费分钟、$0 停用预算已确认。继续本地和代码工作；未经用户明确决定不改变预算、支付设置或仓库可见性。
5. Windows 无 Xcode，不能本机运行 iOS 模拟器或生成 iOS 正式包；云端 Mac 恢复后重跑集成测试并修问题。用户无 iPhone/iPad，暂不安装 Sideloadly、不做个人签名或真机测试。可用模拟器覆盖核心流程，真机验收需将来借用设备或合适的远程真机服务。
6. 修复和测试证据提交仓库，每步更新 `BUILD_PROGRESS.md`。不要把“编译成功”当成功能通过。优先完成 PDF 导入/手指书写/保存重开、挖空、笔记、朗读，再处理 PPTX 一键导入路线和扫描图中样式标记识别。

用户在电脑端的新本地任务可以引用本文件，并要求直接继续实施。
