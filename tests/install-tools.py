#!/usr/bin/env python3
"""Offline installer behavior; no package operations or external downloads."""
import importlib.util
import io
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('installer', ROOT / 'scripts/install-tools.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class InstallerBehavior(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='dotfiles-installer-test-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.home = self.root / 'home'; self.home.mkdir()
        self.bin = self.home / '.local/bin'; self.bin.mkdir(parents=True)
        env = dict(HOME=str(self.home), LOCAL_BIN=str(self.bin), PATH='/usr/bin:/bin',
                   DOTFILES_REPORT_DIR=str(self.root / 'report'))
        self.env_patch = patch.dict(os.environ, env)
        self.env_patch.start(); self.addCleanup(self.env_patch.stop)
        self.report = module.Report()
        self.installer = module.Installer(self.report, ['native', 'github', 'source'], skip_packages=True)
        self.installer.log = self.report.directory / 'test.log'
        self.tool = dict(name='sample', bins=['sample'], repo='example/sample', ref='v1', build='go')

    def executable(self, path, output='sample 1.0.0', code=0):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text('#!/bin/sh\nprintf "%s\\n" ' + repr(output) + '\nexit ' + str(code) + '\n')
        path.chmod(0o755)
        return path

    def cli(self, *args):
        return subprocess.run([sys.executable, str(ROOT / 'scripts/install-tools.py'), *args],
                              capture_output=True, text=True, env=dict(os.environ), timeout=15)

    def test_fallback_order_and_failed_attempts_are_preserved(self):
        order = []
        def native(*args): order.append('native'); raise module.InstallError('package unavailable')
        def github(*args):
            order.append('github'); self.executable(self.bin / 'sample'); return 'sample 1.0.0'
        with patch.object(self.installer, 'native', native), patch.object(self.installer, 'github', github):
            self.assertTrue(self.installer.install(self.tool))
        self.assertEqual(order, ['native', 'github'])
        row = json.loads(self.report.path.read_text())['tools'][0]
        self.assertEqual(row['status'], 'installed'); self.assertEqual(row['method'], 'github')
        self.assertIn('package unavailable', row['attempts'][0]['detail'])
        self.assertEqual(row['attempts'][1]['status'], 'installed')

    def test_optional_failure_does_not_prevent_next_tool(self):
        with patch.object(self.installer, 'native', side_effect=module.InstallError('no package')), \
             patch.object(self.installer, 'github', side_effect=module.InstallError('download blocked')), \
             patch.object(self.installer, 'source', side_effect=module.InstallError('compiler missing')):
            self.assertFalse(self.installer.install(self.tool))
        self.executable(self.bin / 'next')
        self.assertTrue(self.installer.install(dict(name='next', bins=['next'])))
        self.assertEqual([r['status'] for r in self.report.data['tools']], ['failed', 'already-present'])
        self.assertEqual(len(self.report.data['tools'][0]['attempts']), 3)

    def test_failed_upgrade_retains_existing_working_binary(self):
        self.executable(self.bin / 'sample', 'sample 0.5.0')
        self.installer.methods = ['github', 'source']
        tool = dict(self.tool, version='1.0.0')
        with patch.object(self.installer, 'github', side_effect=module.InstallError('blocked')), \
             patch.object(self.installer, 'source', side_effect=module.InstallError('MSRV')):
            self.assertTrue(self.installer.install(tool))
        self.assertEqual(self.report.data['tools'][0]['status'], 'retained')
        self.assertIn('0.5.0', self.installer.current(tool))

    def test_required_missing_is_nonzero_but_report_survives(self):
        result = self.cli('--only', 'chezmoi', '--methods', 'native', '--skip-packages')
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        row = json.loads(self.report.path.read_text())['tools'][0]
        self.assertEqual(row['status'], 'failed'); self.assertTrue(row['required'])
        self.assertIn('disabled', row['attempts'][0]['detail'])

    def test_missing_optional_cli_exits_zero(self):
        result = self.cli('--only', 'wget', '--methods', 'source', '--reinstall')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(json.loads(self.report.path.read_text())['tools'][0]['status'], ('failed', 'retained'))

    def test_skip_packages_never_invokes_admin(self):
        self.installer.log = self.report.directory / 'native.log'
        with patch.object(self.installer, 'run') as run:
            with self.assertRaises(module.InstallError):
                self.installer.native(dict(self.tool, apt='package'), self.root)
        run.assert_not_called()

    def test_dry_run_does_not_create_report_or_destination(self):
        result = self.cli('--only', 'fd,rg', '--dry-run', '--methods', 'github,source')
        self.assertEqual(result.returncode, 0); self.assertFalse(self.report.path.exists())
        self.assertEqual(list(self.bin.iterdir()), [])

    def test_invalid_cli_is_rejected_before_any_report_write(self):
        for args in [('--methods', 'source,source'), ('--methods', 'latest'), ('--only', 'not-a-tool')]:
            result = self.cli(*args)
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
            self.assertFalse(self.report.path.exists())

    def test_wrong_version_does_not_replace_existing_symlink(self):
        system = self.executable(self.root / 'system/sample', 'sample 0.5.0')
        (self.bin / 'sample').symlink_to(system)
        replacement = self.executable(self.root / 'build/sample', 'sample 0.9.0')
        with self.assertRaises(module.InstallError):
            self.installer.publish_binaries(dict(self.tool, version='1.0.0'), {'sample': replacement}, exact=True)
        self.assertEqual((self.bin / 'sample').resolve(), system)
        self.assertIn('0.5.0', system.read_text())

    def test_successful_replacement_never_writes_through_system_link(self):
        system = self.executable(self.root / 'system/sample', 'sample 0.5.0')
        before = system.read_bytes(); (self.bin / 'sample').symlink_to(system)
        replacement = self.executable(self.root / 'build/sample')
        self.installer.publish_binaries(self.tool, {'sample': replacement})
        self.assertEqual(system.read_bytes(), before); self.assertFalse((self.bin / 'sample').is_symlink())
        self.assertIn('1.0.0', self.installer.current(self.tool))

    def test_missing_companion_does_not_publish_runtime(self):
        prefix = self.root / 'stage'
        self.executable(prefix / 'bin/sample')
        with self.assertRaises(module.InstallError):
            self.installer.publish_runtime(dict(self.tool, bins=['sample', 'helper']), prefix)
        self.assertFalse((self.bin / 'sample').exists())

    def test_runtime_retains_relative_companion_links(self):
        prefix = self.root / 'stage'
        self.executable(prefix / 'bin/sample')
        (prefix / 'lib').mkdir(); self.executable(prefix / 'lib/helper')
        (prefix / 'bin/helper').symlink_to('../lib/helper')
        self.installer.publish_runtime(dict(self.tool, bins=['sample', 'helper']), prefix)
        self.assertTrue((self.bin / 'sample').exists()); self.assertTrue((self.bin / 'helper').exists())
        self.assertEqual(os.readlink((self.bin / 'helper').resolve().parent.parent / 'bin/helper'), '../lib/helper')

    def test_existing_tool_origin_is_not_invented(self):
        self.executable(self.bin / 'sample')
        self.assertTrue(self.installer.install(self.tool))
        row = self.report.data['tools'][0]
        self.assertEqual(row['method'], 'existing'); self.assertIn('unknown', row['reason'])

    def test_archive_escape_rejected_without_extracting(self):
        archive = self.root / 'unsafe.tar.gz'
        with tarfile.open(archive, 'w:gz') as file:
            info = tarfile.TarInfo('../outside'); info.size = 4; file.addfile(info, io.BytesIO(b'evil'))
        stage = self.root / 'stage'; stage.mkdir()
        with patch.object(self.installer, 'run') as run:
            with self.assertRaises(module.InstallError): self.installer.extract(archive, stage)
        run.assert_not_called(); self.assertFalse((self.root / 'outside').exists())

    def test_archive_symlink_escape_rejected(self):
        archive = self.root / 'unsafe.tar.gz'
        with tarfile.open(archive, 'w:gz') as file:
            info = tarfile.TarInfo('link'); info.type = tarfile.SYMTYPE; info.linkname = '/tmp/outside'; file.addfile(info)
        stage = self.root / 'stage'; stage.mkdir()
        with self.assertRaises(module.InstallError): self.installer.extract(archive, stage)

    def test_zip_escape_rejected(self):
        archive = self.root / 'unsafe.zip'
        with zipfile.ZipFile(archive, 'w') as file: file.writestr('../../outside', 'evil')
        stage = self.root / 'stage'; stage.mkdir()
        with self.assertRaises(module.InstallError): self.installer.extract(archive, stage)

    def test_corrupt_cache_does_not_get_installed(self):
        metadata = dict(file='binary', version='1', sha256='0' * 64, url='https://github.com/example/sample/releases/download/v1/binary')
        def download(argv, **kwargs): Path(argv[-1]).write_text('bad content')
        with patch.object(self.installer, 'run', download):
            with self.assertRaisesRegex(module.InstallError, 'SHA256'):
                self.installer.download(metadata, 'sample')
        self.assertEqual(list(self.bin.iterdir()), [])
        self.assertFalse(any((self.home / '.cache').rglob('*.part-*')))

    def test_source_uses_official_https_ref_and_records_commit(self):
        commands = []
        def run(argv, **kwargs):
            commands.append([str(x) for x in argv])
            if argv[:2] == ['git', 'clone']: Path(argv[-1]).mkdir(parents=True)
            if argv[:2] == ['go', 'build']: self.executable(Path(argv[argv.index('-o') + 1]))
        with patch.object(self.installer, 'run', run), patch.object(self.installer, 'capture', return_value='a' * 40):
            self.installer.source(self.tool, self.root / 'stage')
        self.assertIn('https://github.com/example/sample.git', commands[0])
        self.assertEqual(commands[0][commands[0].index('--branch') + 1], 'v1')
        self.assertEqual(self.installer.env['GIT_CONFIG_GLOBAL'], '/dev/null')
        self.assertIn('commit=' + 'a' * 40, self.installer.details[0])
        self.assertFalse(any('sudo' in c for c in commands))

    def test_no_source_ref_never_clones_default_branch(self):
        tool = dict(self.tool); del tool['ref']
        with patch.object(self.installer, 'run') as run:
            with self.assertRaisesRegex(module.InstallError, 'ref'): self.installer.source(tool, self.root)
        run.assert_not_called()

    def test_step_failure_is_reported(self):
        result = self.cli('--step', 'optional-plugin', '--', '/bin/sh', '-c', 'echo build-failed >&2; exit 7')
        self.assertEqual(result.returncode, 1)
        row = json.loads(self.report.path.read_text())['tools'][0]
        self.assertIn('build-failed', row['reason']); self.assertTrue((self.report.directory / 'optional-plugin.log').exists())

    def test_timeout_stops_descendant_group(self):
        script = self.root / 'waiting.sh'
        script.write_text('#!/bin/sh\nsleep 30 &\necho $! >"$1"\nwait\n'); script.chmod(0o755)
        pid_file = self.root / 'child.pid'
        result = self.cli('--timeout', '1', '--step', 'timeout', '--', str(script), str(pid_file))
        self.assertEqual(result.returncode, 1); self.assertIn('timed out', result.stderr)
        pid = int(pid_file.read_text())
        status = Path(f'/proc/{pid}/stat')
        if status.exists(): self.assertEqual(status.read_text().split()[2], 'Z')

    def test_reports_append_across_child_invocations(self):
        self.assertEqual(self.cli('--step', 'one', '--', '/bin/true').returncode, 0)
        self.assertEqual(self.cli('--step', 'two', '--', '/bin/false').returncode, 1)
        rows = json.loads(self.report.path.read_text())['tools']
        self.assertEqual([r['tool'] for r in rows], ['one', 'two'])
        self.assertIn('one', (self.report.directory / 'report.md').read_text())

    def test_reinstall_attempts_methods_for_an_existing_tool(self):
        self.executable(self.bin / 'sample')
        self.installer.reinstall = True
        with patch.object(self.installer, 'native', return_value='sample 1.0.0') as native:
            self.assertTrue(self.installer.install(self.tool))
        native.assert_called_once()
        self.assertEqual(self.report.data['tools'][0]['status'], 'installed')

    def test_failed_build_removes_unpublished_permanent_prefix(self):
        self.installer.methods = ['source']
        prefixes = []
        def fail(*args):
            prefixes.append(self.installer.permanent_prefix('failed'))
            raise module.InstallError('compiler failed')
        with patch.object(self.installer, 'source', fail):
            self.assertFalse(self.installer.install(self.tool))
        self.assertFalse(prefixes[0].exists())

    def test_permanent_source_prefix_is_not_relocated(self):
        prefix = self.installer.permanent_prefix('sample')
        self.executable(prefix / 'bin/sample')
        self.installer.publish_runtime(self.tool, prefix)
        self.assertEqual((self.bin / 'sample').resolve(), prefix / 'bin/sample')
        self.installer.cleanup_pending()
        self.assertTrue((self.bin / 'sample').exists())

    def test_skipped_component_is_explicitly_reported(self):
        result = self.cli('--record', 'docker', '--reason', 'disabled by --skip-docker')
        self.assertEqual(result.returncode, 0)
        row = json.loads(self.report.path.read_text())['tools'][0]
        self.assertEqual(row['status'], 'skipped'); self.assertIn('--skip-docker', row['reason'])

    def test_catalog_covers_brewfile_and_linux_extras(self):
        import re
        packages = set(re.findall(r'^(?:brew|cask) "([^"]+)"', (ROOT / 'Brewfile').read_text(), re.M))
        self.assertFalse(packages - {t.get('brew') for t in module.CATALOG})
        extras = {line.split('\t')[0] for line in (ROOT / 'scripts/extra-tools.tsv').read_text().splitlines() if not line.startswith('#')}
        self.assertFalse(extras - {t['name'] for t in module.CATALOG})
        self.assertEqual(len({t['name'] for t in module.CATALOG}), len(module.CATALOG))

    def test_agent_guides_are_host_generated_not_static_source_files(self):
        for name in ('AGENTS.additional.md', 'CLAUDE.additional.md'):
            self.assertFalse((ROOT / 'home' / name).exists())
            self.assertIn('generated', (ROOT / name).read_text())



if __name__ == '__main__': unittest.main(verbosity=2)
