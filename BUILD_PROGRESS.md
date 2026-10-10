# 构建与测试进度

2026-10-10 · 第一批界面完善（开发分支 codex/study-ux-improvements）

- 已完成挖空候选按页加载原文预览、区域叠加、答案及位置修改、移除候选；保存状态在学习页直接显示，失败时可见重试按钮。
- 继续完善学习操作提示与 PPTX 导入反馈；此处仅记录开发进度，待 CI 和设备验证后再标记完成。
- 学习页增加四个模式的短提示和“返回书写”入口；PPTX 导入显示本机转换等待时间、可取消，并区分转换和页面导入的结果。集成流程加入候选区域编辑后保存的断言。
- 通过开发分支临时启用 iOS CI，验证静态分析、集成测试和编译；测试通过后移除临时分支触发配置。
- 首轮 CI 38038612866 在静态分析阶段因 5 条代码规范提示失败；已按日志修复集合表达式、异步 context 使用、占位参数及文件末尾空行，等待复跑。
- 第二轮 CI 38038791782 只剩集成测试文件末尾多余空行，已修复并再次提交。

2026-09-17

第一次运行 35235644496 已完成环境搭建与依赖安装。Flutter 3.47.4、Dart 3.13.3、Xcode 26.6。
静态分析发现 PlatformFile.bytes 接口不存在，已改为插件支持的 readAsBytes()。同时按日志修复 28 项代码规范提示。
本次提交尚待云端重新验证。测试、iOS 编译、签名和真机验证尚未完成。
工作流增加仅 main 分支学习源码/构建配置改动触发，便于后续修复后自动检查，不需要反复手动启动。

2026-09-28 第二次运行 36362081827：Flutter 学习模块静态分析通过；9 项测试中 8 项通过。唯一失败为矩形浮点数的严格相等断言，已改为误差小于百万分之一的坐标比较；苹果编译还未执行，等待下一轮。

2026-09-28 第三次运行 36362400239：Flutter 静态分析成功；9/9 学习测试通过；Xcode 无签名构建成功（Runner.app 52.7 MB）；归档上传成功。
云端产物 artifact 10946217962：Study-unsigned-iOS-app.zip，包含 22,250,648 字节 IPA 和 SHA256 清单；期限截至 2026-10-12。
SHA256：446848005b6c5c678d7d21dfac8f63cfc2b5e606ed7748b8f27260f7fa806571。已下载核验 zip、IPA、清单，Info.plist：Bundle ID com.adilhanney.saber，显示名 Saber，最低 iOS 15.0；没有 embedded.mobileprovision。
安装到真机还需签名。未经真机运行和核心学习流程验收；手机内 PPTX 转换仍未完成。
GitHub 构建记录：https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/36362400239

2026-10-02：第四次运行 36944871735 已通过静态分析、9/9 单元测试、无签名 iOS 构建；新版 IPA 已归档。新增 iOS Vision 扫描 PDF OCR、关键词坐标识别、原生朗读与候选确认。第五次运行 36946610288 成功编译并启动 iPhone 模拟器，但集成测试入口缺少 Saber 的 FlavorConfig 初始化，未到业务步骤。已修复测试入口，增加真实模拟笔书写、扫描 PDF OCR 及保存重开断言；第六次运行 36947400785 正在执行。

验收边界：代码级与模拟器级测试不等同用户 iPhone 真机体验。PPTX 在 App 内直接转换尚未实现；iPhone Keynote 导出 PDF 是目前可操作的教材路径。IPA 仍无签名，不能直接安装到用户手机。下一步按集成测试日志逐项修复，并补充有签名的真机验证和 PPTX 转换方案。

2026-10-03：第六次运行 36947400785 已通过 Flutter 静态分析、9/9 单元测试，iPhone 模拟器完成 Xcode 编译并启动。集成测试因测试入口未初始化 Sentry 状态而在首页报错，后续笔迹断言因此无效。提交 aba0427 已修复测试入口，并让后续即使集成测试失败也保留无签名构建产物，同时通过最后一步维持失败标记。第七次运行 37092999879 等待/正在执行，须读取结果后更新实际验收情况。

2026-10-03：第七次运行 37092999879 通过静态分析、9/9 单元测试、iOS 模拟器 Xcode 编译和无签名 IPA 构建/上传。模拟器集成测试在笔迹断言处失败（第 60 行，保存后笔迹列表为空），因此扫描 OCR、挖空、笔记、朗读及重开流程尚未由这条测试执行。已修正笔迹测试，明确将触点放在导入 PDF 页内、启用 iPhone 手指书写、逐步泵送手势帧，并在保存前断言内存中的笔迹，以便定位画布交互。真实 iPhone 安装、Files 文件选取界面和 PPTX 直接导入仍需单独验收/实现。

2026-10-03：第八次运行 37094153565 的模拟器流程已通过导入页上的手指笔迹保存前断言，并继续到 OCR、自动挖空候选；随后因自动挖空弹窗在退出动画前释放 TextEditingController 而报错，笔记入口未能继续。修复挖空颜色输入及笔记输入的临时控制器生命周期，并在测试中等待保存与按钮启用后再进入笔记；下一轮待验。第八次无签名 IPA 已编译，但该流程测试未通过，不作为验收完成。

2026-10-03：第九次运行 37095870276 再次通过静态分析、9/9 单元测试、iOS 模拟器编译及无签名 IPA 构建。集成流程已越过上次的输入框生命周期异常，但测试辅助代码将 RawTooltip 强制转为 IconButton 而报类型错误（第 119 行）；这是测试选择器问题，尚未证明笔记与后续流程。已改用 IconButton 属性谓词等到按钮可点击，再继续验证。

2026-10-04：第十次运行 37097219204 通过静态分析、9/9 单元测试、模拟器编译和无签名 IPA 构建归档。端到端测试的指尖书写、PDF 文字坐标、扫描页 Vision OCR 与候选生成均已执行，但“保存候选”按钮被仍开启的键盘推到模拟器视窗之外，点击落空；后续笔记、朗读和重开未执行。已在生成候选时关闭键盘，并让集成测试模拟键盘收起后再进入确认页；下一轮仍需核验整条流程。

2026-10-05：第十一次运行 37244200086 的学习模块静态分析、9/9 单元测试、无签名 iOS 正式包构建与归档通过；模拟器集成测试未启动业务流程，因测试辅助语句 `await tester.testTextInput.hide()` 对返回 void 的方法使用 await 导致 Dart 编译失败。已删除 await，下一轮需要重新验证挖空候选确认、笔记、朗读与重开。该轮归档 11319380910 仍未签名，不能直接安装到用户 iPhone。

2026-10-05：第十二次运行 37246129034 通过静态分析、9/9 单元测试、无签名 iOS 构建和归档；模拟器业务测试在辅助代码 TestTextInput.hide() 处失败，因为真机式 integration_test 未注册该假键盘，尚未到候选保存。改用 FocusManager 收起真实界面焦点；工作流增加集成测试静态分析及独立 Study 名称/包标识，Windows 首装指引改为选择绿色构建并逐项实测。下一轮须重新验证。

2026-10-05：第十三次运行 37247985115 及重试均在 GitHub 分配 macOS 运行器前约 6–8 秒失败，步骤 0、runner_id 0、计费时长 0；不能据此判定新代码编译失败。可能与私有仓库 GitHub Actions 额度/账户限制相关，需在账户 Actions/Billing 页面核对具体提示；同时本地核查打包标识替换断言（上游 bundle ID 6 处，显示名配置 3 处，Info.plist 2 处）成立。第十二次归档 IPA 已下载并核验 SHA256，另存为仅供首装排错的未签名临时包，仍保留 Saber 标识且业务集成测试未过。正式 Study 独立标识包待云端运行器恢复后构建。

