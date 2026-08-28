#!/bin/sh
set -eu
KEYDIR=/media/tmzn/DATA5/qemu_vms/protocol-zoo-kali
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/pz-known-hosts -i "$KEYDIR/id_ed25519" root@172.31.250.195 /root/pz-remaining.sh
for f in udplite gre ipip; do scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/pz-known-hosts -i "$KEYDIR/id_ed25519" root@172.31.250.195:/root/pz-remaining/$f.pcapng captures/kali-remaining/$f.pcapng; done
