#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/protocol-zoo-kali-wrappers.XXXXXX")
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

FIXTURE=$TMP/repo
BIN=$TMP/bin
KEYDIR=$TMP/key
EFFECT_LOG=$TMP/effects.log
mkdir -p "$FIXTURE/scripts/lib" "$FIXTURE/scripts/guest" \
  "$FIXTURE/schemas" "$FIXTURE/captures" "$BIN" "$KEYDIR" "$TMP/caller"
cp "$ROOT/scripts/kali-sctp-capture.sh" \
  "$ROOT/scripts/kali-remaining-capture.sh" \
  "$ROOT/scripts/experiment.sh" "$FIXTURE/scripts/"
cp "$ROOT/scripts/lib/capture-path.sh" "$FIXTURE/scripts/lib/"
cp "$ROOT/scripts/guest/sctp.sh" "$ROOT/scripts/guest/remaining.sh" \
  "$FIXTURE/scripts/guest/"
cp "$ROOT/schemas/experiment.schema.json" "$FIXTURE/schemas/"
printf 'test key\n' >"$KEYDIR/id_ed25519"
FIXTURE=$(CDPATH='' cd -- "$FIXTURE" && pwd -P)
SH_BIN=${PZ_TEST_SHELL:-$(command -v sh)}
PYTHON_BIN=${PZ_TEST_PYTHON:-$(command -v python || command -v python3)}
REAL_MV=$(command -v mv)

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$BIN/python3" <<'EOF'
#!/bin/sh
exec "${PZ_TEST_PYTHON:?}" "$@"
EOF

cat >"$BIN/ssh" <<'EOF'
#!/bin/sh
printf 'ssh|%s\n' "$*" >>"${PZ_EFFECT_LOG:?}"
[ "${PZ_FAIL_SSH-}" != 1 ] || exit 71
exit 0
EOF

cat >"$BIN/mv" <<'EOF'
#!/bin/sh
count_file=${PZ_MV_COUNT_FILE:?}
count=0
[ ! -f "$count_file" ] || count=$(cat "$count_file")
count=$((count + 1))
printf '%s\n' "$count" >"$count_file"
[ "${PZ_FAIL_MV_CALL-}" != "$count" ] || exit 75
exec "${PZ_REAL_MV:?}" "$@"
EOF

cat >"$BIN/scp" <<'EOF'
#!/bin/sh
printf 'scp|%s\n' "$*" >>"${PZ_EFFECT_LOG:?}"
count_file=${PZ_SCP_COUNT_FILE:?}
count=0
[ ! -f "$count_file" ] || count=$(cat "$count_file")
count=$((count + 1))
printf '%s\n' "$count" >"$count_file"
[ "${PZ_FAIL_SCP_CALL-}" != "$count" ] || exit 72

source_path=
destination=
for argument do
  destination=$argument
  case "$argument" in root@*:*) source_path=$argument ;; esac
done
remote_file=${source_path##*/}

materialize() {
  shape=$1
  destination=$2
  case "$shape" in
    file) printf 'packet evidence\n' >"$destination" ;;
    empty) : >"$destination" ;;
    missing) ;;
    directory) mkdir -p "$destination" ;;
    link)
      printf 'outside evidence\n' >"${PZ_OUTSIDE_FILE:?}"
      ln -s "$PZ_OUTSIDE_FILE" "$destination"
      ;;
    *) printf 'unknown mock artifact shape: %s\n' "$shape" >&2; exit 73 ;;
  esac
}

