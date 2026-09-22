#!/usr/bin/env python3
"""Retire the explicit, fingerprinted targets from this repository's cleanup."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
import tarfile
import tempfile


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def parent_is_link(path, destination):
    return any(p.is_symlink() for p in path.parents if p != destination and destination in p.parents)


def recognized(path, entry, sources, destination):
    if path.is_symlink():
        # Compare lexical destinations, including dangling links after git pull.
        target = Path(os.path.abspath(path.parent / os.readlink(path)))
        expected = {source / entry["source"] for source in sources} if entry.get("source") else set()
        if target not in expected:
            return False
        if not path.exists():
            return True
    if path.is_file():
        content = path.read_bytes()
        if entry.get("crt"):
            suffix = ('custom-shader = "' + str(destination / ".config/dotfiles/shaders/scanlines.glsl") +
                      '"\ncustom-shader-animation = false\n').encode()
            if content.endswith(suffix):
                content = content[:-len(suffix)]
        return (hashlib.sha256(content).hexdigest() in entry.get("sha256", []) or
                content in [text.encode() for text in entry.get("contents", [])] or
                (entry.get("classic", False) and content == b"# Use the managed Gruvbox theme.\n"))
    if path.is_symlink() and path.is_dir() and "children" in entry:
        # Only a known directory link, with no extra application/user files.
        actual = {str(p.relative_to(path)): digest(p) for p in path.rglob("*") if p.is_file() and not p.is_symlink()}
        return actual == entry["children"] and not any(p.is_symlink() for p in path.rglob("*"))
    return False


def retire(destination, source, profile, dry_run=False):
    destination = destination.absolute()
    sources = {source.absolute()}
    saved = destination / ".local/state/dotfiles/source"
    if saved.is_file():
        old = Path(saved.read_text().strip())
        if old.is_absolute() and str(old) != "/":
            sources.add(old / "home")
    entries = json.loads(Path(__file__).with_name("retired-files.json").read_text())
    eligible, unresolved = [], []
    for entry in entries:
        if entry.get("profile") not in (None, profile):
            continue
        relative = Path(entry["target"])
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError("Unsafe retirement manifest target")
        path = destination / relative
        if not path.exists() and not path.is_symlink():
            continue
        if parent_is_link(path, destination) or not recognized(path, entry, sources, destination):
            unresolved.append(str(relative))
        else:
            eligible.append((path, entry))
    for target in unresolved:
        print("Unresolved cleanup (preserved): " + target, file=sys.stderr)
    if dry_run:
        for path, _ in eligible:
            print("Would back up and retire: " + str(path.relative_to(destination)))
        return bool(unresolved)
    if eligible:
        backup_root = destination / ".local/state/dotfiles/backups"
        if parent_is_link(backup_root, destination) or backup_root.is_symlink():
            raise ValueError("Refusing symlinked backup directory")
        backup_root.mkdir(parents=True, exist_ok=True, mode=0o700)
        backup_root.chmod(0o700)
        backup = Path(tempfile.mkdtemp(prefix="retired-", dir=backup_root))
        # Finish both private archives before unlinking anything.
        old_umask = os.umask(0o077)
        try:
            with tarfile.open(backup / "targets.tar", "w", dereference=False) as metadata, \
                    tarfile.open(backup / "contents.tar", "w", dereference=True) as contents:
                for path, _ in eligible:
                    target = str(path.relative_to(destination))
                    metadata.add(path, arcname=target, recursive=False)
                    if path.exists():
                        contents.add(path, arcname=target)
        finally:
            os.umask(old_umask)
        for path, entry in eligible:
            # Recheck after backup; never follow a newly changed parent/link.
            if parent_is_link(path, destination) or not recognized(path, entry, sources, destination):
                unresolved.append(str(path))
                print("Unresolved cleanup (changed during backup): " + str(path), file=sys.stderr)
                continue
            path.unlink()
            print("Retired: " + str(path.relative_to(destination)))
            parent = path.parent
            while parent != destination:
                try:
                    parent.rmdir()  # Empty directories only; never recursive removal.
                except OSError:
                    break
                parent = parent.parent
        print("Retirement backup: " + str(backup))
    return bool(unresolved)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--profile", choices=("server", "workstation"), required=True)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    # 2 signals preserved remnants; other errors abort apply.
    return 2 if retire(args.destination, args.source, args.profile, args.dry_run) else 0


if __name__ == "__main__":
    sys.exit(main())
