from pathlib import Path
import subprocess,zipfile
ROOT=Path(__file__).resolve().parents[2]
BASE='5b396a40406c75835741f5c4555bc10ae816f121'
out=ROOT.parent/'deliverables';out.mkdir(exist_ok=True)
def git(*args):return subprocess.check_output(['git','-C',str(ROOT),*args])
paths=git('diff',BASE,'--name-only').decode().splitlines()+git('ls-files','--others','--exclude-standard').decode().splitlines()
paths=sorted({p for p in paths if '__pycache__' not in p and not p.endswith('.pyc')})
# Include newly written files in patch without changing their contents.
subprocess.run(['git','-C',str(ROOT),'add','--',*paths],check=True)
patch=git('diff',BASE,'--binary')
with zipfile.ZipFile(out/'StudyApp-checkpoint.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in paths:
  if (ROOT/p).is_file():z.write(ROOT/p,'overlay/'+p)
 z.write(ROOT/'LICENSE.md','LICENSE.md')
 z.writestr('study.patch',patch)
 z.writestr('BASE_COMMIT.txt',BASE+'\n')
 if (out/'restore.sh').exists():z.write(out/'restore.sh','restore.sh')
 z.writestr('README.txt','手机优先学习软件源码检查点。未签名、不是安装包。\n运行 sh restore.sh 恢复基础源码和覆盖文件。\n进度与测试状态见 overlay/STUDY_PROGRESS.md。')
print(out/'StudyApp-checkpoint.zip')