case "$remote_file" in
  pz-sctp.pcap)
    materialize "${PZ_SCTP_PCAP_SHAPE:-file}" "$destination"
    ;;
  pz-sctp.json)
    case "${PZ_SCTP_JSON_SHAPE:-valid}" in
      valid)
        cat >"$destination" <<'JSON'
{"protocol":"sctp","experiment":"phase-6-sctp-netns-kali","evidence_level":"real-capture","environment":{"os":"kali","kernel":"test","topology":"nested-netns-veth"},"capture_point":"pz-b:pz-veth-b","command":"/root/pz-sctp.sh","capture_filter":"sctp port 19090","result":{"handshake":"pass","capture":"/root/pz-sctp.pcap","frames":1,"future_field":"preserved"},"sanitized":true,"notes":[]}
JSON
        ;;
      empty) : >"$destination" ;;
      whitespace) printf '  \n' >"$destination" ;;
      missing) ;;
      directory) mkdir -p "$destination" ;;
      link)
        printf '{}\n' >"${PZ_OUTSIDE_FILE:?}"
        ln -s "$PZ_OUTSIDE_FILE" "$destination"
        ;;
      null) printf 'null\n' >"$destination" ;;
      array) printf '[]\n' >"$destination" ;;
      scalar) printf '1\n' >"$destination" ;;
      missing-result) printf '{"protocol":"sctp"}\n' >"$destination" ;;
      schema-missing) printf '{"result":{}}\n' >"$destination" ;;
      null-result) printf '{"result":null}\n' >"$destination" ;;
      array-result) printf '{"result":[]}\n' >"$destination" ;;
      malformed) printf '{"result":\n' >"$destination" ;;
      multiple) printf '{"result":{}}\n{"result":{}}\n' >"$destination" ;;
      *) exit 74 ;;
    esac
    ;;
  udplite.pcapng)
    materialize "${PZ_UDPLITE_SHAPE:-file}" "$destination"
    ;;
  gre.pcapng)
    materialize "${PZ_GRE_SHAPE:-file}" "$destination"
    ;;
  ipip.pcapng)
    materialize "${PZ_IPIP_SHAPE:-file}" "$destination"
    ;;
esac
EOF

if [ -n "${PZ_REAL_JQ-}" ]; then
  cp "$PZ_REAL_JQ" "$BIN/jq"
else
cat >"$BIN/jq" <<'PY'
#!/usr/bin/env python3
import json
import os
import shlex
import subprocess
import sys

args = sys.argv[1:]

def option(name):
    index = args.index(name)
    return args[index + 1]

try:
    if "-nr" in args:
        print(" ".join(shlex.quote(value) for value in [
            "scripts/kali-sctp-capture.sh", option("target")
        ]))
        raise SystemExit(0)

    capture = option("capture")
    command = option("command")
    source = args[-1]
    if os.name == "nt" and source.startswith("/"):
        source = subprocess.check_output(
            ["cygpath", "-w", source]
        ).decode("utf-8").strip()
    text = open(source, encoding="utf-8").read()
    decoder = json.JSONDecoder()
    values = []
    offset = 0
    while True:
        while offset < len(text) and text[offset].isspace():
            offset += 1
        if offset == len(text):
            break
        value, offset = decoder.raw_decode(text, offset)
        values.append(value)
    if len(values) != 1 or not isinstance(values[0], dict):
        raise ValueError("expected exactly one root object")
    result = values[0].get("result")
    if not isinstance(result, dict):
        raise ValueError("expected object result")
    result["capture"] = capture
    values[0]["command"] = command
    json.dump(values[0], sys.stdout, ensure_ascii=False)
    print()
except (KeyError, ValueError, json.JSONDecodeError) as error:
    print(error, file=sys.stderr)
    raise SystemExit(1)
PY
fi

cat >"$BIN/jsonschema" <<'PY'
#!/usr/bin/env python3
import json
import os
import subprocess
import sys
from jsonschema import Draft202012Validator

args = sys.argv[1:]
if len(args) != 3 or args[0] != "-i":
    raise SystemExit(64)
def native(path):
    if os.name == "nt" and path.startswith("/"):
        return subprocess.check_output(["cygpath", "-w", path]).decode("utf-8").strip()
    return path

instance = json.load(open(native(args[1]), encoding="utf-8"))
schema = json.load(open(native(args[2]), encoding="utf-8"))
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema).validate(instance)
PY
chmod +x "$BIN/python3" "$BIN/ssh" "$BIN/scp" "$BIN/mv" "$BIN/jq" \
  "$BIN/jsonschema" \
  2>/dev/null || true

run_wrapper() {
  (
  cd "$TMP/caller"
  PZ_EFFECT_LOG=$EFFECT_LOG \
  PZ_SCP_COUNT_FILE=$TMP/scp-count \
  PZ_MV_COUNT_FILE=$TMP/mv-count \
  PZ_OUTSIDE_FILE=$TMP/outside-file \
  PZ_TEST_PYTHON=$PYTHON_BIN \
  PZ_REAL_MV=$REAL_MV \
  PZ_KALI_KEYDIR=$KEYDIR \
  PZ_KALI_HOST=203.0.113.77 \
  PZ_FAIL_SSH=${PZ_FAIL_SSH-} \
  PZ_FAIL_SCP_CALL=${PZ_FAIL_SCP_CALL-} \
  PZ_FAIL_MV_CALL=${PZ_FAIL_MV_CALL-} \
  PZ_SCTP_PCAP_SHAPE=${PZ_SCTP_PCAP_SHAPE-} \
  PZ_SCTP_JSON_SHAPE=${PZ_SCTP_JSON_SHAPE-} \
  PZ_UDPLITE_SHAPE=${PZ_UDPLITE_SHAPE-} \
  PZ_GRE_SHAPE=${PZ_GRE_SHAPE-} \
  PZ_IPIP_SHAPE=${PZ_IPIP_SHAPE-} \
  PATH="$BIN:$PATH" \
  "$SH_BIN" "$@"
  )
}

