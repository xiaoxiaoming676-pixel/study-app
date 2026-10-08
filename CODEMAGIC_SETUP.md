# Study 首次 TestFlight 构建准备

当前未启用。用户暂无 Apple Developer Program 会员及可用 iPhone；没有新建账户、付费、上传 Apple 密钥或启动签名。已冻结基线见 [RC1_BASELINE.md](RC1_BASELINE.md)，审计边界见 [SIGNING_AUDIT.md](SIGNING_AUDIT.md)。

## 条件就绪后按顺序操作

1. 用户确认开通 Apple Developer Program，并找到一位可使用真实 iPhone 的测试者。账号与费用必须由用户决定；可用设备不必由用户购买。
2. 在用户团队下创建 App ID `com.xiaoxiaoming676.studyapp` 与 App Store Connect App record，名称 Study。首次测试版本为 `0.9.0`。
3. 在 Codemagic 配置 Developer Portal integration `study-appstore`，使用 App Store Connect API Key；按官方文档配置 App Manager 权限。私钥仅保存于 Codemagic 的专用密钥界面，绝不写入聊天、Git、普通日志或公开 artifact。
4. 通过该 API 集成在 Codemagic Code signing identities 中生成/取得匹配的 Apple Distribution 证书及 App Store profile。`ios_signing` 自动选择已配置 identities；模板不会凭空生成 Apple 身份，也不会撤销已有证书。
5. 在 Codemagic 设置非密钥变量 `STUDY_APPLE_TEAM_ID`，保留冻结 SHA 与两条绿色 CI run ID。默认 build 为项目构建计数；若已上传过相同版本，设置 `STUDY_BUILD_OFFSET`，确保下一 build 大于 Apple 上已有编号。重新创建 Codemagic 项目时必须重新核对，不能重置后重复上传。
6. 可选配置只读 `STUDY_GITHUB_READ_TOKEN` 为 secret，供公开 Actions 查询避开共享 IP 限流；无 token 时匿名查询，任何 API 错误都阻止签名，不跳过绿色检查。
7. 复核上游 SDK 的隐私声明、最终包的 privacy manifests、隐私政策与加密问卷。首次 TestFlight 的测试说明、联系人和测试者组按 App Store Connect 要求填写；外部测试可能还需 beta review。
8. 用户授权启动后，将 `codemagic.template.yaml` 复制为 `codemagic.yaml`，从**包含最新签名脚本的提交**手动运行。不要直接从 RC1 tag 启动：该 tag 的代码冻结早于这些脚本。模板从 `STUDY_RC_SHA` 单独恢复经过测试的应用代码，产物同时记录两个 SHA。
9. 首次检查：固定工具链 → GitHub 两条 CI 完成且绿色 → 应用准备 → managed profiles → IPA 导出 → 原生签名校验 → 元数据检查 → 发布。只有检查通过才复制 IPA 至发布产物目录；正式 App Store 提交关闭。
10. 下载 `Study-RC.ipa`、SHA256SUMS、provenance.json 和 package-check.json。确认 Codemagic 上传成功、Apple processing 成功、TestFlight 可安装是三个独立结果；再执行 [RC1_SMOKE_TEST.md](RC1_SMOKE_TEST.md)。

## 不满足条件时

保留 unsigned IPA、simulator ZIP 和 Windows EXE。签名模板、模拟器测试、BrowserStack 接受上传，都不能替代真实 iPhone 安装证据。工具链变化、签名路线变化或新费用先提交用户决定。

固定 Flutter 3.47.4/revision、Xcode 26.6/17F113 可能将来不再由服务提供；届时停止并验证新工具链，不自动退回 stable/latest。此模板尚未在 Codemagic 实际运行，首次运行按真实日志逐项修复。

官方依据：[签名 identities/API](https://docs.codemagic.io/yaml-code-signing/signing-ios/)、[App Store Connect/TestFlight](https://docs.codemagic.io/yaml-publishing/app-store-connect/)、[构建编号](https://docs.codemagic.io/knowledge-codemagic/build-versioning/)。
