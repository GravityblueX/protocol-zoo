#!/bin/sh
# M13 ICMP lifecycle (live organs) and M18 IGMP membership in private namespaces.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-captures/era2-network}
# shellcheck source=scripts/lib/capture-path.sh
. "$ROOT/scripts/lib/capture-path.sh"
pz_require_capture_path "$ROOT" "$OUT" directory
OUT_DIR=$PZ_CAPTURE_PATH
OUT=$PZ_CAPTURE_RELATIVE
pz_require_capture_children "$ROOT" "$OUT" \
  icmp-lifecycle.pcapng \
  icmp-lifecycle.frames.tsv \
  icmp-lifecycle.json \
  igmp-membership.pcapng \
  igmp-membership.frames.tsv \
  igmp-membership.json
A=pz-era2-a; B=pz-era2-b; VA=pz-era2-a0; VB=pz-era2-b0
PIDS=""; TMP=
cleanup(){ for p in $PIDS; do sudo kill "$p" 2>/dev/null || true; done; sudo ip netns del "$A" 2>/dev/null || true; sudo ip netns del "$B" 2>/dev/null || true; [ -z "$TMP" ] || sudo rm -rf "$TMP"; }
trap cleanup EXIT INT TERM
mkdir -p "$OUT_DIR"
rm -f \
  "$OUT_DIR/icmp-lifecycle.pcapng" \
  "$OUT_DIR/icmp-lifecycle.frames.tsv" \
  "$OUT_DIR/icmp-lifecycle.json" \
  "$OUT_DIR/igmp-membership.pcapng" \
  "$OUT_DIR/igmp-membership.frames.tsv" \
  "$OUT_DIR/igmp-membership.json"
cleanup; TMP=$(mktemp -d /tmp/pz-era2-network.XXXXXX)
sudo ip netns add "$A"; sudo ip netns add "$B"
sudo ip link add "$VA" type veth peer name "$VB"; sudo ip link set "$VA" netns "$A"; sudo ip link set "$VB" netns "$B"
sudo ip -n "$A" link set lo up; sudo ip -n "$B" link set lo up
sudo ip -n "$A" addr add 198.18.130.1/24 dev "$VA"; sudo ip -n "$B" addr add 198.18.130.2/24 dev "$VB"
sudo ip -n "$A" link set "$VA" up; sudo ip -n "$B" link set "$VB" up

# M13: echo plus UDP-to-closed-port produces Destination Unreachable/Port Unreachable.
sudo ip netns exec "$B" tcpdump -U -i "$VB" -w "$TMP/icmp.pcap" 'icmp or udp port 19013' >/dev/null 2>&1 & PIDS="$PIDS $!"
sleep 1
sudo ip netns exec "$A" ping -c 1 -W 1 198.18.130.2 >/dev/null
printf 'closed-port-probe' | sudo ip netns exec "$A" nc -u -w 1 198.18.130.2 19013 || true
sleep 1
for p in $PIDS; do sudo kill -INT "$p" 2>/dev/null || true; done; for p in $PIDS; do wait "$p" 2>/dev/null || true; done; PIDS=""
sudo editcap -F pcapng "$TMP/icmp.pcap" "$OUT_DIR/icmp-lifecycle.pcapng"; sudo chown "$(id -u):$(id -g)" "$OUT_DIR/icmp-lifecycle.pcapng"

# M18: joining then leaving a group causes IGMP reports entirely on the lab link.
sudo ip netns exec "$B" tcpdump -U -i "$VB" -w "$TMP/igmp.pcap" 'igmp' >/dev/null 2>&1 & PIDS="$PIDS $!"
sleep 1
sudo ip netns exec "$A" python3 - <<'PY'
import socket,time
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM,socket.IPPROTO_UDP)
s.setsockopt(socket.IPPROTO_IP,socket.IP_MULTICAST_IF,socket.inet_aton('198.18.130.1'))
mreq=socket.inet_aton('239.1.1.1')+socket.inet_aton('198.18.130.1')
s.setsockopt(socket.IPPROTO_IP,socket.IP_ADD_MEMBERSHIP,mreq)
time.sleep(1)
s.setsockopt(socket.IPPROTO_IP,socket.IP_DROP_MEMBERSHIP,mreq)
time.sleep(1)
s.close()
PY
sleep 1
for p in $PIDS; do sudo kill -INT "$p" 2>/dev/null || true; done; for p in $PIDS; do wait "$p" 2>/dev/null || true; done; PIDS=""
sudo editcap -F pcapng "$TMP/igmp.pcap" "$OUT_DIR/igmp-membership.pcapng"; sudo chown "$(id -u):$(id -g)" "$OUT_DIR/igmp-membership.pcapng"

for name in icmp-lifecycle igmp-membership; do
  tshark -r "$OUT_DIR/$name.pcapng" -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e ip.proto -e icmp.type -e icmp.code -e igmp.type -e igmp.maddr >"$OUT_DIR/$name.frames.tsv" 2>/dev/null
  frames=$(tshark -r "$OUT_DIR/$name.pcapng" -T fields -e frame.number 2>/dev/null | wc -l)
  [ "$frames" -gt 0 ]
  proto=icmp; [ "$name" = igmp-membership ] && proto=igmp
  cat >"$OUT_DIR/$name.json" <<EOF
{"protocol":"$proto","experiment":"$name-netns","evidence_level":"real-capture","environment":{"os":"linux","kernel":"$(uname -r)","topology":"private netns-veth","tools":{"tcpdump":"$(tcpdump --version 2>&1 | sed -n 1p)","tshark":"$(tshark --version 2>/dev/null | sed -n 1p)"}},"capture_point":"$B:$VB","command":"scripts/era2-network-capture.sh","capture_filter":"$proto","result":{"handshake":"pass","capture":"$OUT/$name.pcapng","frames":$frames},"sanitized":true,"notes":["Only 198.18.130.0/24 and multicast group 239.1.1.1 inside private namespaces were used."]}
EOF
  jsonschema -i "$OUT_DIR/$name.json" "$ROOT/schemas/experiment.schema.json"
done
# Require the mechanisms we claim.
tshark -r "$OUT_DIR/icmp-lifecycle.pcapng" -Y 'icmp.type == 0' -T fields -e frame.number | grep -q .
tshark -r "$OUT_DIR/icmp-lifecycle.pcapng" -Y 'icmp.type == 3 && icmp.code == 3' -T fields -e frame.number | grep -q .
tshark -r "$OUT_DIR/igmp-membership.pcapng" -Y 'igmp' -T fields -e frame.number | grep -q .
printf 'M13 ICMP and M18 IGMP: pass\n'
