# Study RC1 工程基线

冻结日期：2026-10-08。标签 `v0.9.0-rc1` 指向经过 CI 验证的代码，**不是签名包或真机通过标记**。

| 项目 | 记录 |
| --- | --- |
| Commit | `229c4d9afb1098dd93953577efb9d17d3ada49c3` |
| Saber source | `5b396a40406c75835741f5c4555bc10ae816f121` |
| Flutter | 3.47.4，revision `9584c6713b324636289d067944a46fd6b49df14b` |
| Dart | 3.13.3 |
| Xcode | 26.6，build 17F113 |
| 最低 iOS | 15.0（Runner 配置；首次 signed IPA 再核验最终 plist） |
| Bundle ID / 显示名 | `com.xiaoxiaoming676.studyapp` / Study |
| 当前 unsigned 版本 | 沿用 pinned upstream 的 `1.36.1+136010`；首次 signed RC 使用 `0.9.0` 和唯一 build number，不改动此标签 |
| Windows 验证 | [37630306519](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37630306519)，绿色 |
| iOS 验证 | [37630306419](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37630306419)，绿色，job `112822526720` |
| iPhone | PDF 学习、120 页合成恢复、PPTX 测试全部 `All tests passed!` |
| iPad | PDF 学习与 PPTX 测试全部 `All tests passed!`；缩略图错误未再出现 |
| 真实 PPTX | 双模拟器各 5 页，3 个图表关键词/坐标；iPhone 视觉平均 RGB MAE 3.959，最差 6.997，字符召回率 1.0，暂定门槛通过 |
| Apple / 真机 | 用户确认暂无 Apple Developer Program 会员，也无可用 iPhone；未签名、未上传 TestFlight、未真机验收 |

## 归档索引

下列 SHA256 均为 GitHub **artifact ZIP** 摘要，不是 ZIP 内 IPA/EXE 的摘要。内部文件另有构建生成的 SHA256 清单。归档有效期至 2026-10-21，请在过期前另行保存交付包。

| 产物 | 归档 | GitHub ZIP SHA256 |
| --- | --- | --- |
| unsigned IPA | [11490946664](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37630306419/artifacts/11490946664) | `1e8c60312f0e495f6f5ce84a6300f352f282cbaa86d60b47ada8caed3e4f7bd0` |
| simulator ZIP | [11491420197](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37630306419/artifacts/11491420197) | `34a70107d8594772ec4cb534346d08d8d9c073b0d9d4dabacc99d2cc48d509d8` |
| PPTX 比较 | [11486949344](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37630306419/artifacts/11486949344) | `754b2f76c728d89c034f84b62dc0275732feb5cd7dabdc73c2a9b6f50fd4b9ed` |
| 合成性能 | [11486558587](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37630306419/artifacts/11486558587) | `1c971653b7d0e27efc06abd93411c6e62eecb5c427aa6d0f2c55470d6ddc647a` |
| Windows EXE | [11472705990](https://github.com/xiaoxiaoming676-pixel/study-app/actions/runs/37600320450/artifacts/11472705990) | `2eb7e8f60d145bd05bf4d2675a87b81bd78f6f8da9096a3cd2c5b10eac44f200` |

Windows EXE 来自绿色 `37600320450` / `90d40f7`；已用 Git 核对 Windows 工具源码、打包脚本和工作流在 `90d40f7..229c4d9` 无差异。它不是 RC1 同 SHA 构建，正式 Release 仍需满足现有工作流的同 SHA 门槛，不跳过该检查。

## 后续主线

签名前置审计 → 用户具备 Apple 会员和可用 iPhone → Codemagic signed IPA → TestFlight → 真机学习/保存/退出/重开 → 真机大教材和恢复验收 → RC2 → v1.0.0。

当前真实大文件草稿保留于本机 `build/pending-real-stress/`，不阻塞首次 RC 安装；不增加外围功能，不更换 PDF/PPTX/OCR 引擎。任何 signed RC 均记录代码 SHA、签名配置 SHA、版本和 build number。`RC1 REAL DEVICE PASS` 只能在真机 Smoke Test 有证据后填写。
