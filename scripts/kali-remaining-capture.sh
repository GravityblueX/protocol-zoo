#!/bin/sh
set -eu
KEYDIR=${PZ_KALI_KEYDIR:-/media/tmzn/DATA5/qemu_vms/protocol-zoo-kali}
HOST=${PZ_KALI_HOST:-172.31.250.195}
[ -r "$KEYDIR/id_ed25519" ] || { echo "missing Kali key: $KEYDIR/id_ed25519" >&2; exit 1; }
mkdir -p captures/kali-remaining
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/pz-known-hosts -o ConnectTimeout=8 -i "$KEYDIR/id_ed25519" root@$HOST /root/pz-remaining.sh
for f in udplite gre ipip; do scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/pz-known-hosts -i "$KEYDIR/id_ed25519" root@172.31.250.195:/root/pz-remaining/$f.pcapng captures/kali-remaining/$f.pcapng; done
