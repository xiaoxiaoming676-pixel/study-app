# Study App · 苹果学习软件

iPhone 优先，兼顾 iPad。基于 Saber 的学习版开发源码。

## 当前状态

GitHub 仓库访问已接通；代码以固定上游源码 + overlay 改动保存。
这不是安装包，苹果编译、签名、真机验收尚未完成。

## 第一次构建

进入 Actions → Build Study iOS → Run workflow → main → Run workflow。
构建会下载固定版本的 Saber 和 Flutter，覆盖学习功能代码，执行检查和测试，再构建无签名 iOS 文件。
成功后下载 Study-unsigned-iOS-app 产物。Study-UNSIGNED.ipa 仍需签名，不能直接安装。

## 源码结构

- BASE_COMMIT.txt：Saber 固定版本。
- overlay/：全部学习功能改动与阶段进度。
- .github/workflows/study-ios.yml：本仓库的唯一构建工作流。
- overlay/STUDY_PROGRESS.md：功能、测试结果及未完成事项（历史检查点）。

工作流先恢复 https://github.com/saber-notes/saber 的固定版本，再覆盖 overlay 文件。原版的自动发布任务不会成为本仓库的任务。
保留 GPL-3.0 许可及上游版权声明。
