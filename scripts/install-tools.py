#!/usr/bin/env python3
"""Install each utility independently and record all native/GitHub/source attempts."""
import argparse
import fnmatch
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shlex
import shutil
import signal
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CATALOG = json.loads((ROOT / 'scripts/tool-catalog.json').read_text())


class InstallError(Exception):
    pass


def atomic_text(path, text):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, delete=False) as file:
        file.write(text)
        file.flush()
        os.fsync(file.fileno())
    os.replace(file.name, path)


def new_report_dir():
    base = Path.home() / '.local/state/dotfiles/install-reports'
    base.mkdir(parents=True, exist_ok=True)
    return Path(tempfile.mkdtemp(prefix=time.strftime('%Y%m%dT%H%M%S-'), dir=base))


class Report:
    def __init__(self, directory=None):
        self.directory = Path(directory or os.environ.get('DOTFILES_REPORT_DIR') or new_report_dir())
        self.directory.mkdir(parents=True, exist_ok=True)
        self.path = self.directory / 'report.json'
        self.data = json.loads(self.path.read_text()) if self.path.exists() else {
            'started_at': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
            'platform': platform.platform(), 'tools': []}

    def add(self, row):
        row.setdefault('required', row.get('tool') in ('git', 'chezmoi', 'apply-dotfiles'))
        self.data['tools'].append(row)
        atomic_text(self.path, json.dumps(self.data, indent=2) + '\n')
        self.render()

    def render(self):
        def cell(value):
            return str(value or '').replace('|', '\\|').replace('\n', '<br>')
        lines = ['# Dotfiles installation report', '', f"Started: {self.data['started_at']}", '',
                 '| Tool | Result | Method | Version observed | Reason / logs |', '|---|---|---|---|---|']
        for row in self.data['tools']:
            lines.append('| ' + ' | '.join(cell(row.get(k)) for k in
                ('tool', 'status', 'method', 'version', 'reason')) + ' |')
        lines += ['', '## Attempts', '']
        for row in self.data['tools']:
            lines.append(f"### {row['tool']}")
            for attempt in row.get('attempts', []):
                lines.append(f"- {attempt['method']}: {attempt['status']}; {attempt.get('detail', '')}; log: {attempt.get('log', '')}")
        atomic_text(self.directory / 'report.md', '\n'.join(lines) + '\n')


