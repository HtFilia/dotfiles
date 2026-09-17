#!/usr/bin/env python3
"""Merge Dotfiles schemes and style the selected WSL profile, keeping a backup."""
import argparse
import json
import os
from pathlib import Path
import shutil
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("settings", type=Path, help="Windows Terminal settings.json (JSON, not JSONC)")
    parser.add_argument("--profile", default=os.environ.get("WSL_DISTRO_NAME", "Debian"))
    parser.add_argument("--style", choices=("operator", "studio", "neon", "matrix"), default="operator")
    parser.add_argument("--crt", action="store_true")
    args = parser.parse_args()
    original = args.settings.read_text(encoding="utf-8-sig")
    try:
        config = json.loads(original)
    except json.JSONDecodeError:
        parser.error("Settings contain comments or invalid JSON; merge the scheme file manually instead.")
    profiles = config.get("profiles", {}).get("list", [])
    targets = [p for p in profiles if p.get("name") == args.profile and p.get("source") == "Microsoft.WSL"]
    if not targets:
        parser.error("No matching WSL profile; no settings changed.")
    schemes = json.loads((Path(__file__).resolve().parents[1] / "home/dot_config/dotfiles/windows-terminal.json").read_text())["schemes"]
    names = {s["name"] for s in schemes}
    config["schemes"] = [s for s in config.get("schemes", []) if s.get("name") not in names] + schemes
    for profile in targets:
        profile.update(colorScheme="Dotfiles " + args.style.title(), cursorShape="filledBox",
                       padding="14, 10", opacity=94, useAcrylic=True)
        profile["experimental.retroTerminalEffect"] = args.crt
    rendered = json.dumps(config, ensure_ascii=False, indent=4) + "\n"
    if json.loads(original) == config:
        print("Windows Terminal style already matches.")
        return
    fd, backup = tempfile.mkstemp(prefix="settings.dotfiles-backup-", suffix=".json", dir=args.settings.parent)
    os.close(fd)
    shutil.copy2(args.settings, backup)
    fd, stage = tempfile.mkstemp(prefix="settings.dotfiles-stage-", dir=args.settings.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(rendered)
        os.replace(stage, args.settings)
    finally:
        Path(stage).unlink(missing_ok=True)
    print(f"Styled {len(targets)} matching WSL profile(s). Backup: {backup}")


if __name__ == "__main__":
    main()
