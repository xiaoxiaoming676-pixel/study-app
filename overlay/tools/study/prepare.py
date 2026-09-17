"""Local-only PDF/PPTX cloze preparation. No document is uploaded.

PPTX is rendered by LibreOffice; matching occurs on the rendered PDF so masks
use real glyph positions. PDF style rules refer to rendered text properties.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

import fitz


def normalize_pdf(source: Path, output: Path) -> None:
    """Flatten page rotation/crop geometry while retaining a searchable PDF."""
    doc = fitz.open(source)
    if doc.needs_pass:
        raise ValueError('Password-protected PDF is not supported')
    # Preserve visible comments/highlights before copying page content.
    # The normalized study copy is intentionally no longer an editable form.
    doc.bake(annots=True, widgets=True)
    normalized = fitz.open()
    for page in doc:
        size, rotation = page.rect, page.rotation
        page.set_rotation(0)
        target = normalized.new_page(width=size.width, height=size.height)
        if page.get_contents():
            target.show_pdf_page(target.rect, doc, page.number, rotate=-rotation)
    normalized.save(output, garbage=4, deflate=True)
    normalized.close()
    doc.close()


def select_masks(page, keywords=(), colors=(), bold=False, underline=False):
    """Select PDF text by keyword, exact RGB or bold. Rules combine with OR.

    Underline is deliberately rejected: a drawn line is not reliably attached
    to text in PDF. PPTX underline is extracted separately before rendering.
    """
    if underline:
        raise ValueError('PDF underline recognition is not implemented')
    masks = []
    seen = set()

    def add(rect, answer):
        r = fitz.Rect(rect) & page.rect
        if r.is_empty:
            return
        key = tuple(round(v, 3) for v in r)
        if key in seen:
            return
        seen.add(key)
        masks.append({'rect': [r.x0 / page.rect.width, r.y0 / page.rect.height,
                     r.width / page.rect.width, r.height / page.rect.height],
                      'answer': answer})

    for keyword in keywords:
        if keyword:
            for r in page.search_for(keyword):
                add(r, keyword)
    for block in page.get_text('dict')['blocks']:
        for line in block.get('lines', []):
            for span in line['spans']:
                if span['color'] in colors or (bold and span['flags'] & 16):
                    if span['text'].strip():
                        add(span['bbox'], span['text'])
    return masks


def pptx_marked_text(source: Path, colors=(), bold=False, underline=False):
    """Return per-slide explicitly styled runs. Inherited styles are reported.

    Explicit underline and explicit run colors are supported. Theme/inherited
    style selection is not guessed. The rendered PDF pass handles effective
    RGB/bold. Multiple identical phrases on a slide are all matched in v0.1.
    """
    from pptx import Presentation
    from pptx.enum.dml import MSO_COLOR_TYPE
    prs = Presentation(source)
    slides = []
    warnings = []
    for number, slide in enumerate(prs.slides):
        marked = []
        def visit(shapes):
            for shape in shapes:
                if hasattr(shape, 'shapes'):
                    visit(shape.shapes)
                frames = [shape.text_frame] if shape.has_text_frame else []
                if shape.has_table:
                    frames.extend(cell.text_frame for row in shape.table.rows for cell in row.cells)
                for frame in frames:
                    for paragraph in frame.paragraphs:
                        for run in paragraph.runs:
                            font = run.font
                            rgb = int(str(font.color.rgb), 16) if font.color.type == MSO_COLOR_TYPE.RGB else None
                            is_underlined = font.underline is not None and font.underline is not False and font.underline != 0
                            if ((rgb is not None and rgb in colors) or (bold and font.bold is True)
                                    or (underline and is_underlined)) and run.text.strip():
                                marked.append(run.text.strip())
        visit(slide.shapes)
        slides.append(list(dict.fromkeys(marked)))
    if underline:
        warnings.append('下划线仅识别 PPTX 显式文字样式，继承样式和手绘线未识别。')
    if any(slides):
        warnings.append('PPTX 标记词语若在同页重复出现，会全部列为候选；应用前请预览删除多余位置。')
    return slides, warnings


def prepare(source: Path, output: Path, *, keywords=(), colors=(), bold=False, underline=False):
    source = source.resolve()
    output.mkdir(parents=True, exist_ok=True)
    targets = [output / name for name in ['textbook.pdf', 'practice.pdf', 'study-rules.json']]
    if source in [p.resolve() for p in targets]:
        raise ValueError('Output must not overwrite the input file')
    if any(p.exists() for p in targets):
        raise ValueError('Output files already exist; choose a new output directory')
    if not (keywords or colors or bold or underline):
        raise ValueError('Specify at least one rule')
    warnings = []
    marked = []
    with tempfile.TemporaryDirectory(prefix='study-') as tmp:
        tmp = Path(tmp)
        rendered = source
        if source.suffix.lower() == '.pptx':
            marked, warnings = pptx_marked_text(source, colors, bold, underline)
            executable = shutil.which('soffice') or shutil.which('libreoffice')
            if not executable:
                raise RuntimeError('Install LibreOffice to convert PPTX')
            profile = (tmp / 'profile').as_uri()
            subprocess.run([executable, f'-env:UserInstallation={profile}', '--headless',
                            '--convert-to', 'pdf', '--outdir', str(tmp), str(source)],
                           check=True, capture_output=True, text=True, timeout=120)
            rendered = tmp / (source.stem + '.pdf')
            if not rendered.exists():
                raise RuntimeError('LibreOffice did not produce a PDF')
            warnings.append('PPTX 转换依赖电脑字体；请对照原教材检查排版、公式和缺失字体。')
        elif source.suffix.lower() != '.pdf':
            raise ValueError('Only .pptx and .pdf are supported')
        elif underline:
            raise ValueError('PDF 下划线识别尚未实现；请使用关键词、颜色或加粗规则。')
        normalize_pdf(rendered, tmp / 'textbook.pdf')
        doc = fitz.open(tmp / 'textbook.pdf')
        pages = []
        for i, page in enumerate(doc):
            words = list(keywords) + (marked[i] if i < len(marked) else [])
            masks = select_masks(page, words, colors, bold)
            pages.append({'index': i, 'masks': masks, 'hidden': True, 'text': page.get_text()})
            if not page.get_text().strip():
                warnings.append(f'第 {i + 1} 页没有可提取文字；未执行 OCR，可手动框选。')
        manifest = {'schema': 'saber-study/1', 'pdf_sha256': hashlib.sha256((tmp / 'textbook.pdf').read_bytes()).hexdigest(),
                    'rules': {'keywords': list(keywords), 'colors': [f'{c:06X}' for c in colors], 'bold': bold, 'underline': underline, 'combine': 'OR'},
                    'warnings': warnings, 'pages': pages}
        # Irreversibly redact answers in the practice export; original stays intact.
        for page, record in zip(doc, pages):
            for mask in record['masks']:
                x,y,w,h=mask['rect']
                r=fitz.Rect(x*page.rect.width,y*page.rect.height,(x+w)*page.rect.width,(y+h)*page.rect.height)
                page.add_redact_annot(r, fill=(1,1,1))
            if record['masks']:
                page.apply_redactions(images=0, graphics=0)
                for mask in record['masks']:
                    x,y,w,h=mask['rect']
                    page.draw_line(fitz.Point(x*page.rect.width,(y+h)*page.rect.height),
                                   fitz.Point((x+w)*page.rect.width,(y+h)*page.rect.height), color=(0,0.45,0.4), width=0.7)
        doc.save(tmp / 'practice.pdf', garbage=4, deflate=True)
        doc.close()
        (tmp / 'study-rules.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
        for target in targets:
            shutil.copy2(tmp / target.name, target)
    return manifest


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('source',type=Path)
    p.add_argument('--out',type=Path,required=True)
    p.add_argument('--keyword',action='append',default=[])
    p.add_argument('--color',action='append',default=[],help='Exact RGB e.g. FF0000; repeatable')
    p.add_argument('--bold',action='store_true')
    p.add_argument('--underline',action='store_true',help='Explicit PPTX underline only')
    a=p.parse_args()
    try:
        colors=[int(s.lstrip('#'),16) for s in a.color]
        if any(c<0 or c>0xFFFFFF for c in colors):raise ValueError('RGB outside range')
        result=prepare(a.source,a.out,keywords=a.keyword,colors=colors,bold=a.bold,underline=a.underline)
        print(json.dumps({'pages':len(result['pages']), 'masks':sum(len(p['masks']) for p in result['pages']),
                          'warnings':result['warnings']},ensure_ascii=False,indent=2))
    except Exception as e:
        p.exit(1, f'Error: {e}\n')
if __name__=='__main__':main()
