#!/usr/bin/env python3
"""Guided terminal workbooks with disposable fixtures and real command output."""
import argparse
import json
import os
from pathlib import Path
import shlex
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib

ROOT = Path(__file__).resolve().parent


def fixtures(root):
    (root / "source").mkdir()
    (root / "duplicates").mkdir()
    (root / "source/notes.txt").write_text("alpha\nbeta\nalpha\nGamma\n")
    (root / "source/demo.py").write_text('def hello(name):\n    return f"hello {name}"\n')
    (root / "duplicates/one.txt").write_text("duplicate sample\n" * 100)
    (root / "duplicates/two.txt").write_text("duplicate sample\n" * 100)
    (root / "data.json").write_text(json.dumps({"host": "lab", "services": [
        {"name": "api", "port": 8080, "healthy": True},
        {"name": "worker", "port": 9090, "healthy": False}]}, indent=2) + "\n")
    (root / "events.csv").write_text("service,requests\napi,120\nworker,40\n")
    (root / "justfile").write_text("hello:\n    @printf 'Hello from a repeatable task\\n'\n")
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    pixels = b"".join(b"\0" + b"".join(bytes((40, 215, 255) if (x // 8 + y // 8) % 2 else (255, 60, 180))
                                      for x in range(64)) for y in range(32))
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 64, 32, 8, 2, 0, 0, 0))
    (root / "signal.png").write_bytes(png + chunk(b"IDAT", zlib.compress(pixels)) + chunk(b"IEND", b""))


def run_step(step, cwd, interactive=False):
    missing = [tool for tool in step["tools"] if shutil.which(tool) is None]
    if missing:
        print("MISSING: " + ", ".join(missing))
        return False
    print("\n$ " + step["command"], flush=True)
    if step.get("interactive"):
        if not interactive:
            print("Interactive step: available from the lesson menu.")
            return True
        print(step.get("exit", "Exit the tool to return to this workbook."), flush=True)
    env = dict(os.environ, PAGER="less", BAT_CACHE_PATH=str(cwd / ".bat-cache"),
               BROOT_CONFIG_DIR=str(cwd / ".broot"),
               XDG_CACHE_HOME=str(cwd / ".cache"), XDG_CONFIG_HOME=str(cwd / ".config"),
               XDG_DATA_HOME=str(cwd / ".data"), XDG_STATE_HOME=str(cwd / ".state"))
    try:
        result = subprocess.run(["bash", "-o", "pipefail", "-c", step["command"]], cwd=cwd,
                                env=env, text=True, capture_output=not step.get("interactive"),
                                timeout=None if step.get("interactive") else 45)
    except (subprocess.TimeoutExpired, KeyboardInterrupt):
        print("\nStopped; returning to the workbook.")
        return False
    if not step.get("interactive"):
        print(result.stdout or "", end="")
        print(result.stderr or "", end="", file=sys.stderr)
    expected = step.get("contains")
    ok = result.returncode == 0 and (expected is None or expected in ((result.stdout or "") + (result.stderr or "")))
    print("PASS" if ok else f"CHECK FAILED (exit {result.returncode})")
    return ok


def lesson_view(lesson, root):
    print(f"\n{lesson['title']}\n{lesson['goal']}\nWorking directory: {root}")
    print("These are disposable sample files. A practice shell is a normal shell, not a security sandbox.")
    for step in lesson["steps"]:
        print(f"\n{step['title']}\n{step['why']}\n$ {step['command']}")
        while True:
            choice = input("[Enter] run  [p] practice shell  [s] skip  [q] lesson menu: ").strip().lower()
            if choice == "q": return
            if choice == "s": break
            if choice == "p":
                print("Type exit to return. Try: " + step["command"], flush=True)
                subprocess.run(["bash", "--noprofile", "--norc"], cwd=root,
                               env=dict(os.environ, PS1="lab:\\w $ "))
                continue
            if choice == "":
                run_step(step, root, interactive=True)
                break
    print("\nChallenge: " + lesson["challenge"])
    print("Use the practice shell on any step to explore variations.")


def main():
    lessons = json.loads((ROOT / "lessons.json").read_text())
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("lesson", nargs="?", choices=[x["id"] for x in lessons])
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--smoke", action="store_true", help="Run noninteractive demos and fail if a tool/check is missing")
    parser.add_argument("--keep", action="store_true", help="Keep the sample directory after exiting")
    args = parser.parse_args()
    if args.list:
        for x in lessons: print(f"{x['id']:12} {x['title']}")
        return 0
    if not args.smoke and not sys.stdin.isatty():
        parser.error("The menu needs a terminal; use --list or --smoke for automation")
    parent = Path(tempfile.mkdtemp(prefix="dotfiles-lab-"))
    failures = 0
    print("Workbook files: " + str(parent))
    try:
        selected = [x for x in lessons if not args.lesson or x["id"] == args.lesson]
        if args.smoke:
            for lesson in selected:
                root = parent / lesson["id"]
                root.mkdir()
                fixtures(root)
                print("\n=== " + lesson["title"] + " ===")
                for step in lesson["steps"]:
                    if not step.get("interactive") and not run_step(step, root): failures += 1
            print(f"\n{failures} failed demonstration(s).")
            return int(failures != 0)
        while True:
            if args.lesson:
                lesson = selected[0]
            else:
                print("\n╭─ DOTFILES / FIELD WORKBOOKS ─╮")
                for i, x in enumerate(selected, 1): print(f" {i:2}. {x['title']}")
                choice = input("Choose a workbook, or q to quit: ").strip()
                if choice.lower() == "q": break
                if not choice.isdigit() or not 1 <= int(choice) <= len(selected): continue
                lesson = selected[int(choice) - 1]
            root = Path(tempfile.mkdtemp(prefix=lesson["id"] + "-", dir=parent))
            fixtures(root)
            lesson_view(lesson, root)
            if args.lesson: break
    except (EOFError, KeyboardInterrupt):
        print("\nLeaving workbook.")
    finally:
        if args.keep: print("Kept sample files at " + str(parent))
        else: shutil.rmtree(parent)
    return 0


if __name__ == "__main__":
    sys.exit(main())
