#!/usr/bin/env python3
"""Dependency-free tool picker; stdout contains only the resolved selection."""
import argparse
import json
import os
from pathlib import Path
import platform
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = json.loads((ROOT / 'scripts/tool-catalog.json').read_text())
REQUIRED = {'git', 'curl', 'python3', 'chezmoi'}
CATEGORIES = ['required', 'recommended', 'project', 'comfort', 'specialist', 'visual']


def platform_tools():
    system = 'darwin' if platform.system() == 'Darwin' else 'linux'
    tools = [t for t in CATALOG if not t.get('platforms') or system in t['platforms']]
    if system == 'darwin':
        packages = set(re.findall(r'^(?:brew|cask) "([^"]+)"', (ROOT / 'Brewfile').read_text(), re.M))
        tools = [t for t in tools if t.get('brew') in packages]
    return tools


def resolve(value, tools):
    allowed = {t['name'] for t in tools}
    if value == 'recommended':
        wanted = {t['name'] for t in tools if t['category'] in ('required', 'recommended')}
    elif value == 'all':
        wanted = allowed
    elif value == 'none':
        wanted = set()
    else:
        wanted = {n.strip() for n in value.split(',')}
        if wanted - allowed:
            raise ValueError('Unavailable/unknown tools: ' + ', '.join(sorted(wanted - allowed)))
    wanted |= REQUIRED
    return [t['name'] for t in tools if t['name'] in wanted]


def methods(value):
    names = value.split(',')
    if any(n not in ('native', 'github', 'source') for n in names) or len(set(names)) != len(names):
        raise ValueError('Use an ordered subset of native,github,source without duplicates.')
    return names


def ask(prompt, default, input_fn):
    print(f'{prompt} [{default}]: ', end='', file=sys.stderr, flush=True)
    answer = input_fn().strip()
    return answer or default


def interactive(tools, selected, order, input_fn=input):
    print('Choose tools. Bootstrap prerequisites are locked; all other tools are optional.', file=sys.stderr)
    ordered = [t for category in CATEGORIES for t in tools if t['category'] == category]
    indices = {str(i + 1): t['name'] for i, t in enumerate(ordered)}
    def show(categories):
        for category in categories:
            print('\n' + category.upper(), file=sys.stderr)
            for i, t in enumerate(ordered):
                if t['category'] != category: continue
                mark = '*' if t['name'] in selected else ' '
                print(f" {mark} {i + 1:2d}. {t['name']:24s} {t['description']}", file=sys.stderr)
    show(['required', 'recommended'])
    extras = [name for name in selected if next(t['category'] for t in tools if t['name'] == name) not in ('required', 'recommended')]
    if extras: print('\nCurrently selected extras: ' + ', '.join(extras), file=sys.stderr)
    print('\nOptional categories: project, comfort, specialist, visual. Type list to show their tools.', file=sys.stderr)
    print('Enter current, recommended, all, none, or comma-separated names/numbers.\n'
          'Extend a preset with +name or remove a tool with -name (for example recommended,+gh,-fzf).', file=sys.stderr)
    while True:
        value = ask('Tools', 'current', input_fn)
        if value == 'list':
            show(['project', 'comfort', 'specialist', 'visual']); continue
        if value == 'current': break
        try:
            tokens = [indices.get(t.strip(), t.strip()) for t in value.split(',')]
            base = tokens[0] if tokens[0] in ('recommended', 'all', 'none') else None
            if base:
                wanted = set(resolve(base, tools))
                for token in tokens[1:]:
                    if not token.startswith(('+', '-')): raise ValueError('Use +name or -name after a preset.')
                    name = token[1:]
                    if name not in {t['name'] for t in tools}: raise ValueError('Unknown tool: ' + name)
                    if token[0] == '+': wanted.add(name)
                    else: wanted.discard(name)
                selected = resolve(','.join(sorted(wanted - REQUIRED)) or 'none', tools)
            else:
                selected = resolve(','.join(tokens), tools)
            break
        except ValueError as error: print(str(error), file=sys.stderr)
    while True:
        primary = ask('First installation method (native, github release artifacts, source clone/build)', order[0], input_fn)
        if primary in ('native', 'github', 'source'): break
        print('Choose native, github or source.', file=sys.stderr)
    order = [primary]
    for method in ('native', 'github', 'source'):
        if method == primary: continue
        default = 'n' if method == 'source' else 'y'
        while True:
            answer = ask(f'Allow {method} as a fallback? (y/n)', default, input_fn).lower()
            if answer in ('y', 'yes', 'n', 'no'): break
            print('Answer y or n.', file=sys.stderr)
        if answer in ('y', 'yes'): order.append(method)
    print('\nSelected: ' + ', '.join(selected) + '\nMethod order: ' + ' → '.join(order), file=sys.stderr)
    return selected, order


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tools', help='recommended, all, none (prerequisites only), or comma-separated names')
    parser.add_argument('--exclude', default='', help='comma-separated optional tools to omit')
    parser.add_argument('--methods', help='ordered subset of native,github,source')
    parser.add_argument('--interactive', action='store_true')
    parser.add_argument('--save', action='store_true')
    parser.add_argument('--list', action='store_true')
    parser.add_argument('--format', choices=['json', 'lines'], default='json')
    args = parser.parse_args()
    tools = platform_tools()
    if args.list:
        for tool in tools: print(f"{tool['name']:24s} {tool['category']:12s} {tool['description']}")
        return 0
    state = Path.home() / '.local/state/dotfiles/tool-selection.json'
    try:
        saved = json.loads(state.read_text()) if state.exists() else {}
        selected = resolve(args.tools or os.environ.get('DOTFILES_TOOLS') or ','.join(saved.get('tools', [])) or 'recommended', tools)
        order = methods(args.methods or os.environ.get('DOTFILES_INSTALL_METHODS') or ','.join(saved.get('methods', [])) or 'native,github')
        exclusions = {name for name in args.exclude.split(',') if name}
        unknown = exclusions - {t['name'] for t in CATALOG}
        if unknown: raise ValueError('Unknown exclusions: ' + ', '.join(sorted(unknown)))
        selected = [name for name in selected if name not in exclusions or name in REQUIRED]
        if args.interactive:
            if not sys.stdin.isatty(): parser.error('--interactive requires a terminal; supply --tools and --methods instead.')
            selected, order = interactive(tools, selected, order)
            selected = [name for name in selected if name not in exclusions or name in REQUIRED]
    except (ValueError, TypeError, KeyError, json.JSONDecodeError) as error: parser.error(str(error))
    except (EOFError, KeyboardInterrupt):
        print('\nSelection cancelled; nothing installed.', file=sys.stderr)
        return 130
    data = dict(tools=selected, methods=order)
    if args.save:
        import importlib.util
        spec = importlib.util.spec_from_file_location('dotfiles_installer', ROOT / 'scripts/install-tools.py')
        installer = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(installer)
        installer.atomic_text(state, json.dumps(data, indent=2) + '\n')
    if args.format == 'lines': print(','.join(selected) + '\n' + ','.join(order))
    else: print(json.dumps(data))
    return 0


if __name__ == '__main__': sys.exit(main())
