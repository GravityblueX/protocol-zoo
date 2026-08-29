#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"
for f in captures/fixtures/era2/*; do [ -s "$f" ] || { echo "empty fixture: $f" >&2; exit 1; }; done
for f in research/second-era-natural-history.md research/pre-ip-ncp.md research/era2-sources.md research/era2-experiment-matrix.md docs/ERA2-STATUS.md; do [ -s "$f" ] || exit 1; done
grep -q 'M10' ROADMAP.md
grep -q 'evidence_level' species/_template/README.md
grep -q 'M19' IMPLEMENTATION_PLAN.md
awk -F, 'NR==1 {n=NF; next} NF!=n {exit 1}' datasets/era2.csv
for f in captures/fixtures/era2/*; do [ -s "$f" ] || exit 1; done
echo 'second-era validation: pass'
