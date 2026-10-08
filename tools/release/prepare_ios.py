"""Apply the Study identity to a disposable pinned Saber checkout for signing."""
import argparse
import json
import plistlib
import re
import struct
from pathlib import Path

BUNDLE_ID = 'com.xiaoxiaoming676.studyapp'


def prepare(source: Path) -> dict:
    project = source / 'ios/Runner.xcodeproj/project.pbxproj'
    text = project.read_text(encoding='utf-8')
    if 'com.adilhanney.saber' not in text and BUNDLE_ID not in text:
        raise ValueError('Unrecognized application identity; inspect upstream changes')
    text = text.replace('com.adilhanney.saber', BUNDLE_ID)
    text = text.replace('INFOPLIST_KEY_CFBundleDisplayName = Saber;',
                        'INFOPLIST_KEY_CFBundleDisplayName = Study;')
    # The provisioning profile, not the upstream developer, supplies the team.
    text = re.sub(r'(?m)^\s*DEVELOPMENT_TEAM = [^;]+;\r?\n', '\n', text)
    if text.count(f'PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};') != 3:
        raise ValueError('Expected Debug, Profile and Release Runner identifiers')
    targets = re.findall(r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);', text)
    if not targets or set(targets) != {'15.0'}:
        raise ValueError(f'Unexpected iOS deployment targets: {targets}')

    plist_path = source / 'ios/Runner/Info.plist'
    with plist_path.open('rb') as stream:
        info = plistlib.load(stream)
    info['CFBundleDisplayName'] = 'Study'
    info['CFBundleName'] = 'Study'
    info['NSCameraUsageDescription'] = '拍摄照片并添加到你的学习笔记。'
    info['NSPhotoLibraryUsageDescription'] = '选择照片并添加到你的学习笔记。'
    for key, expected in {
        'CFBundleIdentifier': '$(PRODUCT_BUNDLE_IDENTIFIER)',
        'CFBundleShortVersionString': '$(FLUTTER_BUILD_NAME)',
        'CFBundleVersion': '$(FLUTTER_BUILD_NUMBER)',
        'UILaunchStoryboardName': 'LaunchScreen',
        'UIMainStoryboardFile': 'Main',
    }.items():
        if info.get(key) != expected:
            raise ValueError(f'Unexpected Info.plist value: {key}')
    for name in ('Main', 'LaunchScreen'):
        if not (source / f'ios/Runner/Base.lproj/{name}.storyboard').is_file():
            raise ValueError(f'Missing {name} storyboard')

    icons = source / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    entries = json.loads((icons / 'Contents.json').read_text())['images']
    default_large_icon = False
    for entry in entries:
        path = icons / entry['filename']
        header = path.read_bytes()[:26]
        if header[:8] != b'\x89PNG\r\n\x1a\n' or header[12:16] != b'IHDR':
            raise ValueError(f'Invalid PNG icon: {path.name}')
        dimensions = struct.unpack('>II', header[16:24])
        expected_size = tuple(round(float(n) * float(entry['scale'][:-1]))
                              for n in entry['size'].split('x'))
        if dimensions != expected_size:
            raise ValueError(f'Wrong icon dimensions: {path.name}')
        if entry['size'] == '1024x1024' and not entry.get('appearances'):
            # Default marketing icon must be opaque; preserve dark variants.
            if header[25] != 2:
                raise ValueError('Default marketing icon must be RGB PNG')
            default_large_icon = True
    if not default_large_icon:
        raise ValueError('Missing default 1024px icon')
    entitlements = re.findall(r'CODE_SIGN_ENTITLEMENTS = ([^;]+);', text)
    if entitlements:
        raise ValueError('New entitlements need review before first signing')
    # Validate the disposable source before changing it. These operations never
    # touch a user's installed application or learning records.
    project.write_text(text, encoding='utf-8')
    with plist_path.open('wb') as stream:
        plistlib.dump(info, stream, sort_keys=False)
    for name in ('study_large_120_pages.pdf', 'deck_complex.pptx',
                 'real_corpus_illinois.pptx', 'real_large_scan.pdf'):
        (source / 'assets/images' / name).unlink(missing_ok=True)
    return {'bundle_id': BUNDLE_ID, 'display_name': 'Study',
            'minimum_ios': '15.0', 'icons_checked': len(entries),
            'explicit_entitlements': entitlements,
            'signing_status': 'requires Codemagic provisioning profiles'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    args = parser.parse_args()
    print(json.dumps(prepare(args.source), ensure_ascii=False, indent=2))
