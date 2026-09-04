#!/bin/sh
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
[ "$#" -le 1 ] || {
  echo 'usage: scripts/kali-remaining-capture.sh [captures/output-directory]' >&2
  exit 2
}
if [ "$#" -eq 1 ]; then
  OUT=$1
else
  OUT=captures/kali-remaining
fi
# shellcheck source=scripts/lib/capture-path.sh
. "$ROOT/scripts/lib/capture-path.sh"
pz_require_capture_path "$ROOT" "$OUT" directory
OUT_DIR=$PZ_CAPTURE_PATH
OUT=$PZ_CAPTURE_RELATIVE
pz_require_capture_children "$ROOT" "$OUT" \
  udplite.pcapng \
  gre.pcapng \
  ipip.pcapng
KEYDIR=${PZ_KALI_KEYDIR:-/media/tmzn/DATA5/qemu_vms/protocol-zoo-kali}
HOST=${PZ_KALI_HOST:-172.31.250.195}
for tool in mktemp mv scp ssh; do
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
STAGE=$(mktemp -d "$OUT_DIR/.kali-remaining.XXXXXX")
COMMITTED=false
PUBLISHED=
cleanup() {
  [ -n "$STAGE" ] || return 0
  rollback_ok=true
  if [ "$COMMITTED" != true ]; then
    for name in udplite.pcapng gre.pcapng ipip.pcapng; do
      backup=$STAGE/.previous.$name
      case " $PUBLISHED " in
        *" $name "*)
          rm -f "$OUT_DIR/$name" || rollback_ok=false
          ;;
      esac
      if [ -e "$backup" ]; then
        if ! mv "$backup" "$OUT_DIR/$name"; then
          echo "unable to restore previous Kali remaining artifact: $name" >&2
          rollback_ok=false
        fi
      fi
    done
  fi
  if [ "$rollback_ok" = true ]; then
    rm -rf "$STAGE"
  else
    echo "retained failed Kali remaining staging directory: $STAGE" >&2
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
  "$ROOT/scripts/guest/remaining.sh" \
  "root@$HOST:/tmp/protocol-zoo-remaining.sh"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/pz-known-hosts \
  -o ConnectTimeout=8 -i "$KEYDIR/id_ed25519" \
  "root@$HOST" bash /tmp/protocol-zoo-remaining.sh
for f in udplite gre ipip; do
  scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/pz-known-hosts \
    -i "$KEYDIR/id_ed25519" \
    "root@$HOST:/root/pz-remaining/$f.pcapng" "$STAGE/$f.pcapng"
done

for file in "$STAGE/udplite.pcapng" "$STAGE/gre.pcapng" \
  "$STAGE/ipip.pcapng"; do
  if [ -L "$file" ] || [ ! -f "$file" ] || [ ! -s "$file" ]; then
    echo "invalid staged Kali remaining artifact: $file" >&2
    exit 1
  fi
done

for f in udplite gre ipip; do
  publish "$STAGE/$f.pcapng" "$f.pcapng"
done
COMMITTED=true
cleanup
STAGE=
trap - EXIT HUP INT TERM
