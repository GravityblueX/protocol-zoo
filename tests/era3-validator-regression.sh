#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/protocol-zoo-era3-validator.XXXXXX")
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

mkdir -p "$TMP/repo/scripts"
cp "$ROOT/scripts/era3-validate.sh" "$TMP/repo/scripts/era3-validate.sh"

# Reproduce the old false-positive shape: packet/text artifacts could remain,
# but one evidence descriptor could disappear and the discovery loop would
# simply validate the six records it still found.
for descriptor in \
  era3-dns \
  era3-http \
  era3-tls \
  era3-tunnels \
  era3-proxy \
  era3-pmtud
do
  mkdir -p "$TMP/repo/captures/$descriptor"
  printf '{}\n' > "$TMP/repo/captures/$descriptor/evidence.json"
done

if output=$(sh "$TMP/repo/scripts/era3-validate.sh" 2>&1); then
  echo 'Era 3 validator accepted a missing traceroute descriptor' >&2
  exit 1
fi

printf '%s\n' "$output" | grep -Fq \
  'missing Era 3 evidence descriptor: captures/era3-traceroute/evidence.json'
printf 'Era 3 missing-descriptor regression: pass\n'
