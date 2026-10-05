# Windows 开发验证与未来 iPhone 安装

当前用户没有 iPhone、iPad 或其他苹果设备。Windows 电脑今天先用于核对 GitHub Actions 失败原因、运行可在 Windows 执行的源码/教材工具测试；没有设备时不进行签名安装或真机验收。云端 iPhone 模拟器仍可验证交互，但不能替代真实设备。

本学习版使用独立标识 `com.xiaoxiaoming676.studyapp`，桌面名称 Study。图标暂沿用 Saber，功能与进度以本仓库最新构建为准。请在首次安装后固定 Apple ID 和包标识；变更签名工具或标识前先备份笔记。

## 今天在 Windows 电脑上做

1. 先前的零步骤失败是私有仓库免费分钟 2,000/2,000 用尽且 Actions 预算为 $0 所致。用户确认后仓库已公开，标准托管运行器已能启动；未修改预算或支付资料。
2. Windows 本地 PowerPoint 教材转换及 Python 工具测试 10/10 通过。[公开后的 Windows Flutter 验证](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37267237712) 静态检查无问题，9/9 项学习模块测试通过。
3. [第一轮公开后的 iOS 运行](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37267208722) 静态检查、9/9 项单元测试、无签名编译和上传通过，但模拟器端到端测试在关闭并重开笔记后的工具栏点击失败。[第二轮](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37269586591) 在“挖空”标签仍滑入屏幕时过早点击，模拟器测试也未通过；两个工作流均为红色。已让测试等待这两处控件可命中，待下一轮重跑；仅在整条工作流绿色通过后使用它的无签名产物。Windows 本机不能运行 Xcode iOS 模拟器或完成 iOS 构建。
4. PPTX 可先在 Windows 的 PowerPoint 或 LibreOffice 导出 PDF 检查教材版式；App 内直接导入 PPTX 仍需继续开发。

下面的 IPA、签名和真机步骤保留给将来有 iPhone/iPad 时使用。现在不用安装 Sideloadly，不用准备 Apple ID 签名，也不用购买苹果设备来完成本阶段的软件检查。

## 获取待测包

1. 打开 [Build Study iOS 运行列表](https://github.com/xiaoxiaoming676-pixel/study-app/actions/workflows/study-ios.yml)，只选择最新 **绿色通过** 的运行。在 Artifacts 下载 `Study-unsigned-iOS-app`，解压得到 `Study-UNSIGNED.ipa`、`SHA256.txt` 和 `INSTALL-NOTE.txt`。若没有绿色运行，先等我修复测试，不要拿失败轮次作为已验收版。
2. 在 Windows PowerShell 进入文件夹运行 `Get-FileHash .\Study-UNSIGNED.ipa -Algorithm SHA256`，与 `SHA256.txt` 对照。该包未签名，直接点开不会装到 iPhone。
3. 如需确认名称和包标识，可解压 IPA，查看 `Payload/Runner.app/Info.plist`；签名工具可能在安装时调整实际标识，请记录最终值。

## 旧版临时包

2026-10-05：第十三次运行 [37247985115](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37247985115) 两次均在分配运行器前失败（0 步、0 计费毫秒），原因已确认为私有仓库免费分钟用尽与 $0 停用预算。若将来有 iPhone、只需验证电脑签名/手机安装流程，可下载[第十二次无签名产物](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37246129034/artifacts/11319767491)。IPA SHA256：`63b79316f4ebbd35a2ed6460467c8fef719fa39f1949c0f7afaef9bc7fb91b85`。这版仍是上游 Saber 标识，模拟器端到端测试未通过（测试辅助方法异常）；仅用于无敏感资料的临时排错。未来独立 Study 包不会直接覆盖它，测试笔记须先导出备份。

## 将来有 iPhone 时：Windows 签名安装

1. 从 [Sideloadly 官网](https://sideloadly.io/)下载 Windows 版，并按其当前指引安装所需的 Apple 组件。只从官方页面获取工具。
2. 数据线连接 iPhone，在手机上选择“信任此电脑”；在 Sideloadly 选择设备、拖入 IPA，选 Apple ID 签名安装。Apple ID、密码和双重验证码只在官方/安装工具界面输入，不要发给聊天。
3. 按 iPhone 提示启用“开发者模式”并重启；若系统提示信任开发者，按设置里的实际提示操作。安装失败请保留工具原始错误、iOS 版本和手机型号，我会据此排查签名/权限/包内容。
4. 免费个人签名通常要周期性刷新；别把 App 删除后再重装当作刷新办法。先从 App 内导出并备份教材和笔记。

Sideloadly 是第一轮个人设备测试路线，不代表 App Store 或 TestFlight 正式分发。若电脑是 Mac，可改用 Xcode 个人团队签名；目前无开发者会员，不能直接提供长期有效的正式签名包。

## 将来有 iPhone 时：首轮真机验收

用一份不含敏感信息、含文字的 PDF，再用一份扫描 PDF：

- 从“文件”导入 PDF，检查页数、排版和缩放。
- 在空白处用手指写两笔，保存退出，重开检查笔迹。
- 按一个关键词生成挖空候选，核对位置后保存；手写或键入答案，增加长期笔记，退出重开核对。
- 对扫描页测试关键词 OCR；不准的区域手动框选。
- 启动中文朗读，试暂停、继续、停止及重新打开后的进度。
- 导出原文版、练习版、答题笔记版 PDF，核对页面和笔迹。

记录每一步是否通过、截图、手机型号和 iOS 版本。不要上传私人教材、Apple 密码或验证码。PPTX 在 App 内直接转换仍未完成：当前可在 iPhone 的 Keynote 将 PPTX 导出 PDF，再导入本 App；复杂公式和字体需人工核对。
