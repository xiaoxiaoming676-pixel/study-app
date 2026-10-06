# 固定教材验收 corpus（阶段 1）

`fixtures/` 全部是无个人信息的**合成样本**，`corpus.json` 固定文件 SHA256、页数、扫描页预期词语和位置。不要用这些样本的通过结果代替真实教材准确率。

| 文件 | 覆盖内容 | 参考结果 |
| --- | --- | --- |
| `text_styles.pdf` | 可选中文字、中英文字、彩色、加粗、下划线、PDF 高亮、竖页和重复词 | 页数与文字可提取性 |
| `scan_styles.pdf` | 只有图片的扫描页：红字、黄底高亮、横线和普通字 | `corpus.json` 中的词语与归一化位置 |
| `deck_complex.pptx` | 中文字体、彩色与下划线文字、形状、表格、图片、公式图片、柱状图 | `deck_complex_powerpoint.pdf`：由 Windows PowerPoint 16 导出 |
| `large_120_pages.pdf` | 120 页、重复段落和跨章节页码 | 120 页、可提取末页文字 |

## 固定质量指标

将候选离线转换器输出的 PDF 与 `deck_complex_powerpoint.pdf` 比较：

```sh
python overlay/tools/study/quality/evaluate.py candidate.pdf --gate --output quality-report.json
```

报告逐页列出 RGB 平均绝对像素差（0–255）、页面宽高比差、可提取文字字符召回率。暂定合成样本门槛：页数完全相等、宽高比差不超过 0.005、平均 RGB 差不超过 12、最差页不超过 20、每页文字字符召回率不低于 0.98。工具以统一宽度渲染两份 PDF；此指标无法单独发现图表数值错误，必须保留人工逐页对照。候选 PDF 若把文字画成图片，文字召回率会暴露这一点。

扫描页需分别运行关键词、红字、浅底高亮、近似下划线模式，并保存各自返回的 `masks`：

```json
{"keyword": [{"answer": "Alpha", "rect": [0.07, 0.09, 0.10, 0.08]}], "red_text": [], "highlight": [], "underline": []}
```

再运行 `python overlay/tools/study/quality/score_scan.py predictions.json --output scan-report.json`。词语相同且位置交并比至少 0.25 才算命中；报告分别列出 TP、FP、FN、精确率、召回率以及误检和漏检详情。真实样本应人工标注词语与页面归一化框，再用 `--expected` 指定标注 JSON。

## 真实教材接收与验收

目前**尚无用户许可的真实教材样本**。取得已去隐私且获准测试的样本后，放在不提交的本机 `quality/private/`。为每份 PDF、扫描件和 PPTX 记录：来源及许可、SHA256、页数、页面方向、字体/图表/公式类型、人工标注的重点位置；PPTX 还要用本机 PowerPoint 导出参考 PDF。每次转换保存工具版本、设备/模拟器、耗时、峰值内存、是否取消、失败提示和恢复结果。每种扫描规则按页报告 FP/FN；PPTX 按页报告视觉指标并人工审查图表与公式。100 页以上文件分别测试导入、翻页、保存、取消和异常后的原文件/笔记完整性。真实样本结果另存本机，不把私人教材或标注上传到公开仓库。

`make_corpus.py` 用于有 PowerPoint 的 Windows 开发机有意重建合成样本；重建会改变 corpus SHA256，必须重新审查差异后提交。自动测试只校验已固定的文件，不在 CI 中重新生成参考 PDF。
