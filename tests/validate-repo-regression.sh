#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/protocol-zoo-repo-validator.XXXXXX")
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

mkdir -p "$TMP/repo/scripts" "$TMP/bin"
cp "$ROOT/scripts/validate-repo.sh" "$TMP/repo/scripts/validate-repo.sh"

SH=$(command -v sh)
SYSTEM_GREP=$(command -v grep)

# The single-quoted payload defers expansion to the generated mock.
# shellcheck disable=SC2016
printf '%s\n' \
  '#!/bin/sh' \
  'if [ "$1" = -- ]; then shift; fi' \
  'case "$1" in */*) printf "%s\n" "${1%/*}" ;; *) printf ".\n" ;; esac' \
  > "$TMP/bin/dirname"
# shellcheck disable=SC2016
printf '%s\n' \
  '#!/bin/sh' \
  'case "$*" in' \
  '  *result.handshake*) printf "pass\n" ;;' \
  '  *sanitized*) printf "true\n" ;;' \
  'esac' \
  > "$TMP/bin/jq"
printf '#!/bin/sh\nexit 0\n' > "$TMP/bin/jsonschema"
printf '#!/bin/sh\nexit 0\n' > "$TMP/bin/git"
chmod +x "$TMP/bin/dirname" "$TMP/bin/jq" "$TMP/bin/jsonschema" \
  "$TMP/bin/git"

run_validator() {
  PATH="$TMP/bin" "$SH" "$TMP/repo/scripts/validate-repo.sh" 2>&1
}

# A missing iproute2 client cannot establish that cleanup succeeded.
if output=$(run_validator); then
  echo 'repository validator accepted a missing ip command' >&2
  exit 1
fi
printf '%s\n' "$output" | "$SYSTEM_GREP" -Fq 'missing required command: ip'

# Finding an executable is insufficient when the namespace query itself fails.
printf '#!/bin/sh\nexit 42\n' > "$TMP/bin/ip"
chmod +x "$TMP/bin/ip"
if output=$(run_validator); then
  echo 'repository validator accepted a failed namespace inspection' >&2
  exit 1
fi
printf '%s\n' "$output" | "$SYSTEM_GREP" -Fq \
  'unable to inspect namespace cleanup'

# Both an empty query and a query containing only unrelated namespaces are clean.
# These success cases also pin the exact iproute2 subcommand under validation.
# shellcheck disable=SC2016
printf '%s\n' \
  '#!/bin/sh' \
  '[ "$#" -eq 2 ] && [ "$1" = netns ] && [ "$2" = list ] || exit 64' \
  > "$TMP/bin/ip"
if ! output=$(run_validator); then
  printf '%s\n' "$output" >&2
  echo 'repository validator rejected an empty namespace list' >&2
  exit 1
fi
printf '%s\n' "$output" | "$SYSTEM_GREP" -Fq \
  'protocol-zoo validation: pass'

# shellcheck disable=SC2016
printf '%s\n' \
  '#!/bin/sh' \
  '[ "$#" -eq 2 ] && [ "$1" = netns ] && [ "$2" = list ] || exit 64' \
  'printf "other-ns (id: 1)\n"' \
  > "$TMP/bin/ip"
if ! output=$(run_validator); then
  printf '%s\n' "$output" >&2
  echo 'repository validator rejected a clean namespace list' >&2
  exit 1
fi
printf '%s\n' "$output" | "$SYSTEM_GREP" -Fq \
  'protocol-zoo validation: pass'

# Any Protocol Zoo namespace at the start of an output line is residue.
# shellcheck disable=SC2016
printf '%s\n' \
  '#!/bin/sh' \
  '[ "$#" -eq 2 ] && [ "$1" = netns ] && [ "$2" = list ] || exit 64' \
  'printf "other-ns (id: 1)\npz-regression (id: 2)\n"' \
  > "$TMP/bin/ip"
if output=$(run_validator); then
  echo 'repository validator accepted Protocol Zoo namespace residue' >&2
  exit 1
fi
printf '%s\n' "$output" | "$SYSTEM_GREP" -Fq 'namespace residue'

printf 'repository validator regressions: pass\n'
