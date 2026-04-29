#!/usr/bin/env python3
"""Render .tmpl dotfiles and symlink them into $HOME.

Handles the Go-template subset used by the templates in this repo: dotted
variable lookup, `{{- ... }}` whitespace trimming, `if/else if/else/end`
with `eq`, `ne`, `and`, `or`, `not`, `contains`, `lower`, `upper`, and
parenthesized sub-expressions.

Requires: python3, python3-yaml (both in Debian main).
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:
    sys.stderr.write(
        "error: PyYAML is required. Install with: sudo apt install python3-yaml\n"
    )
    sys.exit(2)


REPO_ROOT = Path(__file__).resolve().parent.parent
HOME_SRC = REPO_ROOT / "home"
CONFIG_DIR = Path.home() / ".config" / "dotfiles"
MACHINE_YAML = CONFIG_DIR / "machine.yaml"
RENDER_DIR = CONFIG_DIR / "rendered"


_TTY = sys.stdout.isatty()
C_GREEN = "\033[0;32m" if _TTY else ""
C_YELLOW = "\033[0;33m" if _TTY else ""
C_CYAN = "\033[0;36m" if _TTY else ""
C_RED = "\033[0;31m" if _TTY else ""
C_BOLD = "\033[1m" if _TTY else ""
C_RESET = "\033[0m" if _TTY else ""


def _log(prefix: str, msg: str, stream=sys.stdout) -> None:
    stream.write(f"{prefix} {msg}\n")


def info(msg: str) -> None:
    _log(f"{C_CYAN}  i{C_RESET}", msg)


def success(msg: str) -> None:
    _log(f"{C_GREEN}  ✓{C_RESET}", msg)


def warn(msg: str) -> None:
    _log(f"{C_YELLOW}  ⚠{C_RESET}", msg, stream=sys.stderr)


def error(msg: str) -> None:
    _log(f"{C_RED}  ✗{C_RESET}", msg, stream=sys.stderr)


def banner(msg: str) -> None:
    _log(f"{C_CYAN}{C_BOLD}==>{C_RESET}", msg)


# ---------------------------------------------------------------------------
# Go-template subset evaluator
# ---------------------------------------------------------------------------


class TemplateError(Exception):
    pass


def _lookup(path: str, data: dict[str, Any]) -> Any:
    parts = path.lstrip(".").split(".")
    cur: Any = data
    for p in parts:
        if isinstance(cur, dict) and p in cur:
            cur = cur[p]
        else:
            return None
    return cur


def _split_top(expr: str) -> list[str]:
    """Split a list of args on top-level whitespace, respecting () and "..".."""
    args: list[str] = []
    cur: list[str] = []
    depth = 0
    in_str = False
    i = 0
    while i < len(expr):
        ch = expr[i]
        if ch == '"' and (i == 0 or expr[i - 1] != "\\"):
            in_str = not in_str
            cur.append(ch)
        elif not in_str and ch == "(":
            depth += 1
            cur.append(ch)
        elif not in_str and ch == ")":
            depth -= 1
            cur.append(ch)
        elif not in_str and depth == 0 and ch in " \t":
            if cur:
                args.append("".join(cur))
                cur = []
        else:
            cur.append(ch)
        i += 1
    if cur:
        args.append("".join(cur))
    return args


def _strip_outer_parens(expr: str) -> str:
    """Strip a single pair of balanced outer parens, if present."""
    if not (expr.startswith("(") and expr.endswith(")")):
        return expr
    depth = 0
    for i, ch in enumerate(expr):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0 and i < len(expr) - 1:
                return expr
    return expr[1:-1].strip()


def _eval(expr: str, data: dict[str, Any]) -> Any:
    expr = expr.strip()
    if not expr:
        return None
    stripped = _strip_outer_parens(expr)
    if stripped != expr:
        return _eval(stripped, data)
    if expr.startswith('"') and expr.endswith('"') and len(expr) >= 2:
        return expr[1:-1]
    if re.fullmatch(r"-?\d+", expr):
        return int(expr)
    if expr == "true":
        return True
    if expr == "false":
        return False
    if expr.startswith("."):
        return _lookup(expr, data)
    parts = _split_top(expr)
    if not parts:
        return None
    fn = parts[0]
    args = parts[1:]
    if fn == "eq":
        if len(args) < 2:
            raise TemplateError(f"eq needs >= 2 args: {expr!r}")
        vals = [_eval(a, data) for a in args]
        return all(v == vals[0] for v in vals[1:])
    if fn == "ne":
        if len(args) != 2:
            raise TemplateError(f"ne needs 2 args: {expr!r}")
        return _eval(args[0], data) != _eval(args[1], data)
    if fn == "and":
        result: Any = True
        for a in args:
            result = _eval(a, data)
            if not result:
                return result
        return result
    if fn == "or":
        result = False
        for a in args:
            result = _eval(a, data)
            if result:
                return result
        return result
    if fn == "not":
        if len(args) != 1:
            raise TemplateError(f"not needs 1 arg: {expr!r}")
        return not _eval(args[0], data)
    if fn == "contains":
        if len(args) != 2:
            raise TemplateError(f"contains needs 2 args: {expr!r}")
        needle = _eval(args[0], data)
        haystack = _eval(args[1], data)
        if haystack is None or needle is None:
            return False
        return str(needle) in str(haystack)
    if fn == "lower":
        if len(args) != 1:
            raise TemplateError(f"lower needs 1 arg: {expr!r}")
        v = _eval(args[0], data)
        return str(v).lower() if v is not None else ""
    if fn == "upper":
        if len(args) != 1:
            raise TemplateError(f"upper needs 1 arg: {expr!r}")
        v = _eval(args[0], data)
        return str(v).upper() if v is not None else ""
    raise TemplateError(f"unknown function or expression: {expr!r}")


# ---------------------------------------------------------------------------
# Tokenizer
# ---------------------------------------------------------------------------

_TOKEN_RE = re.compile(r"\{\{(-?)\s*(.*?)\s*(-?)\}\}", re.DOTALL)


@dataclass
class Token:
    kind: str
    text: str = ""
    action: str = ""
    trim_left: bool = False
    trim_right: bool = False


def tokenize(src: str) -> list[Token]:
    tokens: list[Token] = []
    pos = 0
    for m in _TOKEN_RE.finditer(src):
        if m.start() > pos:
            tokens.append(Token("TEXT", text=src[pos : m.start()]))
        tokens.append(
            Token(
                "ACTION",
                action=m.group(2).strip(),
                trim_left=m.group(1) == "-",
                trim_right=m.group(3) == "-",
            )
        )
        pos = m.end()
    if pos < len(src):
        tokens.append(Token("TEXT", text=src[pos:]))
    for i, t in enumerate(tokens):
        if t.kind != "ACTION":
            continue
        if t.trim_left and i > 0 and tokens[i - 1].kind == "TEXT":
            tokens[i - 1].text = tokens[i - 1].text.rstrip(" \t\r\n")
        if t.trim_right and i + 1 < len(tokens) and tokens[i + 1].kind == "TEXT":
            tokens[i + 1].text = tokens[i + 1].text.lstrip(" \t\r\n")
    return tokens


# ---------------------------------------------------------------------------
# Renderer
# ---------------------------------------------------------------------------


_ESCAPE_RE = re.compile(r"\{\{-?\s*`([^`]*)`\s*-?\}\}")


def render(src: str, data: dict[str, Any]) -> str:
    placeholders: dict[str, str] = {}

    def _stash(m: re.Match[str]) -> str:
        key = f"__CHEZMOI_RAW_{len(placeholders):04d}__"
        placeholders[key] = m.group(1)
        return key

    preprocessed = _ESCAPE_RE.sub(_stash, src)
    tokens = tokenize(preprocessed)
    out, pos = _render(tokens, 0, data, stop_on=())
    if pos != len(tokens):
        raise TemplateError(f"Stopped early at token {pos}/{len(tokens)}")
    for key, val in placeholders.items():
        out = out.replace(key, val)
    return out


def _render(
    tokens: list[Token],
    pos: int,
    data: dict[str, Any],
    stop_on: tuple[str, ...],
) -> tuple[str, int]:
    out: list[str] = []
    while pos < len(tokens):
        t = tokens[pos]
        if t.kind == "TEXT":
            out.append(t.text)
            pos += 1
            continue
        action = t.action
        first = action.split(None, 1)[0] if action else ""
        if first in stop_on:
            return "".join(out), pos
        if first == "if":
            cond_expr = action[len("if") :].strip()
            rendered, pos = _render_if(tokens, pos + 1, data, cond_expr)
            out.append(rendered)
            continue
        if first in ("else", "end"):
            raise TemplateError(f"unexpected {{{{ {action} }}}}")
        val = _eval(action, data)
        if val is None:
            pass
        elif isinstance(val, bool):
            out.append("true" if val else "false")
        else:
            out.append(str(val))
        pos += 1
    return "".join(out), pos


def _render_if(
    tokens: list[Token],
    pos: int,
    data: dict[str, Any],
    cond_expr: str,
) -> tuple[str, int]:
    branches: list[tuple[bool, str]] = []
    any_matched = False
    cond = bool(_eval(cond_expr, data))
    content, pos = _render(tokens, pos, data, stop_on=("else", "end"))
    branches.append((cond and not any_matched, content))
    any_matched = any_matched or cond
    while pos < len(tokens):
        t = tokens[pos]
        if t.kind != "ACTION":
            raise TemplateError("expected action after branch content")
        action = t.action
        first = action.split(None, 1)[0] if action else ""
        if first == "end":
            pos += 1
            for matched, rendered in branches:
                if matched:
                    return rendered, pos
            return "", pos
        if first == "else":
            rest = action[len("else") :].strip()
            if rest.startswith("if "):
                elif_expr = rest[3:].strip()
                elif_cond = bool(_eval(elif_expr, data))
                entering = elif_cond and not any_matched
                content, pos = _render(tokens, pos + 1, data, stop_on=("else", "end"))
                branches.append((entering, content))
                any_matched = any_matched or elif_cond
                continue
            entering = not any_matched
            content, pos = _render(tokens, pos + 1, data, stop_on=("end",))
            branches.append((entering, content))
            any_matched = True
            continue
        raise TemplateError(f"unexpected action in if-block: {action!r}")
    raise TemplateError("unterminated if-block")


# ---------------------------------------------------------------------------
# Machine data
# ---------------------------------------------------------------------------


REQUIRED_FIELDS = ("name", "email", "machineType", "hostname")


def _read_osrelease() -> str:
    try:
        return Path("/proc/sys/kernel/osrelease").read_text().strip()
    except OSError:
        return ""


def load_machine_data(interactive: bool = True) -> dict[str, Any]:
    data: dict[str, Any] = {}
    if MACHINE_YAML.exists():
        loaded = yaml.safe_load(MACHINE_YAML.read_text()) or {}
        if isinstance(loaded, dict):
            data.update(loaded)
    missing = [k for k in REQUIRED_FIELDS if not data.get(k)]
    if missing:
        if not interactive:
            raise SystemExit(
                f"{MACHINE_YAML} is missing fields {missing}. "
                "Run with an interactive terminal to set them up."
            )
        print(f"{C_BOLD}First-run setup for {MACHINE_YAML}{C_RESET}")
        if "name" in missing:
            data["name"] = input("Full name: ").strip()
        if "email" in missing:
            data["email"] = input("Email: ").strip()
        if "machineType" in missing:
            mt = input("Machine type [work/personal] (work): ").strip() or "work"
            data["machineType"] = mt
        if "hostname" in missing:
            default_host = os.uname().nodename
            host = input(f"Machine hostname ({default_host}): ").strip() or default_host
            data["hostname"] = host
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        MACHINE_YAML.write_text(
            yaml.safe_dump({k: data[k] for k in REQUIRED_FIELDS}, default_flow_style=False, sort_keys=True)
        )
        success(f"wrote {MACHINE_YAML}")
    data["chezmoi"] = {
        "os": "linux",
        "kernel": {"osrelease": _read_osrelease()},
    }
    return data


# ---------------------------------------------------------------------------
# File layout (dot_ prefix convention → $HOME)
# ---------------------------------------------------------------------------

SKIP_NAMES = {".chezmoiroot", ".chezmoiignore"}  # legacy files, skip if present
SKIP_SUFFIXES = {".example", ".bak", ".orig", ".swp"}


def target_path(rel: Path) -> Path:
    parts = [p.replace("dot_", ".", 1) if p.startswith("dot_") else p for p in rel.parts]
    return Path.home().joinpath(*parts)


def iter_sources() -> list[Path]:
    out: list[Path] = []
    for p in sorted(HOME_SRC.rglob("*")):
        if not p.is_file():
            continue
        rel = p.relative_to(HOME_SRC)
        if any(part.startswith(".chezmoi") for part in rel.parts):
            continue
        if rel.name in SKIP_NAMES:
            continue
        if p.suffix in SKIP_SUFFIXES:
            continue
        out.append(p)
    return out


# ---------------------------------------------------------------------------
# Apply (render + symlink)
# ---------------------------------------------------------------------------


@dataclass
class ApplyResult:
    rendered: list[Path] = field(default_factory=list)
    linked: list[Path] = field(default_factory=list)
    skipped: list[Path] = field(default_factory=list)
    backed_up: list[Path] = field(default_factory=list)
    errors: list[tuple[Path, str]] = field(default_factory=list)


def _symlink(src: Path, dst: Path, force: bool, result: ApplyResult) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.is_symlink():
        try:
            if dst.resolve() == src.resolve():
                result.skipped.append(dst)
                return
        except OSError:
            pass
        dst.unlink()
    elif dst.exists():
        if not force:
            backup = dst.with_name(dst.name + ".bak")
            shutil.move(str(dst), str(backup))
            result.backed_up.append(backup)
        else:
            if dst.is_dir():
                shutil.rmtree(dst)
            else:
                dst.unlink()
    dst.symlink_to(src)
    result.linked.append(dst)


def apply(dry_run: bool, force: bool) -> int:
    data = load_machine_data(interactive=not dry_run)
    result = ApplyResult()
    if not dry_run:
        RENDER_DIR.mkdir(parents=True, exist_ok=True)

    for src in iter_sources():
        rel = src.relative_to(HOME_SRC)
        is_tmpl = src.suffix == ".tmpl"
        rel_final = rel.with_suffix("") if is_tmpl else rel
        dst = target_path(rel_final)

        if is_tmpl:
            try:
                content = render(src.read_text(), data)
            except TemplateError as e:
                result.errors.append((src, str(e)))
                error(f"render failed: {rel}: {e}")
                continue
            link_src = RENDER_DIR / rel_final
            if dry_run:
                info(f"would render {rel} -> {link_src}")
            else:
                link_src.parent.mkdir(parents=True, exist_ok=True)
                link_src.write_text(content)
                result.rendered.append(link_src)
        else:
            link_src = src

        if dry_run:
            info(f"would link {dst} -> {link_src}")
            continue
        _symlink(link_src, dst, force=force, result=result)

    banner(
        f"rendered {len(result.rendered)}, linked {len(result.linked)}, "
        f"skipped {len(result.skipped)}, backed up {len(result.backed_up)}, "
        f"errors {len(result.errors)}"
    )
    for path in result.backed_up:
        warn(f"existing file saved as {path}")
    return 1 if result.errors else 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Render .tmpl dotfiles and deploy them via symlinks into $HOME."
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_apply = sub.add_parser("apply", help="Render templates and create symlinks")
    p_apply.add_argument("--dry-run", action="store_true", help="Show actions without modifying disk")
    p_apply.add_argument("--force", action="store_true", help="Overwrite existing regular files without backup")

    p_render = sub.add_parser("render", help="Render a single template to stdout")
    p_render.add_argument("template", type=Path)

    args = parser.parse_args()
    if args.cmd == "apply":
        return apply(dry_run=args.dry_run, force=args.force)
    if args.cmd == "render":
        data = load_machine_data(interactive=False)
        sys.stdout.write(render(args.template.read_text(), data))
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
