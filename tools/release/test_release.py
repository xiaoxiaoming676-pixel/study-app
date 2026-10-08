"""Release guards: reject wrong builds before any Apple publishing step."""
import copy
import datetime
import json
import os
import plistlib
import shutil
import struct
import tempfile
import unittest
import zipfile
from pathlib import Path

from prepare_ios import BUNDLE_ID, prepare
from verify_ci import REPOSITORY, validate
from verify_ipa import ROOT, verify

REPO = Path(__file__).resolve().parents[2]


class CIGateTest(unittest.TestCase):
    def setUp(self):
        self.sha = 'a' * 40
        self.path = '.github/workflows/study-ios.yml'
        self.run = dict(repository={'full_name': REPOSITORY}, head_sha=self.sha,
                        path=self.path, status='completed', conclusion='success')

    def test_green_exact_commit(self):
        validate(self.run, self.sha, self.path)

    def test_rejects_other_repo_commit_workflow_or_incomplete_run(self):
        for change in ({'repository': {'full_name': 'other/study-app'}},
                       {'head_sha': 'b' * 40}, {'path': 'different.yml'},
                       {'status': 'in_progress'}, {'conclusion': 'failure'},
                       {'conclusion': 'cancelled'}, {'conclusion': None}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                validate(self.run | change, self.sha, self.path)


class PrepareTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / 'ios/Runner.xcodeproj/project.pbxproj'
        self.project.parent.mkdir(parents=True)
        self.project.write_text(('PRODUCT_BUNDLE_IDENTIFIER = com.adilhanney.saber;\n'
                                 'INFOPLIST_KEY_CFBundleDisplayName = Saber;\n'
                                 'DEVELOPMENT_TEAM = OLDTEAM123;\n'
                                 'IPHONEOS_DEPLOYMENT_TARGET = 15.0;\n') * 3)
        runner = self.root / 'ios/Runner'
        (runner / 'Base.lproj').mkdir(parents=True)
        for name in ('Main', 'LaunchScreen'):
            (runner / f'Base.lproj/{name}.storyboard').write_text('<document/>')
        self.plist = runner / 'Info.plist'
        self.plist.write_bytes(plistlib.dumps({
            'CFBundleIdentifier': '$(PRODUCT_BUNDLE_IDENTIFIER)',
            'CFBundleShortVersionString': '$(FLUTTER_BUILD_NAME)',
            'CFBundleVersion': '$(FLUTTER_BUILD_NUMBER)',
            'UILaunchStoryboardName': 'LaunchScreen', 'UIMainStoryboardFile': 'Main'}))
        icons = runner / 'Assets.xcassets/AppIcon.appiconset'
        icons.mkdir(parents=True)
        self.icon = icons / 'icon.png'
        # Only header is relevant to the preflight dimension/color-type guard.
        self.icon.write_bytes(b'\x89PNG\r\n\x1a\n' + struct.pack('>I', 13) +
                              b'IHDR' + struct.pack('>II', 1024, 1024) + b'\x08\x02')
        (icons / 'Contents.json').write_text(json.dumps({'images': [
            {'filename': 'icon.png', 'size': '1024x1024', 'scale': '1x'}]}))

    def test_identity_idempotence_and_fixture_removal(self):
        fixture = self.root / 'assets/images/real_large_scan.pdf'
        fixture.parent.mkdir(parents=True)
        fixture.write_bytes(b'ci only')
        report = prepare(self.root)
        self.assertEqual(report['bundle_id'], BUNDLE_ID)
        self.assertNotIn('DEVELOPMENT_TEAM', self.project.read_text())
        self.assertNotIn('Saber', self.project.read_text())
        self.assertFalse(fixture.exists())
        after = self.project.read_bytes(), self.plist.read_bytes()
        prepare(self.root)
        self.assertEqual(after, (self.project.read_bytes(), self.plist.read_bytes()))

    def test_bad_icon_leaves_original_project_and_plist_untouched(self):
        before = self.project.read_bytes(), self.plist.read_bytes()
        self.icon.write_bytes(b'broken')
        with self.assertRaises(ValueError):
            prepare(self.root)
        self.assertEqual(before, (self.project.read_bytes(), self.plist.read_bytes()))

    def test_missing_launch_resource(self):
        (self.root / 'ios/Runner/Base.lproj/LaunchScreen.storyboard').unlink()
        with self.assertRaises(ValueError):
            prepare(self.root)

    def test_unreviewed_entitlements(self):
        self.project.write_text(self.project.read_text() + 'CODE_SIGN_ENTITLEMENTS = new.plist;')
        with self.assertRaises(ValueError):
            prepare(self.root)

    def test_foreign_identity(self):
        self.project.write_text(self.project.read_text().replace('com.adilhanney.saber', 'org.other.app'))
        with self.assertRaises(ValueError):
            prepare(self.root)

    @unittest.skipUnless(os.environ.get('STUDY_UPSTREAM_IOS'), 'Set STUDY_UPSTREAM_IOS for pinned-source audit')
    def test_actual_pinned_ios_copy(self):
        actual = self.root / 'actual'
        shutil.copytree(os.environ['STUDY_UPSTREAM_IOS'], actual / 'ios')
        result = prepare(actual)
        self.assertEqual(result['icons_checked'], 48)
        self.assertEqual(prepare(actual), result)
        self.assertNotIn('3DB8QX4Z23', (actual / 'ios/Runner.xcodeproj/project.pbxproj').read_text())


class IPAGateTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.ipa = Path(self.temp.name) / 'Study.ipa'
        self.team = 'ABCDEFGHIJ'
        self.signed = {'application-identifier': f'{self.team}.{BUNDLE_ID}',
                       'com.apple.developer.team-identifier': self.team,
                       'get-task-allow': False}
        self.profile = {'TeamIdentifier': [self.team],
                        'ApplicationIdentifierPrefix': [self.team],
                        'ExpirationDate': datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=30),
                        'Entitlements': copy.deepcopy(self.signed)}
        self.export = {'method': 'app-store-connect', 'teamID': self.team}
        self.info = {'CFBundleIdentifier': BUNDLE_ID, 'CFBundleDisplayName': 'Study',
                     'CFBundleShortVersionString': '0.9.0', 'CFBundleVersion': '7',
                     'MinimumOSVersion': '15.0', 'CFBundleSupportedPlatforms': ['iPhoneOS']}

    def package(self, bridge=b'<script>var StudyPptx={};</script>', fixture=False, missing=None):
        files = {'Info.plist': plistlib.dumps(self.info), 'embedded.mobileprovision': b'fixture',
                 '_CodeSignature/CodeResources': b'fixture', 'Runner': b'fixture',
                 'Frameworks/App.framework/flutter_assets/assets/images/pptx_bridge.html': bridge,
                 'Frameworks/example.framework/PrivacyInfo.xcprivacy': plistlib.dumps({})}
        if missing:
            files.pop(missing)
        if fixture:
            files['Frameworks/App.framework/flutter_assets/assets/images/real_large_scan.pdf'] = b'fixture'
        with zipfile.ZipFile(self.ipa, 'w') as archive:
            for name, value in files.items():
                archive.writestr(ROOT + name, value)

    def check(self):
        return verify(self.ipa, '0.9.0', '7', self.team, self.profile, self.signed, self.export)

    def test_valid_metadata_is_not_reported_as_device_pass(self):
        self.package()
        result = self.check()
        self.assertIn('pending', result['status'])
        self.assertEqual(len(result['sha256']), 64)
        self.assertEqual(len(result['privacy_manifests']), 1)

    def test_rejects_wrong_version_build_platform_bundle(self):
        for key, value in [('CFBundleIdentifier', 'com.adilhanney.saber'),
                           ('CFBundleVersion', '6'), ('CFBundleShortVersionString', '1.36.1'),
                           ('CFBundleSupportedPlatforms', ['iPhoneSimulator']),
                           ('MinimumOSVersion', '16.0')]:
            original = self.info[key]
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.info[key] = value
                self.package()
                self.check()
            self.info[key] = original

    def test_rejects_development_and_enterprise_profiles(self):
        self.package()
        for change in ({'ProvisionedDevices': []}, {'ProvisionedDevices': ['device']},
                       {'ProvisionsAllDevices': True}, {'TeamIdentifier': ['OTHERTEAM1']},
                       {'ExpirationDate': datetime.datetime(2000, 1, 1)}):
            original = self.profile
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.profile = original | change
                self.check()
            self.profile = original

    def test_rejects_debuggable_or_wrong_signature(self):
        self.package()
        for key, value in [('get-task-allow', True), ('application-identifier', 'OTHER.app'),
                           ('com.apple.developer.team-identifier', 'OTHERTEAM1')]:
            original = self.signed[key]
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.signed[key] = value
                self.check()
            self.signed[key] = original

    def test_legacy_app_prefix_can_differ_from_team(self):
        self.package()
        self.profile['ApplicationIdentifierPrefix'] = ['LEGACY1234']
        self.profile['Entitlements']['application-identifier'] = f'LEGACY1234.{BUNDLE_ID}'
        self.signed['application-identifier'] = f'LEGACY1234.{BUNDLE_ID}'
        self.check()

    def test_rejects_wrong_export(self):
        self.package()
        self.export['method'] = 'ad-hoc'
        with self.assertRaises(ValueError):
            self.check()

    def test_rejects_missing_offline_renderer(self):
        self.package(bridge=b'/* STUDY_RENDERER_SCRIPT */ StudyPptx')
        with self.assertRaises(ValueError):
            self.check()

    def test_rejects_test_textbook_in_distribution(self):
        self.package(fixture=True)
        with self.assertRaises(ValueError):
            self.check()

    def test_rejects_unsigned_application(self):
        self.package(missing='_CodeSignature/CodeResources')
        with self.assertRaises(ValueError):
            self.check()


class TemplateTest(unittest.TestCase):
    def test_dormant_template_has_gate_before_publish_and_pinned_tools(self):
        import yaml
        doc = yaml.safe_load((REPO / 'codemagic.template.yaml').read_text(encoding='utf-8-sig'))
        workflow = doc['workflows']['study-testflight']
        self.assertEqual([p for p in workflow['artifacts'] if p.endswith('.ipa')],
                         ['release-evidence/Study-RC.ipa'])
        self.assertNotIn('triggering', workflow)
        self.assertFalse((REPO / 'codemagic.yaml').exists())
        self.assertEqual(workflow['environment']['flutter'], '3.47.4')
        self.assertEqual(workflow['environment']['xcode'], '26.6')
        self.assertIn('checkout_rc.sh', workflow['scripts'][0]['script'])
        self.assertIn('check_signed.sh', workflow['scripts'][-1]['script'])
        self.assertFalse(workflow['publishing']['app_store_connect']['submit_to_app_store'])
        self.assertTrue(workflow['publishing']['app_store_connect']['submit_to_testflight'])
        for item in workflow['scripts']:
            if item['script'].startswith('bash '):
                self.assertTrue((REPO / item['script'].strip()[5:]).is_file())


if __name__ == '__main__':
    unittest.main()
