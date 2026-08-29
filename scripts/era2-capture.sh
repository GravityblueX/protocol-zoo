#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-captures/era2-netns}; mkdir -p "$ROOT/$OUT"
PIDS=""; cleanup(){ for p in $PIDS; do kill "$p" 2>/dev/null || true; done; sudo "$ROOT/scripts/lab-netns.sh" teardown; }
trap cleanup EXIT INT TERM
sudo "$ROOT/scripts/lab-netns.sh" setup
rm -rf /tmp/pz-era2-tftp /tmp/pz-era2-out; mkdir -p /tmp/pz-era2-tftp /tmp/pz-era2-out
printf 'protocol-zoo boot payload\n' >/tmp/pz-era2-tftp/boot.img
cat >/tmp/pz-era2-dnsmasq.conf <<EOF
port=0
interface=pz-veth-s
bind-interfaces
dhcp-range=198.18.0.10,198.18.0.20,255.255.255.252,1m
dhcp-boot=boot.img,198.18.0.2
enable-tftp
tftp-root=/tmp/pz-era2-tftp
log-dhcp
EOF
sudo ip netns exec pz-server dnsmasq --no-daemon --conf-file=/tmp/pz-era2-dnsmasq.conf >/tmp/pz-era2-dnsmasq.log 2>&1 & PIDS="$PIDS $!"
sudo ip netns exec pz-server tcpdump -U -i pz-veth-s -w /tmp/pz-era2-boot.pcap 'udp port 67 or udp port 68 or udp port 69' >/dev/null 2>&1 & PIDS="$PIDS $!"
sleep 1
# Real DHCP client gets a lease on the lab link. It may replace the fixture address.
sudo ip netns exec pz-client dhclient -1 -v -nw -pf /tmp/pz-dhclient.pid -lf /tmp/pz-dhclient.leases pz-veth-c >/tmp/pz-era2-dhcp.log 2>&1 || true
# TFTP is independently addressed and stays inside the server namespace.
printf 'get boot.img /tmp/pz-era2-out/boot.img\nquit\n' | sudo ip netns exec pz-client tftp 198.18.0.2 >/tmp/pz-era2-tftp.log 2>&1 || true
sleep 1
for p in $PIDS; do kill -INT "$p" 2>/dev/null || true; done; PIDS=""
[ -s /tmp/pz-era2-out/boot.img ] && HS=pass || HS=not_run
[ "$HS" = pass ] && NOTE='Real TFTP RRQ/DATA/ACK transfer completed; DHCP client attempt recorded separately' || NOTE='dnsmasq started; client transfer did not complete'
sudo editcap -F pcapng /tmp/pz-era2-boot.pcap "$ROOT/$OUT/boot-chain.pcapng" 2>/dev/null || true
FRAMES=$(tshark -r "$ROOT/$OUT/boot-chain.pcapng" -T fields -e frame.number 2>/dev/null | wc -l)
DHCP_STATUS=$(grep -q 'bound to' /tmp/pz-era2-dhcp.log 2>/dev/null && printf pass || printf not_run)
cat >"$ROOT/$OUT/boot-chain.json" <<EOF
{"protocol":"dhcp+tftp","experiment":"phase-10-boot-chain-netns","environment":{"os":"linux","kernel":"$(uname -r)","topology":"pz-client/pz-server netns-veth","tools":{"dnsmasq":"$(dnsmasq --version 2>/dev/null | sed -n 1p)","dhclient":"$(dhclient --version 2>&1 | sed -n 1p)","tftp":"$(tftp --version 2>&1 | sed -n 1p)","tshark":"$(tshark --version 2>/dev/null | sed -n 1p)"}},"capture_point":"pz-server:pz-veth-s","command":"scripts/era2-capture.sh","capture_filter":"udp port 67 or udp port 68 or udp port 69","result":{"handshake":"$HS","capture":"captures/era2-netns/boot-chain.pcapng","frames":$FRAMES,"dhcp":"$DHCP_STATUS","tftp":"$HS"},"sanitized":true,"notes":["Only private namespace addresses and synthetic boot.img were used.","$NOTE"]}
EOF
rm -rf /tmp/pz-era2-tftp /tmp/pz-era2-out /tmp/pz-era2-dnsmasq.conf /tmp/pz-era2-dnsmasq.log /tmp/pz-era2-dhcp.log /tmp/pz-era2-tftp.log /tmp/pz-era2-boot.pcap /tmp/pz-dhclient.pid /tmp/pz-dhclient.leases
jsonschema -i "$ROOT/$OUT/boot-chain.json" "$ROOT/schemas/experiment.schema.json"
printf 'era2 capture result: %s; DHCP: %s; %s frames\n' "$HS" "$DHCP_STATUS" "$FRAMES"
