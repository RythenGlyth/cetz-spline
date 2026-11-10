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

TMP_PDF="$(mktemp --suffix=.pdf)"
trap 'rm -f "$TMP_PDF"' EXIT

echo -e "${BLUE}==>${NC} Running cetz-spline test suite..."

FAILURES=0

run_test() {
  local target="$1"
  local name="$(basename "$target")"
  printf "  Testing %-35s ... " "$name"
  if typst compile --root . "$target" "$TMP_PDF" > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
  else
    echo -e "${RED}FAIL${NC}"
    typst compile --root . "$target" "$TMP_PDF" || true
    FAILURES=$((FAILURES + 1))
  fi
}

# Run all test typst files
for test_file in tests/*.typ; do
  if [[ -f "$test_file" ]]; then
    run_test "$test_file"
  fi
done

# Compile manual to ensure documentation examples never break
run_test "manual.typ"

if [[ $FAILURES -eq 0 ]]; then
  echo -e "${GREEN}==>${NC} All tests and documentation examples passed successfully!"
  exit 0
else
  echo -e "${RED}==>${NC} $FAILURES test(s) failed."
  exit 1
fi
