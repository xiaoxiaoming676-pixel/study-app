#!/usr/bin/env bash
set -euo pipefail
: "${STUDY_APPLE_TEAM_ID:?Set the owner Apple team in Codemagic}"
: "${CM_ENV:?This script runs in the Codemagic build environment}"
python3 tools/release/verify_ci.py --sha "$STUDY_RC_SHA" \
  --ios-run "$STUDY_IOS_RUN_ID" --windows-run "$STUDY_WINDOWS_RUN_ID"
python3 - <<'PY'
import os, re
team = os.environ['STUDY_APPLE_TEAM_ID']
if not re.fullmatch(r'[A-Z0-9]{10}', team):
    raise ValueError('Expected owner Apple team identifier')
if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', os.environ['STUDY_VERSION']):
    raise ValueError('App Store version must be three numeric components')
values = [os.environ['PROJECT_BUILD_NUMBER'], os.environ['STUDY_BUILD_OFFSET']]
if any(not re.fullmatch(r'[0-9]+', v) for v in values):
    raise ValueError('Build count and offset must be nonnegative integers')
build = sum(map(int, values))
if not 1 <= build <= 9999:
    raise ValueError('First RC uses a positive one-component build number <= 9999')
with open(os.environ['CM_ENV'], 'a', encoding='utf-8') as stream:
    stream.write(f'STUDY_BUILD_NUMBER={build}\n')
PY
# Fail if the selected image no longer matches the tested toolchain.
flutter --version --machine > /tmp/study-flutter-version.json
python3 - <<'PY'
import json
with open('/tmp/study-flutter-version.json') as stream:
    data = json.load(stream)
if data['frameworkRevision'] != '9584c6713b324636289d067944a46fd6b49df14b':
    raise ValueError('Flutter revision differs from RC1; revalidate before signing')
PY
test "$(xcodebuild -version)" = "$(printf 'Xcode 26.6\nBuild version 17F113')"
git fetch origin "$STUDY_RC_SHA"
base=$(git show "$STUDY_RC_SHA:BASE_COMMIT.txt" | tr -d '\r\n')
test "$base" = '5b396a40406c75835741f5c4555bc10ae816f121'
# Never overwrite an existing checkout.
test ! -e source
git clone --no-checkout https://github.com/saber-notes/saber.git source
git -C source checkout --detach "$base"
overlay_dir=$(mktemp -d)
git archive "$STUDY_RC_SHA" overlay | tar -x -C "$overlay_dir"
cp -R "$overlay_dir/overlay/." source/
mkdir -p release-evidence
python3 - <<'PY'
import json, os, subprocess
from pathlib import Path
record = {
    'application_sha': os.environ['STUDY_RC_SHA'],
    'signing_config_sha': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
    'ios_ci_run': os.environ['STUDY_IOS_RUN_ID'],
    'windows_ci_run': os.environ['STUDY_WINDOWS_RUN_ID'],
    'flutter': json.loads(Path('/tmp/study-flutter-version.json').read_text()),
    'xcode': subprocess.check_output(['xcodebuild', '-version'], text=True).strip(),
    'version': os.environ['STUDY_VERSION'],
    'build_number': str(int(os.environ['PROJECT_BUILD_NUMBER']) + int(os.environ['STUDY_BUILD_OFFSET'])),
    'device_status': 'pending',
}
Path('release-evidence/provenance.json').write_text(json.dumps(record, indent=2) + '\n')
PY
