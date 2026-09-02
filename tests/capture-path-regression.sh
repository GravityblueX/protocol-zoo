#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/protocol-zoo-capture-paths.XXXXXX")
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

FIXTURE=$TMP/repo
STUB_BIN=$TMP/bin
EFFECT_LOG=$TMP/effects.log
COMMAND_OUTPUT=$TMP/command.out
ORIGINAL_PATH=$PATH
SH_BIN=$(command -v sh)

mkdir -p "$FIXTURE/scripts/lib" "$FIXTURE/captures" "$STUB_BIN" \
  "$TMP/outside-directory"
FIXTURE=$(CDPATH='' cd -- "$FIXTURE" && pwd -P)
for script in \
  capability-report.sh \
  dummy-capture.sh \
  era2-capture.sh \
  era2-ipv6-capture.sh \
  era2-network-capture.sh \
  era2-ppp-capture.sh \
  era2-rip-capture.sh \
  era2-static-results.sh \
  real-app-capture.sh \
  lab-netns.sh
do
  cp "$ROOT/scripts/$script" "$FIXTURE/scripts/$script"
done
cp "$ROOT/scripts/lib/capture-path.sh" "$FIXTURE/scripts/lib/capture-path.sh"

for tool in \
  mkdir rm sudo ip mktemp jq jsonschema uname tshark tcpdump editcap nc \
  sleep socat chmod chown cmp grep awk cut wc tee cat python3 timeout
do
  {
    printf '%s\n' '#!/bin/sh'
    # The generated stub expands these variables when it runs, not now.
    # shellcheck disable=SC2016
    printf '%s\n' \
      'printf "%s|%s\n" "${0##*/}" "$*" >> "${PZ_EFFECT_LOG:?}"'
    # shellcheck disable=SC2016
    printf '%s\n' \
      'case " ${PZ_STUB_SUCCEED-} " in *" ${0##*/} "*) exit 0 ;; esac'
    printf '%s\n' 'exit 97'
  } >"$STUB_BIN/$tool"
  # Git Bash on Windows may not expose chmod; its filesystem layer still
  # treats shebang scripts as executable.
  chmod +x "$STUB_BIN/$tool" 2>/dev/null || true
done

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_no_effects() {
  [ ! -s "$EFFECT_LOG" ] || {
    printf 'unexpected side effects:\n' >&2
    cat "$EFFECT_LOG" >&2
    fail "$1"
  }
}

assert_rejected_output() {
  grep -Fq 'unsafe ' "$COMMAND_OUTPUT" || {
    cat "$COMMAND_OUTPUT" >&2
    fail "$1 did not report an unsafe capture path"
  }
}

run_rejected_arg() {
  description=$1
  script=$2
  requested=$3
  : >"$EFFECT_LOG"
  : >"$COMMAND_OUTPUT"
  if PZ_EFFECT_LOG=$EFFECT_LOG PATH="$STUB_BIN:$ORIGINAL_PATH" \
    "$SH_BIN" "$FIXTURE/scripts/$script" "$requested" \
    >"$COMMAND_OUTPUT" 2>&1
  then
    fail "$description was accepted"
  fi
  assert_no_effects "$description reached a side-effect command"
  assert_rejected_output "$description"
}

run_rejected_dummy() {
  description=$1
  capture=$2
  result=$3
  : >"$EFFECT_LOG"
  : >"$COMMAND_OUTPUT"
  if CAPTURE=$capture RESULT=$result PZ_EFFECT_LOG=$EFFECT_LOG \
    PATH="$STUB_BIN:$ORIGINAL_PATH" \
    "$SH_BIN" "$FIXTURE/scripts/dummy-capture.sh" \
    >"$COMMAND_OUTPUT" 2>&1
  then
    fail "$description was accepted"
  fi
  assert_no_effects "$description reached a side-effect command"
  assert_rejected_output "$description"
}

assert_reaches_mkdir() {
  description=$1
  first_effect=$(sed -n '1p' "$EFFECT_LOG")
  case "$first_effect" in
    mkdir\|*"$FIXTURE/captures/"*) ;;
    *)
      cat "$EFFECT_LOG" >&2
      fail "$description did not reach an in-captures mkdir after validation"
      ;;
  esac
}

run_valid_arg() {
  description=$1
  script=$2
  requested=$3
  : >"$EFFECT_LOG"
  : >"$COMMAND_OUTPUT"
  if PZ_EFFECT_LOG=$EFFECT_LOG PATH="$STUB_BIN:$ORIGINAL_PATH" \
    "$SH_BIN" "$FIXTURE/scripts/$script" "$requested" \
    >"$COMMAND_OUTPUT" 2>&1
  then
    fail "$description unexpectedly completed past the stopping stub"
  fi
  assert_reaches_mkdir "$description"
}