class Installer:
    def __init__(self, report, methods, skip_packages=False, timeout=1800, reinstall=False):
        self.report, self.methods, self.skip_packages, self.timeout = report, methods, skip_packages, timeout
        self.local_bin = Path(os.environ.get('LOCAL_BIN', str(Path.home() / '.local/bin')))
        self.env = dict(os.environ)
        self.env['PATH'] = f"{self.local_bin}:{Path.home()}/.cargo/bin:{Path.home()}/go/bin:" + self.env['PATH']
        # Bypass deployed global HTTPS->SSH rewrites before keys exist on a new host.
        self.env.update(GIT_CONFIG_GLOBAL='/dev/null', GIT_CONFIG_NOSYSTEM='1', GIT_TERMINAL_PROMPT='0')
        self.log, self.details, self.pins = None, [], {}
        self.reinstall = reinstall
        self.pending = []
        self.os = 'linux' if platform.system() == 'Linux' else 'darwin'
        self.arch = 'aarch64' if platform.machine() in ('aarch64', 'arm64') else 'x86_64'
        self.goarch = 'arm64' if self.arch == 'aarch64' else 'amd64'

    def run(self, argv, cwd=None, env=None, timeout=None):
        argv = [str(a) for a in argv]
        with self.log.open('a') as log:
            log.write('$ ' + shlex.join(argv) + '\n'); log.flush()
            try:
                with subprocess.Popen(argv, cwd=cwd, env=env or self.env, stdout=log,
                                      stderr=log, start_new_session=True) as proc:
                    try:
                        code = proc.wait(timeout=timeout or self.timeout)
                    except BaseException:
                        os.killpg(proc.pid, signal.SIGTERM)
                        try:
                            proc.wait(timeout=5)
                        except subprocess.TimeoutExpired:
                            os.killpg(proc.pid, signal.SIGKILL); proc.wait()
                        raise
            except subprocess.TimeoutExpired as error:
                raise InstallError(f'timed out after {error.timeout}s: {shlex.join(argv)}') from error
            except OSError as error:
                raise InstallError(str(error)) from error
        if code:
            raise InstallError(f'exit {code}: {self.log.read_text(errors="replace")[-1600:].strip()}')

    def capture(self, argv, timeout=30, env=None, exit_codes=(0,)):
        try:
            result = subprocess.run(argv, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                    timeout=timeout, env=env or self.env)
        except (OSError, subprocess.TimeoutExpired) as error:
            raise InstallError(str(error)) from error
        if result.returncode not in exit_codes:
            raise InstallError(f'exit {result.returncode}: {result.stdout[-1200:]}')
        return result.stdout.strip()

    def pin(self, tool):
        key = tool.get('asset')
        if not key:
            return {'version': tool.get('version', '')}
        if key not in self.pins:
            output = self.capture(['bash', '-c',
                'source "$1"; for field in version url file sha256 reported-version binary-sha256; do '
                'value=$(pinned_asset_field "$2" "$field") || continue; printf "%s\\t%s\\n" "$field" "$value"; done',
                '_', str(ROOT / 'scripts/pinned-assets.sh'), key])
            self.pins[key] = dict(line.split('\t', 1) for line in output.splitlines())
        return self.pins[key]

    def probe(self, tool, binary=None, exact=False):
        binary = binary or shutil.which(tool.get('probe_name', tool['name']), path=self.env['PATH'])
        if not binary:
            raise InstallError(f"executable not found: {tool['name']}")
        output = self.capture([str(binary)] + tool.get('probe', ['--version']), exit_codes=tool.get('probe_exit_codes', [0]))
        pin = self.pin(tool)
        expected = pin.get('reported-version', pin.get('version', '')).lstrip('v')
        if exact and expected and not re.search(r'(?<![\d.])' + re.escape(expected) + r'(?![\d.])', output):
            raise InstallError(f'expected {expected}; observed {output[:200]}')
        return next((line for line in output.splitlines() if re.search(r'\d+\.\d+', line)), output.splitlines()[0] if output else 'executable probe passed')[:240]

    def current(self, tool, exact=False):
        if tool.get('cask'):
            return self.capture(['brew', 'list', '--cask', '--versions', tool['brew']])
        if tool.get('presence_only'):
            for name in tool['bins']:
                if not shutil.which(name, path=self.env['PATH']): raise InstallError(f'executable missing: {name}')
            return 'all package executables available'
        version = self.probe(tool, exact=exact)
        for name in tool['bins'][1:]:
            binary = shutil.which(name, path=self.env['PATH'])
            if not binary:
                raise InstallError(f'companion executable missing: {name}')
            self.capture([binary, '--version'])
        return version

    def admin(self):
        return [] if os.geteuid() == 0 else ['sudo']

    def native(self, tool, stage):
        if self.os == 'darwin' and tool.get('brew'):
            if self.skip_packages:
                raise InstallError('Homebrew disabled by --skip-packages')
            kind = ['--cask'] if tool.get('cask') else ['--formula']
            try:
                self.capture(['brew', 'list'] + kind + ['--versions', tool['brew']])
                action = 'upgrade'
            except InstallError:
                action = 'install'
            self.run(['brew', action] + kind + [tool['brew']])
            if tool['name'] == 'rustup':
                try: self.capture(['rustup', 'show', 'active-toolchain'])
                except InstallError: self.run(['rustup-init', '-y', '--no-modify-path', '--default-toolchain', 'stable'])
        elif tool.get('pip'):
            prefix = self.permanent_prefix(tool['name'])
            self.run(['python3', '-m', 'venv', prefix])
            self.run([prefix / 'bin/python', '-m', 'pip', 'install', tool['pip'] + '==' + self.pin(tool)['version'].lstrip('v')])
            version = self.probe(tool, prefix / 'bin' / tool['name'], exact=True)
            for name in tool['bins']:
                self.capture([str(prefix / 'bin' / name), '--version'])
            for name in tool['bins']: self.link(prefix / 'bin' / name, name)
            self.pending.remove(prefix)
            return version
        elif tool.get('npm'):
            prefix = stage / 'prefix'
            self.run(['npm', 'install', '--global', '--prefix', prefix, tool['npm'] + '@' + tool['version']])
            self.publish_runtime(tool, prefix, exact=True)
        elif tool.get('runtime') in ('go', 'node'):
            metadata = self.pin(tool)
            try:
                archive = self.download(metadata, tool['asset'])
                self.extract(archive, stage)
                binary = self.match(stage, 'bin/' + tool['name'])
                managed = dict(tool, bins=tool['bins'])
                return self.publish_runtime(managed, binary.parent.parent, exact=True)
            except (InstallError, OSError) as error:
                self.details.append('official distribution failed: ' + str(error))
                if self.skip_packages or not tool.get('apt'): raise
                self.run(self.admin() + ['apt-get', 'install', '-y', '--no-install-recommends', tool['apt']])
                self.native_links(tool)
                return self.current(tool)
        elif tool.get('apt'):
            if self.skip_packages:
                if tool.get('crate'): return self.cargo_native(tool, stage)
                raise InstallError('APT disabled by --skip-packages')
            try:
                self.run(self.admin() + ['apt-get', 'install', '-y', '--no-install-recommends', tool['apt']])
            except InstallError as error:
                if not tool.get('crate'): raise
                self.details.append('APT failed: ' + str(error))
                return self.cargo_native(tool, stage)
            self.native_links(tool)
        elif tool.get('crate'):
            return self.cargo_native(tool, stage)
        else:
            raise InstallError('no supported native package recipe')
        return self.current(tool)

    def native_links(self, tool):
        # Prefer the executable just supplied by APT, not an old user binary that
        # still shadows /usr/bin. Replace the link itself, never its target.
        paths = '/usr/bin:/bin:/usr/sbin:/sbin'
        for name in tool['bins']:
            candidates = [name] + (tool.get('aliases', []) if name == tool['name'] else [])
            target = next((shutil.which(n, path=paths) for n in candidates if shutil.which(n, path=paths)), None)
            if target: self.link(Path(target), name)

    def cargo_native(self, tool, stage):
        version = self.pin(tool).get('version', '').lstrip('v')
        if not version: raise InstallError('no reviewed Cargo version')
        self.run(['cargo', 'install', '--locked', '--jobs', os.environ.get('DOTFILES_BUILD_JOBS', '2'), '--root', stage / 'prefix', '--version', version, tool['crate']])
        return self.publish_runtime(tool, stage / 'prefix', exact=True)

    def github_metadata(self, tool):
        if not tool.get('repo') or not tool.get('release_pattern'):
            raise InstallError('no compatible, verified official GitHub artifact recipe')
        request = urllib.request.Request(f'https://api.github.com/repos/{tool["repo"]}/releases/latest',
            headers={'User-Agent': 'dotfiles-bootstrap', 'Accept': 'application/vnd.github+json'})
        with urllib.request.urlopen(request, timeout=30) as response:
            release = json.load(response)
        pattern = tool['release_pattern'].format(os=self.os, arch=self.arch, goarch=self.goarch)
        matches = [a for a in release['assets'] if fnmatch.fnmatch(a['name'], pattern)]
        if len(matches) != 1:
            raise InstallError(f'expected one official asset matching {pattern}; found {len(matches)}')
        asset = matches[0]
        digest = asset.get('digest') or ''
        if not re.fullmatch(r'sha256:[a-f0-9]{64}', digest):
            raise InstallError('official release has no SHA256 digest; refusing unverified download')
        return dict(url=asset['browser_download_url'], file=asset['name'], sha256=digest[7:], version=release['tag_name'])

    def download(self, metadata, cache_key):
        cache = Path(os.environ.get('DOTFILES_DOWNLOAD_DIR', str(Path.home() / '.cache/dotfiles/downloads')))
        directory = cache / cache_key / metadata['version']
        directory.mkdir(parents=True, exist_ok=True)
        target = directory / metadata['file']
        def digest(path):
            with path.open('rb') as file:
                digest = hashlib.sha256()
                for chunk in iter(lambda: file.read(1024 * 1024), b''): digest.update(chunk)
                return digest.hexdigest()
        if not target.is_file() or digest(target) != metadata['sha256']:
            partial = directory / (metadata['file'] + '.part-' + str(os.getpid()))
            try:
                self.run(['curl', '--proto', '=https', '--tlsv1.2', '--fail', '--silent', '--show-error',
                    '--location', '--retry', '2', '--connect-timeout', '15', '--max-time',
                    os.environ.get('DOTFILES_DOWNLOAD_TIMEOUT', '180'), metadata['url'], '-o', partial])
                if digest(partial) != metadata['sha256']:
                    raise InstallError(f'SHA256 mismatch for {metadata["url"]}')
                os.replace(partial, target)
            finally:
                partial.unlink(missing_ok=True)
        self.details.append(f"{metadata['url']} SHA256={metadata['sha256']}")
        return target

    def extract(self, archive, destination):
        def safe(name):
            if not (destination / name).resolve().is_relative_to(destination.resolve()):
                raise InstallError(f'unsafe archive path: {name}')
        if zipfile.is_zipfile(archive):
            with zipfile.ZipFile(archive) as file:
                for member in file.infolist():
                    safe(member.filename)
                    if (member.external_attr >> 16) & 0o170000 == 0o120000:
                        raise InstallError('ZIP symlinks are unsupported')
            self.run(['unzip', '-oq', archive, '-d', destination])
        else:
            with tarfile.open(archive) as file:
                for member in file.getmembers():
                    safe(member.name)
                    if member.issym(): safe(str(Path(member.name).parent / member.linkname))
                    elif member.islnk(): safe(member.linkname)
                    elif not (member.isfile() or member.isdir()):
                        raise InstallError(f'unsupported archive member: {member.name}')
            self.run(['tar', '--no-same-owner', '-xf', archive, '-C', destination])

    def match(self, stage, name):
        matches = [p for p in stage.rglob(Path(name).name)
                   if p.is_file() and (name == p.name or p.as_posix().endswith('/' + name))]
        if len(matches) != 1:
            raise InstallError(f'expected one {name} in artifact/build; found {len(matches)}')
        return matches[0]

    def link(self, source, name):
        self.local_bin.mkdir(parents=True, exist_ok=True)
        temporary = self.local_bin / ('.' + name + '-' + str(os.getpid()))
        temporary.unlink(missing_ok=True); temporary.symlink_to(source)
        os.replace(temporary, self.local_bin / name)

    def permanent_prefix(self, name):
        base = Path.home() / '.local/opt/dotfiles'
        base.mkdir(parents=True, exist_ok=True)
        prefix = Path(tempfile.mkdtemp(prefix=name + '-', dir=base))
        self.pending.append(prefix)
        return prefix

    def cleanup_pending(self):
        for prefix in self.pending: shutil.rmtree(prefix, ignore_errors=True)
        self.pending.clear()

    def publish_runtime(self, tool, prefix, exact=False):
        candidate = prefix / 'bin' / tool['name']
        candidate.chmod(candidate.stat().st_mode | 0o111)
        version = self.probe(tool, candidate, exact=exact)
        for name in tool['bins']:
            if not (prefix / 'bin' / name).exists():
                raise InstallError(f'companion binary missing: {name}')
        base = Path.home() / '.local/opt/dotfiles'
        base.mkdir(parents=True, exist_ok=True)
        if prefix in self.pending:
            destination = prefix
        else:
            destination = Path(tempfile.mkdtemp(prefix=tool['name'] + '-', dir=base))
            shutil.copytree(prefix, destination, dirs_exist_ok=True, symlinks=True)
        for name in tool['bins']: self.link(destination / 'bin' / name, name)
        if destination in self.pending: self.pending.remove(destination)
        return version

    def publish_binaries(self, tool, candidates, exact=False):
        for path in candidates.values(): path.chmod(path.stat().st_mode | 0o111)
        version = self.probe(tool, candidates[tool['name']], exact=exact)
        for name, path in candidates.items():
            if name != tool['name']: self.capture([str(path), '--version'])
        self.local_bin.mkdir(parents=True, exist_ok=True)
        for name, path in candidates.items():
            with tempfile.NamedTemporaryFile(dir=self.local_bin, delete=False) as file:
                stage = Path(file.name)
            shutil.copyfile(path, stage); stage.chmod(0o755)
            os.replace(stage, self.local_bin / name)
        return version

    def github(self, tool, stage):
        metadata = self.pin(tool)
        if self.os != 'linux' or not metadata.get('url', '').startswith('https://github.com/'):
            metadata = self.github_metadata(tool)
        if not metadata['url'].startswith(f'https://github.com/{tool.get("repo")}/releases/download/'):
            raise InstallError('artifact URL is not in the official repository')
        archive = self.download(metadata, tool.get('asset', tool['name']) if self.os == 'linux' else tool['name'] + '-' + self.os)
        member = tool.get('member', tool['name'])
        if tool.get('release_binary') or member == '@binary':
            candidate = stage / tool['name']; shutil.copyfile(archive, candidate)
            return self.publish_binaries(tool, {tool['name']: candidate}, exact=bool(tool.get('asset')))
        self.extract(archive, stage)
        if member == '@tmux':
            directory = self.match(stage, 'configure').parent
            self.run(['./configure', '--prefix=' + str(stage / 'prefix')], cwd=directory)
            self.run(['make', '-j' + os.environ.get('DOTFILES_BUILD_JOBS', '2')], cwd=directory)
            return self.publish_binaries(tool, {'tmux': directory / 'tmux'}, exact=True)
        if tool.get('runtime'):
            binary = self.match(stage, 'bin/' + tool['name'])
            return self.publish_runtime(tool, binary.parent.parent, exact=True)
        return self.publish_binaries(tool, {n: self.match(stage, member if n == tool['name'] else n)
                                           for n in tool['bins']}, exact=True)

    def source(self, tool, stage):
        if not tool.get('repo') or not tool.get('build'):
            raise InstallError(tool.get('note', 'no supported official GitHub source build recipe'))
        ref = tool.get('ref')
        if not ref: raise InstallError('no reviewed source ref; refusing an unpinned default branch build')
        directory, prefix = stage / 'checkout', stage / 'prefix'
        self.run(['git', 'clone', '--depth', '1', '--branch', ref,
                  f'https://github.com/{tool["repo"]}.git', directory], timeout=180)
        commit = self.capture(['git', '-C', str(directory), 'rev-parse', 'HEAD'])
        self.details.append(f'https://github.com/{tool["repo"]}.git ref={ref} commit={commit}')
        kind, jobs, binaries = tool['build'], '-j' + os.environ.get('DOTFILES_BUILD_JOBS', '2'), {}
        if kind not in ('cargo', 'go', 'chezmoi', 'gh', 'go-runtime', 'jc'):
            # Configure embeds prefixes in binaries (Git, Python, Neovim, etc.).
            # Build at the permanent prefix and expose it only after verification.
            prefix = self.permanent_prefix(tool['name'])
        if kind == 'cargo':
            argv = ['cargo', 'build', '--release', '--locked', jobs]
            if tool.get('cargo_package'): argv += ['--package', tool['cargo_package']]
            for name in tool['bins']: argv += ['--bin', name]
            self.run(argv, cwd=directory, env=dict(self.env, CARGO_TARGET_DIR=str(directory / 'target')))
            binaries = {n: directory / 'target/release' / n for n in tool['bins']}
        elif kind in ('go', 'chezmoi', 'gh'):
            if kind == 'chezmoi':
                self.run(['make', 'build'], cwd=directory, env=dict(self.env, VERSION=self.pin(tool)['version']))
                binaries = {'chezmoi': directory / 'chezmoi'}
            elif kind == 'gh':
                self.run(['make', 'bin/gh'], cwd=directory); binaries = {'gh': directory / 'bin/gh'}
            else:
                out = stage / tool['name']
                version = (self.pin(tool).get('version') or ref).lstrip('v')
                ldflags = tool.get('ldflags', '-X main.version={version}').format(version=version)
                self.run(['go', 'build', '-ldflags', ldflags, '-o', out, tool.get('source_path', '.')], cwd=directory)
                binaries = {tool['name']: out}
        elif kind in ('neovim', 'fastfetch'):
            if kind == 'neovim':
                self.run(['make', jobs, 'CMAKE_BUILD_TYPE=Release', 'CMAKE_EXTRA_FLAGS=-DCMAKE_INSTALL_PREFIX=' + str(prefix)], cwd=directory)
                self.run(['cmake', '--install', 'build'], cwd=directory)
            else:
                self.run(['cmake', '-S', '.', '-B', 'build', '-DCMAKE_BUILD_TYPE=Release', '-DCMAKE_INSTALL_PREFIX=' + str(prefix)], cwd=directory)
                self.run(['cmake', '--build', 'build', '--parallel', jobs[2:]], cwd=directory)
                self.run(['cmake', '--install', 'build'], cwd=directory)
        elif kind == 'go-runtime':
            bootstrap = shutil.which('go', path=self.env['PATH'])
            if not bootstrap: raise InstallError('Go source build requires an existing compatible Go bootstrap compiler')
            goroot = self.capture([bootstrap, 'env', 'GOROOT'])
            self.run(['bash', 'make.bash'], cwd=directory / 'src', env=dict(self.env, GOROOT_BOOTSTRAP=goroot))
            prefix = directory; tool = dict(tool, bins=['go', 'gofmt'])
        elif kind == 'node-runtime':
            self.run(['./configure', '--prefix=' + str(prefix)], cwd=directory)
            self.run(['make', jobs], cwd=directory); self.run(['make', 'install'], cwd=directory)
        elif kind in ('autotools', 'tmux', 'jq'):
            if (directory / 'autogen.sh').exists(): self.run(['sh', 'autogen.sh'], cwd=directory)
            elif not (directory / 'configure').exists(): self.run(['autoreconf', '-fi'], cwd=directory)
            argv = ['./configure', '--prefix=' + str(prefix)]
            if kind == 'jq':
                self.run(['git', 'submodule', 'update', '--init', '--recursive'], cwd=directory)
                argv += ['--with-oniguruma=builtin']
            self.run(argv, cwd=directory); self.run(['make', jobs], cwd=directory)
            self.run(['make', 'install'], cwd=directory)
        elif kind in ('btop', 'git', 'make-install'):
            self.run(['make', jobs, 'PREFIX=' + str(prefix), 'prefix=' + str(prefix)], cwd=directory)
            self.run(['make', 'install', 'PREFIX=' + str(prefix), 'prefix=' + str(prefix)], cwd=directory)
        elif kind == 'bats': self.run(['bash', 'install.sh', prefix], cwd=directory)
        elif kind == 'stack': self.run(['stack', 'build', '--copy-bins', '--local-bin-path', prefix / 'bin'], cwd=directory)
        elif kind == 'jc':
            # venv scripts embed their path: create it directly at its permanent location.
            permanent = self.permanent_prefix('jc')
            self.run(['python3', '-m', 'venv', permanent], cwd=directory)
            self.run([permanent / 'bin/python', '-m', 'pip', 'install', directory], cwd=directory)
            version = self.probe(tool, permanent / 'bin/jc', exact=True)
            self.link(permanent / 'bin/jc', 'jc'); self.pending.remove(permanent); return version
        else: raise InstallError(f'unimplemented source recipe: {kind}')
        exact = bool(tool.get('asset') or tool.get('version'))
        if binaries: return self.publish_binaries(tool, binaries, exact=exact)
        return self.publish_runtime(tool, prefix, exact=exact)

    def install(self, tool):
        attempts = []
        try:
            if self.reinstall: raise InstallError('explicit reinstall requested')
            version = self.current(tool, exact=(self.os == 'linux' or bool(tool.get('npm'))) and bool(tool.get('asset') or tool.get('version')) and self.methods[0] != 'native')
            self.report.add(dict(tool=tool['name'], status='already-present', method='existing', version=version,
                reason='available before this run; original installation method unknown', attempts=[]))
            print(f"  = {tool['name']}: already present", flush=True); return True
        except InstallError: pass
        for method in self.methods:
            self.log = self.report.directory / (tool['name'] + '-' + method + '.log'); self.details = []
            print(f"  > {tool['name']}: {method}", flush=True)
            try:
                with tempfile.TemporaryDirectory(prefix='dotfiles-' + tool['name'] + '-') as temporary:
                    version = getattr(self, method)(tool, Path(temporary)); self.current(tool)
                attempts.append(dict(method=method, status='installed', detail='; '.join(self.details), log=str(self.log)))
                self.report.add(dict(tool=tool['name'], status='installed', method=method, version=version,
                    reason='; '.join(self.details), attempts=attempts)); return True
            except (InstallError, OSError, ValueError, KeyError, tarfile.TarError, zipfile.BadZipFile) as error:
                self.cleanup_pending()
                attempts.append(dict(method=method, status='failed', detail=str(error), log=str(self.log)))
                print(f"  ! {tool['name']}: {str(error).splitlines()[0][:180]}", file=sys.stderr, flush=True)
        try:
            version = self.current(tool); status, usable = 'retained', True
            reason = 'requested installation failed; existing executable retained'
        except InstallError:
            version, status, usable, reason = '', 'failed', False, 'all selected methods failed'
        self.report.add(dict(tool=tool['name'], status=status, method='existing' if usable else '', version=version,
            reason=reason, required=tool.get('required', False), attempts=attempts))
        return usable


