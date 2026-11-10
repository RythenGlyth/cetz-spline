#!/usr/bin/env bash
# cetz-spline test runner script
set -euo pipefail

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d)"
TMP_PDF="$TMP_DIR/test.pdf"
trap 'rm -rf "$TMP_DIR"' EXIT

echo -e "${BLUE}==>${NC} Running cetz-spline test suite..."

FAILURES=0

run_test() {
  local target="$1"
  local name="$(basename "$target")"
  printf "  Testing %-35s ... " "$name"
  if typst compile --root . "$target" "$TMP_PDF" > "$TMP_DIR/diagnostics" 2>&1; then
    echo -e "${GREEN}PASS${NC}"
  else
    echo -e "${RED}FAIL${NC}"
    cat "$TMP_DIR/diagnostics"
    FAILURES=$((FAILURES + 1))
  fi
}

# Run all test typst files
for test_file in tests/*.typ; do
  if [[ -f "$test_file" ]]; then
    run_test "$test_file"
  fi
done

# Rejected input is part of the API contract. Check the intended diagnostic,
# so a parser error or unrelated failure cannot accidentally pass these tests.
while IFS='|' read -r case expected; do
  printf "  Rejecting %-33s ... " "$case"
  if typst compile --root . --input "case=$case" tests/invalid/input.typ "$TMP_PDF" > "$TMP_DIR/diagnostics" 2>&1; then
    echo -e "${RED}FAIL (accepted invalid input)${NC}"
    FAILURES=$((FAILURES + 1))
  elif ! grep -Fq "$expected" "$TMP_DIR/diagnostics"; then
    echo -e "${RED}FAIL (wrong diagnostic)${NC}"
    cat "$TMP_DIR/diagnostics"
    FAILURES=$((FAILURES + 1))
  else
    echo -e "${GREEN}PASS${NC}"
  fi
done <<'CASES'
alpha|alpha must be a number in [0, 1]
boundary|boundary must be clamped or natural
points|B-spline requires at least 2 points
degree|degree must be a positive integer
knot-count|Invalid knot vector length
knot-order|Knots must be non-decreasing
knot-domain|Knot domain must have positive length
discontinuous|Discontinuous interior knots are not supported
count|count must be an integer >= 2
lut|samples-per-segment must be a positive integer
mode|Unknown homotopy mode
topology|Homotopy requires matching open/closed topology
CASES

# Verify an installed package with only the runtime/distribution files.
mkdir -p "$TMP_DIR/packages/local/cetz-spline/0.1.0"
cp -R src typst.toml README.md LICENSE-MIT "$TMP_DIR/packages/local/cetz-spline/0.1.0/"
cat > "$TMP_DIR/package-smoke.typ" <<'TYPST'
#import "@local/cetz-spline:0.1.0" as cs
#import "@preview/cetz:0.5.3"
#let sp = cs.spline-catmull(((0, 0), (1, 2), (3, 0)))
#assert(cs.segment-count(sp) == 2)
#cetz.canvas({ cs.draw.spline(sp, mark: (end: ">")) })
TYPST
printf "  Testing %-35s ... " "installed package"
if typst compile --root "$TMP_DIR" --package-path "$TMP_DIR/packages" "$TMP_DIR/package-smoke.typ" "$TMP_PDF" > "$TMP_DIR/diagnostics" 2>&1; then
  echo -e "${GREEN}PASS${NC}"
else
  echo -e "${RED}FAIL${NC}"
  cat "$TMP_DIR/diagnostics"
  FAILURES=$((FAILURES + 1))
fi

# Compile the cover as well as all executable manual examples.
run_test "assets/cover.typ"

# Compile manual to ensure documentation examples never break
run_test "manual.typ"

if [[ $FAILURES -eq 0 ]]; then
  echo -e "${GREEN}==>${NC} All tests and documentation examples passed successfully!"
  exit 0
else
  echo -e "${RED}==>${NC} $FAILURES test(s) failed."
  exit 1
fi