run_valid_dummy() {
  : >"$EFFECT_LOG"
  : >"$COMMAND_OUTPUT"
  if CAPTURE=captures/valid-dummy/session.pcapng \
    RESULT=captures/valid-dummy/session.json \
    PZ_EFFECT_LOG=$EFFECT_LOG PATH="$STUB_BIN:$ORIGINAL_PATH" \
    "$SH_BIN" "$FIXTURE/scripts/dummy-capture.sh" \
    >"$COMMAND_OUTPUT" 2>&1
  then
    fail 'valid dummy paths unexpectedly completed past the stopping stub'
  fi
  assert_reaches_mkdir 'valid dummy paths'
}

# Every user-controlled destination must reject an absolute path before any
# mkdir/rm/temp/network/tool action. dummy-capture has two independent paths.
run_rejected_arg 'capability absolute path' capability-report.sh /tmp/pz-capability.json
for script in \
  era2-capture.sh \
  era2-ipv6-capture.sh \
  era2-network-capture.sh \
  era2-ppp-capture.sh \
  era2-rip-capture.sh \
  era2-static-results.sh \
  real-app-capture.sh
do
  run_rejected_arg "$script absolute path" "$script" /tmp/pz-output
done
run_rejected_dummy \
  'dummy CAPTURE absolute path' \
  /tmp/pz-dummy.pcapng \
  captures/valid-dummy.json
run_rejected_dummy \
  'dummy RESULT absolute path' \
  captures/valid-dummy.pcapng \
  /tmp/pz-dummy.json
run_rejected_arg \
  'Git Bash drive-letter absolute path' \
  capability-report.sh \
  'C:/outside/pz-capability.json'

# Canonical containment and root/type shape regressions.
run_rejected_arg \
  'parent-directory escape' \
  era2-static-results.sh \
  captures/../../outside
run_rejected_arg \
  'captures root' \
  era2-static-results.sh \
  captures
run_rejected_arg \
  'normalized captures root' \
  era2-static-results.sh \
  captures/.

mkdir -p "$FIXTURE/captures/existing-directory"
printf 'regular file\n' >"$FIXTURE/captures/existing-file"
run_rejected_arg \
  'file output resolving to a directory' \
  capability-report.sh \
  captures/existing-directory
run_rejected_arg \
  'directory output resolving to a file' \
  era2-static-results.sh \
  captures/existing-file
run_rejected_arg \
  'file in a non-directory parent' \
  capability-report.sh \
  captures/existing-file/child.json
run_rejected_dummy \
  'dummy CAPTURE resolving to a directory' \
  captures/existing-directory \
  captures/valid-dummy.json
run_rejected_dummy \
  'dummy RESULT resolving to a directory' \
  captures/valid-dummy.pcapng \
  captures/existing-directory
run_rejected_dummy \
  'dummy outputs resolving to the same file' \
  captures/dummy-overlap \
  captures/dummy-overlap
run_rejected_dummy \
  'dummy CAPTURE containing RESULT' \
  captures/dummy-overlap \
  captures/dummy-overlap/result.json
run_rejected_dummy \
  'dummy RESULT containing CAPTURE' \
  captures/dummy-overlap/session.pcapng \
  captures/dummy-overlap
run_rejected_dummy \
  'dummy case-insensitive alias' \
  captures/CaseAlias \
  captures/casealias
run_rejected_dummy \
  'dummy case-insensitive ancestor alias' \
  captures/CaseTree \
  captures/casetree/result.json

mkdir -p \
  "$FIXTURE/captures/static-child-directory/status.json" \
  "$FIXTURE/captures/real-app-child-symlink"
run_rejected_arg \
  'derived file output resolving to a directory' \
  era2-static-results.sh \
  captures/static-child-directory

printf 'outside file\n' >"$TMP/outside-file"
if ln -s "$TMP/outside-directory" "$FIXTURE/captures/external-directory" \
   2>/dev/null && [ -L "$FIXTURE/captures/external-directory" ]
then
  run_rejected_arg \
    'directory symlink escape' \
    era2-static-results.sh \
    captures/external-directory/nested
else
  printf '%s\n' \
    'SKIP: real directory symlink regression (platform cannot create symlinks)'
fi
if ln -s "$TMP/outside-file" "$FIXTURE/captures/external-file" \
   2>/dev/null && [ -L "$FIXTURE/captures/external-file" ]
then
  run_rejected_arg \
    'file symlink escape' \
    capability-report.sh \
    captures/external-file
