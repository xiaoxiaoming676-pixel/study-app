param(
    [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$python = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $python)) {
    py -3 -m venv .venv
}
if (-not $SkipInstall) {
    & $python -m pip install -r overlay\tools\study\requirements.txt
    if ($LASTEXITCODE -ne 0) { throw 'Could not install textbook dependencies.' }
    & $python -m pip install pyinstaller==6.22.3
    if ($LASTEXITCODE -ne 0) { throw 'Could not install PyInstaller.' }
}
& $python -m PyInstaller --noconfirm --clean --onefile --windowed `
    --name StudyTextbookTool `
    --distpath dist\windows-tool `
    --workpath build\pyinstaller `
    --specpath build\pyinstaller `
    overlay\tools\study\gui.py
if ($LASTEXITCODE -ne 0) { throw 'Windows EXE build failed.' }
$exe = Join-Path $PSScriptRoot 'dist\windows-tool\StudyTextbookTool.exe'
& $exe --self-test
if ($LASTEXITCODE -ne 0) { throw 'Packaged EXE smoke test failed.' }
Get-FileHash -Algorithm SHA256 -LiteralPath $exe |
    ForEach-Object { "$($_.Hash.ToLowerInvariant())  StudyTextbookTool.exe" } |
    Set-Content -Encoding ascii dist\windows-tool\SHA256.txt
Write-Host "Ready: $exe"
