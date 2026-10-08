#!/usr/bin/env bash
# Run inside the disposable source directory. Same renderer and checksums as RC1 CI.
set -euo pipefail
package=$(npm pack @aiden0z/pptx-renderer@1.3.0 --silent)
renderer_dir=$(mktemp -d)
tar -xzf "$package" -C "$renderer_dir"
renderer="$renderer_dir/package/dist/aiden0z-pptx-renderer.browser.es.js"
printf '%s  %s\n' '46b61afa1435de0c194f93324c9467ca392c891c6e07517727c8ffb5e51c376b' "$renderer" | shasum -a 256 -c -
npx --yes esbuild@0.25.12 "$renderer" --bundle --platform=browser \
  --format=iife --global-name=StudyPptx --minify --legal-comments=none \
  --outfile=assets/images/pptx_renderer.js
printf '%s  %s\n' 'f83a58c6bcb652ea61456ce8ad6e5e49f10f7f6f4e9dd42f96c3be37a9706958' assets/images/pptx_renderer.js | shasum -a 256 -c -
python3 - <<'PY'
from pathlib import Path
page = Path('assets/images/pptx_bridge.html')
script = Path('assets/images/pptx_renderer.js').read_text(encoding='utf-8')
source = page.read_text(encoding='utf-8')
marker = '/* STUDY_RENDERER_SCRIPT */'
assert source.count(marker) == 1 and '</script' not in script.lower()
page.write_text(source.replace(marker, script), encoding='utf-8')
PY
cp "$renderer_dir/package/LICENSE" assets/images/pptx_renderer.LICENSE
rm -f assets/images/pptx_renderer.js "$package"