assert_clean_failure() {
  target=$1
  shift
  rm -rf "$FIXTURE/${target:?}"
  : >"$EFFECT_LOG"
  rm -f "$TMP/scp-count"
  rm -f "$TMP/mv-count"
  mkdir -p "$FIXTURE/$target"
  printf 'old final\n' >"$FIXTURE/$target/old.keep"
  if run_wrapper "$@" "$target" >"$TMP/output" 2>&1; then
    fail "$* accepted a failing artifact scenario"
  fi
  [ -f "$FIXTURE/$target/old.keep" ] || fail "$* damaged an old final"
  [ "$(find "$FIXTURE/$target" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ] || {
    find "$FIXTURE/$target" -mindepth 1 -maxdepth 1 >&2
    fail "$* left staged or partial artifacts"
  }
}

# Direct wrappers accept zero or one destination. Empty is not the default,
# and argument validation happens before any network command.
for script in kali-sctp-capture.sh kali-remaining-capture.sh; do
  : >"$EFFECT_LOG"
  if run_wrapper "$FIXTURE/scripts/$script" '' >"$TMP/output" 2>&1; then
    fail "$script accepted an explicit empty destination"
  fi
  grep -Fq 'path is empty' "$TMP/output" || fail "$script hid the empty-path error"
  [ ! -s "$EFFECT_LOG" ] || fail "$script reached the network for an empty path"
  if run_wrapper "$FIXTURE/scripts/$script" captures/a captures/b \
    >"$TMP/output" 2>&1; then
    fail "$script accepted more than one destination"
  fi
  [ ! -s "$EFFECT_LOG" ] || fail "$script reached the network with extra arguments"
done

# experiment.sh must preserve omitted-versus-explicit-empty behavior instead
# of turning an empty second argument into the default destination.
for action in sctp remaining; do
  : >"$EFFECT_LOG"
  if run_wrapper "$FIXTURE/scripts/experiment.sh" "$action" '' \
    >"$TMP/output" 2>&1; then
    fail "experiment.sh $action accepted an explicit empty destination"
  fi
  grep -Fq 'path is empty' "$TMP/output" || \
    fail "experiment.sh $action did not forward its explicit empty destination"
  [ ! -s "$EFFECT_LOG" ] || \
    fail "experiment.sh $action reached the network for an empty path"
  if run_wrapper "$FIXTURE/scripts/experiment.sh" "$action" captures/a extra \
    >"$TMP/output" 2>&1; then
    fail "experiment.sh $action accepted extra arguments"
  fi
  [ ! -s "$EFFECT_LOG" ] || \
    fail "experiment.sh $action reached the network with extra arguments"
done

# Every remote operation can fail without publishing a final artifact.
for call in 1 2 3; do
  PZ_FAIL_SCP_CALL=$call assert_clean_failure \
    "captures/fail-sctp-scp-$call" \
    "$FIXTURE/scripts/kali-sctp-capture.sh"
done
PZ_FAIL_SSH=1 assert_clean_failure captures/fail-sctp-ssh \
  "$FIXTURE/scripts/kali-sctp-capture.sh"
for call in 1 2 3 4; do
  PZ_FAIL_SCP_CALL=$call assert_clean_failure \
    "captures/fail-remaining-scp-$call" \
    "$FIXTURE/scripts/kali-remaining-capture.sh"
done
PZ_FAIL_SSH=1 assert_clean_failure captures/fail-remaining-ssh \
  "$FIXTURE/scripts/kali-remaining-capture.sh"
for call in 1 2; do
  PZ_FAIL_MV_CALL=$call assert_clean_failure \
    "captures/fail-sctp-mv-$call" \
    "$FIXTURE/scripts/kali-sctp-capture.sh"
done
for call in 1 2 3; do
  PZ_FAIL_MV_CALL=$call assert_clean_failure \
    "captures/fail-remaining-mv-$call" \
    "$FIXTURE/scripts/kali-remaining-capture.sh"
done

