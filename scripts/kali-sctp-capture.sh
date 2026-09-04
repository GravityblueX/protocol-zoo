#!/bin/sh
# Execute the real SCTP experiment inside the isolated protocol-zoo-kali guest.
# The guest is reachable only through pz-isolated (172.31.250.0/24).
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
[ "$#" -le 1 ] || {
  echo 'usage: scripts/kali-sctp-capture.sh [captures/output-directory]' >&2
  exit 2
}
CUSTOM_OUT=false
if [ "$#" -eq 1 ]; then
  OUT=$1
  CUSTOM_OUT=true
else
  OUT=captures/kali-sctp
fi
# shellcheck source=scripts/lib/capture-path.sh
. "$ROOT/scripts/lib/capture-path.sh"
pz_require_capture_path "$ROOT" "$OUT" directory
OUT_DIR=$PZ_CAPTURE_PATH
OUT=$PZ_CAPTURE_RELATIVE
pz_require_capture_children "$ROOT" "$OUT" sctp.pcap sctp.json
KEYDIR=${PZ_KALI_KEYDIR:-/media/tmzn/DATA5/qemu_vms/protocol-zoo-kali}
HOST=${PZ_KALI_HOST:-172.31.250.195}
for tool in jq jsonschema mktemp mv scp ssh; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "missing required command: $tool" >&2
    exit 1
  }
done
[ -r "$KEYDIR/id_ed25519" ] || {
  echo "missing Kali key: $KEYDIR/id_ed25519" >&2
  exit 1
}
mkdir -p "$OUT_DIR"
STAGE=$(mktemp -d "$OUT_DIR/.kali-sctp.XXXXXX")
COMMITTED=false
PUBLISHED=
cleanup() {
  [ -n "$STAGE" ] || return 0
  rollback_ok=true
  if [ "$COMMITTED" != true ]; then
    for name in sctp.pcap sctp.json; do
      backup=$STAGE/.previous.$name
      case " $PUBLISHED " in
        *" $name "*)
          rm -f "$OUT_DIR/$name" || rollback_ok=false
          ;;
      esac
      if [ -e "$backup" ]; then
        if ! mv "$backup" "$OUT_DIR/$name"; then
          echo "unable to restore previous Kali SCTP artifact: $name" >&2
          rollback_ok=false
        fi
      fi
    done
  fi
  if [ "$rollback_ok" = true ]; then
    rm -rf "$STAGE"
  else
    echo "retained failed Kali SCTP staging directory: $STAGE" >&2
  fi
}
publish() {
  source=$1
  name=$2
  if [ -e "$OUT_DIR/$name" ]; then
    mv "$OUT_DIR/$name" "$STAGE/.previous.$name"
  fi
  mv "$source" "$OUT_DIR/$name"
  PUBLISHED="$PUBLISHED $name"
}
trap cleanup EXIT HUP INT TERM

scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/pz-known-hosts \
  -o ConnectTimeout=8 -i "$KEYDIR/id_ed25519" \
  "$ROOT/scripts/guest/sctp.sh" \
  "root@$HOST:/tmp/protocol-zoo-sctp.sh"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/pz-known-hosts \
  -o ConnectTimeout=8 -i "$KEYDIR/id_ed25519" \
  "root@$HOST" sh /tmp/protocol-zoo-sctp.sh
scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/pz-known-hosts \
  -i "$KEYDIR/id_ed25519" \
  "root@$HOST:/root/pz-sctp.pcap" "$STAGE/sctp.pcap"
scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/pz-known-hosts \
  -i "$KEYDIR/id_ed25519" \
  "root@$HOST:/root/pz-sctp.json" "$STAGE/sctp.json"

for file in "$STAGE/sctp.pcap" "$STAGE/sctp.json"; do
  if [ -L "$file" ] || [ ! -f "$file" ] || [ ! -s "$file" ]; then
    echo "invalid staged Kali SCTP artifact: $file" >&2
    exit 1
  fi
done

COMMAND=scripts/kali-sctp-capture.sh
if [ "$CUSTOM_OUT" = true ]; then
  COMMAND=$(jq -nr --arg target "$OUT" \
    '["scripts/kali-sctp-capture.sh", $target] | map(@sh) | join(" ")')
fi
jq -e -s --arg capture "$OUT/sctp.pcap" \
  --arg command "$COMMAND" \
  'if length == 1 and (.[0] | type == "object") and
      (.[0].result | type == "object")
   then .[0] | .result.capture = $capture | .command = $command
   else error("expected exactly one root object with an object result")
   end' \
  "$STAGE/sctp.json" >"$STAGE/sctp.validated.json"
if [ -L "$STAGE/sctp.validated.json" ] || \
  [ ! -f "$STAGE/sctp.validated.json" ] || \
  [ ! -s "$STAGE/sctp.validated.json" ]; then
  echo 'invalid rewritten Kali SCTP metadata' >&2
  exit 1
fi
jsonschema -i "$STAGE/sctp.validated.json" \
  "$ROOT/schemas/experiment.schema.json"

publish "$STAGE/sctp.pcap" sctp.pcap
publish "$STAGE/sctp.validated.json" sctp.json
COMMITTED=true
rm -f "$STAGE/sctp.json"
cleanup
STAGE=
trap - EXIT HUP INT TERM
