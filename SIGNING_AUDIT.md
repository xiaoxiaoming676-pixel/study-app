# Study RC1 签名前置审计

日期：2026-10-08。应用基线 `v0.9.0-rc1` / `229c4d9`；签名配置单独提交。

## 当前结论

已补齐旧模板的已知代码配置缺项，本机 18 项检查通过；[GitHub 37713847100](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37713847100) 同样 18/18 及三个 Bash 脚本语法检查通过（提交 `d79c962`）。模板仍为 `codemagic.template.yaml`，没有启用正式签名或向 Apple 上传；Windows 无法执行 Xcode/codesign。GitHub 的 RC1 双模拟器绿色属于原应用基线，不能视为新签名模板在 Codemagic 已通过。

| 检查项 | 处理与证据 | 剩余验证 |
| --- | --- | --- |
| Bundle ID | Runner 三种配置统一 `com.xiaoxiaoming676.studyapp`；RunnerTests 同前缀 | 用户在 Apple 注册匹配 App ID |
| App 名称 | plist 和 Xcode 显示名均为 Study | 首份 signed IPA 再校验 |
| version / build | 首 RC 使用 `0.9.0`；`PROJECT_BUILD_NUMBER + STUDY_BUILD_OFFSET`，正整数，首阶段上限 9999 | 首次配置确认没有与既有 TestFlight build 重复；重建 Codemagic 项目时调整 offset |
| minimum iOS | Runner 为 15.0，最终包必须为 15.0 | AppFrameworkInfo 的较低声明不是 Runner 部署目标 |
| App icon | pinned 上游 48 个 PNG 槽位尺寸已核对，默认 1024 图为 RGB；保留暗色/着色变体 | Apple 最终资源校验 |
| launch | Main / LaunchScreen storyboard 存在，plist 引用正确；LaunchImage 三尺寸存在 | 真机启动验收 |
| Info.plist / 权限 | 保留 Flutter 版本变量；相机、相册用途说明中文化，均用于笔记图片 | Files、OCR、朗读沿用原链路，不增加无关权限 |
| entitlement | 当前源码未指定额外 entitlement；新增能力将阻止静默签名 | 校验最终签名及 profile 的应用标识、team 和禁止调试标记 |
| signing | 移除上游 DEVELOPMENT_TEAM，使用 Codemagic 现有 managed signing identities | 用户 Apple Team、证书及匹配 profile；不生成任何占位密钥 |
| export | 只接受 app-store / app-store-connect，拒绝设备列表、企业包及过期 profile | 首次 Xcode 导出 |
| Codemagic | Flutter 3.47.4 + revision 校验，Xcode 26.6 / 17F113 校验；从已绿色的完整 SHA 取 overlay | 镜像或 SDK 下架时明确失败，重新验收后再更新 |
| PPTX | 同 RC1 renderer 1.3.0、esbuild 0.25.12 和两级 SHA256；签名包不能留桥接占位符 | 首次签名构建的离线导入 |
| 发布 | 原生 `codesign --verify --deep --strict` 后检查包元数据；仅将检查通过的副本交给发布器 | Codemagic → Apple processing → TestFlight 逐项确认 |
| TestFlight | API integration `study-appstore`；允许 TestFlight beta 提交，禁止自动正式商店提交 | App record、测试者、必要 beta review 与首次安装 |
| 隐私/加密 | 记录最终包 `.xcprivacy` 清单，校验 plist 可解析；沿用上游加密声明 | 清单存在不等于声明合规；首次上传前复核 SDK 隐私声明、上游可选 Sentry、隐私政策及 Apple 加密问卷 |

## 自动检查边界

`tools/release/test_release.py` 测试错误 CI SHA/仓库/工作流、未完成或失败 CI、应用身份、图标/启动资源、上游团队残留、签名团队与 prefix、debug entitlement、过期/设备/企业 profile、版本及平台、PPTX 占位符、测试教材泄漏；在 pinned iOS 源码临时副本上核对 48 个图标和重复执行安全性。IPA 测试使用合成元数据，不是假装 Apple 签名成功。

`study-release-preflight.yml` 只在 GitHub 执行 Python 检查和 Bash 语法检查，不需要 Apple 密钥，不重新跑 PDF 模拟器流程。正式模板保持休眠。

最终产物记录应用 SHA、签名配置 SHA、工具链、版本/build、IPA SHA256；不公开解码的 provisioning profile。原 unsigned IPA、simulator ZIP、Windows EXE 流水线不变。

## 未完成的外部关卡

1. 用户无 Apple Developer Program 会员、无可用 iPhone。不得自行注册付费或改签名路线。
2. Apple 身份就绪后，需要配置 App record、团队、API integration 和签名 identities，并由用户确认隐私/加密资料。
3. 首次执行才能验证真实签名、Apple 接收/处理与 TestFlight 安装；目前不能保证不存在 Apple 端或云端环境阻塞。
4. 真实设备 smoke、160 页扫描教材压力、保存恢复最终验收仍未通过。BrowserStack 仍只有上传记录。

参考：[Codemagic 签名](https://docs.codemagic.io/yaml-code-signing/signing-ios/)、[发布设置](https://docs.codemagic.io/yaml-publishing/app-store-connect/)、[构建编号](https://docs.codemagic.io/knowledge-codemagic/build-versioning/)。