else
  printf '%s\n' \
    'SKIP: real file symlink regression (platform cannot create symlinks)'
fi
if ln -s \
     "$TMP/outside-file" \
     "$FIXTURE/captures/real-app-child-symlink/ftp-passive.log" \
     2>/dev/null && \
   [ -L "$FIXTURE/captures/real-app-child-symlink/ftp-passive.log" ]
then
  run_rejected_arg \
    'derived file symlink escape' \
    real-app-capture.sh \
    captures/real-app-child-symlink
else
  printf '%s\n' \
    'SKIP: derived file symlink regression (platform cannot create symlinks)'
fi

# A normal captures/ descendant in every integration must pass the guard and
# reach the first deliberately-stubbed side effect. No real experiment runs.
run_valid_arg \
  'valid capability path' \
  capability-report.sh \
  captures/valid-capability/report.json
for script in \
  era2-capture.sh \
  era2-ipv6-capture.sh \
  era2-network-capture.sh \
  era2-ppp-capture.sh \
  era2-rip-capture.sh \
  era2-static-results.sh \
  real-app-capture.sh
do
  name=${script%.sh}
  run_valid_arg "$script valid path" "$script" "captures/valid-$name/output"
done
run_valid_dummy

run_exact_cleanup() {
  script=$1
  directory=$2
  shift 2

  output_directory=$FIXTURE/captures/$directory
  mkdir -p "$output_directory"
  printf 'must survive cleanup\n' >"$output_directory/unknown.keep"
  expected='rm|-f'
  for basename do
    expected="$expected $output_directory/$basename"
  done

  : >"$EFFECT_LOG"
  : >"$COMMAND_OUTPUT"
  if PZ_STUB_SUCCEED=mkdir PZ_EFFECT_LOG=$EFFECT_LOG \
    PATH="$STUB_BIN:$ORIGINAL_PATH" \
    "$SH_BIN" "$FIXTURE/scripts/$script" "captures/$directory" \
    >"$COMMAND_OUTPUT" 2>&1
  then
    fail "$script unexpectedly completed past the rm stopping stub"
  fi

  rm_count=$(grep -c '^rm|' "$EFFECT_LOG" || true)
  [ "$rm_count" -eq 1 ] || {
    cat "$EFFECT_LOG" >&2
    fail "$script did not call rm exactly once"
  }
  actual=$(grep '^rm|' "$EFFECT_LOG")
  [ "$actual" = "$expected" ] || {
    printf 'expected: %s\nactual:   %s\n' "$expected" "$actual" >&2
    fail "$script cleanup did not use its exact basename allowlist"
  }
  [ -f "$output_directory/unknown.keep" ] || \
    fail "$script removed an unknown output file"
}

run_exact_cleanup \
  era2-capture.sh \
  cleanup-era2-capture \
  boot-chain.pcapng \
  boot-chain.json \
  boot-chain.frames.tsv
run_exact_cleanup \
  era2-ipv6-capture.sh \
  cleanup-ipv6 \
  sit-ipv6-in-ipv4.pcapng \
  sit-ipv6-in-ipv4.frames.tsv \
  sit-ipv6-in-ipv4.json
run_exact_cleanup \
  era2-network-capture.sh \
  cleanup-network \
  icmp-lifecycle.pcapng \
  icmp-lifecycle.frames.tsv \
  icmp-lifecycle.json \
  igmp-membership.pcapng \
  igmp-membership.frames.tsv \
  igmp-membership.json
run_exact_cleanup \
  era2-ppp-capture.sh \
  cleanup-ppp \
  serial-hdlc.txt \
  pppd-a.log \
  pppd-b.log \
  ppp-icmp.pcapng \
  ppp-icmp.frames.tsv \
  ppp.json
run_exact_cleanup \
  era2-rip-capture.sh \
  cleanup-rip \
  rip-convergence.pcapng \
  rip-convergence.frames.tsv \
  rip-convergence.json
run_exact_cleanup \
  era2-static-results.sh \
  cleanup-static \
  status.json
run_exact_cleanup \
  real-app-capture.sh \
  cleanup-real-app \
  telnet.pcapng \
  ftp-passive.log \
  ftp-active.log \
  ftp.pcapng \
  telnet.frames.tsv \
  ftp.frames.tsv

