# 第一版交付与云端苹果编译

核查日期：2026-09-17。结论：沿用现有 Saber/Flutter 源码，使用 GitHub Actions 的 macOS runner 编译。无需为了编译重写 App。

## 查到的可复用项目

| 项目 | 能解决什么 | 维护/社区证据 | 接入成本与决定 |
| --- | --- | --- | --- |
| [actions/runner-images](https://github.com/actions/runner-images) | GitHub 云端 macOS 构建环境 | 官方维护，说明按周更新镜像 | 直接使用托管 runner，不自行部署镜像 |
| [subosito/flutter-action](https://github.com/subosito/flutter-action) | 安装 Flutter，含无签名 iOS 示例 | 页面约 2.6k stars；本次未核实最新提交时间 | 备用；现项目优先保留固定 Flutter 子模块的 upstream helper |
| [fastlane](https://github.com/fastlane/fastlane) | 构建、证书管理、TestFlight 自动化 | 页面约 42.1k stars；[发布页](https://github.com/fastlane/fastlane/releases)显示 9 月 15 日发布 2.240.1 | 可用；签名需要账号配置，不能凭开源代码绕过 |
| [Codemagic CLI Tools](https://github.com/codemagic-ci-cd/cli-tools) | 签名文件、钥匙串、构建导出 | Flutter 官方发布文档给出操作流程；本次未核实近期维护日期 | 现有 Saber 的 ios.yml 已使用，正式签名优先沿用 |
| [SideStore](https://github.com/SideStore/SideStore) | 使用个人 Apple ID 重签并安装 IPA | 页面约 6.5k stars；有发布记录 | 备选安装方式；不是编译器。需首次安装配置及定期刷新，兼容性待测 |

Stars 为查询页面近似值，不代表适配验证已经完成。
来源：[Flutter iOS 发布](https://docs.flutter.dev/deployment/ios)、[fastlane match](https://docs.fastlane.tools/actions/match/)、[SideStore 官方说明](https://sidestore.io/)。

## 已准备与实际阻塞

- `.github/workflows/study-validate.yml`：依赖、学习模块分析、Flutter 测试、无签名 iOS 构建。新增 Payload/Runner.app 打包与 SHA256；产物明确命名 Study-UNSIGNED.ipa，不能直接安装。
- Workflow 尚未运行。本地 YAML 检查不代表 macOS 执行成功。
- 当前 GitHub 连接可读取用户账号，但可访问仓库列表为空。不能判断用户没有仓库，只能确认本次连接未返回仓库。
- 需要用户提供/授权一个该项目仓库；然后上传源码、运行构建、读日志并修复。现有连接有日志和产物读取能力，但没有发现直接触发 workflow 的操作，可能需要用户首次点 Run workflow。
- 编译可以先不签名。安装到真实 iPhone 则必须完成适当签名；TestFlight 还需 Apple Developer Program/App Store Connect 配置。
- 不索要 Apple ID 密码或要求把证书放入源码。凭据使用仓库 Secrets 或安装工具的正式登录界面。
- 上游 ios.yml 使用原作者 bundle ID、发布与 Sentry 配置，不能直接当本项目发布流程运行；签名前必须更换归属和标识。

## 第一版目标与验收

赞成先做出可安装、可完成一次学习流程的版本，再根据使用反馈调整。界面细节后续迭代；保存与再次打开属于首版必须通过的功能。

1. 能安装到目标 iPhone，正常启动并导入 PDF。
2. 自动规则不限红色；可确认候选、手动框选和删除。
3. 能手写/输入答案，能在教材空白处自由批注。
4. 保存后退出并重新打开，答案和笔记保留；重新练习不删除长期笔记。
5. 可选系统声音朗读、暂停和停止；扫描件需明确提示无法提取文字。
6. 能导出挖空练习及笔记答题 PDF。
7. iPad 基本布局不溢出。

手机内直接 PPT/PPTX 导入仍是原始需求，但目前没有实现；现阶段只有电脑 PPTX 转 PDF 工具。不能把预转换说成手机内导入已完成。先编译现有核心以暴露真实问题，同时将手机内 PPT 转换列为首版需求缺口；若采用临时预转换方案，需要向用户明确说明。

## 下一步顺序

接通项目仓库 → 首次云端编译 → 修复日志中的错误 → 确定签名安装路线 → iPhone 验收 → 调整体验。
