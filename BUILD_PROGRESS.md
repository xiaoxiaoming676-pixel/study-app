# 构建与测试进度

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
