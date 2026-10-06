"""Small Windows-friendly front end for the existing local textbook tool."""
from __future__ import annotations

import queue
import re
import threading
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

from prepare import prepare


def suggested_output(source: Path) -> Path:
    """Choose a new folder so a previous set of study files is never replaced."""
    base = source.with_name(f'{source.stem}-study')
    candidate = base
    number = 2
    while candidate.exists():
        candidate = base.with_name(f'{base.name}-{number}')
        number += 1
    return candidate


def parse_rules(keywords: str, colors: str, bold: bool, underline: bool):
    words = [line.strip() for line in keywords.splitlines() if line.strip()]
    rgb = []
    for raw in re.split(r'[,，;；\s]+', colors.strip()):
        if not raw:
            continue
        color = raw.removeprefix('#')
        if not re.fullmatch(r'[0-9a-fA-F]{6}', color):
            raise ValueError(f'颜色“{raw}”不是六位 RGB，例如 FF0000。')
        rgb.append(int(color, 16))
    if not (words or rgb or bold or underline):
        raise ValueError('请填写关键词、颜色，或勾选加粗/下划线中的至少一项。')
    return words, rgb


class StudyTool(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title('Study 教材准备')
        self.geometry('610x510')
        self.minsize(540, 460)
        self.source = tk.StringVar()
        self.output = tk.StringVar()
        self.colors = tk.StringVar()
        self.bold = tk.BooleanVar()
        self.underline = tk.BooleanVar()
        self.status = tk.StringVar(value='选择 PDF 或 PPTX，然后设置需要挖空的内容。')
        self.results = queue.Queue()
        self.last_output = None
        self.protocol('WM_DELETE_WINDOW', self.close)

        body = ttk.Frame(self, padding=16)
        body.pack(fill='both', expand=True)
        body.columnconfigure(0, weight=1)

        ttk.Label(body, text='教材文件（PDF 或 PPTX）').grid(row=0, column=0, sticky='w')
        ttk.Button(body, text='选择文件', command=self.choose_source).grid(row=0, column=1, padx=(8, 0))
        ttk.Entry(body, textvariable=self.source).grid(row=1, column=0, columnspan=2, sticky='ew', pady=(4, 12))

        ttk.Label(body, text='输出文件夹（自动建议新文件夹，不覆盖旧结果）').grid(row=2, column=0, sticky='w')
        ttk.Button(body, text='选择位置', command=self.choose_output).grid(row=2, column=1, padx=(8, 0))
        ttk.Entry(body, textvariable=self.output).grid(row=3, column=0, columnspan=2, sticky='ew', pady=(4, 12))

        ttk.Label(body, text='关键词（一行一个，同页重复的词会全部成为候选）').grid(row=4, column=0, columnspan=2, sticky='w')
        self.keywords = tk.Text(body, height=5, wrap='word')
        self.keywords.grid(row=5, column=0, columnspan=2, sticky='nsew', pady=(4, 12))
        body.rowconfigure(5, weight=1)

        ttk.Label(body, text='字体颜色（六位 RGB；多个颜色用逗号隔开）').grid(row=6, column=0, columnspan=2, sticky='w')
        ttk.Entry(body, textvariable=self.colors).grid(row=7, column=0, columnspan=2, sticky='ew', pady=(4, 8))
        ttk.Checkbutton(body, text='加粗', variable=self.bold).grid(row=8, column=0, sticky='w')
        ttk.Checkbutton(body, text='下划线（仅 PPTX 显式文字样式）', variable=self.underline).grid(row=8, column=1, sticky='w')
        ttk.Label(body, text='规则按“任意匹配”组合；候选仍需在 App 内逐项核对。', wraplength=550).grid(
            row=9, column=0, columnspan=2, sticky='w', pady=(10, 6))
        ttk.Label(body, textvariable=self.status, wraplength=550).grid(row=10, column=0, columnspan=2, sticky='w')
        buttons = ttk.Frame(body)
        buttons.grid(row=11, column=0, columnspan=2, sticky='e', pady=(12, 0))
        self.open_button = ttk.Button(buttons, text='打开输出文件夹', command=self.open_output, state='disabled')
        self.open_button.pack(side='left', padx=(0, 8))
        self.run_button = ttk.Button(buttons, text='生成教材', command=self.run)
        self.run_button.pack(side='left')

    def choose_source(self):
        path = filedialog.askopenfilename(filetypes=[('教材', '*.pdf *.pptx'), ('所有文件', '*.*')])
        if path:
            self.source.set(path)
            self.output.set(str(suggested_output(Path(path))))

    def choose_output(self):
        path = filedialog.askdirectory(title='选择用于保存结果的新文件夹的上级目录')
        if path:
            source = Path(self.source.get()) if self.source.get().strip() else None
            name = source.stem if source else 'output'
            self.output.set(str(suggested_output(Path(path) / name)))

    def run(self):
        try:
            source = Path(self.source.get().strip()).expanduser().resolve()
            output = Path(self.output.get().strip()).expanduser().resolve()
            if not self.source.get().strip() or not source.is_file() or source.suffix.lower() not in ('.pdf', '.pptx'):
                raise ValueError('请选择一个现有的 PDF 或 PPTX 文件。')
            if not self.output.get().strip():
                raise ValueError('请选择输出文件夹。')
            if output.exists():
                raise ValueError('输出文件夹已存在。请换一个新文件夹，避免覆盖以前的结果。')
            if source.suffix.lower() == '.pdf' and self.underline.get():
                raise ValueError('PDF 下划线尚不能可靠识别；请改用关键词、颜色或加粗。')
            words, rgb = parse_rules(self.keywords.get('1.0', 'end'), self.colors.get(),
                                     self.bold.get(), self.underline.get())
        except (ValueError, OSError) as error:
            messagebox.showerror('无法生成', str(error), parent=self)
            return
        self.run_button.config(state='disabled')
        self.open_button.config(state='disabled')
        self.last_output = None
        self.status.set('正在本机处理教材；较大的课件可能需要几分钟……')
        bold, underline = self.bold.get(), self.underline.get()

        def worker():
            try:
                result = prepare(source, output, keywords=words, colors=rgb,
                                 bold=bold, underline=underline)
                self.results.put((output, result, None))
            except Exception as error:
                self.results.put((output, None, error))

        threading.Thread(target=worker, daemon=True).start()
        self.after(100, self.check_result)

    def check_result(self):
        try:
            output, result, error = self.results.get_nowait()
        except queue.Empty:
            self.after(100, self.check_result)
            return
        self.run_button.config(state='normal')
        if error:
            self.status.set('处理失败；原始教材未修改。')
            messagebox.showerror('处理失败', str(error), parent=self)
            return
        pages = len(result['pages'])
        masks = sum(len(page['masks']) for page in result['pages'])
        self.status.set(f'完成：{pages} 页、{masks} 个挖空候选。')
        self.last_output = output
        self.open_button.config(state='normal')
        warnings = '\n'.join(result['warnings'])
        messagebox.showinfo('教材已生成',
                            f'保存到：\n{output}\n\n把 textbook.pdf 导入 App，再导入 study-rules.json。'
                            + (f'\n\n请检查：\n{warnings}' if warnings else ''), parent=self)

    def open_output(self):
        import os
        if self.last_output:
            os.startfile(self.last_output)

    def close(self):
        if str(self.run_button['state']) == 'disabled':
            messagebox.showinfo('正在处理', '请等本次教材处理结束后再关闭窗口。', parent=self)
            return
        self.destroy()


if __name__ == '__main__':
    import sys
    if '--self-test' in sys.argv:
        # Usable by CI without opening a window or converting a private file.
        import fitz
        import pptx
        interpreter = tk.Tcl()
        assert interpreter.eval('expr {2 + 2}') == '4'
        assert fitz.open().page_count == 0
        assert pptx.Presentation()
    else:
        StudyTool().mainloop()
