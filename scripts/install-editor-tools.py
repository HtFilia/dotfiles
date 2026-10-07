#!/usr/bin/env python3
"""Install reviewed editor closures with native npm/pip in isolated user prefixes."""
import argparse
import base64
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile
import zipfile

spec = importlib.util.spec_from_file_location("corporate_download", Path(__file__).with_name("corporate-download.py"))
download = importlib.util.module_from_spec(spec)
spec.loader.exec_module(download)

TOOLS = {
    "lua": ["lua-language-server", "stylua"],
    "python": ["basedpyright-langserver", "ruff"],
    "go": ["gopls", "goimports"],
    "rust": ["rust-analyzer"],
    "node": ["typescript-language-server", "tsc", "prettier"],
    "shell": ["bash-language-server", "shfmt", "shellcheck"],
}


def read_json(path):
    if not path.is_file():
        raise ValueError(f"Missing reviewed manifest {path}; resolve AGENTS.md C07/C08")
    return json.loads(path.read_text())


def safe_name(value):
    if not isinstance(value, str) or value in {".", ".."} or not re.fullmatch(r"[A-Za-z0-9_.+-]+", value):
        raise ValueError("Unsafe tool/version/filename in manifest")
    return value


def native_run(args, cwd=None):
    # Native commands only consume local verified inputs. Keep diagnostics free
    # of internal URLs/tokens; detailed investigations are done on the host.
    result = subprocess.run(args, cwd=cwd, capture_output=True, text=True)
    if result.returncode:
        raise ValueError(f"{Path(args[0]).name} failed; review local dependency closure/runtime compatibility (C07)")


def validate_npm(source):
    registry = download.internal_registry("DOTFILES_NPM_REGISTRY")
    package = read_json(source / "package.json")
    lock = read_json(source / "package-lock.json")
    if lock.get("lockfileVersion") not in {2, 3} or not lock.get("packages"):
        raise ValueError("Require a reviewed npm v2/v3 lockfile")
    if package.get("scripts"):
        raise ValueError("Editor package manifest must not execute lifecycle scripts")
    for name, version in package.get("dependencies", {}).items():
        if not re.fullmatch(r"\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?", version):
            raise ValueError(f"Pin exact npm dependency version: {name}")
    records = []
    for key, item in lock["packages"].items():
        if not key:
            continue
        path = Path(key)
        if not key.startswith("node_modules/") or path.is_absolute() or ".." in path.parts:
            raise ValueError("Unsafe npm lockfile package path")
        if item.get("link") or not download.authorized_url(item.get("resolved", ""), registry):
            raise ValueError("npm lockfile contains an unapproved dependency source")
        integrity = item.get("integrity", "")
        if not integrity.startswith("sha512-"):
            raise ValueError("Every npm dependency needs SHA512 integrity")
        checksum = base64.b64decode(integrity[7:], validate=True).hex()
        if len(checksum) != 128:
            raise ValueError("Invalid npm dependency integrity")
        records.append((item["resolved"], checksum))
    return registry, records


def npm_install(source, destination):
    registry, records = validate_npm(source)
    cache = destination / "npm-cache"
    for url, checksum in records:
        archive = download.fetch(url, destination / (checksum + ".tgz"), checksum, "sha512", registry)
        native_run(["npm", "cache", "add", str(archive), "--cache", str(cache), "--offline", "--ignore-scripts", "--audit=false", "--fund=false"], destination)
    shutil.copy2(source / "package.json", destination / "package.json")
    shutil.copy2(source / "package-lock.json", destination / "package-lock.json")
    native_run(["npm", "ci", "--offline", "--ignore-scripts", "--engine-strict", "--audit=false", "--fund=false", "--cache", str(cache), "--registry", registry], destination)
    native_run(["npm", "ls", "--all", "--offline", "--audit=false", "--fund=false"], destination)
    return destination / "node_modules/.bin"


def validate_python(source):
    registry = download.internal_registry("DOTFILES_PYTHON_REGISTRY")
    manifest = read_json(source / "wheels.json")
    wheels = manifest.get("wheels", [])
    if not wheels:
        raise ValueError("Provide the complete compatible wheel closure in wheels.json")
    for item in wheels:
        safe_name(item["filename"])
        if not item["filename"].endswith(".whl") or not download.authorized_url(item["url"], registry):
            raise ValueError("Python closure must contain only internal, hashed wheels")
        if not re.fullmatch(r"[0-9a-f]{64}", item.get("sha256", "")):
            raise ValueError("Python wheel checksum missing")
    return registry, wheels


