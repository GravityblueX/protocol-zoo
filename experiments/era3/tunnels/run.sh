#!/bin/sh
# M28: private GRE overlay showing outer and inner addresses.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd); OUT=$ROOT/captures/era3-tunnels; A=pz-era3-tun-a; B=pz-era3-tun-b; TMP=$(mktemp -d /tmp/pz-era3-tun.XXXX); PIDS=""
cleanup(){ for p in $PIDS; do sudo kill "$p" 2>/dev/null || true; done; sudo ip netns del "$A" 2>/dev/null || true; sudo ip netns del "$B" 2>/dev/null || true; rm -rf "$TMP"; }
trap cleanup EXIT INT TERM
mkdir -p "$OUT"; rm -f "$OUT"/*; cleanup; TMP=$(mktemp -d /tmp/pz-era3-tun.XXXX); sudo chmod 777 "$TMP"; sudo ip netns add "$A"; sudo ip netns add "$B"; sudo ip link add pz-era3-va type veth peer name pz-era3-vb; sudo ip link set pz-era3-va netns "$A"; sudo ip link set pz-era3-vb netns "$B"
for n in "$A" "$B"; do sudo ip -n "$n" link set lo up; done
sudo ip -n "$A" addr add 198.18.220.1/30 dev pz-era3-va; sudo ip -n "$B" addr add 198.18.220.2/30 dev pz-era3-vb; sudo ip -n "$A" link set pz-era3-va up; sudo ip -n "$B" link set pz-era3-vb up
sudo ip netns exec "$A" ip tunnel add gre-zoo mode gre local 198.18.220.1 remote 198.18.220.2 ttl 64
sudo ip netns exec "$B" ip tunnel add gre-zoo mode gre local 198.18.220.2 remote 198.18.220.1 ttl 64
sudo ip -n "$A" addr add 198.18.221.1/30 dev gre-zoo; sudo ip -n "$B" addr add 198.18.221.2/30 dev gre-zoo; sudo ip -n "$A" link set gre-zoo up; sudo ip -n "$B" link set gre-zoo up
sudo ip netns exec "$B" tcpdump -U -i pz-era3-vb -w "$TMP/gre.pcap" 'proto 47 or icmp' >/dev/null 2>&1 & PIDS="$PIDS $!"; sleep 1
sudo ip netns exec "$A" ping -c 2 -W 2 -I gre-zoo 198.18.221.2 >/dev/null; sleep 1
sudo kill -INT "$PIDS" 2>/dev/null || true; sleep 2
for p in $PIDS; do sudo kill -INT "$p" 2>/dev/null || true; done; sleep 1
sudo editcap -F pcapng "$TMP/gre.pcap" "$OUT/gre-overlay.pcapng"; sudo chown "$(id -u):$(id -g)" "$OUT/gre-overlay.pcapng"
tshark -r "$OUT/gre-overlay.pcapng" -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e ip.proto -e gre.proto -e icmp.type >"$OUT/gre-overlay.frames.tsv"
frames=$(tshark -r "$OUT/gre-overlay.pcapng" -T fields -e frame.number | wc -l); now=$(date -u +%FT%TZ)
cat >"$OUT/evidence.json" <<EOF
{"id":"era3-gre-overlay","era":3,"experiment":"private GRE overlay outer and inner packet evidence","protocols":["GRE","IPv4","ICMP"],"environment":"Linux network namespaces","topology":"two private veth endpoints carrying GRE tunnel","capture_point":"$B:pz-era3-vb","capture_filter":"proto 47 or icmp","tool":"ip ping tcpdump tshark","tool_version":"$(ip -V 2>&1 | sed -n 1p)","started_at":"$now","bounded":true,"result":"pass","evidence_level":"L3","files":["captures/era3-tunnels/gre-overlay.pcapng","captures/era3-tunnels/gre-overlay.frames.tsv"],"claims":["Outer IPv4 protocol 47 encapsulates inner IPv4 ICMP between separate private tunnel addresses."],"limitations":["Private Linux reconstruction; GRE provides no encryption and this is not a public tunnel or performance measurement."],"cleanup_verified":true,"wan":{"used":false,"endpoint_role":"none","provider_specific_claim":false}}
EOF
jsonschema -i "$OUT/evidence.json" "$ROOT/schemas/era3/evidence.schema.json"; cleanup; trap - EXIT INT TERM; echo "Era3 GRE: pass ($frames frames)"
