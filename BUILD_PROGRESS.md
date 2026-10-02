# 云端构建进度

2026-09-17：第一次运行 35235644496 完成环境和依赖安装；发现并修复 PlatformFile.bytes API 问题与代码规范提示。

2026-09-28：第二次运行 36362081827，Flutter 分析通过，9 项测试 8 项通过；修正矩形浮点数严格相等断言。

2026-09-28：第三次运行 [36362400239](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/36362400239)，学习模块分析成功、9/9 测试通过、Xcode 无签名 iOS 构建成功（Runner.app 52.7 MB）。Artifact 10946217962 含 22,250,648 字节 IPA 和 SHA256 清单，保留截至 2026-10-12。IPA SHA256：`446848005b6c5c678d7d21dfac8f63cfc2b5e606ed7748b8f27260f7fa806571`。实测 Info.plist：Bundle ID `com.adilhanney.saber`、显示名 Saber、最低 iOS 15.0；无 embedded.mobileprovision。

2026-09-28：核查苹果、Flutter、GitHub Actions、Sideloadly 正式文档，形成 [两条安装路线和首版验收](RELEASE_OPTIONS.md)。免费个人账号可通过 Windows 工具签名自用测试，7 天内重签；长期 TestFlight 需要用户开发者会员、App ID 和签名材料。Notion 连接中未找到该项目已有文档。仓库为开发进度来源。

待办：在目标 iPhone 实测安装、PDF 导入/挖空/批注/保存/朗读/导出；实现手机端 PPTX/其他文档处理及扫描件 OCR；正式命名和唯一 Bundle ID；如走 TestFlight，配置用户本人开发者账号与签名。当前无真机运行证据，不能认定完整版本已完成。

2026-10-02：加入 iOS Vision 本地扫描 PDF 文字识别供朗读；扫描页自动挖空仍需手动框选。新增无电脑安装路线核查 PHONE_ONLY.md；云端编译和真机结果待验证。
