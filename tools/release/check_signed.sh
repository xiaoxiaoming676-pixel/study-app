#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob
ipas=(source/build/ios/ipa/*.ipa)
if [ "${#ipas[@]}" -ne 1 ]; then
  echo 'Expected exactly one exported IPA'; exit 1
fi
inspection_dir=$(mktemp -d)
ditto -x -k "${ipas[0]}" "$inspection_dir"
app="$inspection_dir/Payload/Runner.app"
# Verify actual Apple signature; Python metadata checks alone cannot do this.
codesign --verify --deep --strict "$app"
security cms -D -i "$app/embedded.mobileprovision" > "$inspection_dir/profile.plist"
codesign -d --entitlements :- "$app" > "$inspection_dir/entitlements.plist"
python3 tools/release/verify_ipa.py --ipa "${ipas[0]}" \
  --profile "$inspection_dir/profile.plist" \
  --entitlements "$inspection_dir/entitlements.plist" \
  --export-options "$HOME/export_options.plist" \
  --version "$STUDY_VERSION" --build "$STUDY_BUILD_NUMBER" \
  --team "$STUDY_APPLE_TEAM_ID" --output release-evidence/package-check.json
# Expose an IPA to the publisher only after all verification succeeds.
test ! -e release-evidence/Study-RC.ipa
cp "${ipas[0]}" release-evidence/Study-RC.ipa
(cd release-evidence && shasum -a 256 Study-RC.ipa > SHA256SUMS)
# Only safe metadata and IPA are artifacts; decoded profiles stay temporary.