def python_install(source, destination):
    registry, wheels = validate_python(source)
    wheelhouse = destination / "wheelhouse"
    for item in wheels:
        download.fetch(item["url"], wheelhouse / item["filename"], item["sha256"], registry=registry)
    native_run(["python3", "-m", "venv", str(destination / "venv")])
    native_run([str(destination / "venv/bin/python"), "-m", "pip", "--disable-pip-version-check", "install", "--no-index", "--only-binary=:all:", "--find-links", str(wheelhouse), *map(str, wheelhouse.glob("*.whl"))])
    native_run([str(destination / "venv/bin/python"), "-m", "pip", "check"])
    return destination / "venv/bin"


def validate_artifacts(source):
    artifacts = read_json(source / "artifacts.json")
    if not isinstance(artifacts, list) or not artifacts:
        raise ValueError("artifacts.json must contain reviewed GitHub release artifacts")
    for item in artifacts:
        safe_name(item["tool"])
        if not download.authorized_url(item["url"]):
            raise ValueError("Editor artifact must be an official reviewed GitHub release")
        if not re.fullmatch(r"[0-9a-f]{64}", item.get("sha256", "")):
            raise ValueError("Editor artifact checksum missing")
        if not re.fullmatch(r"[A-Za-z0-9_.+-]+", item.get("version", "")):
            raise ValueError("Editor artifact requires a reviewed version")
        member = Path(item["member"])
        if member.is_absolute() or ".." in member.parts:
            raise ValueError("Unsafe artifact executable member")
    return artifacts


def artifacts_install(source, destination):
    artifacts = validate_artifacts(source)
    binaries = destination / "bin"
    binaries.mkdir(exist_ok=True)
    for item in artifacts:
        tool = item["tool"]
        archive = download.fetch(item["url"], destination / (tool + ".download"), item["sha256"])
        extracted = destination / tool
        extracted.mkdir()
        kind = item.get("format", "binary")
        if kind in {"tar.gz", "tar.xz", "zip"}:
            download.extract(archive, extracted)
        elif kind == "binary":
            (extracted / item["member"]).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(archive, extracted / item["member"])
        else:
            raise ValueError("Unsupported artifact format")
        executable = extracted / item["member"]
        if not executable.is_file() or not executable.resolve().is_relative_to(extracted.resolve()):
            raise ValueError("Missing/unsafe editor executable in artifact")
        executable.chmod(executable.stat().st_mode | 0o700)
        arguments = item.get("version_args", ["--version"])
        if not isinstance(arguments, list) or not all(isinstance(x, str) for x in arguments):
            raise ValueError("Invalid executable version arguments")
        result = subprocess.run([str(executable), *arguments], capture_output=True, text=True, timeout=30)
        expected = item.get("reported_version", item["version"]).removeprefix("v")
        if result.returncode or not re.search(r"(?<![0-9.])" + re.escape(expected) + r"(?![0-9.])", result.stdout + result.stderr):
            raise ValueError(f"Installed {tool} does not report the reviewed version")
        (binaries / tool).symlink_to(executable)
    return binaries


def apt_owned(tool):
    path = Path("/usr/bin", tool)
    if not path.is_file() or not os.access(path, os.X_OK):
        return False
    ownership = subprocess.run(["dpkg-query", "-S", str(path)], capture_output=True, text=True)
    if ownership.returncode:
        return False
    package = ownership.stdout.split(": ", 1)[0]
    status = subprocess.run(["dpkg-query", "-W", "-f=${Status}", package], capture_output=True, text=True)
    return status.returncode == 0 and status.stdout == "install ok installed"


