# 云端构建进度

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
