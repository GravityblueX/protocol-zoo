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
REALPATH_BIN=$(command -v realpath)

if output=$(PATH="$TMP/bin" "$SH" "$TMP/repo/scripts/era3-validate.sh" 2>&1); then
  echo 'Era 3 validator accepted an unverifiable namespace cleanup check' >&2
  exit 1
fi
printf '%s\n' "$output" | grep -Fq 'missing required command: ip'

# `test -s` alone accepts a non-empty directory on Linux. A descriptor must
# name an actual evidence file, not merely a path whose inode has a size.
printf '#!/bin/sh\nexit 0\n' > "$TMP/bin/ip"
printf '%s\n' \
  '#!/bin/sh' \
  'if [ "$1" = -r ] && [ "$2" = ".files[]" ] && [ "${3##*/}" = evidence.json ]; then' \
  '  case "$3" in *era3-dns/*) printf "captures/era3-dns\n" ;; esac' \
  'fi' \
  'exit 0' \
  > "$TMP/bin/jq"
chmod +x "$TMP/bin/jq"

if output=$(PATH="$TMP/bin:$PATH" "$SH" "$TMP/repo/scripts/era3-validate.sh" 2>&1); then
  echo 'Era 3 validator accepted a directory as an evidence file' >&2
  exit 1
fi
printf '%s\n' "$output" | grep -Fq \
  'empty or non-regular declared evidence: captures/era3-dns'

# Lexical `..`/absolute-path checks do not catch a repository path that is a
# symlink to an external file. Resolve the path before checking containment.
printf 'outside fixture\n' > "$TMP/outside-evidence"
link_path="$TMP/repo/captures/era3-dns/external-evidence"
printf '%s\n' \
  '#!/bin/sh' \
  'if [ "$1" = -r ] && [ "$2" = ".files[]" ] && [ "${3##*/}" = evidence.json ]; then' \
  '  case "$3" in *era3-dns/*) printf "captures/era3-dns/external-evidence\n" ;; esac' \
  'fi' \
  'exit 0' \
  > "$TMP/bin/jq"
chmod +x "$TMP/bin/jq"

if ln -s "$TMP/outside-evidence" "$link_path" 2>/dev/null && [ -L "$link_path" ]; then
  if output=$(PATH="$TMP/bin:$PATH" "$SH" "$TMP/repo/scripts/era3-validate.sh" 2>&1); then
    echo 'Era 3 validator accepted a symlink that escaped the repository' >&2
    exit 1
  fi
  printf '%s\n' "$output" | grep -Fq \
    'evidence path escapes repository: captures/era3-dns/external-evidence'
else
  printf '%s\n' \
    'SKIP: real symlink escape regression (platform cannot create symbolic links)'
fi
rm -f "$link_path"

# Exercise the canonical containment decision on every platform, including
# Git Bash installations where `ln -s` silently creates a regular file.
printf 'inside placeholder\n' \
  > "$TMP/repo/captures/era3-dns/canonical-escape"
printf '%s\n' \
  '#!/bin/sh' \
  'if [ "$1" = -r ] && [ "$2" = ".files[]" ] && [ "${3##*/}" = evidence.json ]; then' \
  '  case "$3" in *era3-dns/*) printf "captures/era3-dns/canonical-escape\n" ;; esac' \
  'fi' \
  'exit 0' \
  > "$TMP/bin/jq"
chmod +x "$TMP/bin/jq"
printf '%s\n' \
  '#!/bin/sh' \
  'if [ "${3-}" = captures/era3-dns/canonical-escape ]; then' \
  '  printf "%s\n" "$REALPATH_OUTSIDE"' \
  'else' \
  '  exec "$REALPATH_BIN" "$@"' \
  'fi' \
  > "$TMP/bin/realpath"
chmod +x "$TMP/bin/realpath"

if output=$(
  REALPATH_BIN="$REALPATH_BIN" \
  REALPATH_OUTSIDE="$TMP/outside-evidence" \
  PATH="$TMP/bin:$PATH" \
  "$SH" "$TMP/repo/scripts/era3-validate.sh" 2>&1
); then
  echo 'Era 3 validator accepted a canonically external evidence path' >&2
  exit 1
fi
printf '%s\n' "$output" | grep -Fq \
  'evidence path escapes repository: captures/era3-dns/canonical-escape'
rm -f "$TMP/bin/realpath"

# Finding an `ip` executable is not enough: a failed namespace query must not
# be mistaken for an empty namespace list by a negated pipeline.
printf '#!/bin/sh\nexit 42\n' > "$TMP/bin/ip"
chmod +x "$TMP/bin/ip"
printf '#!/bin/sh\nexit 0\n' > "$TMP/bin/jq"
chmod +x "$TMP/bin/jq"
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