# A mid-publication failure restores an older complete set, not a mixture.
target=captures/sctp-rollback
mkdir -p "$FIXTURE/$target"
printf 'old pcap\n' >"$FIXTURE/$target/sctp.pcap"
printf 'old json\n' >"$FIXTURE/$target/sctp.json"
rm -f "$TMP/scp-count" "$TMP/mv-count"
if PZ_FAIL_MV_CALL=4 run_wrapper "$FIXTURE/scripts/kali-sctp-capture.sh" \
  "$target" >"$TMP/output" 2>&1; then
  fail 'SCTP accepted a failed second publication move'
fi
if [ "$(cat "$FIXTURE/$target/sctp.pcap")" != 'old pcap' ] || \
  [ "$(cat "$FIXTURE/$target/sctp.json")" != 'old json' ]; then
  fail 'SCTP rollback did not restore the old artifact pair'
fi
[ "$(find "$FIXTURE/$target" -mindepth 1 -maxdepth 1 | wc -l)" -eq 2 ] || \
  fail 'SCTP rollback left staging artifacts'

# Successful transfers that produce anything other than a nonempty regular
# file fail closed. Symlinks run where the platform supports them.
for shape in missing empty directory; do
  PZ_SCTP_PCAP_SHAPE=$shape assert_clean_failure \
    "captures/sctp-pcap-$shape" "$FIXTURE/scripts/kali-sctp-capture.sh"
done
if ln -s "$TMP/outside-file" "$TMP/link-probe" 2>/dev/null && \
  [ -L "$TMP/link-probe" ]; then
  rm -f "$TMP/link-probe"
  PZ_SCTP_PCAP_SHAPE='link' assert_clean_failure captures/sctp-pcap-link \
    "$FIXTURE/scripts/kali-sctp-capture.sh"
  PZ_SCTP_JSON_SHAPE='link' assert_clean_failure captures/sctp-json-link \
    "$FIXTURE/scripts/kali-sctp-capture.sh"
  for protocol in udplite gre ipip; do
    case "$protocol" in
      udplite) PZ_UDPLITE_SHAPE='link' ;;
      gre) PZ_GRE_SHAPE='link' ;;
      ipip) PZ_IPIP_SHAPE='link' ;;
    esac
    export PZ_UDPLITE_SHAPE PZ_GRE_SHAPE PZ_IPIP_SHAPE
    assert_clean_failure "captures/remaining-$protocol-link" \
      "$FIXTURE/scripts/kali-remaining-capture.sh"
    unset PZ_UDPLITE_SHAPE PZ_GRE_SHAPE PZ_IPIP_SHAPE
  done
else
  printf 'SKIP: Kali staged symlink regressions (platform cannot create symlinks)\n'
fi
for shape in empty whitespace missing directory null array scalar missing-result \
  schema-missing null-result array-result malformed multiple; do
  PZ_SCTP_JSON_SHAPE=$shape assert_clean_failure \
    "captures/sctp-json-$shape" "$FIXTURE/scripts/kali-sctp-capture.sh"
done
for protocol in udplite gre ipip; do
  for shape in missing empty directory; do
    case "$protocol" in
      udplite) PZ_UDPLITE_SHAPE=$shape ;;
      gre) PZ_GRE_SHAPE=$shape ;;
      ipip) PZ_IPIP_SHAPE=$shape ;;
    esac
    export PZ_UDPLITE_SHAPE PZ_GRE_SHAPE PZ_IPIP_SHAPE
    assert_clean_failure "captures/remaining-$protocol-$shape" \
      "$FIXTURE/scripts/kali-remaining-capture.sh"
    unset PZ_UDPLITE_SHAPE PZ_GRE_SHAPE PZ_IPIP_SHAPE
  done
done

# One deliberately hostile but legal repository path checks jq @sh quoting.
# Replaying the recorded command must deliver one literal argument and must
# not execute the embedded command substitution, semicolon or glob.
quoted_target="captures/quote space 'semi;\$(touch PZ_QUOTE_EXECUTED)' *?[x]"
: >"$EFFECT_LOG"
rm -f "$TMP/scp-count"
run_wrapper "$FIXTURE/scripts/kali-sctp-capture.sh" "$quoted_target" || {
  cat "$EFFECT_LOG" >&2
  fail 'valid SCTP artifacts were rejected'
}
sctp_json=$FIXTURE/$quoted_target/sctp.json
sctp_json_native=$sctp_json
if command -v cygpath >/dev/null 2>&1; then
  sctp_json_native=$(cygpath -w "$sctp_json")