2026-10-05 用户更正设备条件：当前没有 iPhone、iPad 或其他苹果设备，今天只能拿到 Windows 电脑。已修正安装文档：先查 GitHub Actions 的无运行器失败提示、做 Windows 可执行的源码/教材工具测试；iOS 编译和模拟器继续依赖云端 Mac，签名安装与真机验收延后至有设备/合适远程真机时。先前要求今天用电脑签名安装到本人 iPhone 的步骤不适用。

2026-10-05 Windows 本地接手：在用户电脑的 Documents 目录运行 PowerShell，Python 3.10.7 可用；Git 和 Flutter 命令均未安装或未在 PATH。私有仓库实时 main 为 `ae6b2b480f7ec1e3a74574827a89ea7386431b50`，确认它包含交接检查点 `7454f5076c87976d1c49609bf0d6fd396eea78c9`。已通过仓库连接取回源码；固定 Saber 基线的压缩包下载中断，且本机无 Flutter SDK，所以本轮不能声称完成 Flutter 静态分析、Dart 测试或 iOS 编译。

本机安装了 PowerPoint 16.0，教材工具新增无 LibreOffice 时调用 PowerPoint 导出 PDF 的路径，支持中文文件名，无需改变系统 PowerShell 执行策略。PowerPoint 实际导出的文件以 `%PDF-` 开头；`python -m py_compile` 通过；在本地虚拟环境安装固定的 `python-pptx 1.0.2` 和 `PyMuPDF 1.26.6` 后，`python -m unittest discover -s tools/study -p "test_*.py" -v` 全部 **10/10 通过**，其中包含真实 PPTX 转换和挖空生成。Windows 教材工具可用，但 App 内 PPTX 一键导入仍未完成。

GitHub API 再次确认第十三次运行的第二次尝试只有 1 个失败作业、0 步、`runner_id=0`、计费 0 毫秒；读取作业日志返回不存在。浏览器入口本轮无法载入 GitHub 页面，仍未取得网页顶部的原始失败提示，暂不能确认是额度、账单还是其他运行器限制。没有修改任何付费设置。用户没有苹果设备，iOS 模拟器完整流程及真机体验仍待云端 Mac 恢复和未来有设备时验证。

提交 `bdd2dd9ac623117627e0c9850f0fa6a962fa4149` 已把上述 Windows PowerPoint 转换、中文路径回归测试及本地 10/10 测试证据推送至 main。它触发的 [第十四次 iOS 运行](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37260329062) 再次于约 8 秒后失败：0 步、`runner_id=0`、macOS 计费 0 毫秒；新代码仍未进入云端编译。已新增独立的 Windows Flutter 静态分析和学习单元测试工作流，以尝试在无 Mac 运行器时取得 Dart 结果；其 YAML 已在本机解析，运行结果待核对。GitHub 网页在未登录状态对私有仓库显示 404，已打开登录页供仓库拥有者查看原始提示。

提交 `37f437059737030be2f4e5e6ccd045259ffa614f` 新增的 [Windows Flutter 验证](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37265710398) 也在约 6 秒后失败：0 步、`runner_id=0`、Windows 计费 0 毫秒。两种操作系统的托管运行器均未启动，不能把失败归因于 Flutter 源码或仅 macOS 镜像。下一步需在已登录 GitHub 的运行页面读取顶部原始提示，再决定是否调整 Actions 设置；未经用户决定不增加预算或付费。