run_exact_file_cleanup() {
  script=$1
  relative_file=$2

  output_file=$FIXTURE/$relative_file
  output_directory=${output_file%/*}
  mkdir -p "$output_directory"
  printf 'must survive cleanup\n' >"$output_directory/unknown.keep"

  : >"$EFFECT_LOG"
  : >"$COMMAND_OUTPUT"
  if PZ_STUB_SUCCEED=mkdir PZ_EFFECT_LOG=$EFFECT_LOG \
    PATH="$STUB_BIN:$ORIGINAL_PATH" \
    "$SH_BIN" "$FIXTURE/scripts/$script" "$relative_file" \
    >"$COMMAND_OUTPUT" 2>&1
  then
    fail "$script unexpectedly completed past the rm stopping stub"
  fi

  expected="rm|-f $output_file"
  actual=$(grep '^rm|' "$EFFECT_LOG")
  [ "$actual" = "$expected" ] || {
    printf 'expected: %s\nactual:   %s\n' "$expected" "$actual" >&2
    fail "$script cleanup did not unlink its exact output file"
  }
  [ -f "$output_directory/unknown.keep" ] || \
    fail "$script removed an unknown output file"
}

run_exact_file_cleanup \
  capability-report.sh \
  captures/cleanup-capability/report.json

run_exact_dummy_cleanup() {
  capture_relative=captures/cleanup-dummy/session.pcapng
  result_relative=captures/cleanup-dummy/session.json
  output_directory=$FIXTURE/captures/cleanup-dummy
  capture_file=$FIXTURE/$capture_relative
  result_file=$FIXTURE/$result_relative

  mkdir -p "$output_directory"
  printf 'old capture\n' >"$capture_file"
  printf 'old result\n' >"$result_file"
  printf 'must survive cleanup\n' >"$output_directory/unknown.keep"

  : >"$EFFECT_LOG"
  : >"$COMMAND_OUTPUT"
  if CAPTURE=$capture_relative RESULT=$result_relative \
    PZ_STUB_SUCCEED=mkdir PZ_EFFECT_LOG=$EFFECT_LOG \
    PATH="$STUB_BIN:$ORIGINAL_PATH" \
    "$SH_BIN" "$FIXTURE/scripts/dummy-capture.sh" \
    >"$COMMAND_OUTPUT" 2>&1
  then
    fail 'dummy-capture.sh unexpectedly completed past the rm stopping stub'
  fi

  rm_count=$(grep -c '^rm|' "$EFFECT_LOG" || true)
  [ "$rm_count" -eq 1 ] || {
    cat "$EFFECT_LOG" >&2
    fail 'dummy-capture.sh did not call rm exactly once'
  }
  expected="rm|-f $capture_file $result_file"
  actual=$(grep '^rm|' "$EFFECT_LOG")
  [ "$actual" = "$expected" ] || {
    printf 'expected: %s\nactual:   %s\n' "$expected" "$actual" >&2
    fail 'dummy-capture.sh cleanup did not unlink both exact outputs'
  }
  [ -f "$output_directory/unknown.keep" ] || \
    fail 'dummy-capture.sh removed an unknown output file'
}

run_exact_dummy_cleanup

# A regular file can be a hard link to an inode outside captures/. Unlinking
# each validated output before writing prevents redirection from modifying the
# external name while preserving unknown files in the selected directory.
HARDLINK_BIN=$TMP/hardlink-bin
mkdir -p "$HARDLINK_BIN"
for tool in uname ip tshark jq jsonschema
do
  {
    printf '%s\n' '#!/bin/sh'
    printf '%s\n' 'printf "generated-output\\n"'
  } >"$HARDLINK_BIN/$tool"
  chmod +x "$HARDLINK_BIN/$tool" 2>/dev/null || true
done

run_hardlink_preservation() {
  description=$1
  script=$2
  requested=$3
  relative_file=$4
  outside=$TMP/$description.outside
  output=$FIXTURE/$relative_file

  mkdir -p "${output%/*}"
  printf 'outside-original\n' >"$outside"
  ln "$outside" "$output" || \
    fail "$description could not create its hard-link fixture"

  PATH="$HARDLINK_BIN:$ORIGINAL_PATH" \
    "$SH_BIN" "$FIXTURE/scripts/$script" "$requested" \
    >"$COMMAND_OUTPUT" 2>&1 || {
      cat "$COMMAND_OUTPUT" >&2
      fail "$description did not complete with stubbed tools"
    }

  [ "$(cat "$outside")" = outside-original ] || \
    fail "$description modified the external hard-link name"
  [ "$(cat "$output")" != outside-original ] || \
    fail "$description did not replace the validated capture output"
}

run_hardlink_preservation \
  hardlink-capability \
  capability-report.sh \
  captures/hardlink-capability/report.json \
  captures/hardlink-capability/report.json
run_hardlink_preservation \
  hardlink-static \
  era2-static-results.sh \
  captures/hardlink-static \
  captures/hardlink-static/status.json

printf 'capture path regressions: pass\n'
