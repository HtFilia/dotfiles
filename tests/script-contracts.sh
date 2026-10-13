#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 "$ROOT/tests/regressions.py"
python3 "$ROOT/tests/install-tools.py"
exec python3 "$ROOT/tests/selection-guides.py"