2026-10-05 登录后确认账户级阻塞：上述 [iOS 运行](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37247985115) 与 [Windows 运行](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37265710398) 顶部均提示作业未启动，原因是最近付款失败或需提高支出上限。账户 [Billing Overview](https://github.com/settings/billing) 显示 GitHub Free 的 Actions 免费分钟 **2,000 / 2,000 已用完**、本月已计费金额 $0；[Budgets and alerts](https://github.com/settings/billing/budgets) 显示 Actions 预算 **$0** 且“Stop usage”启用。这一组合足以解释私有仓库的托管运行器被阻止；没有源码编译失败证据。页面显示免费额度约 27 天后重置。未查看或更改支付资料、预算、仓库可见性。后续可等额度重置，或由用户明确决定付费预算/公开仓库；本地 Windows 教材工具测试结果仍为 10/10 通过，Flutter/iOS 业务验收仍待进行。

用户选择改为公开仓库以使用免费的标准托管运行器，变更尚未执行。公开前检查了当前源码和 28 次提交中的文件名/补丁：没有发现密钥格式或曾删除的文件；历史提交含作者邮箱，早期文档补丁含本机用户名路径。公开还会让 Actions 历史及日志对所有人可见。已从当前文档删去本机绝对路径，但历史记录不会因此消失。等待公开操作的最终确认；不修改 Actions 预算。

2026-10-05 用户最终确认后，仓库已改为公开，GitHub API 确认 `visibility=public`。历史提交作者邮箱、早期文档中的本机用户名路径和 Actions 历史/日志现已公开可见。Actions 预算仍为 $0，没有修改支付设置。公开后手动启动 [iOS 运行 37267208722](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37267208722) 和 [Windows 运行 37267237712](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37267237712)。两个作业都已获得真实托管运行器。Windows Flutter 学习模块静态分析无问题，9/9 项单元测试通过。iOS 静态分析、9/9 项单元测试、无签名编译和归档上传成功（产物 11327269574，Study 包标识）；但模拟器测试**失败**，整条工作流为红色。工作流的 `continue-on-error` 使步骤列表显示 `conclusion=success`，完整日志才显示测试退出码 1。测试已实际通过 PDF 导入、手指书写和保存、原生 PDF 文字坐标、扫描页 Vision OCR、挖空候选、长期笔记和朗读；在关闭并重新打开笔记后，测试脚本点击了尚不能命中的旧工具栏 Tooltip，随后未找到学习面板（测试第 147–148 行）。已把重新打开后的按钮查找改为等待可命中控件，再重跑确认持久化 UI 流程。先前的零步骤失败是私有仓库免费分钟用尽造成的运行器阻塞。没有苹果设备，真机验收仍待将来进行；App 内直接导入 PPTX 尚未完成。

2026-10-05 提交 `9e04e783c139c725757c3e5c076ddd927563a3f3` 后，[Windows 运行 37269586628](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37269586628) 再次绿色通过；[iOS 运行 37269586591](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37269586591) 静态检查、9/9 单元测试、无签名编译和归档上传成功，但模拟器测试又在更早的“挖空”标签点击处失败（第 106–107 行），整条工作流红色。日志显示标签仍在页面滑入动画中，测试点击坐标 x=523.5 超出 390 像素屏幕，因此“自动挖空”未显示；这是测试交互时序问题，不能据此认定挖空功能失败。已让测试等待“挖空”标签真正可命中后再点击，保留重开笔记处的同类等待；下一轮需完整通过后才能称为模拟器业务验收。

2026-10-05 提交 `8c4d25f4c7d0819bab8eb35121231a88fa6390d7` 后，[Windows 运行 37271995128](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37271995128) **绿色通过**：Flutter 静态检查无问题，9/9 项学习模块单元测试通过。[iOS 运行 37271995174](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37271995174) **整体绿色通过**：静态检查无问题、9/9 单元测试通过、iPhone 模拟器端到端测试日志为 `+1: All tests passed!`，最后的失败检查正确跳过，Study 独立标识 `com.xiaoxiaoming676.studyapp` 的无签名 iOS 应用构建与归档上传成功。模拟器流程覆盖 PDF 导入、手指笔迹保存、文字坐标和扫描页 OCR、自动挖空与候选保存、长期笔记、朗读通道，以及关闭重开后的挖空和笔记持久化。归档 [Study-unsigned-iOS-app](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37271995174/artifacts/11329312423) 为 22,149,658 字节，GitHub 记录的归档 ZIP SHA256 为 `69ed0896055ab47dd0543e53c40f35ac44ffdf3580f805c8fbf712250c98eca0`，有效期至 2026-10-19 06:47 UTC；ZIP 内含 IPA 和 IPA 自身的 `SHA256.txt`。这是未签名包，不能直接安装到 iPhone；用户当前无苹果设备，真机验收未做。App 内直接导入 PPTX 尚未完成，Windows PowerPoint 教材转换工具已通过本地 10/10 测试。

2026-10-05 继续开发：查验 iOS 离线 PPTX 开源路线后，DocReader 的幻灯片解析只读文字框，PDF 渲染使用固定背景、固定字体；无法保留图片、公式和原版式，暂不集成到教材导入。扫描 PDF 新增按任意六位 RGB 字体颜色生成 OCR 挖空候选，保留人工逐项确认；模拟器测试增加红字 Alpha 与黑字 Beta 的区别断言。Windows 本地 Python 教材工具再次 10/10 通过。此项 iOS 变更仍待云端编译和模拟器验证，不能提前视为通过。

2026-10-05 [Windows 运行 37297200483](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37297200483) 绿色通过；[iOS 运行 37297200446](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37297200446) 静态检查、9/9 单元测试、模拟器编译、无签名应用构建及归档均通过，但新增的扫描红字候选断言失败，整条工作流为红色。日志显示 `Red scan text should be detected`，尚未完成后续原有业务断言。已修正像素读取的 RGBA 顺序和 Vision 左下角坐标与位图顶行坐标的转换，并让测试独立断言 OCR 文本；下一轮必须以整个工作流绿色为准。

2026-10-05 再次核对测试颜色：Flutter 的 `Colors.red` 实际为 `#F44336`，而新增断言原先请求 `#FF0000`。两者绿色和蓝色通道差距超过当时的匹配阈值，故第一次失败不能单凭日志归因于坐标方向。已把模拟器测试改成与样本一致的 `F44336`；像素顺序/坐标修正仍需在新一轮测试确认。

2026-10-05 [最新 Windows 运行 37300523370](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37300523370) 与 [iOS 运行 37300523342](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37300523342) **整体绿色通过**。iOS 日志确认静态检查无问题、9/9 学习单元测试、iPhone 模拟器端到端测试 `+1: All tests passed!`，包含扫描页彩色 Alpha 与黑色 Beta 的区别断言及此前已通过的 PDF 导入、笔迹、挖空、笔记、朗读和重开。无签名 `Study-unsigned-iOS-app` [归档 11343632694](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37300523342/artifacts/11343632694) 为 22,152,794 字节，GitHub ZIP SHA256 为 `d92606eb3fde5272d86b5b012ec3f0ca8a429fad6316c11610162e56438eab5d`，有效期至 2026-10-19 12:00 UTC。此包未签名，仍不能直接安装到 iPhone；真机测试未进行。已给 iOS 工作流加入 iPad 模拟器业务流程回归，待下一轮验证后才可称为 iPad 模拟器通过。

2026-10-05 [iPhone + iPad 双模拟器运行 37319109435](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37319109435) **整体绿色通过**：静态分析无问题、9/9 单元测试通过，iPhone 与 iPad 两次业务测试日志各为 `+1: All tests passed!`，无签名应用构建成功。两种屏幕均覆盖 PDF 导入、手指书写、扫描页关键词/颜色候选、挖空保存、笔记、朗读通道及重开持久化。最新 [归档 11351295695](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37319109435/artifacts/11351295695) 为 22,152,771 字节，ZIP SHA256 `e4f32ca1431289df53ba7452adcd3259fb4ba954358da88afbc6ea867c8f186d`，有效期至 2026-10-19 14:15 UTC。用户无苹果设备，真机实际手感、Files 选择器和系统语音听感仍未验收；包无签名，不能直接安装到用户手机。

2026-10-05 补充导出运行时检查：双模拟器端到端脚本在已保存笔迹、挖空和中文长期笔记后，逐一生成原文版、练习版、答题笔记版 PDF，并核对非空及 `%PDF` 文件头。此新增断言须待下一轮云端运行通过，不能以此前的绿色运行代替。

2026-10-05 [新增导出测试运行 37329256657](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37329256657) 整体失败：iPhone 与 iPad 均在首次生成 PDF 时由 pdfrx 抛出 `FPDF_ERR_FORMAT: 3`。静态检查、9/9 单元测试和无签名编译仍通过。已在测试中增加导入源 PDF 与保存资产逐字节比较，以区分保存损坏和渲染器读取问题；此诊断需由下一次云端运行确认。当前推荐下载仍是上一次绿色双模拟器归档 11351295695。

2026-10-05 [诊断运行 37334090670](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37334090670) **整体绿色通过**：Windows 静态分析及 9/9 单元测试通过；iPhone、iPad 两次端到端测试均显示 `+1: All tests passed!`。保存的 PDF 资产与导入源逐字节一致，三种学习 PDF 导出都生成有效文件头。前一轮 `FPDF_ERR_FORMAT` 未复现，原因尚未确定，故保留断言并在下一轮再次运行。无签名 [归档 11356863783](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37334090670/artifacts/11356863783) 为 22,153,060 字节，GitHub ZIP SHA256 `85a663f57efc25f689deff18c6f65fa4ffd86b8c7d693faf54310f74f72b2f67`，有效期至 2026-10-19 16:12 UTC。

2026-10-05 针对扫描教材的样式候选，新增对 OCR 文字区域中彩色浅底的高亮检测；测试样本使用黄色背景黑字 Beta 与白底红字 Alpha，要求只选前者。此逻辑仍会交给用户逐项复核，尚未通过云端模拟器验证。扫描图加粗、下划线仍无可靠证据，不宣称已支持。

2026-10-06 [扫描高亮运行 37339570321](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37339570321)：Windows 静态检查和 9/9 单元测试通过；iPhone 模拟器完整业务流程 `+1: All tests passed!`，覆盖黄色高亮候选和三种 PDF 导出；iPad 模拟器在测试脚本点击“保存候选”时按钮尚在屏幕外（日志坐标 y=2088，模拟器高度 1180），点击未命中，随后保存状态断言超时，整体 iOS 工作流红色。已让测试等待按钮真正可命中；下一轮需验证 iPad 完整通过。此轮无签名编译成功，但不作为推荐版本。

2026-10-06 正在增强导出回归：逐一用 PDF 阅读器重新打开三种导出，核对原文版、挖空版各 1 页、笔记答题版 2 页；重开学习面板后还等待页面预览出现，确认保存的 PDF 资产可实际渲染。此断言尚未通过云端验证。

2026-10-06 [最终双模拟器运行 37345346944](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37345346944) **整体绿色通过**：对应 [Windows 运行 37345347141](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37345347141) 静态检查与 9/9 单元测试通过；iPhone、iPad 端到端日志各显示 `+1: All tests passed!`，没有 `FPDF_ERR_FORMAT`。流程包含扫描页黄色浅底高亮候选、红字颜色候选、PDF 导入与手指书写、挖空和长期笔记保存、朗读通道、保存 PDF 与导入源逐字节比对、三种 PDF 导出重新打开后的页数（原文与练习各 1 页，笔记答题 2 页），以及关闭重开后的教材页面预览、挖空和笔记。无签名 [Study 归档 11360794709](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37345346944/artifacts/11360794709) 为 22,154,203 字节，GitHub ZIP SHA256 `78f20c4408b6bd100f77684f055b0949ea8cac39768cdf42323e21ceab7c6e6c`，有效期至 2026-10-19 17:27 UTC。前两轮中有一次 PDFium 读取错误，当前两轮未复现，原因仍不明；继续保留导出断言。用户无苹果设备，真机与正式签名未完成；App 内直接 PPTX 仍缺可靠转换路径。

2026-10-06 正在验证扫描页下划线候选：在 OCR 文字框下缘附近寻找跨越大部分文字宽度的深色横线；合成样本要求选中带横线的 Beta，排除无横线的 Alpha。候选仍需人工确认，代码尚待 iPhone、iPad 模拟器编译和业务回归。

2026-10-06 [下划线 iOS 运行 37368501535](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37368501535) 与 [Windows 运行 37368501599](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37368501599) 已触发，但截至 2026-10-06 04:19 北京时间仍在排队、尚未分配运行器。[GitHub 官方状态页](https://www.githubstatus.com/) 同时报告 Actions 托管运行器分配延迟，不能把排队视为代码编译失败。新增研究确认 office-kit/pptx 自称预览不具像素精确性，900Slides 是桌面工具；二者尚不能证明手机内可靠 PPTX 转换，细节见 `PPTX_EVALUATION.md`。最后已验证版本仍为运行 37345346944。
2026-10-06 约 04:30 北京时间，上述 iOS 与 Windows 作业均在等待约 15 分钟后显示整体失败；各自唯一作业为 `cancelled`，`steps=null`、无运行器日志，未进行编译或业务测试。GitHub 状态页当时仍报告 Actions 托管运行器分配延迟。下划线识别提交 `7281401e54badcee1a9eaa81fd8ce20e15286d13` 仍待云端验证，不能归入绿色版本。已另在 Windows 用三页合成 PPTX 核对浏览器离线渲染原型与 PowerPoint PDF：基本画面接近，中英文普通文本可正确提取，但图表有可见差异且浏览器 PDF 中图表标签无可提取文字；细节及尚未满足的 iOS 验收条件见 `PPTX_EVALUATION.md`。两条失败作业已申请第 2 次运行，结果待核对。
2026-10-06 约 04:50 北京时间，第 2 次运行也结束：iOS `37368501535` 和 Windows `37368501599` 各自在排队约 15 分钟后显示整体失败，最新尝试的唯一作业均为 `cancelled`、`steps=null`，没有执行 Flutter 分析、Swift 编译或模拟器测试。[GitHub 状态页](https://www.githubstatus.com/) 20:39 UTC 的更新明确报告托管运行器分配造成作业失败和延迟。暂不在事故持续期间反复重试；恢复后优先重跑上述提交并查看完整日志，若下划线断言或编译失败再修代码。当前可用的最后绿色版本仍是 `89d0eee9a9b5b09e635609d1f0ce839daf574630` 对应运行 `37345346944`；`7281401` 的下划线功能尚未验证。
2026-10-06 GitHub Actions 恢复后，第 3 次运行已在托管运行器真正执行。[iOS 运行 37368501535](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37368501535) 与 [Windows 运行 37368501599](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37368501599) **整体绿色通过**，验证源代码提交 `7281401e54badcee1a9eaa81fd8ce20e15286d13`。Windows 日志确认 Flutter 静态检查无问题、9/9 学习单元测试通过；iOS 日志确认同样检查通过、iPhone 与 iPad 模拟器各有 `+1: All tests passed!`、无签名 iOS 构建及归档成功。合成扫描页的近似下划线 Beta 候选与无下划线 Alpha 排除断言随完整业务流程通过。新 [Study 无签名归档 11381842224](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37368501535/artifacts/11381842224) 为 22,154,549 字节，GitHub ZIP SHA256 `f3adbf5eb13872854c5e40b970933f6ccee1c116894c17f2bf05dcafbb4fa628`，有效期至 2026-10-20 00:12 UTC。历史上两次零步骤失败是 GitHub 服务事故，不是源代码失败。扫描页下划线仅为近似候选，真实教材准确率仍待验证；App 内 PPTX 直接导入、真实设备测试及正式签名仍未完成。
2026-10-06 Windows 教材准备流程简化：增加 `start_study_tool.cmd` 和 `overlay/tools/study/gui.py`，可在本机窗口选择 PDF/PPTX、输入关键词与 RGB 颜色、勾选加粗/显式下划线，并自动建议不覆盖旧结果的新文件夹。仍调用现有 `prepare.py`，没有改变手机端导入格式或云端部署。修正 Windows PowerPoint 转换：如果转换前已有 POWERPNT 进程，就不调用会退出整个应用的 `Application.Quit`。本机 Python 工具 10/10 测试通过，其中 PPTX 测试在已有 PowerPoint 会话时仍通过且会话保留；窗口合成 PDF 端到端检查成功生成 textbook.pdf、practice.pdf、study-rules.json。Flutter/iOS 本轮尚未重新触发，前次绿色运行仍为 37368501535/37368501599。App 内直接 PPTX 导入、真实教材精度和苹果真机交付仍未完成。
2026-10-06 提交 [`063200ecc4a60ed8d4aa16593597b6085dc45e80`](https://github.com/xiaoxiaoming676-pixel/study-app/commit/063200ecc4a60ed8d4aa16593597b6085dc45e80) 后，[Windows 运行 37394157102](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37394157102) 与 [iOS 运行 37394156946](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37394156946) **整体绿色通过**。Windows Flutter 静态检查和学习测试步骤成功；iOS 日志确认静态分析无问题、9/9 单元测试、iPhone 与 iPad 各 `+1: All tests passed!`、无签名 iOS 构建及归档上传成功。新 [Study 无签名归档 11384530556](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37394156946/artifacts/11384530556) 为 22,154,624 字节，GitHub ZIP SHA256 `629039466e7b6a2e3f2d6ad385f9bd710df3bca288b875f53dc09e650fcae9db`，有效期至 2026-10-20 01:11 UTC。新 GUI 的本机合成 PDF 完整生成检查及 PowerPoint 已运行会话保留检查已通过；云端工作流未单独运行 GUI 自动化。旧段“本轮尚未重新触发”是提交前状态，以本段为准。仍需真实教材版式/准确率、大文件性能、App 内 PPTX 和苹果真机签名交付。
同日补充本机 GUI PPTX 端到端检查：用无敏感合成单页 PPTX，在窗口设置关键词后，经 PowerPoint 转换成功生成 `textbook.pdf`、`practice.pdf`、`study-rules.json`；前述 PDF GUI 检查也通过。这验证电脑端窗口调用真实转换器的路径，不代表 iOS 手机内已能直接导入 PPTX。
2026-10-06 阶段 1（合成教材验收框架）本机完成、待云端验证：新增固定 corpus（可选中文字 PDF、图像扫描页、含中文/表格/图表/图片的四页 PPTX 及 PowerPoint 参考 PDF、120 页 PDF），以 `corpus.json` 固定 SHA256、页数、扫描词语与位置。`quality/evaluate.py` 对候选 PDF 按页计算视觉误差、宽高比和可提取文字召回率；`quality/score_scan.py` 记录 TP/FP/FN 与误检漏检。Windows 工作流加入固定 corpus 自动检查；本机教材工具测试 **14/14 通过**，参考 PDF 自比较门槛通过，故意损坏页面被门槛拒绝。用户暂无可去隐私的真实教材，合成样本通过不等于真实准确率或大文件手机性能通过；本阶段后续必须以真实教材与 iPhone/iPad 模拟器记录补齐。
2026-10-06 阶段 1 云端复核：提交 `5b8004526a77733444ce2442dcd07ca141fd0a9c` 的 [Windows 运行 37401781636](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37401781636) 整体绿色，固定 corpus 检查和现有 Flutter 测试均成功。[iOS 运行 37401781526](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37401781526) 的 iPhone 模拟器学习流程已成功；iPad、无签名构建仍在运行，暂不记为整体通过。
2026-10-06 阶段 2 离线 PPTX 原型待云端验证：以固定 `@aiden0z/pptx-renderer` 1.3.0 独立浏览器 ESM、SHA256 校验和 Apache-2.0 许可文件在构建时打包进 App；运行时 WKWebView 不调用网络。新增 PPTX 入口，转换成功后调用现有 PDF 导入，不另建笔迹/挖空系统。加入 16 MB 输入、推荐 ZIP 解压限制、100 页、150 MB 输出、180 秒超时、取消、WebKit 进程终止提示和字体回退。Windows Edge 用固定四页合成课件和同一桥接页面渲染成功，PowerPoint 参考 PDF 的平均 RGB 误差约 1.933/255、最大页 2.604/255，图表页 PDF 可提取文字召回率 0，故完整质量门槛未过；这不代表 iOS WKWebView 转换已成功。iPhone/iPad 新集成测试和云端编译须在下一提交后运行。
2026-10-06 阶段 1 合成验收框架云端完成：提交 `5b8004526a77733444ce2442dcd07ca141fd0a9c` 的 [Windows 运行 37401781636](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37401781636) 和 [iOS 运行 37401781526](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37401781526) 均整体绿色。iPhone、iPad 模拟器原有学习流程各自通过，无签名 iOS 构建上传成功；[归档 11386628152](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37401781526/artifacts/11386628152) 的 GitHub ZIP 摘要为 `f5527a35609efc08e9360462bcedec7581449277b9bb05fd5b09704e2e47e17f`，到期 2026-10-20 02:34 UTC。上一段“iOS 运行中”是过程状态，以本段为准。合成语料及模拟器通过仍不等于真实教材准确率、真实 120 页手机峰值内存或真机体验通过；用户暂未提供真实教材。
2026-10-06 用户要求保存进度，暂停主动开发时的交接点：主分支已提交离线 PPTX 原型 `0f7b821`、静态检查修正 `24fe712`、iPhone PDF 视觉对比流水线 `7663e40`，以及阶段 1 绿色结果记录 `6de364e`。Windows [运行 37404450202](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37404450202) 已整体绿色；最新视觉对比版本的 [Windows 运行 37404816039](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37404816039) 当时仍在静态分析。[iOS 运行 37404450255](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37404450255) 已通过离线渲染器固定版本/摘要校验和 Flutter 静态分析，正在执行学习测试；[iOS 运行 37404816081](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37404816081) 排队，包含新增的模拟器 PDF 对 PowerPoint 参考文件视觉打分。尚未声称 iOS PPTX 转换通过。恢复后先检查这三条运行的结果和失败日志，修复并重跑，再将 iPhone/iPad PPTX 导入、保存重开、失败边界及视觉对比分数写入本文件。之后按用户阶段顺序继续真实样本验收、数据可靠性、测试包、发布准备。真实教材暂无，因此真实准确率和大文件真机内存仍待样本；无 Apple Developer 账号，正式签名/TestFlight 仍待账号。
2026-10-06 阶段 2 失败定位与修复待复验：[iOS 运行 37404450255](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37404450255) 与 [37404816081](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37404816081) 均完成 Flutter 静态分析、原有 PDF 学习测试和无签名构建，但新 PPTX 测试抛出 `PPTX_MODULE`（WKWebView 本地 ES 模块未启动），因此最终强制检查失败；部分步骤显示绿色是 `continue-on-error` 的包装状态，不可当成 PPTX 通过。最新 [Windows 运行 37404816039](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37404816039) 整体绿色。已将固定渲染器 ESM 经固定 esbuild 0.25.12 转为 IIFE，并在构建时内嵌到唯一的离线 HTML 文件，保留脚本 SHA256 校验和第三方许可说明；同一内嵌文件在本机 Edge 的 file:// 页面重新渲染固定四页成功。此修复尚待新的 iPhone/iPad 模拟器与视觉打分运行验证。恢复后先看新运行，尤其区分测试步骤的实际 outcome 与 continue-on-error 后的 conclusion。
2026-10-06 接续：[Windows 运行 37434382602](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37434382602) 整体绿色；[iOS 运行 37434382755](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37434382755) 最终红色，但执行到了 iPhone PPTX 后的视觉比较步骤，该步骤退出码 2，且未上传预期的合成 PDF/评分归档。由于 `continue-on-error` 包装，不能仅凭步骤外观断言 iPhone/iPad PPTX 测试均通过；未取得可复核的视觉分数。已调整集成测试：将固定合成 PPTX 生成的 PDF 分块写入测试日志，CI 严格核对块数、字节数及 PDF 文件头后还原并评分，避免测试 App 结束后依赖模拟器临时目录。只传合成样本产物。离线解析额外收紧 ZIP 解压限制（单项 16 MiB、总量 96 MiB、媒体 64 MiB、并发 2）；本机以高压缩比的超限样本确认被拒，正常四页样本仍可渲染。本机 Python 教材与质量测试 15/15 通过。以上修复需由下一次 iOS 整体绿色、评分文件和双模拟器结果复验，当前不能称阶段 2 完成。
同日提交 `6947eed` 的 [Windows 运行 37443429868](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37443429868) 与 [iOS 运行 37443429990](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37443429990) 都在约 3 分钟处失败，没有生成归档；尚未拿到两者的具体失败行，不能断言根因。新增测试中的 `print` 可能违反 Flutter 静态检查规则，现改为 `debugPrintSynchronously` 后重新运行。上一轮 15/15 本机 Python 测试仍通过，但不替代这次云端 Flutter 检查。
2026-10-06 阶段 2 模拟器原型复验：提交 `aada5dc` 的 [Windows 运行 37444388641](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37444388641) 与 [iOS 运行 37444388719](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37444388719) **整体绿色**。iOS 作业摘要逐项显示 Flutter 分析、原有学习测试、iPhone/iPad 两次离线 PPTX 转换测试、iPhone 视觉比较、无签名构建及上传均成功，最终失败检查跳过。固定四页合成课件的模拟器 PDF 与本机 PowerPoint 参考比较：RGB 平均误差 2.219/255，最差页 2.916/255，四页页数和宽高比均过线；图表第 3 页的可提取文字召回率为 0，完整质量门槛 `passed=false`，因此只能称**视觉原型通过**，不能称复杂教材语义质量通过。并排查看图表页，月份标签和柱体均可见，但标签未成为 PDF 可提取文字。合成比较 [归档 11403134528](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37444388719/artifacts/11403134528) 包含实际模拟器 PDF 和 JSON 评分，GitHub ZIP SHA256 `9db264d3be6e5b58cb5bf1420668bf2007690100285a59408de024d7e92125e0`；无签名应用 [归档 11404124367](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37444388719/artifacts/11404124367)，GitHub ZIP SHA256 `a89e525681330ce58744a487badd8273a7946659d019b14021681220794aafdb`。二者截至 2026-10-20 过期。后续还需真实教材、图表文字可用性、100+ 页性能及真机确认，不能由合成模拟器结果代替。
阶段 2 接口补验待复核：在原有四页 PPTX 离线转换断言之后，新增通过现有 PDF 教材入口导入结果、保存并重开四页及背景资产断言。这只验证转换产物能进入既有学习数据链，不改写已经绿色通过的 PDF 学习流程；需等待下一轮 Windows 分析和 iPhone/iPad 模拟器通过。
阶段 2 接口测试修正：编辑器会额外保留一张空白笔记页，因此断言改为数四张有 PDF 背景的课件页，并等待异步导入结束后再保存。提交 `c358658` 的 Windows 运行 `37466877547` 已绿色，iOS 运行 `37466878025` 仍在执行；修正提交 `8054143` 的 Windows 运行 `37466996127` 已绿色，iOS 运行 `37466995996` 等待前一作业。两次 iOS 均未取得最终结论，暂不报告 PPTX→教材保存重开通过。
阶段 3 真实教材准确率仍缺用户许可样本；固定合成 corpus 可记录误检漏检，但不能外推到真实教材。120 页合成 PDF 只有 94,448 字节，虽能检查页数相关问题，不能代表几十 MB 扫描教材的内存压力。
阶段 4 数据可靠性本地改动待自动测试：学习记录新增 `schemaVersion=1`，无版本旧记录按 v0 读取并迁移，未来未知版本拒绝静默覆盖；保存期间的新编辑继续保持未保存并安排下一次写入，失败时最多延时重试三次。资产先于主文档写入，各文件先写同目录临时文件、刷新后替换，失败时旧文件保留；新增中断注入及旧版笔记/回答迁移测试。当前仍是逐文件提交，整组文档与多资产并非数据库式原子事务；实际 iOS 模拟器保存升级回归和大文件异常恢复尚待运行，不能承诺零丢失。

阶段 5 模拟器包流水线待验证：现有 unsigned IPA 继续保留；iOS 工作流新增调试版模拟器 `.app` 编译、在云端 iPad 模拟器安装启动及 ZIP/SHA256 归档，供无苹果设备阶段手动上传 Appetize。Appetize 官方要求 ZIP 中包含模拟器 `.app`；BrowserStack 接受 IPA 上传并可对 iOS 应用重签名，但本项目的 **unsigned IPA 尚未在 BrowserStack 实测**，不能声称可直接使用。阶段 4 提交 `b292bb8` 的 Windows 静态分析失败，具体诊断仍待本地工具复查；暂不记录为阶段 4 通过。

阶段 6 已提交未启用的 `codemagic.template.yaml` 和 `CODEMAGIC_SETUP.md`。模板复用固定 Saber 来源与 overlay，通过 Codemagic 的 App Store Connect API 集成取得签名材料，构建 signed IPA 并提交 TestFlight；仓库不存任何 Apple 密钥。要等用户拥有 Apple Developer Program 与 App Store Connect app 后才能实际调试和启用，当前不能视作签名或上传已完成。

阶段 7 Windows GUI 已在本机打成单文件 `StudyTextbookTool.exe`，40,397,858 字节，SHA256 `34f6d053b2fdf7b5377e95e47acf9f55d4a028b93494e367c0609485f12c3323`。打包后的无窗口依赖 smoke test 与本机教材测试 15/15 通过；保留已有 PowerPoint/LibreOffice 自动选择逻辑。新增 Windows Actions 可重复构建及归档，但云端结果待核对。EXE 未签名，Windows 首次运行可能提示发布者未知。

阶段 8 已编写手动稳定版 Release 流水线，要求指定同一提交的绿色 iOS 和 Windows 工具运行，下载其经过测试的 unsigned IPA、模拟器 ZIP、Windows EXE，生成 SHA256 和提交变更记录后才创建版本。工作流只响应手动触发，尚未实际发布；必须等阶段 4、5、7 的云端结果绿色并核对产物后再运行。

阶段 7 云端复验：[Windows 工具运行 37471751616](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37471751616) 整体绿色，包含 EXE 打包、封装后 smoke test 和固定教材测试；[归档 11417452584](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37471751616/artifacts/11417452584) GitHub ZIP SHA256 `f08eb5b3836e439506a386bdb1114bc58351e361c4c821aebc31ce5083906301`，2026-10-20 过期。云端无 PowerPoint/LibreOffice，真实转换用例有明确条件跳过；本机有 PowerPoint，15/15 全部通过。阶段 4 Windows Flutter 分析在同一提交仍失败，不能因此认定 App 数据可靠性通过。

阶段 4 静态检查根因已本机定位：保存重试计数器显式写 `int` 触发仓库的 `omit_obvious_property_types` 规则。改为类型推断后，以固定 Flutter 3.47.4 / Dart 3.13.3 在 Windows 本机按云端同范围执行 `dart analyze`，结果 `No issues found!`；Flutter 单元与 iOS 模拟器仍需新提交的云端结果。

提交 `db23867` 的 [Windows 运行 37474771603](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37474771603) 整体绿色：Flutter 分析、学习记录单元测试及固定 corpus 均通过。对应 [iOS 运行 37474771689](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37474771689) 已通过静态分析和学习单元测试，进入模拟器阶段，尚未取得整体结论；阶段 4 保存回归及阶段 5 模拟器 ZIP 暂不算完成。

阶段 3 合成大文件验收准备：复用固定的 120 页 PDF 作为 iOS 测试资源，新增独立模拟器用例记录导入毫秒、保存毫秒及进程 RSS 高水位，并验证关闭重开仍有 120 页、无效 PDF 导入不破坏原教材。该 PDF 仅 94,448 字节，测得到页数扩展和恢复路径，**测不到几十 MB 扫描教材的真实内存压力**；取消与真实扫描教材误检/漏检仍待专门样本和测试。

2026-10-06 初步核查（2026-10-07 已纠正）：此前只按步骤 conclusion=success 推断 db23867 的 iOS 流程通过，并将末尾失败错误归因于不存在的 large_pdf_flow，该推断不成立。该提交的工作流没有引用 large_pdf_flow；完整日志确认 iPhone/iPad 均在长期笔记持久化断言失败（期望“这段需要复习”，实际为空），continue-on-error 将步骤 conclusion 包装为成功。PPTX 两次集成测试确有 All tests passed；IPA 与模拟器 ZIP 构建上传成功，但不能称整轮验收通过。Windows 37476926902 绿色，iOS 37476926700 的实际失败见下方收口记录。
阶段 5 BrowserStack 试跑：用户已登录 App Live，平台接受旧版绿色构建 `aada5dc` 的无签名 IPA 上传并显示为应用。免费 iPhone 会话在启动时提示可用试用时段已用完，未取得安装、启动或功能操作的真机证据；因此真机 smoke test 仍待可用测试时段。上传的旧包也不包含后续阶段 4 的数据保存修复。

2026-10-07 收口第一轮：已读取指定 [iOS 运行 37476926700](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37476926700) 的最终状态及完整作业日志。整轮失败，真实失败项为：① iPhone/iPad 的 study_flow_test.dart:180 提前读取长期笔记（期望内容，实际为空）；② 120 页测试在坏 PDF 加载错误被调用者捕获后，缓存释放再次传播同一失败。两次 PPTX 测试、视觉比较、unsigned IPA 和 simulator ZIP 构建均成功。未建立新稳定 tag。

仅针对失败项修复：长期笔记测试在输入并关闭弹窗后先 pump 一帧，避免命中尚未刷新的旧“已保存”标签，保留原持久化断言；覆盖上游 PDF 缓存的失败处理，加载失败时移除缓存，允许修复同一路径后重试，并处理释放与失败加载竞态，不改文档存储或 PDF 学习架构。增加失败后重试、失败加载期间释放、并发加载单次释放三个回归测试。Windows 本机对改动范围执行固定 Dart/Flutter 静态分析无问题；同版本 PDF 依赖的独立 Flutter 测试环境 3/3 通过。完整 App 本机测试因缺 Rust 工具链未执行成功，须由现有 Windows/iOS CI 复验；未把独立测试等同于模拟器验收。

上述失败运行仍留下合成 120 页测量：94448 字节、导入 3660 ms、保存 1400 ms、进程峰值 RSS 745799680 字节。该值是调试模拟器的进程高水位，包含运行环境且样本很小；失败恢复尚未通过，不能当作真实大型扫描教材性能通过。下一步先复验这两个失败项，绿色后对实际通过的提交建立验收基线，再按用户顺序做 PPTX 图表 OCR、真实教材 corpus、大文件压力和保存故障注入。

2026-10-07 用户要求保存进度、暂停开发：失败修复已提交并推送为 `945550d`。[Windows 运行 37555585853](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37555585853) **整体绿色**；[iOS 运行 37555585902](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37555585902) 已通过静态分析和单元测试，暂停时正在执行 iPhone 学习流程，尚无最终结论。**没有新稳定 tag**。恢复后先读取该 iOS 运行最终结果及作业 `112580936515` 的完整日志，重点确认长期笔记保存重开与坏 PDF 恢复；不能只看被 continue-on-error 包装的步骤 conclusion。失败只修实际失败项；整体绿色后给经过测试的代码提交建立验收基线，再推进 PPTX 图表 Vision OCR 验收。

暂停时的只读准备：现有 Vision OCR 在 PDF 页面完全无可提取文字时已会启动，但图表中文标签识别、坐标准确率和文字/图像混排页仍需专门验收。尚未修改 OCR 或 PPTX 核心。已将公开教材《动手学深度学习》2.0.0 下载到忽略目录 `prototype-pptx/corpus-candidates/d2l-zh.pdf`，来源 https://zh.d2l.ai/d2l-zh.pdf ，813 页、32671481 字节、SHA256 `632eee9582b967f5de7bf1927244366683a06db4544fe2364147aa9fbe58e146`；以 pypdf 核对页数并渲染抽查第 60 页，中文与公式可见。它只是后续 corpus 候选，尚未进入 App 测试；许可线索见 https://github.com/d2l-ai/d2l-zh/blob/master/config.ini （CC-BY-SA-4.0 / MIT-0），正式纳入前保留归属说明。它不是实际扫描件，不能补齐自然扫描/手写高亮样本缺口。

恢复约束：继续最终收口，不新增外围功能；BrowserStack 仍仅“上传验证”；Apple 账号就绪前不启动签名。PPTX 核心、存储架构、收费服务或签名路线如需重大改变，先交用户确认。用户偏好关键技术判断使用 GPT-6 Astra High。Windows 本机完整 Flutter 测试仍缺 Rust；本次缓存独立回归 3/3 与云端完整 Windows 绿色分别记录。当前 bundled Git 的 HTTPS helper 位于 mingw64/bin，推送使用 git 的 --exec-path 指向该目录；受限环境下 Windows 网络凭据需要工具批准后访问。源码及进度已提交，下载样本和独立测试环境在忽略目录保留于本机。

2026-10-07 稳定基线复验：提交 `945550d` 的 [Windows 运行 37555585853](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37555585853) 与 [iOS 运行 37555585902](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37555585902) 均整体绿色。完整 iOS 日志确认 iPhone 与 iPad 的 PDF 学习流程、长期笔记保存重开、离线 PPTX 转换并导入现有学习系统、120 页导入保存和坏 PDF 恢复全部为 `All tests passed!`；末尾强制检查正确跳过。合成 120 页 PDF 在该调试模拟器的导入为 1841 ms、保存为 800 ms、进程峰值 RSS 735215616 字节；样本只有 94448 字节，仍不代表真实大型扫描教材。PPTX 视觉平均 RGB MAE 2.568/255、最差页 2.916/255；图表页文字召回率仍为 0，故只作为当前稳定工程基线，PPTX 完整质量门槛仍未通过。产物为 [unsigned IPA 11456670656](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37555585902/artifacts/11456670656)（GitHub ZIP SHA256 `aa32b33b19626d32203c92b95b8c3ecedd0989e7100bc5a9e93a56a7a32baf9b`）、[simulator ZIP 11457045431](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37555585902/artifacts/11457045431)（`00c02e1a9ad5af9e55249dc00ddf51a2fd68d6d74212637d6eddcbad70997e6c`）、[PPTX 比较 11455222537](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37555585902/artifacts/11455222537)及[性能指标 11455067199](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37555585902/artifacts/11455067199)，到期日均为 2026-10-21。经过测试的代码提交建立 annotated tag `study-baseline-2026-10-07`；后续从此基线推进图表 Vision OCR 和真实 corpus。

2026-10-07 PPTX 图表 OCR 收口待云端验证：确认旧逻辑只在整页没有可提取文字时调用 Vision，会漏掉“标题为可选文字、图表标签为像素”的混排课件。现改为保留 PDFKit 的精确文字和坐标，仅对用户关键词中 PDFKit 找不到的部分补充 Vision OCR；纯扫描页原有颜色、高亮和下划线识别保持原路径。iOS 集成测试新增两项断言：固定 PPTX 第 3 页必须识别“一月、二月、三月”并返回归一化坐标；混排 PDF 必须同时保留可选标题并识别图片内的 Alpha。PPTX 比较归档增加完整测试日志作为 OCR 证据。Windows 本机对两份 Dart 集成测试静态分析为 `No issues found!`；Swift 编译与 iPhone/iPad Vision 结果须以新一轮 iOS CI 为准，当前仍不称 PPTX 完整质量通过。

2026-10-07 PPTX 图表 OCR 云端验收完成：提交 `449294c` 的 [Windows 运行 37592007964](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37592007964)（5 分 44 秒）与 [iOS 运行 37592007949](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37592007949)（1 小时 7 分 13 秒）均整体绿色。iPhone/iPad 的 PDF 学习流程、120 页恢复、离线 PPTX 和最终强制检查全部通过；iPhone 日志明确记录 `STUDY_PPTX_OCR:page=3 labels=3 masks=3` 及 `All tests passed!`。这证明 App 在图表标签不能由 PDFKit 提取时，会通过现有 Vision 通道返回“一月、二月、三月”及归一化坐标，同时混排页仍保留 PDFKit 文字路径。原始 PDF 第 3 页内嵌文字召回率仍为 0，不把 Vision 通过误报为 PDF 内嵌文字通过。

该轮合成 PPTX 平均 RGB MAE 2.178/255、最差 2.916；[PPTX 比较归档 11469798245](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37592007949/artifacts/11469798245) 的 GitHub ZIP SHA256 为 `1da0b6554abb5179f1e5e55d2d242110f61bb7e1ad21dac8f988acc57f78d401`。120 页合成 PDF 指标为导入 2564 ms、保存 1346 ms、峰值 RSS 744570880 字节，[指标归档 11470231873](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37592007949/artifacts/11470231873) 摘要 `73add30fdee635dc405d5be50975c268c87e9e9a67e1d69498c254c61b65ac2b`；仍不代表几十 MB 真实扫描教材。新 [unsigned IPA 11471796385](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37592007949/artifacts/11471796385) 摘要 `a1e9be95d0e7fb20b49fbc65da12bf75ed9f57f6016a6342399426432ae0438e`，[simulator ZIP 11471494569](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37592007949/artifacts/11471494569) 摘要 `3ac0b32ca1bddc96d1c02e784ca138561e99084a0822f1b7f2dae59b0a2de456`。经过测试的提交建立并推送 annotated tag `study-pptx-ocr-2026-10-07`。

2026-10-07 公开真实 corpus 已在 Windows 本机建立并固定：①《动手学深度学习》中文文字 PDF，813 页、32671481 字节；② Library of Congress 公共领域扫描教材，160 页、39754146 字节；③ Illinois DoIT 复杂 PPTX 与官方 PowerPoint PDF 对照件，各 5 页；④由已校验真实扫描页生成的一页受控高亮/下划线样本。`real_corpus.json` 记录 HTTPS 来源、用途/许可说明、SHA256、字节数、页数和覆盖项；大文件留在被忽略的 `quality/private/real/`，没有提交到公开仓库。下载/派生/校验脚本具备临时文件、固定大小、SHA256 和页数检查。本机完整教材与质量测试 17/17 通过，固定 corpus 全部再次校验成功。

同一 `@aiden0z/pptx-renderer` 1.3.0 与桥接页面在本机 Edge 离线转换 Illinois 真实课件，和官方 PDF 比较的逐页 RGB MAE 为 1.444、4.296、2.227、2.949、3.089，平均 2.801/255、最差 4.296，最低文字字符召回率 1.0，所有暂定门槛通过；人工抽查图表页确认月份、图例、数值、颜色和图片保留。下一提交把这份小型真实课件按固定哈希下载到 iOS CI，要求 iPhone/iPad 离线转换、图表关键词坐标和 iPhone 官方 PDF 质量门槛同时通过；当前这部分代码已由固定 Dart SDK 静态检查 `No issues found!` 和本机 17/17 Python 测试验证，云端 iOS 结果仍待提交后取得。

2026-10-07 晚间恢复：`90d40f7` 的 Windows 验证 `37600320542`（6 分 38 秒）及 Windows EXE `37600320450`（1 分 6 秒）绿色；[iOS 37600320442](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37600320442) 最终失败。已读取作业 `112722823015` 完整日志：iPhone 学习流程、120 页合成 PDF、iPhone/iPad 离线 PPTX 均为 `All tests passed!`，两种模拟器均记录 `STUDY_REAL_PPTX:pages=5 labels=3 masks=3`。真实 Illinois PPTX 的 iPhone 视觉比较平均 RGB MAE 3.959/255、最差 6.997/255、最低字符召回率 1.0、页数和比例通过，`passed=true`。这是固定公开样本的模拟器证据，不能替代用户教材准确率或真机验收。

本轮唯一业务失败是 iPad 学习流程读取首页 `.sbn2.p` 缩略图时出现 `Invalid image data`。源码确认缩略图仍直接截断写入，首页可能在写入间隙读取它；现让该写入复用现有 `writeNoteAssetAtomically`，保持文件名、PNG 格式和通知行为。新增故障注入：暂存 PNG 截断后中断写入，验证正式路径仍为完整旧 PNG 且可解码，重试后新 PNG 完整落盘。Windows 本机完整源码范围静态分析无问题；抽取未改动原子替换函数的独立 Flutter 回归环境 2/2 通过。完整 App 测试与 iOS 模拟器复验待新提交 CI；未绕过现有测试或建立新稳定 tag。

真实大文件测试草稿已保存在本机忽略目录 `build/pending-real-stress/`：160 页、39754146 字节 LoC 扫描 PDF，记录导入/分析/保存/重开耗时和进程 RSS，并在打包前删除测试教材。Dart 静态分析与 YAML 解析通过，但尚未接入当前 CI；先修复上述真实失败项再启用。该扫描件带历史 OCR 层，分析耗时不能标为纯 Vision OCR 耗时；取消、内存保护、重开 PDF 资产完整性及独立 OCR 压测仍需加强。草稿没有更改 PDF 学习系统。稳定回退点仍为 `study-pptx-ocr-2026-10-07`（`449294c`）。之前聊天的约 82% 是粗略工程估算，非正式验收百分比；签名、真机和真实压力项目仍未完成。

缩略图修复已推送为 `229c4d9`。对应 Windows 运行 `37630306519`、iOS 运行 `37630306419` 已启动，尚无最终结果。下次恢复先核对这两条运行及 iPad 缩略图错误是否消失；失败只修实际失败项，绿色后再启用本机大文件测试草稿。

2026-10-08 RC 主线切换及绿色复核：已通过 GitHub 连接器读取 `37630306519`、`37630306419` 的最终 job 状态，均 success；读取完整 iOS 日志确认 iPhone/iPad 学习与 PPTX、合成 120 页测试全部 `All tests passed!`，最终强制检查 skipped。为实际受测提交 `229c4d9afb1098dd93953577efb9d17d3ada49c3` 建立 annotated tag `v0.9.0-rc1`，工具链、产物、摘要及边界见 `RC1_BASELINE.md`。本轮合成 120 页导入 2479 ms、保存 1201 ms、峰值 RSS 744538112 字节。真实 PPTX 双模拟器通过，视觉门槛通过；不代表真实 iPhone 通过。

用户已明确新的优先顺序：CI 绿色 → RC1 → Apple 签名/TestFlight → 第一台 iPhone 学习保存重开 → 真机大文件及恢复 → RC2 → v1.0.0。用户确认尚无 Apple Developer Program 会员，也没有可用 iPhone；不得自行开通账号、付费或改变签名路线。大文件草稿后移，不阻塞第一次 RC 安装。旧 Codemagic 模板尚缺 Study 身份替换、固定 Flutter 和离线 PPTX 引擎打包；`tools/release/` 已开始准备两个签名审计脚本，目前未接入流水线，尚需测试与模板补齐。正式签名/Apple 上传未执行。


2026-10-08 签名前置准备收口：补齐未启用的 Codemagic 模板，固定 Flutter 3.47.4/revision 和 Xcode 26.6/17F113；签名前核对两条 GitHub CI 与完整应用 SHA，独立记录签名配置 SHA；从冻结 SHA 应用 overlay，替换 Study 身份、移除上游团队、校验 48 个图标与启动配置，沿用固定离线 PPTX 引擎及摘要。首份 signed RC 使用 0.9.0 + 递增构建号。导出后要求原生 codesign 校验及 profile/team/版本/平台检查，仅将通过检查的 IPA 副本交给发布器，保留 TestFlight，禁止自动正式商店提交。

本机 18 项发布检查通过（含 pinned iOS 源码临时副本），初次缺 PyYAML 已在忽略目录安装固定 6.0.3 后复验。新增轻量 GitHub release-preflight 检查，不触发重复 PDF 模拟器测试；云端结果待本次提交后核对。SIGNING_AUDIT.md 列明已知配置修复及边界，RC1_SMOKE_TEST.md 保留 20 项未执行的真机验收栏。未修改 overlay 学习代码、存储格式或现有三类构建产物流水线。真实 macOS 签名、Apple processing、隐私/加密资料确认和真机验证尚未发生；用户无会员和 iPhone 是当前外部阻塞。恢复后先核对本次 release-preflight 最终日志，再等用户具备外部条件，按 CODEMAGIC_SETUP.md 手动启用。


2026-10-08 发布准备云端复验完成：提交 `d79c96250c34a29dfc257b56345571563db70b54` 已推送，[GitHub release-preflight 37713847100](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37713847100) 整体绿色；已读取 job `113105692716` 完整日志，确认 18/18 检查通过（含 pinned iOS 副本），三个 Bash 脚本语法检查通过。签名模板继续休眠，未执行 Codemagic、Apple 上传或真实设备测试；核心应用仍以 `229c4d9` / `v0.9.0-rc1` 为验收基线。本次恢复没有修改 PDF/PPTX/OCR 或数据存储。当前暂停点为外部条件：用户决定 Apple 会员及找到可用 iPhone/测试者后，继续首次 signed RC/TestFlight，按 RC1_SMOKE_TEST.md 验收保存退出重开。

归档保留说明：RC1 的 GitHub artifact 链接和摘要已记录；尝试通过连接器的临时下载链接保存 unsigned ZIP 时返回 HTTP 403，本机 `dist/rc1/` 未取得这份文件。不能声称已经本机备份。GitHub 原始 artifact 有效期仍为 2026-10-21，需在到期前从登录的 GitHub 下载保存或重新构建。

