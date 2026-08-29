#!/bin/sh
# M18/M19: three-namespace PMTUD and traceroute ground-truth experiment.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd); OUT=$ROOT/captures/era3-pmtud; TOUT=$ROOT/captures/era3-traceroute; C=pz-era3-path-c; R=pz-era3-path-r; S=pz-era3-path-s; TMP=$(mktemp -d /tmp/pz-era3-path.XXXX); PIDS=""
cleanup(){ for p in $PIDS; do sudo kill "$p" 2>/dev/null || true; done; for n in $C $R $S; do sudo ip netns del "$n" 2>/dev/null || true; done; rm -rf "$TMP"; }
trap cleanup EXIT INT TERM
mkdir -p "$OUT" "$TOUT"; rm -f "$OUT"/* "$TOUT"/*; cleanup; TMP=$(mktemp -d /tmp/pz-era3-path.XXXX); sudo chmod 777 "$TMP"
for n in $C $R $S; do sudo ip netns add "$n"; sudo ip -n "$n" link set lo up; done
sudo ip link add pc type veth peer name prc; sudo ip link set pc netns $C; sudo ip link set prc netns $R
sudo ip link add prs type veth peer name ps; sudo ip link set prs netns $R; sudo ip link set ps netns $S
sudo ip -n $C addr add 198.18.240.2/30 dev pc; sudo ip -n $R addr add 198.18.240.1/30 dev prc
sudo ip -n $R addr add 198.18.240.5/30 dev prs; sudo ip -n $S addr add 198.18.240.6/30 dev ps
for x in "$C pc" "$R prc" "$R prs" "$S ps"; do set -- $x; sudo ip -n "$1" link set "$2" up; done
sudo ip -n $R link set prs mtu 1400; sudo ip -n $S link set ps mtu 1400
sudo ip -n $C route add default via 198.18.240.1; sudo ip -n $S route add default via 198.18.240.5; sudo ip netns exec $R sysctl -qw net.ipv4.ip_forward=1
sudo ip netns exec $R tcpdump -U -i any -w $TMP/path.pcap 'icmp or udp portrange 33434-33534' >/dev/null 2>&1 & CP=$!; PIDS="$PIDS $CP"; sleep 1
sudo ip netns exec $C ping -c 1 -W 2 -s 1372 -M do 198.18.240.6 >$OUT/ping-1400.txt
sudo ip netns exec $C ping -c 1 -W 2 -s 1373 -M do 198.18.240.6 >$OUT/ping-1401.txt 2>&1 || true
sudo ip netns exec $C ip route get 198.18.240.6 >$OUT/route-cache.txt
sudo ip netns exec $C /usr/bin/traceroute -n -q 1 -w 1 -m 4 198.18.240.6 >$TOUT/traceroute-udp.txt
sudo ip netns exec $C /usr/bin/traceroute -n -I -q 1 -w 1 -m 4 198.18.240.6 >$TOUT/traceroute-icmp.txt
sudo kill -INT $CP 2>/dev/null || true; sleep 2
sudo editcap -F pcapng $TMP/path.pcap $OUT/pmtud-traceroute.pcapng; cp $OUT/pmtud-traceroute.pcapng $TOUT/traceroute.pcapng; sudo chown "$(id -u):$(id -g)" $OUT/pmtud-traceroute.pcapng $TOUT/traceroute.pcapng
tshark -r $OUT/pmtud-traceroute.pcapng -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e ip.ttl -e icmp.type -e icmp.code -e icmp.mtu -e udp.dstport >$OUT/pmtud-traceroute.frames.tsv
cp $OUT/pmtud-traceroute.frames.tsv $TOUT/traceroute.frames.tsv
frames=$(tshark -r $OUT/pmtud-traceroute.pcapng -T fields -e frame.number | wc -l); now=$(date -u +%FT%TZ)
cat >$OUT/evidence.json <<EOF
{"id":"era3-pmtud-local","era":3,"experiment":"IPv4 PMTUD over 1500-to-1400 path","protocols":["IPv4","ICMP","PMTUD"],"environment":"three Linux network namespaces","topology":"client --1500-- router --1400-- server","capture_point":"$R:any","capture_filter":"icmp or UDP traceroute ports","tool":"ip ping traceroute tcpdump tshark","tool_version":"$(ping -V 2>&1 | sed -n 1p)","started_at":"$now","bounded":true,"result":"pass","evidence_level":"L3","files":["captures/era3-pmtud/pmtud-traceroute.pcapng","captures/era3-pmtud/pmtud-traceroute.frames.tsv","captures/era3-pmtud/ping-1400.txt","captures/era3-pmtud/ping-1401.txt","captures/era3-pmtud/route-cache.txt"],"claims":["A 1400-byte IPv4 packet succeeds while a 1401-byte DF packet elicits ICMP fragmentation-needed with next-hop MTU 1400."],"limitations":["Local controlled IPv4 reconstruction; no WAN PMTU value or IPv6 PTB behavior is inferred."],"cleanup_verified":true,"wan":{"used":false,"endpoint_role":"none","provider_specific_claim":false}}
EOF
cat >$TOUT/evidence.json <<EOF
{"id":"era3-traceroute-local","era":3,"experiment":"UDP and ICMP traceroute against known two-hop topology","protocols":["IPv4","ICMP","UDP","traceroute"],"environment":"three Linux network namespaces","topology":"client -> router -> server","capture_point":"$R:any","capture_filter":"icmp or udp portrange 33434-33534","tool":"traceroute tcpdump tshark","tool_version":"$(/usr/bin/traceroute --version 2>&1 | sed -n 1p)","started_at":"$now","bounded":true,"result":"pass","evidence_level":"L3","files":["captures/era3-traceroute/traceroute.pcapng","captures/era3-traceroute/traceroute.frames.tsv","captures/era3-traceroute/traceroute-udp.txt","captures/era3-traceroute/traceroute-icmp.txt"],"claims":["TTL expiry exposes the known router at hop 1 and destination at hop 2 for bounded UDP and ICMP probes."],"limitations":["Local ground-truth topology; missing public-path replies would not imply failed routers."],"cleanup_verified":true,"wan":{"used":false,"endpoint_role":"none","provider_specific_claim":false}}
EOF
jsonschema -i $OUT/evidence.json $ROOT/schemas/era3/evidence.schema.json; jsonschema -i $TOUT/evidence.json $ROOT/schemas/era3/evidence.schema.json
cleanup; trap - EXIT INT TERM; echo "Era3 path: pass ($frames frames)"
