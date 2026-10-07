#!/usr/bin/env python3
"""Install explicit reviewed GitHub VSIXs; no Marketplace dependency resolution."""
import importlib.util
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import zipfile

spec = importlib.util.spec_from_file_location("corporate_download", Path(__file__).with_name("corporate-download.py"))
download = importlib.util.module_from_spec(spec)
spec.loader.exec_module(download)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Validate manifest without downloading or installing")
    args = parser.parse_args()
    manifest = Path(os.environ.get("DOTFILES_VSIX_MANIFEST", Path.home() / ".config/dotfiles/vsix.json"))
    if not manifest.is_file():
        raise ValueError("Provide reviewed vsix.json with complete extension dependency closure (AGENTS.md C09)")
    items = json.loads(manifest.read_text())
    if not isinstance(items, list) or not items:
        raise ValueError("VSIX manifest must contain selected extensions")
    ids = {item["id"] for item in items}
    if len(ids) != len(items):
        raise ValueError("Duplicate VSIX extension ID")
    for item in items:
        if not re.fullmatch(r"[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+", item["id"]):
            raise ValueError("Invalid extension ID")
        if not item.get("runtime_reviewed"):
            raise ValueError("Review each extension's external downloads/services before enabling it")
        if not download.authorized_url(item["url"]) or not re.fullmatch(r"[0-9a-f]{64}", item.get("sha256", "")):
            raise ValueError("Require reviewed GitHub release VSIX URL and SHA256")
        if not isinstance(item.get("version"), str) or not item["version"]:
            raise ValueError("Pin each VSIX version")
    if args.check:
        return
    cache = Path.home() / ".cache/dotfiles/vsix"
    archives = {}
    dependencies = {}
    # Download and validate all packages/dependencies before activating any.
    for item in items:
        path = download.fetch(item["url"], cache / (item["sha256"] + ".vsix"), item["sha256"])
        with zipfile.ZipFile(path) as zipped:
            package = json.loads(zipped.read("extension/package.json"))
        if package["publisher"] + "." + package["name"] != item["id"] or package["version"] != item["version"]:
            raise ValueError("VSIX identity/version differs from manifest")
        deps = package.get("extensionDependencies", []) + package.get("extensionPack", [])
        if any(dep not in ids for dep in deps):
            raise ValueError("VSIX manifest lacks a required dependency; refuse Marketplace fallback")
        archives[item["id"]] = (item, path)
        dependencies[item["id"]] = deps
    # Dependencies must already exist when code activates a dependent VSIX.
    # Otherwise code can try to resolve them through Marketplace.
    ordered = []
    visiting = set()
    visited = set()

    def visit(extension):
        if extension in visiting:
            raise ValueError("Cyclic VSIX dependency closure; review C09 before activation")
        if extension in visited:
            return
        visiting.add(extension)
        for dependency in dependencies[extension]:
            visit(dependency)
        visiting.remove(extension)
        visited.add(extension)
        ordered.append(archives[extension])

    for extension in archives:
        visit(extension)
    result = subprocess.run(["code", "--list-extensions", "--show-versions"], capture_output=True, text=True, check=True)
    installed = set(result.stdout.splitlines())
    for item, path in ordered:
        if item["id"] + "@" + item["version"] not in installed:
            subprocess.run(["code", "--install-extension", str(path), "--force"], capture_output=True, check=True)
    actual = subprocess.run(["code", "--list-extensions", "--show-versions"], capture_output=True, text=True, check=True)
    if any(item["id"] + "@" + item["version"] not in actual.stdout.splitlines() for item in items):
        raise ValueError("VS Code did not activate all intended extension versions")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, KeyError, zipfile.BadZipFile, subprocess.CalledProcessError) as error:
        print(str(error) if isinstance(error, ValueError) else "VSIX acquisition/installation failed; inspect C09", file=sys.stderr)
        raise SystemExit(1)
