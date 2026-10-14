#!/usr/bin/env python3
"""Offline installer behavior; no package operations or external downloads."""
import importlib.util
import itertools
import io
import queue
import threading
import time
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
        self.root = Path(temporary.name).resolve()  # macOS /var aliases /private/var
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

    def test_every_ordered_channel_policy_uses_only_its_permitted_attempts(self):
        for size in (1,2,3):
            for order in itertools.permutations(('native','github','source'),size):
                with self.subTest(order=order):
                    report=module.Report(self.root/('-'.join(order)))
                    engine=module.Installer(report,list(order),reinstall=True)
                    attempts=[]
                    def fail(method):
                        def attempt(*args):
                            attempts.append(method);raise module.InstallError(method+' unavailable')
                        return attempt
                    def github(*args):
                        attempts.append('github');self.executable(self.bin/'sample');return 'sample 1.0.0'
                    (self.bin/'sample').unlink(missing_ok=True)
                    with patch.object(engine,'native',fail('native')), patch.object(engine,'source',fail('source')), \
                         patch.object(engine,'github',github):
                        usable=engine.install(self.tool)
                    expected=list(order[:order.index('github')+1]) if 'github' in order else list(order)
                    self.assertEqual(attempts,expected)
                    self.assertEqual(usable,'github' in order)
                    self.assertEqual([r['method'] for r in report.data['tools'][0]['attempts']],expected)

    def test_optional_failure_does_not_prevent_next_tool(self):
        with patch.object(self.installer, 'native', side_effect=module.InstallError('no package')), \
             patch.object(self.installer, 'github', side_effect=module.InstallError('download blocked')), \
             patch.object(self.installer, 'source', side_effect=module.InstallError('compiler missing')):
            self.assertFalse(self.installer.install(self.tool))
        self.executable(self.bin / 'next')
        self.assertTrue(self.installer.install(dict(name='next', bins=['next'])))
        self.assertEqual([r['status'] for r in self.report.data['tools']], ['failed', 'already-present'])
        self.assertEqual(len(self.report.data['tools'][0]['attempts']), 3)

    def test_existing_version_is_kept_for_every_channel_order(self):
        existing=self.executable(self.bin/'sample','sample 0.5.0')
        before=existing.read_bytes()
        for size in (1,2,3):
            for order in itertools.permutations(('native','github','source'),size):
                with self.subTest(order=order):
                    engine=module.Installer(module.Report(self.root/('keep-'+'-'.join(order))),list(order))
                    with patch.object(engine,'native') as native, patch.object(engine,'github') as github, \
                         patch.object(engine,'source') as source:
                        self.assertTrue(engine.install(dict(self.tool,version='1.0.0')))
                    native.assert_not_called();github.assert_not_called();source.assert_not_called()
                    row=engine.report.data['tools'][0]
                    self.assertEqual(row['status'],'already-present');self.assertEqual(row['attempts'],[])
                    self.assertIn('0.5.0',row['version']);self.assertEqual(existing.read_bytes(),before)

    def test_all_present_cli_does_not_prepare_packages_or_request_sudo(self):
        binary=self.executable(self.bin/'sample','sample 0.5.0')
        before=binary.read_bytes()
        with patch.object(module,'CATALOG',[dict(self.tool,version='1.0.0')]), \
             patch.object(module.sys,'argv',['installer','--only','sample','--methods','github,native']), \
             patch.object(module.Installer,'prepare_native') as prepare:
            self.assertEqual(module.main(),0)
        prepare.assert_not_called();self.assertEqual(binary.read_bytes(),before)
        self.assertEqual([r['status'] for r in json.loads(self.report.path.read_text())['tools']],['already-present'])

    def test_native_preparation_receives_only_missing_tools(self):
        self.executable(self.bin/'present')
        present=dict(self.tool,name='present',bins=['present'])
        with patch.object(module,'CATALOG',[present,self.tool]), \
             patch.object(module.sys,'argv',['installer','--only','present,sample','--methods','native']), \
             patch.object(module.Installer,'prepare_native') as prepare, \
             patch.object(module.Installer,'install_missing',return_value=True) as install:
            self.assertEqual(module.main(),0)
        self.assertEqual([t['name'] for t in prepare.call_args.args[0]],['sample'])
        self.assertEqual(install.call_args.args[0]['name'],'sample');install.assert_called_once()

    def test_distribution_alias_is_recognized_without_package_installation(self):
        self.executable(self.bin/'sample-dist','sample 0.5.0')
        with patch.object(self.installer,'native') as native:
            self.assertTrue(self.installer.install(dict(self.tool,aliases=['sample-dist'])))
        native.assert_not_called()
        self.assertEqual(self.report.data['tools'][0]['status'],'already-present')
        self.assertFalse((self.bin/'sample').exists())

    def test_existing_go_is_kept_with_gofmt_help_probe(self):
        tool=next(t for t in module.CATALOG if t['name']=='go')
        self.executable(self.bin/'go','go version go1.20.0 linux/amd64')
        formatter=self.bin/'gofmt'
        formatter.write_text('#!/bin/sh\n[ "$1" = "-h" ] || exit 2\necho "usage: gofmt"\n')
        formatter.chmod(0o755)
        self.installer.methods=['github','native']
        with patch.object(self.installer,'github') as github, patch.object(self.installer,'native') as native:
            self.assertTrue(self.installer.install(tool))
        github.assert_not_called();native.assert_not_called()
        self.assertEqual(self.report.data['tools'][0]['status'],'already-present')
        self.assertIn('go1.20.0',self.report.data['tools'][0]['version'])

    def test_failed_upgrade_retains_existing_working_binary(self):
        self.executable(self.bin / 'sample', 'sample 0.5.0')
        self.installer.methods = ['github', 'source']
        self.installer.reinstall = True  # Exercise failed upgrades on both native platforms.
        tool = dict(self.tool, version='1.0.0')
        with patch.object(self.installer, 'github', side_effect=module.InstallError('blocked')) as github, \
             patch.object(self.installer, 'source', side_effect=module.InstallError('MSRV')) as source:
            self.assertTrue(self.installer.install(tool))
        github.assert_called_once(); source.assert_called_once()
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

    def test_non_root_native_authenticates_before_logged_packages(self):
        self.installer.os='linux';self.installer.skip_packages=False;commands=[]
        def package(argv, **kwargs):
            self.assertTrue(auth.called, 'Package commands started before terminal authentication')
            commands.append(argv)
        with patch.object(module.os,'geteuid',return_value=1000), \
             patch.object(module.sys.stdin,'isatty',return_value=True), \
             patch.object(module.shutil,'which',return_value='/usr/bin/sudo'), \
             patch.object(module.subprocess,'run',return_value=subprocess.CompletedProcess(['sudo','-v'],0)) as auth, \
             patch.object(self.installer,'run',side_effect=package):
            self.installer.prepare_native([self.tool])
        self.assertEqual(auth.call_args.args[0],['sudo','-v'])
        self.assertNotIn('stdin',auth.call_args.kwargs)
        self.assertNotIn('stdout',auth.call_args.kwargs)
        self.assertTrue(commands)
        self.assertTrue(all(argv[:2]==['sudo','-n'] for argv in commands))

    def test_denied_native_credentials_are_reported_before_github_fallback(self):
        self.installer.os='linux';self.installer.skip_packages=False;self.installer.methods=['native','github']
        with patch.object(module.os,'geteuid',return_value=1000), \
             patch.object(module.sys.stdin,'isatty',return_value=False), \
             patch.object(module.shutil,'which',return_value='/usr/bin/sudo'), \
             patch.object(self.installer,'run',side_effect=module.InstallError('sudo: a password is required')):
            self.installer.prepare_native([self.tool])
        def fallback(*args):
            self.executable(self.bin/'sample');return 'sample 1.0.0'
        with patch.object(self.installer,'github',side_effect=fallback):
            self.assertTrue(self.installer.install(dict(self.tool,apt='sample')))
        rows=self.report.data['tools']
        self.assertEqual(rows[0]['status'],'failed')
        self.assertIn('sudo -v',rows[0]['reason'])
        self.assertEqual(rows[1]['method'],'github')
        self.assertIn('password',rows[1]['attempts'][0]['detail'])

    def test_commands_keep_the_sudo_session_with_an_isolated_process_group(self):
        result=self.installer.capture([sys.executable,'-c',
            'import os,json;print(json.dumps([os.getsid(0),os.getpgrp(),os.getpid()]))'])
        session,group,pid=json.loads(result)
        self.assertEqual(session,os.getsid(0))
        self.assertEqual(group,pid)
        self.assertNotEqual(group,os.getpgrp())

    def test_logged_commands_cannot_wait_for_hidden_input(self):
        self.installer.run(['/bin/sh','-c','read answer || echo stdin-closed'],timeout=1)
        self.assertIn('stdin-closed',self.installer.log.read_text())

    def test_cleanup_permission_error_does_not_hide_timeout_or_leave_child_waiting(self):
        with patch.object(module.os,'killpg',side_effect=PermissionError('group denied')):
            started=time.monotonic()
            with self.assertRaisesRegex(module.InstallError,'timed out'):
                self.installer.run([sys.executable,'-c','import time; time.sleep(30)'],timeout=0.1)
        self.assertLess(time.monotonic()-started,5)
        self.assertIn('cannot signal process group',self.installer.log.read_text())

    def test_output_is_visible_while_a_command_is_still_running(self):
        proc=subprocess.Popen([sys.executable,str(ROOT/'scripts/install-tools.py'),'--timeout','2',
            '--step','progress','--','/bin/sh','-c','echo child-ready; sleep 30'],
            env=dict(os.environ),stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        self.addCleanup(lambda: proc.kill() if proc.poll() is None else None)
        lines=queue.Queue()
        def read():
            for line in proc.stdout: lines.put(line)
        reader=threading.Thread(target=read,daemon=True);reader.start()
        deadline=time.monotonic()+1.5
        while True:
            line=lines.get(timeout=max(0.01,deadline-time.monotonic()))
            if 'child-ready'==line.strip(): break
            self.assertLess(time.monotonic(),deadline)
        self.assertIsNone(proc.poll())
        proc.wait(timeout=5);reader.join(timeout=1)
        self.assertEqual(proc.returncode,1)
        self.assertIn('timed out',json.loads(self.report.path.read_text())['tools'][0]['reason'])
        proc.stdout.close();proc.stderr.close()

    def test_cancellation_saves_report_and_stops_a_waiting_step(self):
        ready=self.root/'ready'
        proc=subprocess.Popen([sys.executable,str(ROOT/'scripts/install-tools.py'),
            '--step','cancel','--','/bin/sh','-c',f'touch "{ready}"; sleep 30'],
            env=dict(os.environ),stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        self.addCleanup(lambda: proc.kill() if proc.poll() is None else None)
        deadline=time.monotonic()+3
        while not ready.exists():
            self.assertIsNone(proc.poll());self.assertLess(time.monotonic(),deadline);time.sleep(0.02)
        proc.send_signal(signal.SIGTERM);proc.communicate(timeout=5)
        self.assertEqual(proc.returncode,130)
        self.assertEqual(json.loads(self.report.path.read_text())['tools'][0]['status'],'interrupted')

    def test_reports_append_across_child_invocations(self):
        self.assertEqual(self.cli('--step', 'one', '--', '/bin/sh', '-c', 'exit 0').returncode, 0)
        self.assertEqual(self.cli('--step', 'two', '--', '/bin/sh', '-c', 'exit 1').returncode, 1)
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
        result = self.cli('--record', 'docker', '--reason', 'not selected')
        self.assertEqual(result.returncode, 0)
        row = json.loads(self.report.path.read_text())['tools'][0]
        self.assertEqual(row['status'], 'skipped'); self.assertIn('not selected', row['reason'])

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
