# iPhone 第一版安装与实测（Windows）

本学习版使用独立标识 `com.xiaoxiaoming676.studyapp`，桌面名称 Study。图标暂沿用 Saber，功能与进度以本仓库最新构建为准。请在首次安装后固定 Apple ID 和包标识；变更签名工具或标识前先备份笔记。

## 获取待测包

1. 打开 [Build Study iOS 运行列表](https://github.com/xiaoxiaoming676-pixel/study-app/actions/workflows/study-ios.yml)，只选择最新 **绿色通过** 的运行。在 Artifacts 下载 `Study-unsigned-iOS-app`，解压得到 `Study-UNSIGNED.ipa`、`SHA256.txt` 和 `INSTALL-NOTE.txt`。若没有绿色运行，先等我修复测试，不要拿失败轮次作为已验收版。
2. 在 Windows PowerShell 进入文件夹运行 `Get-FileHash .\Study-UNSIGNED.ipa -Algorithm SHA256`，与 `SHA256.txt` 对照。该包未签名，直接点开不会装到 iPhone。
3. 如需确认名称和包标识，可解压 IPA，查看 `Payload/Runner.app/Info.plist`；签名工具可能在安装时调整实际标识，请记录最终值。

## Windows 电脑签名安装

1. 从 [Sideloadly 官网](https://sideloadly.io/)下载 Windows 版，并按其当前指引安装所需的 Apple 组件。只从官方页面获取工具。
2. 数据线连接 iPhone，在手机上选择“信任此电脑”；在 Sideloadly 选择设备、拖入 IPA，选 Apple ID 签名安装。Apple ID、密码和双重验证码只在官方/安装工具界面输入，不要发给聊天。
3. 按 iPhone 提示启用“开发者模式”并重启；若系统提示信任开发者，按设置里的实际提示操作。安装失败请保留工具原始错误、iOS 版本和手机型号，我会据此排查签名/权限/包内容。
4. 免费个人签名通常要周期性刷新；别把 App 删除后再重装当作刷新办法。先从 App 内导出并备份教材和笔记。

Sideloadly 是第一轮个人设备测试路线，不代表 App Store 或 TestFlight 正式分发。若电脑是 Mac，可改用 Xcode 个人团队签名；目前无开发者会员，不能直接提供长期有效的正式签名包。

## 首轮真机验收

用一份不含敏感信息、含文字的 PDF，再用一份扫描 PDF：

- 从“文件”导入 PDF，检查页数、排版和缩放。
- 在空白处用手指写两笔，保存退出，重开检查笔迹。
- 按一个关键词生成挖空候选，核对位置后保存；手写或键入答案，增加长期笔记，退出重开核对。
- 对扫描页测试关键词 OCR；不准的区域手动框选。
- 启动中文朗读，试暂停、继续、停止及重新打开后的进度。
- 导出原文版、练习版、答题笔记版 PDF，核对页面和笔迹。

记录每一步是否通过、截图、手机型号和 iOS 版本。不要上传私人教材、Apple 密码或验证码。PPTX 在 App 内直接转换仍未完成：当前可在 iPhone 的 Keynote 将 PPTX 导出 PDF，再导入本 App；复杂公式和字体需人工核对。
