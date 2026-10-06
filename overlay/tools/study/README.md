# 本地教材处理工具

这是可独立运行的 Windows 教材准备工具；App 内 PPTX 离线导入另有模拟器原型，仍需真实教材验收。

## 环境

Python 3.10+。PPTX 转换需要 LibreOffice，或 Windows 上安装的 Microsoft PowerPoint。

Windows 用户可直接双击构建产物 `StudyTextbookTool.exe`，无需另装 Python。窗口选择课件、填写关键词或颜色、勾选加粗/下划线，再点“生成教材”。窗口自动建议新的输出文件夹，避免覆盖旧文件；下划线仅适用于 PPTX 显式文字样式。PPTX 转 PDF 自动选用系统上的 LibreOffice，若无则使用 Windows PowerPoint；PDF 输入不需要两者。处理过程在本机完成，不会上传课件。首次运行单文件 EXE 可能稍慢。

开发者在仓库根目录运行 `build_windows_tool.ps1` 即可重新生成 EXE 和 SHA256；GitHub Actions 也会自动构建并上传 `Study-Windows-textbook-tool` 归档。源码模式可双击 `start_study_tool.cmd`，此模式需要 Python 和依赖。

命令行方式仍可用于批量处理：

```sh
python3 -m pip install -r tools/study/requirements.txt
python3 tools/study/prepare.py lesson.pptx --out lesson-study --color FF0000 --bold --underline
python3 tools/study/prepare.py lesson.pdf --out pdf-study --keyword 关键词 --color 0000FF
```

Windows 上如已安装 PowerPoint，无需另装 LibreOffice。可用 `python` 代替上面命令中的 `python3`；工具会优先使用 LibreOffice，未找到时调用本机 PowerPoint 导出 PDF。

颜色不是固定为红色，可多次传 --color；关键词也可多次传 --keyword。
规则按“任意匹配（OR）”组合。暂不支持高亮颜色、AI 重点和 OCR。

输出：
- textbook.pdf：供 App 导入的规范化教材原文。
- practice.pdf：已移除对应答案文字的固定练习 PDF，可在任何批注工具中书写；不能直接恢复答案。
- study-rules.json：可恢复挖空候选，包含答案、页面文字、归一化位置及 PDF SHA256。

在学习版 Saber 中导入 textbook.pdf，打开某页的“学习”按钮，导入对应 study-rules.json。
规则会导入到笔记中所有属于同一 PDF 的页面；确认候选后保存。可手动增加或删除框。
手机学习页包含阅读、挖空、答题、听读入口。点选题目打开手写/输入答案面板；自由批注仍在原教材编辑器使用笔工具完成。
重新练习仅清除独立答案。导出分原文版、挖空版、笔记与答题版；原生界面尚待编译和真机测试。

## 限制

- PDF 颜色/加粗基于实际渲染文字；颜色精确匹配，不自动合并近似色。
- PPTX 下划线只支持显式文字样式，不支持继承样式和手绘线。
- PPTX 标记词语在同页重复时，可能将未标记的相同词语也列为候选，需预览。
- 字体替换、公式、复杂图表可能影响 PPTX 转换，需对照教材。
- 图片和扫描件未 OCR，只能手动框选。
- 矩形挖空可能遮住局部背景；此版本尚未做复杂背景修补。
- Apple PDFKit 自动定位暂不支持旋转/裁切 PDF，工具生成的 textbook.pdf 会规范化页面。
- 手动框选没有答案文字映射；隐藏答案时会阻止朗读，避免泄露答案。
- study-rules.json 保存了原文答案，作为个人学习资料保管。
- 输出文件已存在会拒绝覆盖，请更换输出目录。

测试：
```sh
python3 -m unittest discover -s tools/study -p 'test_*.py' -v
```

规范化会保留批注和表单的可见外观，并固定为页面内容；不保留其可编辑性、链接和目录。原始输入文件不变。
电脑工具尚不按 PDF 高亮生成规则；App 的 PDFKit 高亮候选代码已写入但未真机验证。
原文版导出会排除学习遮盖、独立答案和笔迹，但无法区分原文和后来添加的文字/图片；若需完全原始教材请保留输入文件。
