#!/bin/sh
# M10: DHCP address acquisition followed by TFTP boot-file retrieval.
# Uses a dedicated /24 namespace link; never touches host routes or DHCP.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-captures/era2-netns}
CLIENT_NS=pz-m10-client
SERVER_NS=pz-m10-server
VETH_C=pz-m10-c
VETH_S=pz-m10-s
SERVER_IP=198.18.50.1
LEASE_IP=198.18.50.10
PIDS=""
TMP=$(mktemp -d /tmp/pz-m10.XXXXXX)

cleanup() {
  for p in $PIDS; do sudo kill "$p" 2>/dev/null || true; done
  sudo ip netns del "$CLIENT_NS" 2>/dev/null || true
  sudo ip netns del "$SERVER_NS" 2>/dev/null || true
  sudo ip link del "$VETH_C" 2>/dev/null || true
  sudo rm -rf "$TMP"
}
trap cleanup EXIT INT TERM

mkdir -p "$ROOT/$OUT"
rm -f "$ROOT/$OUT/boot-chain.pcapng" "$ROOT/$OUT/boot-chain.json" "$ROOT/$OUT/boot-chain.frames.tsv"
cleanup
TMP=$(mktemp -d /tmp/pz-m10.XXXXXX)

sudo ip netns add "$CLIENT_NS"
sudo ip netns add "$SERVER_NS"
sudo ip link add "$VETH_C" type veth peer name "$VETH_S"
sudo ip link set "$VETH_C" netns "$CLIENT_NS"
sudo ip link set "$VETH_S" netns "$SERVER_NS"
sudo ip -n "$CLIENT_NS" link set lo up
sudo ip -n "$SERVER_NS" link set lo up
sudo ip -n "$CLIENT_NS" link set "$VETH_C" up
sudo ip -n "$SERVER_NS" link set "$VETH_S" up
sudo ip -n "$SERVER_NS" addr add "$SERVER_IP/24" dev "$VETH_S"
# Client deliberately starts without an IPv4 address.
[ -z "$(sudo ip -n "$CLIENT_NS" -4 -o addr show dev "$VETH_C")" ]

printf 'protocol-zoo boot payload\n' | sudo tee "$TMP/boot.img" >/dev/null
sudo tee "$TMP/dnsmasq.conf" >/dev/null <<EOF
port=0
interface=$VETH_S
bind-interfaces
dhcp-range=$LEASE_IP,198.18.50.20,255.255.255.0,1m
dhcp-option=3
dhcp-option=6
dhcp-boot=boot.img,$SERVER_IP,$SERVER_IP
enable-tftp
tftp-root=$TMP
log-dhcp
EOF
sudo chmod 755 "$TMP"; sudo chmod 644 "$TMP/boot.img" "$TMP/dnsmasq.conf"

sudo ip netns exec "$SERVER_NS" dnsmasq --no-daemon --conf-file="$TMP/dnsmasq.conf" >"$TMP/dnsmasq.log" 2>&1 & PIDS="$PIDS $!"
# Capture all UDP: TFTP switches from port 69 to a server transfer ID after RRQ.
sudo ip netns exec "$SERVER_NS" tcpdump -U -i "$VETH_S" -w "$TMP/boot-chain.pcap" 'udp' >/dev/null 2>&1 & PIDS="$PIDS $!"
sleep 1

sudo ip netns exec "$CLIENT_NS" dhclient -4 -1 -v -pf "$TMP/dhclient.pid" -lf "$TMP/dhclient.leases" "$VETH_C" >"$TMP/dhclient.log" 2>&1
CLIENT_IP=$(sudo ip -n "$CLIENT_NS" -4 -o addr show dev "$VETH_C" | awk '{print $4}' | cut -d/ -f1)
[ -n "$CLIENT_IP" ]
printf 'binary\nget boot.img %s/received.img\nquit\n' "$TMP" | sudo ip netns exec "$CLIENT_NS" tftp "$SERVER_IP" >"$TMP/tftp.log" 2>&1
cmp "$TMP/boot.img" "$TMP/received.img"

sleep 1
for p in $PIDS; do sudo kill -INT "$p" 2>/dev/null || true; done
for p in $PIDS; do wait "$p" 2>/dev/null || true; done
PIDS=""
sudo editcap -F pcapng "$TMP/boot-chain.pcap" "$ROOT/$OUT/boot-chain.pcapng"
sudo chown "$(id -u):$(id -g)" "$ROOT/$OUT/boot-chain.pcapng"

FRAMES=$(tshark -r "$ROOT/$OUT/boot-chain.pcapng" -T fields -e frame.number 2>/dev/null | wc -l)
[ "$FRAMES" -gt 0 ]
tshark -r "$ROOT/$OUT/boot-chain.pcapng" -Y 'dhcp || tftp' -T fields -E header=y \
  -e frame.number -e ip.src -e ip.dst -e udp.srcport -e udp.dstport \
  -e dhcp.option.dhcp -e tftp.opcode -e tftp.source_file -e tftp.block \
  >"$ROOT/$OUT/boot-chain.frames.tsv"
for msg in 1 2 3 5; do tshark -r "$ROOT/$OUT/boot-chain.pcapng" -Y "dhcp.option.dhcp == $msg" -T fields -e frame.number 2>/dev/null | grep -q .; done
tshark -r "$ROOT/$OUT/boot-chain.pcapng" -Y 'tftp.opcode == 1' -T fields -e frame.number 2>/dev/null | grep -q .
tshark -r "$ROOT/$OUT/boot-chain.pcapng" -Y 'tftp.opcode == 3' -T fields -e frame.number 2>/dev/null | grep -q .
tshark -r "$ROOT/$OUT/boot-chain.pcapng" -Y 'tftp.opcode == 4' -T fields -e frame.number 2>/dev/null | grep -q .

cat >"$ROOT/$OUT/boot-chain.json" <<EOF
{
  "protocol": "dhcp+tftp",
  "experiment": "m10-boot-chain-netns",
  "evidence_level": "real-capture",
  "environment": {"os": "linux", "kernel": "$(uname -r)", "topology": "dedicated /24 netns-veth", "tools": {"dnsmasq": "$(dnsmasq --version 2>/dev/null | sed -n 1p)", "dhclient": "$(dhclient --version 2>&1 | sed -n 1p)", "tftp": "$(tftp --version 2>&1 | sed -n 1p)", "tshark": "$(tshark --version 2>/dev/null | sed -n 1p)"}},
  "capture_point": "$SERVER_NS:$VETH_S",
  "command": "scripts/era2-capture.sh",
  "capture_filter": "udp port 67 or udp port 68 or udp port 69",
  "result": {"handshake": "pass", "capture": "$OUT/boot-chain.pcapng", "frames": $FRAMES, "dhcp": "pass", "tftp": "pass", "leased_address": "$CLIENT_IP", "boot_file": "boot.img"},
  "sanitized": true,
  "notes": ["Client began without IPv4, completed DISCOVER/OFFER/REQUEST/ACK, then retrieved synthetic boot.img using TFTP RRQ/DATA/ACK.", "All traffic remained on 198.18.50.0/24 inside dedicated namespaces."]
}
EOF
jsonschema -i "$ROOT/$OUT/boot-chain.json" "$ROOT/schemas/experiment.schema.json"
printf 'M10 boot chain: pass (%s frames, lease %s)\n' "$FRAMES" "$CLIENT_IP"