def review_selection(language, source):
    required = TOOLS[language]
    apt_tools = [t for t in required if apt_owned(t)] if language in {"go", "shell"} else []
    missing = [t for t in required if t not in apt_tools]
    files = [p for p in (source / "package.json", source / "package-lock.json", source / "wheels.json", source / "artifacts.json") if p.is_file()]
    if missing and not files:
        raise ValueError(f"Selected {language} tools require reviewed manifests in {source}; resolve AGENTS.md C07/C08")
    if (source / "package-lock.json").is_file():
        validate_npm(source)
    elif (source / "package.json").is_file():
        raise ValueError("package.json requires a reviewed package-lock.json")
    if (source / "wheels.json").is_file():
        validate_python(source)
    if (source / "artifacts.json").is_file():
        validate_artifacts(source)
    return apt_tools, missing, files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("languages", nargs="+", choices=TOOLS)
    parser.add_argument("--check", action="store_true", help="Validate selected tools/manifests without installing")
    args = parser.parse_args()
    root = Path(os.environ.get("DOTFILES_EDITOR_MANIFEST_DIR", Path.home() / ".config/dotfiles/corporate-packages"))
    local_bin = Path(os.environ.get("LOCAL_BIN", Path.home() / ".local/bin"))
    opt = Path.home() / ".local/opt/dotfiles-editor"
    manifest = []
    # Validate the entire selection before publishing any executable.
    selections = {language: review_selection(language, root / language) for language in args.languages}
    if args.check:
        return
    for language in args.languages:
        required = TOOLS[language]
        source = root / language
        apt_tools, missing, files = selections[language]
        local_bin.mkdir(parents=True, exist_ok=True)
        if local_bin.is_symlink() or not local_bin.stat().st_uid == os.getuid():
            raise ValueError("Unsafe local executable directory")
        for tool in apt_tools:
            target = local_bin / tool
            stage = local_bin / (tool + ".stage")
            stage.unlink(missing_ok=True)
            stage.symlink_to(Path("/usr/bin", tool))
            stage.replace(target)
        if missing:
            identity = hashlib.sha256(b"".join(p.name.encode() + p.read_bytes() for p in files)).hexdigest()
            opt.mkdir(parents=True, exist_ok=True)
            if opt.is_symlink() or opt.stat().st_uid != os.getuid():
                raise ValueError("Unsafe editor installation directory")
            destination = opt / (language + "-" + identity[:16])
            bins = []
            if not (destination / ".complete").is_file():
                stage = Path(tempfile.mkdtemp(prefix=language + "-stage-", dir=opt))
                try:
                    if (source / "package-lock.json").is_file():
                        (stage / "npm").mkdir()
                        bins.append(npm_install(source, stage / "npm"))
                    if (source / "wheels.json").is_file():
                        (stage / "python").mkdir()
                        bins.append(python_install(source, stage / "python"))
                    if (source / "artifacts.json").is_file():
                        (stage / "artifacts").mkdir()
                        bins.append(artifacts_install(source, stage / "artifacts"))
                    mappings = {}
                    for tool in missing:
                        matches = [directory / tool for directory in bins if (directory / tool).is_file()]
                        if len(matches) != 1:
                            raise ValueError(f"Expected one executable for selected tool {tool}")
                        if not os.access(matches[0], os.X_OK):
                            raise ValueError(f"Editor output is not executable: {tool}")
                        mappings[tool] = {"path": str(matches[0].relative_to(stage)),
                                          "sha256": hashlib.sha256(matches[0].read_bytes()).hexdigest()}
                    (stage / ".complete").write_text(json.dumps(mappings))
                    # venv scripts and npm/artifact symlinks contain absolute stage paths.
                    # Keep immutable stage directory; atomically publish a versioned link.
                    if destination.exists() or destination.is_symlink():
                        raise ValueError("Incomplete editor prefix; move it aside after inspection")
                    destination.symlink_to(stage, target_is_directory=True)
                except BaseException:
                    shutil.rmtree(stage)
                    raise
            mappings = json.loads((destination / ".complete").read_text())
            targets = {}
            for tool in missing:
                target = destination / mappings[tool]["path"]
                if (not target.is_file() or not target.resolve().is_relative_to(destination.resolve()) or
                        hashlib.sha256(target.read_bytes()).hexdigest() != mappings[tool]["sha256"]):
                    raise ValueError(f"Partial editor installation: {tool}; inspect prefix before retrying")
                targets[tool] = target
            for tool, target in targets.items():
                link = local_bin / (tool + ".stage")
                link.unlink(missing_ok=True)
                link.symlink_to(target)
                link.replace(local_bin / tool)
        for tool in required:
            path = local_bin / tool
            if not os.access(path, os.X_OK):
                raise ValueError(f"Required editor tool does not execute: {tool}")
            manifest.append(str(path))
    if not args.check:
        state = Path.home() / ".local/state/dotfiles"
        state.mkdir(parents=True, exist_ok=True)
        (state / "editor-tools.pending").write_text("\n".join(manifest) + "\n")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, KeyError, tarfile.TarError, zipfile.BadZipFile, subprocess.TimeoutExpired):
        # Individual URLs/authentication failures must never leak secrets.
        import sys
        error = sys.exc_info()[1]
        print(str(error) if isinstance(error, ValueError) else "Editor acquisition failed; inspect source/runtime availability (AGENTS.md C07/C08)", file=sys.stderr)
        raise SystemExit(1)
