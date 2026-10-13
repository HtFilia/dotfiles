#!/usr/bin/env python3
"""Write host-specific guides from available tools and custom executable inventory."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('dotfiles_installer', ROOT / 'scripts/install-tools.py')
installer_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer_module)


def custom_registry(path):
    if not path.exists(): return []
    records = json.loads(path.read_text())
    if not isinstance(records, list): raise ValueError('Custom-tool registry must be a JSON array.')
    names = set()
    for record in records:
        if not isinstance(record, dict) or not re.fullmatch(r'[A-Za-z0-9_.+-]+', record.get('name', '')):
            raise ValueError('Custom tools need a simple executable name.')
        if record['name'] in names: raise ValueError('Duplicate custom-tool name: ' + record['name'])
        names.add(record['name'])
        for key in ('description', 'usage', 'path'):
            if key in record and not isinstance(record[key], str): raise ValueError(key + ' must be text.')
    return records


def inventory(catalog, registry, env):
    path = env.get('PATH', '')
    probe = installer_module.Installer.__new__(installer_module.Installer)
    probe.env, probe.pins = dict(env), {}
    records = {}
    reserved = set()
    for tool in catalog:
        reserved.update(tool['bins']); reserved.update(tool.get('aliases', [])); reserved.add(tool['name'])
        if not tool['bins']: continue
        candidates = [tool['name'], tool.get('probe_name', tool['name'])] + tool.get('aliases', [])
        actual = next((n for n in candidates if shutil.which(n, path=path)), None)
        if not actual: continue
        binary = shutil.which(actual, path=path)
        try:
            if tool.get('presence_only'): version = 'Executable present (not invoked)'
            else: version = probe.probe(tool, binary=binary)
        except installer_module.InstallError: continue
        usage = tool.get('usage', '')
        if actual != tool['name'] and usage.split(' ', 1)[0] == tool['name']:
            usage = actual + usage[len(tool['name']):] if actual in tool.get('aliases', []) else actual + ' --help'
        records[actual] = dict(name=actual, path=binary, description=tool['description'], usage=usage,
                               version=version, origin='catalog', validated=not tool.get('presence_only', False))
        for name in tool['bins']:
            if name == actual or not shutil.which(name, path=path): continue
            records.setdefault(name, dict(name=name, path=shutil.which(name, path=path),
                description=tool['description'] + ' companion executable', usage=name + ' --help',
                version='Executable present', origin='catalog companion', validated=False))
    home = Path(env.get('HOME', str(Path.home())))
    cargo = Path(env.get('CARGO_HOME', str(home / '.cargo'))) / 'bin'
    go = Path(env.get('GOBIN') or str(Path(env.get('GOPATH', str(home / 'go')).split(os.pathsep)[0]) / 'bin'))
    directories = [(cargo, 'Cargo bin'), (go, 'Go bin'), (home / '.local/bin', 'user-local bin')]
    for directory, origin in directories:
        if not directory.is_dir(): continue
        for binary in sorted(directory.iterdir()):
            if binary.name in reserved or binary.name in records: continue
            if not binary.is_file() or not os.access(binary, os.X_OK): continue
            # Inventory metadata only. Never execute an unknown binary to guess its role.
            active = shutil.which(binary.name, path=path)
            if active and Path(active).resolve() != binary.resolve(): continue
            records[binary.name] = dict(name=binary.name, path=active or str(binary),
                description='Custom executable; description not registered', usage='',
                version='Not probed', origin=origin, validated=False)
    for custom in registry:
        name = custom['name']
        binary = str(Path(custom['path']).expanduser()) if custom.get('path') else shutil.which(name, path=path)
        if not binary:
            binary = records.get(name, {}).get('path')
        if not binary or not Path(binary).is_file() or not os.access(binary, os.X_OK): continue
        records[name] = dict(name=name, path=binary, description=custom.get('description', 'Custom executable'),
            usage=custom.get('usage', ''), version='Not probed', origin='custom registry', validated=False)
    return sorted(records.values(), key=lambda r: r['name'])


def render(records):
    def cell(text): return str(text).replace('|', '\\|').replace('\n', ' ').replace('`', "'")
    lines = ['# Tools available on this host', '',
        'Generated from executable availability, not the installation wish list. Known catalog',
        'commands have read-only version probes where supported. Custom commands are discovered',
        'as executable files and are not invoked to guess their purpose. Check registered/project',
        'documentation before executing an unfamiliar command. Use bounded, non-interactive output;',
        'inspect project tasks and command effects before mutations. Recheck availability when needed.', '',
        '| Executable | Purpose | Usage / guidance | Origin |', '|---|---|---|---|']
    for r in records:
        usage = r['usage'] or 'Purpose/usage not registered; consult project documentation.'
        lines.append('| ' + ' | '.join(cell(x) for x in [r['name'],r['description'],usage,r['origin']]) + ' |')
    lines += ['', '## Executable paths', '']
    lines += [f"- {cell(r['name'])}: {cell(r['path'])}" for r in records]
    lines += ['', 'These additional guides can be referenced by the agent instructions in each project.',
              'Existing global/project instructions are not overwritten.', '']
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', type=Path, default=Path.home())
    parser.add_argument('--custom-tools', type=Path, help='registry path (remembered for later regenerations)')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    registry_reference = args.destination / '.local/state/dotfiles/custom-tool-registry'
    registry_path = args.custom_tools
    if registry_path is None:
        registry_path = Path(registry_reference.read_text().strip()) if registry_reference.exists() else Path.home() / '.config/dotfiles/custom-tools.json'
    try: registry = custom_registry(registry_path)
    except (ValueError, TypeError, json.JSONDecodeError) as error: parser.error(str(error))
    env = dict(os.environ)
    env['PATH'] = f"{os.environ.get('LOCAL_BIN', str(Path.home() / '.local/bin'))}:{Path.home()}/.cargo/bin:{Path.home()}/go/bin:" + env['PATH']
    records = inventory(installer_module.CATALOG, registry, env)
    if args.dry_run:
        print(render(records)); return 0
    content = render(records)
    if args.custom_tools:
        installer_module.atomic_text(registry_reference, str(args.custom_tools.resolve()) + '\n')
    for name in ('AGENTS.additional.md', 'CLAUDE.additional.md'):
        # Atomic replacement breaks any former Chezmoi source symlink instead of writing through it.
        installer_module.atomic_text(args.destination / name, content)
    installer_module.atomic_text(args.destination / '.local/state/dotfiles/tool-inventory.json', json.dumps(records, indent=2) + '\n')
    print(f'Generated agent guides for {len(records)} available executables in {args.destination}')
    return 0


if __name__ == '__main__': sys.exit(main())
