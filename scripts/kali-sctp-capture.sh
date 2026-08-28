#!/bin/sh
# Execute the real SCTP experiment inside the isolated protocol-zoo-kali guest.
# The guest is reachable only through pz-isolated (172.31.250.0/24).
set -eu
KEYDIR=/media/tmzn/DATA5/qemu_vms/protocol-zoo-kali
HOST=172.31.250.195
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/pz-known-hosts -i "$KEYDIR/id_ed25519" root@$HOST /root/pz-sctp.sh
scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/pz-known-hosts -i "$KEYDIR/id_ed25519" root@$HOST:/root/pz-sctp.pcap captures/kali-sctp/sctp.pcap
scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/pz-known-hosts -i "$KEYDIR/id_ed25519" root@$HOST:/root/pz-sctp.json captures/kali-sctp/sctp.json
sed -i 's#/root/pz-sctp.pcap#captures/kali-sctp/sctp.pcap#; s#/root/pz-sctp.sh#scripts/kali-sctp-capture.sh#' captures/kali-sctp/sctp.json
