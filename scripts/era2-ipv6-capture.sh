#!/bin/sh
# M15: private IPv6-in-IPv4 tunnel evidence. No public relay or broker.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-captures/era2-ipv6}; A=pz-m15-a; B=pz-m15-b; VA=pz-m15-va; VB=pz-m15-vb
TMP=$(mktemp -d /tmp/pz-m15.XXXXXX); PIDS=""
cleanup(){ for p in $PIDS; do sudo kill "$p" 2>/dev/null || true; done; sudo ip netns del "$A" 2>/dev/null || true; sudo ip netns del "$B" 2>/dev/null || true; sudo rm -rf "$TMP"; }
trap cleanup EXIT INT TERM
mkdir -p "$ROOT/$OUT"; rm -f "$ROOT/$OUT"/*; cleanup; TMP=$(mktemp -d /tmp/pz-m15.XXXXXX)
sudo ip netns add "$A"; sudo ip netns add "$B"; sudo ip link add "$VA" type veth peer name "$VB"; sudo ip link set "$VA" netns "$A"; sudo ip link set "$VB" netns "$B"
for n in "$A" "$B"; do sudo ip -n "$n" link set lo up; done
sudo ip -n "$A" addr add 198.18.180.1/30 dev "$VA"; sudo ip -n "$B" addr add 198.18.180.2/30 dev "$VB"; sudo ip -n "$A" link set "$VA" up; sudo ip -n "$B" link set "$VB" up
sudo ip -n "$A" -6 addr add 2001:db8:180::1/64 dev "$VA"; sudo ip -n "$B" -6 addr add 2001:db8:180::2/64 dev "$VB"
# IPv6-in-IPv4 tunnel (ip6tnl mode ip4ip6 is not required; this uses SIT mode).
sudo ip netns exec "$A" ip tunnel add sit-zoo mode sit local 198.18.180.1 remote 198.18.180.2 ttl 64
sudo ip netns exec "$B" ip tunnel add sit-zoo mode sit local 198.18.180.2 remote 198.18.180.1 ttl 64
sudo ip -n "$A" -6 addr add 2001:db8:181::1/64 dev sit-zoo; sudo ip -n "$B" -6 addr add 2001:db8:181::2/64 dev sit-zoo
sudo ip -n "$A" link set sit-zoo up; sudo ip -n "$B" link set sit-zoo up
sudo ip netns exec "$B" tcpdump -U -i "$VB" -w "$TMP/sit.pcap" 'ip proto 41 or icmp6' >/dev/null 2>&1 & PIDS="$PIDS $!"
sleep 1; sudo ip netns exec "$A" ping -6 -c 2 -W 2 2001:db8:181::2 >/dev/null
sleep 1; for p in $PIDS; do sudo kill -INT "$p" 2>/dev/null || true; done; for p in $PIDS; do wait "$p" 2>/dev/null || true; done; PIDS=""
sudo editcap -F pcapng "$TMP/sit.pcap" "$ROOT/$OUT/sit-ipv6-in-ipv4.pcapng"; sudo chown "$(id -u):$(id -g)" "$ROOT/$OUT/sit-ipv6-in-ipv4.pcapng"
tshark -r "$ROOT/$OUT/sit-ipv6-in-ipv4.pcapng" -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e ip.proto -e ipv6.src -e ipv6.dst -e icmpv6.type >"$ROOT/$OUT/sit-ipv6-in-ipv4.frames.tsv"
frames=$(tshark -r "$ROOT/$OUT/sit-ipv6-in-ipv4.pcapng" -T fields -e frame.number | wc -l); [ "$frames" -gt 0 ]
cat >"$ROOT/$OUT/sit-ipv6-in-ipv4.json" <<EOF
{"protocol":"6to4-private-sit","experiment":"m15-private-ipv6-in-ipv4-netns","evidence_level":"real-capture","environment":{"os":"linux","kernel":"$(uname -r)","topology":"private netns-veth plus SIT tunnel","tools":{"ip":"$(ip -V 2>&1 | sed -n 1p)","tcpdump":"$(tcpdump --version 2>&1 | sed -n 1p)","tshark":"$(tshark --version 2>/dev/null | sed -n 1p)"}},"capture_point":"$B:$VB","command":"scripts/era2-ipv6-capture.sh","capture_filter":"ip proto 41 or icmp6","result":{"handshake":"pass","capture":"$OUT/sit-ipv6-in-ipv4.pcapng","frames":$frames,"outer_protocol":41,"inner_protocol":"IPv6/ICMPv6"},"sanitized":true,"notes":["Private SIT-style IPv6-in-IPv4 only; no public 6to4 anycast, Teredo relay, ISATAP broker, or NAT64 service was contacted."]}
EOF
jsonschema -i "$ROOT/$OUT/sit-ipv6-in-ipv4.json" "$ROOT/schemas/experiment.schema.json"
cleanup
trap - EXIT INT TERM
printf 'M15 private IPv6 transition: pass (%s frames)\n' "$frames"
