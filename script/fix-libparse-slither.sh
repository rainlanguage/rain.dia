#!/usr/bin/env bash
# Slither 0.11+ rejects //slither-disable-start/end pairs in pinned rain.interpreter.
# Apply upstream fix (next-line on parseRHS) until the submodule is bumped.
set -euo pipefail

f="${1:-lib/rain.interpreter/src/lib/parse/LibParse.sol}"

if [[ ! -f "$f" ]] || ! grep -q 'slither-disable-start cyclomatic-complexity' "$f"; then
  exit 0
fi

perl -0777 -i -pe '
  s/    \/\/slither-disable-start cyclomatic-complexity\n    \/\/forge-lint: disable-next-line\(mixed-case-function\)\n/    \/\/forge-lint: disable-next-line(mixed-case-function)\n    \/\/slither-disable-next-line cyclomatic-complexity\n/s;
  s/\n    \/\/slither-disable-end\n/\n/s;
' "$f"
