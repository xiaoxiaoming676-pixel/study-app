"""Verify exported RC metadata and decoded Apple signing data before publishing.

macOS codesign verification must precede this script. Presence of signature
files alone is not proof of a valid signature or of TestFlight acceptance.
"""
import argparse
import datetime
import hashlib
import json
import plistlib
import zipfile
from pathlib import Path

BUNDLE_ID = 'com.xiaoxiaoming676.studyapp'
ROOT = 'Payload/Runner.app/'


def verify(ipa: Path, version: str, build: str, team: str,
           profile: dict, signed: dict, export: dict) -> dict:
    if export.get('method') not in ('app-store', 'app-store-connect'):
        raise ValueError('Export method must be App Store Connect')
    if export.get('teamID') != team or not team:
        raise ValueError('Export team does not match the owner-selected team')
    if profile.get('TeamIdentifier') != [team]:
        raise ValueError('Wrong provisioning team')
    if 'ProvisionedDevices' in profile or profile.get('ProvisionsAllDevices'):
        raise ValueError('Device/enterprise profile cannot be used for TestFlight')
    expiration = profile.get('ExpirationDate')
    if not isinstance(expiration, datetime.datetime):
        raise ValueError('Missing profile expiration')
    if expiration.replace(tzinfo=datetime.timezone.utc) <= datetime.datetime.now(datetime.timezone.utc):
        raise ValueError('Expired provisioning profile')
    prefixes = profile.get('ApplicationIdentifierPrefix', [])
    if len(prefixes) != 1 or not isinstance(prefixes[0], str):
        raise ValueError('Expected one Apple application identifier prefix')
    for label, entitlements in [('profile', profile.get('Entitlements', {})),
                                 ('signature', signed)]:
        if entitlements.get('application-identifier') != f'{prefixes[0]}.{BUNDLE_ID}':
            raise ValueError(f'Wrong {label} application identifier')
        if entitlements.get('com.apple.developer.team-identifier') != team:
            raise ValueError(f'Wrong {label} team identifier')
        if entitlements.get('get-task-allow') is not False:
            raise ValueError(f'{label} must explicitly disallow debugging')
    with zipfile.ZipFile(ipa) as archive:
        names = set(archive.namelist())
        for name in ('Info.plist', 'embedded.mobileprovision',
                     '_CodeSignature/CodeResources', 'Runner'):
            if ROOT + name not in names:
                raise ValueError(f'Missing device application file: {name}')
        info = plistlib.loads(archive.read(ROOT + 'Info.plist'))
        expected = {'CFBundleIdentifier': BUNDLE_ID,
                    'CFBundleDisplayName': 'Study',
                    'CFBundleShortVersionString': version,
                    'CFBundleVersion': build,
                    'MinimumOSVersion': '15.0',
                    'CFBundleSupportedPlatforms': ['iPhoneOS']}
        for key, value in expected.items():
            if info.get(key) != value:
                raise ValueError(f'Unexpected exported {key}: {info.get(key)!r}')
        bridge_path = ROOT + 'Frameworks/App.framework/flutter_assets/assets/images/pptx_bridge.html'
        bridge = archive.read(bridge_path)
        if b'/* STUDY_RENDERER_SCRIPT */' in bridge or b'StudyPptx' not in bridge:
            raise ValueError('Offline PPTX renderer was not embedded')
        fixtures = {'study_large_120_pages.pdf', 'deck_complex.pptx',
                    'real_corpus_illinois.pptx', 'real_large_scan.pdf'}
        if any(name.rsplit('/', 1)[-1] in fixtures for name in names):
            raise ValueError('CI-only textbook fixture leaked into signed IPA')
        privacy = sorted(name[len(ROOT):] for name in names
                         if name.endswith('/PrivacyInfo.xcprivacy'))
        for name in privacy:
            if not isinstance(plistlib.loads(archive.read(ROOT + name)), dict):
                raise ValueError('Malformed bundled privacy manifest')
    digest = hashlib.sha256(ipa.read_bytes()).hexdigest()
    return {'bundle_id': BUNDLE_ID, 'display_name': 'Study', 'version': version,
            'build_number': build, 'minimum_ios': '15.0', 'sha256': digest,
            'ipa_bytes': ipa.stat().st_size,
            'privacy_manifests': privacy,
            'privacy_review': 'inventory only; declarations need owner review',
            'status': 'local package checks passed; Apple processing and device test pending'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for flag in ('ipa', 'profile', 'entitlements', 'export-options', 'output'):
        parser.add_argument(f'--{flag}', type=Path, required=True)
    for flag in ('version', 'build', 'team'):
        parser.add_argument(f'--{flag}', required=True)
    args = parser.parse_args()
    report = verify(args.ipa, args.version, args.build, args.team,
                    plistlib.loads(args.profile.read_bytes()),
                    plistlib.loads(args.entitlements.read_bytes()),
                    plistlib.loads(args.export_options.read_bytes()))
    args.output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))
