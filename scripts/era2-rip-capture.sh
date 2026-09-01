#!/bin/sh
# M12: three-node RIPv2 propagation with BIRD in isolated namespaces.
# Redirects intentionally stay in caller-writable temporary/output directories.
# shellcheck disable=SC2024
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-captures/era2-rip}
# shellcheck source=scripts/lib/capture-path.sh
. "$ROOT/scripts/lib/capture-path.sh"
pz_require_capture_path "$ROOT" "$OUT" directory
OUT_DIR=$PZ_CAPTURE_PATH
OUT=$PZ_CAPTURE_RELATIVE
pz_require_capture_children "$ROOT" "$OUT" \
  rip-convergence.pcapng \
  rip-convergence.frames.tsv \
  rip-convergence.json
TMP=; PIDS=""
cleanup(){ for p in $PIDS; do sudo kill "$p" 2>/dev/null || true; done; for n in a b c; do sudo ip netns del pz-rip-$n 2>/dev/null || true; done; [ -z "$TMP" ] || sudo rm -rf "$TMP"; }
trap cleanup EXIT INT TERM
mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR/rip-convergence.pcapng" "$OUT_DIR/rip-convergence.frames.tsv" "$OUT_DIR/rip-convergence.json"
cleanup; TMP=$(mktemp -d /tmp/pz-rip.XXXXXX); sudo chmod 777 "$TMP"
for n in a b c; do sudo ip netns add pz-rip-$n; sudo ip -n pz-rip-$n link set lo up; done
sudo ip link add pz-rip-ab-a type veth peer name pz-rip-ab-b; sudo ip link set pz-rip-ab-a netns pz-rip-a; sudo ip link set pz-rip-ab-b netns pz-rip-b
sudo ip link add pz-rip-bc-b type veth peer name pz-rip-bc-c; sudo ip link set pz-rip-bc-b netns pz-rip-b; sudo ip link set pz-rip-bc-c netns pz-rip-c
sudo ip -n pz-rip-a addr add 198.18.160.1/30 dev pz-rip-ab-a; sudo ip -n pz-rip-b addr add 198.18.160.2/30 dev pz-rip-ab-b; sudo ip -n pz-rip-b addr add 198.18.160.5/30 dev pz-rip-bc-b; sudo ip -n pz-rip-c addr add 198.18.160.6/30 dev pz-rip-bc-c
for x in a:pz-rip-ab-a b:pz-rip-ab-b b:pz-rip-bc-b c:pz-rip-bc-c; do
  n=${x%%:*}; link=${x#*:}
  sudo ip -n "pz-rip-$n" link set "$link" up
done
# Synthetic loopback prefixes are the routes that should propagate end to end.
sudo ip -n pz-rip-a addr add 198.18.161.1/32 dev lo; sudo ip -n pz-rip-c addr add 198.18.163.1/32 dev lo
cat >"$TMP/a.conf" <<'EOF'
router id 198.18.160.1; protocol device { scan time 1; } protocol direct { ipv4; interface "lo"; } protocol rip zoo { ipv4 { import all; export all; }; interface "pz-rip-ab-a" { update time 2; }; }
EOF
cat >"$TMP/b.conf" <<'EOF'
router id 198.18.160.2; protocol device { scan time 1; } protocol direct { ipv4; interface "pz-rip-ab-b", "pz-rip-bc-b"; } protocol rip zoo { ipv4 { import all; export all; }; interface "pz-rip-ab-b", "pz-rip-bc-b" { update time 2; }; }
EOF
cat >"$TMP/c.conf" <<'EOF'
router id 198.18.160.6; protocol device { scan time 1; } protocol direct { ipv4; interface "lo"; } protocol rip zoo { ipv4 { import all; export all; }; interface "pz-rip-bc-c" { update time 2; }; }
EOF
sudo ip netns exec pz-rip-b timeout 15 tcpdump -U -i any -w "$TMP/rip.pcap" 'udp port 520' >/dev/null 2>&1 & PIDS="$PIDS $!"
for n in a b c; do sudo ip netns exec "pz-rip-$n" timeout 15 /usr/sbin/bird -f -c "$TMP/$n.conf" -s "$TMP/$n.ctl" -P "$TMP/$n.pid" >"$TMP/$n.log" 2>&1 & PIDS="$PIDS $!"; done
sleep 8
sudo ip netns exec pz-rip-a /usr/sbin/birdc -s "$TMP/a.ctl" 'show route protocol zoo' >"$TMP/a.routes"
sudo ip netns exec pz-rip-c /usr/sbin/birdc -s "$TMP/c.ctl" 'show route protocol zoo' >"$TMP/c.routes"
grep -q '198.18.163.1/32' "$TMP/a.routes"; grep -q '198.18.161.1/32' "$TMP/c.routes"
for p in $PIDS; do wait "$p" 2>/dev/null || true; done; PIDS=""
sudo editcap -F pcapng "$TMP/rip.pcap" "$OUT_DIR/rip-convergence.pcapng"; sudo chown "$(id -u):$(id -g)" "$OUT_DIR/rip-convergence.pcapng"
tshark -r "$OUT_DIR/rip-convergence.pcapng" -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e udp.srcport -e udp.dstport -e rip.command -e rip.ip -e rip.metric >"$OUT_DIR/rip-convergence.frames.tsv" 2>/dev/null
frames=$(tshark -r "$OUT_DIR/rip-convergence.pcapng" -T fields -e frame.number | wc -l); [ "$frames" -gt 0 ]; tshark -r "$OUT_DIR/rip-convergence.pcapng" -Y 'rip' -T fields -e frame.number | grep -q .
cat >"$OUT_DIR/rip-convergence.json" <<EOF
{"protocol":"rip","experiment":"m12-three-node-rip-netns","evidence_level":"real-capture","environment":{"os":"linux","kernel":"$(uname -r)","topology":"three private namespaces A-B-C","tools":{"bird":"$(/usr/sbin/bird --version 2>&1 | sed -n 1p)","tshark":"$(tshark --version 2>/dev/null | sed -n 1p)"}},"capture_point":"pz-rip-b:any","command":"scripts/era2-rip-capture.sh","capture_filter":"udp port 520","result":{"handshake":"pass","capture":"$OUT/rip-convergence.pcapng","frames":$frames,"route_a_learned":"198.18.163.1/32","route_c_learned":"198.18.161.1/32"},"sanitized":true,"notes":["Three-node RIPv2 propagation used only 198.18.160.0/24-style documentation ranges inside namespaces."]}
EOF
jsonschema -i "$OUT_DIR/rip-convergence.json" "$ROOT/schemas/experiment.schema.json"
cleanup; trap - EXIT INT TERM; printf 'M12 RIP convergence: pass (%s frames)\n' "$frames"
