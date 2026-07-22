#!/usr/bin/env bash
# Run the aowljson test suite with the Nimony compiler.
# Override the compiler with NIMONY=/path/to/nimony.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIMONY="${NIMONY:-$HOME/nimony/bin/nimony}"
cd "$ROOT"
"$NIMONY" c -r --path:"$ROOT/src" tests/tjson.nim
