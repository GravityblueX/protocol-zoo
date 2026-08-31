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

# A missing iproute2 client used to make `! ip netns list | grep ...` succeed:
# the shell inverted the failed command and treated an unverifiable cleanup
# check as clean. Keep dependency absence fail-closed before semantic checks.
mkdir -p "$TMP/repo/captures/era3-traceroute" "$TMP/bin"
printf '{}\n' > "$TMP/repo/captures/era3-traceroute/evidence.json"
for tool in jq jsonschema; do
  printf '#!/bin/sh\nexit 0\n' > "$TMP/bin/$tool"
  chmod +x "$TMP/bin/$tool"
done
printf '%s\n' \
  '#!/bin/sh' \
  'case " $* " in *" -Y http "*) exit 0 ;; *) printf "1\n" ;; esac' \
  > "$TMP/bin/tshark"
chmod +x "$TMP/bin/tshark"
printf '%s\n' \
  '#!/bin/sh' \
  'if [ "$1" = -- ]; then shift; fi' \
  'case "$1" in */*) printf "%s\n" "${1%/*}" ;; *) printf ".\n" ;; esac' \
  > "$TMP/bin/dirname"
chmod +x "$TMP/bin/dirname"
SH=$(command -v sh)

if output=$(PATH="$TMP/bin" "$SH" "$TMP/repo/scripts/era3-validate.sh" 2>&1); then
  echo 'Era 3 validator accepted an unverifiable namespace cleanup check' >&2
  exit 1
fi
printf '%s\n' "$output" | grep -Fq 'missing required command: ip'

# Finding an `ip` executable is not enough: a failed namespace query must not
# be mistaken for an empty namespace list by a negated pipeline.
printf '#!/bin/sh\nexit 42\n' > "$TMP/bin/ip"
chmod +x "$TMP/bin/ip"
printf 'backend-response\n' > "$TMP/repo/captures/era3-proxy/client.txt"
printf '198.18.230.2\n' > "$TMP/repo/captures/era3-proxy/reverse-proxy.frames.tsv"
printf '198.18.240.1\n' > "$TMP/repo/captures/era3-traceroute/traceroute-udp.txt"
printf '198.18.240.6\n' > "$TMP/repo/captures/era3-traceroute/traceroute-icmp.txt"
mkdir -p "$TMP/repo/docs/era3" "$TMP/repo/data/era3" "$TMP/repo/experiments"
printf 'complete Era 3 note\n' > "$TMP/repo/docs/era3/README.md"
printf 'complete guide\n' > "$TMP/repo/docs/中文导览.md"
printf '{}\n' > "$TMP/repo/data/era3/sample.json"

if output=$(PATH="$TMP/bin:$PATH" "$SH" "$TMP/repo/scripts/era3-validate.sh" 2>&1); then
  echo 'Era 3 validator accepted a failed namespace inspection' >&2
  exit 1
fi
printf '%s\n' "$output" | grep -Fq 'unable to inspect Era 3 namespace cleanup'
printf 'Era 3 validator regressions: pass\n'
