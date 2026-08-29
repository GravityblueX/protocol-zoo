#!/bin/sh
# M11: bounded PPP-over-private-PTY experiment.
# Two pppd instances run in isolated namespaces; socat is only the virtual serial wire.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-captures/era2-ppp}; A=pz-m11-a; B=pz-m11-b; VA=pz-m11-va; VB=pz-m11-vb
TMP=$(mktemp -d /tmp/pz-m11.XXXXXX); PIDS=""; CAP_PID=""; OK=0
cleanup(){ for p in $PIDS; do sudo kill "$p" 2>/dev/null || true; done; sudo ip netns del "$A" 2>/dev/null || true; sudo ip netns del "$B" 2>/dev/null || true; sudo rm -rf "$TMP"; }
trap cleanup EXIT INT TERM
mkdir -p "$ROOT/$OUT"; rm -f "$ROOT/$OUT"/*; cleanup; TMP=$(mktemp -d /tmp/pz-m11.XXXXXX); sudo chmod 777 "$TMP"
for n in "$A" "$B"; do sudo ip netns add "$n"; sudo ip -n "$n" link set lo up; done
sudo ip link add "$VA" type veth peer name "$VB"; sudo ip link set "$VA" netns "$A"; sudo ip link set "$VB" netns "$B"
sudo ip -n "$A" link set "$VA" up; sudo ip -n "$B" link set "$VB" up
# socat creates two private PTYs and logs the async-HDLC octets in hex.
socat -d -d -x -v PTY,link="$TMP/pty-a",raw,echo=0 PTY,link="$TMP/pty-b",raw,echo=0 >"$ROOT/$OUT/serial-hdlc.txt" 2>&1 & PIDS="$PIDS $!"
sleep 1
[ -e "$TMP/pty-a" ] && [ -e "$TMP/pty-b" ]
# Start capture before pppd creates ppp0. `any` sees the dynamically-created
# interface; the resulting frame index records the actual PPP IP data path.
sudo ip netns exec "$A" tcpdump -U -i any -w "$TMP/ppp-a.pcap" 'icmp' >/dev/null 2>&1 & CAP_PID=$!; PIDS="$PIDS $CAP_PID"
# pppd is setuid root on this host; invoke through sudo and keep each endpoint in its namespace.
sudo ip netns exec "$A" /usr/sbin/pppd "$TMP/pty-a" 198.18.170.1:198.18.170.2 noauth nodetach local lock asyncmap 0 mtu 1500 mru 1500 >"$ROOT/$OUT/pppd-a.log" 2>&1 & PIDS="$PIDS $!"
sudo ip netns exec "$B" /usr/sbin/pppd "$TMP/pty-b" 198.18.170.2:198.18.170.1 noauth nodetach local lock asyncmap 0 mtu 1500 mru 1500 >"$ROOT/$OUT/pppd-b.log" 2>&1 & PIDS="$PIDS $!"
sleep 5
if sudo ip netns exec "$A" ip link show ppp0 >/dev/null 2>&1 && sudo ip netns exec "$B" ip link show ppp0 >/dev/null 2>&1; then
  sudo ip netns exec "$A" ping -I ppp0 -c 2 -W 2 198.18.170.2 >/dev/null 2>&1 || true
  sleep 1
fi
sudo kill -INT "$CAP_PID" 2>/dev/null || true
sleep 1
FRAMES=0
if [ -s "$TMP/ppp-a.pcap" ]; then sudo editcap -F pcapng "$TMP/ppp-a.pcap" "$ROOT/$OUT/ppp-icmp.pcapng"; sudo chown "$(id -u):$(id -g)" "$ROOT/$OUT/ppp-icmp.pcapng"; FRAMES=$(tshark -r "$ROOT/$OUT/ppp-icmp.pcapng" -T fields -e frame.number 2>/dev/null | wc -l); fi
# Require all three evidence legs before calling this real-capture.
if grep -Eq 'local +IP address' "$ROOT/$OUT/pppd-a.log" 2>/dev/null && grep -Eq 'local +IP address' "$ROOT/$OUT/pppd-b.log" 2>/dev/null && [ "$FRAMES" -gt 0 ] && grep -Eqi 'c0 21' "$ROOT/$OUT/serial-hdlc.txt" && grep -Eqi '80 21' "$ROOT/$OUT/serial-hdlc.txt" && grep -Eqi '7e 21' "$ROOT/$OUT/serial-hdlc.txt"; then OK=1; fi
if [ "$OK" -eq 1 ]; then
  tshark -r "$ROOT/$OUT/ppp-icmp.pcapng" -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e icmp.type -e icmp.code >"$ROOT/$OUT/ppp-icmp.frames.tsv"
  cat >"$ROOT/$OUT/ppp.json" <<EOF
{"protocol":"ppp","experiment":"m11-ppp-private-pty","evidence_level":"real-capture","environment":{"os":"linux","kernel":"$(uname -r)","topology":"two netns pppd endpoints bridged by private socat PTYs","tools":{"pppd":"$(/usr/sbin/pppd --version 2>&1 | sed -n 1p)","socat":"$(socat -V 2>&1 | sed -n 1p)","tshark":"$(tshark --version 2>/dev/null | sed -n 1p)"}},"capture_point":"$A:any (PPP data observed on ppp0)","command":"scripts/era2-ppp-capture.sh","capture_filter":"icmp","result":{"handshake":"pass","capture":"$OUT/ppp-icmp.pcapng","frames":$FRAMES,"lcp_ipcp":"pass","serial_hdlc":"pass"},"sanitized":true,"notes":["Only private PTYs, namespaces and 198.18.170.0/24 were used."]}
EOF
  printf 'M11 PPP: pass (%s frames)\n' "$FRAMES"
else
  cat >"$ROOT/$OUT/ppp.json" <<EOF
{"protocol":"ppp","experiment":"m11-ppp-private-pty","evidence_level":"not-run","environment":{"os":"linux","kernel":"$(uname -r)","topology":"two netns pppd endpoints bridged by private socat PTYs","tools":{"pppd":"$(/usr/sbin/pppd --version 2>&1 | sed -n 1p)","socat":"$(socat -V 2>&1 | sed -n 1p)"}},"capture_point":"$A:$TMP/pty-a","command":"scripts/era2-ppp-capture.sh","capture_filter":"ppp0/serial PTY","result":{"handshake":"not_run","capture":"none","frames":0},"sanitized":true,"notes":["The bounded probe did not satisfy all three PPP evidence legs (pppd LCP/IPCP logs, async-HDLC serial bytes, and IP-layer ppp0 capture); no success is claimed.","See pppd-a.log, pppd-b.log and serial-hdlc.txt for diagnostics."]}
EOF
  printf 'M11 PPP: not-run (three evidence legs not all satisfied)\n'
fi
jsonschema -i "$ROOT/$OUT/ppp.json" "$ROOT/schemas/experiment.schema.json"