def parse_methods(value):
    methods = value.split(',')
    if any(m not in ('native', 'github', 'source') for m in methods) or len(set(methods)) != len(methods):
        raise argparse.ArgumentTypeError('use an ordered comma-separated subset of native,github,source')
    return methods


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--methods', type=parse_methods, default=os.environ.get('DOTFILES_INSTALL_METHODS', 'github,native,source'))
    parser.add_argument('--reinstall', action='store_true', help='attempt selected methods even when a working version exists')
    parser.add_argument('--skip-packages', action='store_true'); parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--only', help='comma-separated tool names'); parser.add_argument('--group', choices=['extra'])
    parser.add_argument('--exclude', help='comma-separated tool names to skip'); parser.add_argument('--report-dir'); parser.add_argument('--new-report', action='store_true')
    parser.add_argument('--timeout', type=int, default=int(os.environ.get('DOTFILES_INSTALL_TIMEOUT', '1800')))
    parser.add_argument('--record', help='record an intentionally skipped component')
    parser.add_argument('--reason', default='disabled by option')
    parser.add_argument('--step', help='record isolated bootstrap component; command follows --')
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if args.timeout <= 0: parser.error('--timeout must be positive')
    if not (args.step or args.record or args.new_report):
        if platform.system() not in ('Linux', 'Darwin'):
            parser.error('workstation tools require Linux or macOS')
        if platform.system() == 'Linux' and platform.machine() != 'x86_64':
            parser.error('Linux tools currently support x86_64 only')
        if platform.system() == 'Darwin' and platform.machine() not in ('x86_64', 'arm64'):
            parser.error('unsupported macOS architecture')
    tools = CATALOG
    if args.only:
        names = args.only.split(','); unknown = set(names) - {t['name'] for t in CATALOG}
        if unknown: parser.error('unknown tools: ' + ','.join(sorted(unknown)))
        tools = [t for t in CATALOG if t['name'] in names]
    if args.exclude: tools = [t for t in tools if t['name'] not in args.exclude.split(',')]
    if args.group: tools = [t for t in tools if t.get('group') == args.group]
    if args.dry_run:
        for tool in tools:
            print(f"{tool['name']}: {','.join(args.methods)}; official repository={tool.get('repo') or 'unavailable'}; ref={tool.get('ref') or 'unavailable'}")
        return 0
    report = Report(args.report_dir)
    if args.new_report: print(report.directory); return 0
    if args.record:
        report.add(dict(tool=args.record, status='skipped', method='', reason=args.reason))
        return 0
    installer = Installer(report, args.methods, args.skip_packages, args.timeout, args.reinstall)
    if args.step:
        command = args.command[1:] if args.command[:1] == ['--'] else args.command
        if not command: parser.error('--step needs a command after --')
        installer.log = report.directory / (re.sub(r'[^a-zA-Z0-9_.-]', '_', args.step) + '.log')
        try:
            installer.run(command)
            report.add(dict(tool=args.step, status='completed', method='bootstrap', reason=shlex.join(command),
                attempts=[dict(method='bootstrap', status='completed', detail=shlex.join(command), log=str(installer.log))]))
            return 0
        except InstallError as error:
            report.add(dict(tool=args.step, status='failed', method='bootstrap', reason=str(error),
                attempts=[dict(method='bootstrap', status='failed', detail=str(error), log=str(installer.log))]))
            print(f'Warning: {args.step}: {error}', file=sys.stderr); return 1
    if args.command: parser.error('unexpected positional arguments')
    failed_required = False
    try:
        for tool in tools:
            if tool.get('platforms') and installer.os not in tool['platforms']: continue
            tool = dict(tool, required=tool['name'] in ('chezmoi', 'git'))
            if not installer.install(tool) and tool['required']: failed_required = True
    except KeyboardInterrupt:
        installer.cleanup_pending()
        report.add(dict(tool='installation', status='interrupted', reason='interrupted by user; completed results retained'))
        return 130
    print(f'Report: {report.directory / "report.md"}')
    return 1 if failed_required else 0


if __name__ == '__main__':
    sys.exit(main())