fi
if [ ! -s "$FIXTURE/$quoted_target/sctp.pcap" ] || [ ! -s "$sctp_json" ]; then
  fail 'successful SCTP run did not publish both artifacts'
fi
! grep -Fq '172.31.250.195' "$EFFECT_LOG" || fail 'SCTP ignored PZ_KALI_HOST'
[ "$(grep -c 'root@203.0.113.77' "$EFFECT_LOG")" -eq 4 ] || \
  fail 'not every SCTP ssh/scp operation used PZ_KALI_HOST'
[ ! -e "$TMP/caller/captures" ] || \
  fail 'Kali wrapper wrote captures under the caller CWD'
"$PYTHON_BIN" - "$sctp_json_native" "$quoted_target" <<'PY'
import json
import sys
value = json.load(open(sys.argv[1], encoding="utf-8"))
assert value["result"]["capture"] == sys.argv[2] + "/sctp.pcap"
assert value["result"]["future_field"] == "preserved"
assert value["command"]
PY
REPLAY=$TMP/replay
mkdir -p "$REPLAY/scripts"
cat >"$REPLAY/scripts/kali-sctp-capture.sh" <<'EOF'
#!/bin/sh
printf '%s\n' "$#" >"${PZ_ARGV_LOG:?}"
for argument do printf '%s\n' "$argument" >>"$PZ_ARGV_LOG"; done
EOF
chmod +x "$REPLAY/scripts/kali-sctp-capture.sh" 2>/dev/null || true
command_value=$("$PYTHON_BIN" -c \
  'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["command"])' \
  "$sctp_json_native")
(
  cd "$REPLAY"
  PZ_ARGV_LOG=$TMP/argv "$SH_BIN" -c "$command_value"
)
[ "$(sed -n '1p' "$TMP/argv")" = 1 ] || fail 'quoted command changed argv count'
[ "$(sed -n '2p' "$TMP/argv")" = "$quoted_target" ] || \
  fail 'quoted command did not round-trip its target'
[ ! -e "$REPLAY/PZ_QUOTE_EXECUTED" ] || \
  fail 'quoted command executed target contents'

# The default remains stable, every remote call honors the host override, and
# remaining publishes all three captures only after validating the set.
: >"$EFFECT_LOG"
rm -f "$TMP/scp-count"
run_wrapper "$FIXTURE/scripts/kali-sctp-capture.sh" || {
  cat "$EFFECT_LOG" >&2
  fail 'default SCTP artifacts were rejected'
}
default_command=$("$PYTHON_BIN" -c \
  'import json,sys; print(json.load(open(sys.argv[1]))["command"])' \
  "$FIXTURE/captures/kali-sctp/sctp.json")
[ "$default_command" = scripts/kali-sctp-capture.sh ] || \
  fail 'default SCTP command changed'
rm -rf "$FIXTURE/captures/kali-sctp"
rm -f "$TMP/scp-count"
run_wrapper "$FIXTURE/scripts/experiment.sh" sctp || {
  cat "$EFFECT_LOG" >&2
  fail 'experiment.sh rejected default SCTP artifacts'
}
[ -s "$FIXTURE/captures/kali-sctp/sctp.json" ] || \
  fail 'experiment.sh sctp did not preserve the omitted default'
: >"$EFFECT_LOG"
rm -f "$TMP/scp-count"
run_wrapper "$FIXTURE/scripts/kali-remaining-capture.sh" captures/remaining-ok || {
  cat "$EFFECT_LOG" >&2
  fail 'valid remaining artifacts were rejected'
}
for file in udplite gre ipip; do
  [ -s "$FIXTURE/captures/remaining-ok/$file.pcapng" ] || \
    fail "remaining did not publish $file"
done
! grep -Fq '172.31.250.195' "$EFFECT_LOG" || \
  fail 'remaining ignored PZ_KALI_HOST'
[ "$(grep -c 'root@203.0.113.77' "$EFFECT_LOG")" -eq 5 ] || \
  fail 'not every remaining ssh/scp operation used PZ_KALI_HOST'
rm -rf "$FIXTURE/captures/kali-remaining"
rm -f "$TMP/scp-count"
run_wrapper "$FIXTURE/scripts/experiment.sh" remaining || {
  cat "$EFFECT_LOG" >&2
  fail 'experiment.sh rejected default remaining artifacts'
}
for file in udplite gre ipip; do
  [ -s "$FIXTURE/captures/kali-remaining/$file.pcapng" ] || \
    fail "experiment.sh remaining did not publish $file"
done

printf 'Kali capture wrapper regressions: pass (%s)\n' "$SH_BIN"
