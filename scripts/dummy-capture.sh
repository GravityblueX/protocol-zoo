#!/bin/sh
# Prove setup -> TCP exchange -> pcapng -> structured result -> cleanup.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
CAPTURE=${CAPTURE:-captures/dummy-tcp-netns.pcapng}
RESULT=${RESULT:-captures/dummy-tcp-netns.json}
PORT=${PORT:-18080}
# shellcheck source=scripts/lib/capture-path.sh
. "$ROOT/scripts/lib/capture-path.sh"
pz_require_capture_path "$ROOT" "$CAPTURE" file
CAPTURE_FILE=$PZ_CAPTURE_PATH
CAPTURE=$PZ_CAPTURE_RELATIVE
pz_require_capture_path "$ROOT" "$RESULT" file
RESULT_FILE=$PZ_CAPTURE_PATH
RESULT=$PZ_CAPTURE_RELATIVE
pz_require_disjoint_capture_files "$CAPTURE_FILE" "$RESULT_FILE"
PCAP_TMP=
HARNESS="$ROOT/scripts/lab-netns.sh"
SERVER_PID=
CAPTURE_PID=
cleanup() {
  [ -z "$SERVER_PID" ] || kill "$SERVER_PID" 2>/dev/null || true
  [ -z "$CAPTURE_PID" ] || kill -INT "$CAPTURE_PID" 2>/dev/null || true
  [ -z "$PCAP_TMP" ] || rm -f "$PCAP_TMP"
  "$HARNESS" teardown
}
trap cleanup EXIT INT TERM
mkdir -p "$(dirname "$CAPTURE_FILE")" "$(dirname "$RESULT_FILE")"
rm -f "$CAPTURE_FILE" "$RESULT_FILE"
PCAP_TMP=$(mktemp --suffix=.pcap)
"$HARNESS" setup
ip netns exec pz-server sh -c "printf 'museum-ok\\n' | nc -l -s 198.18.0.2 -p $PORT -q 1" & SERVER_PID=$!
ip netns exec pz-server tcpdump -U -i pz-veth-s -w "$PCAP_TMP" "tcp port $PORT" >/dev/null 2>&1 & CAPTURE_PID=$!
sleep 1
REPLY=$(printf 'visitor-hello\n' | ip netns exec pz-client nc -w 3 198.18.0.2 "$PORT")
[ "$REPLY" = "museum-ok" ]
wait "$SERVER_PID"; SERVER_PID=
sleep 1
kill -INT "$CAPTURE_PID" 2>/dev/null || true
wait "$CAPTURE_PID" || true; CAPTURE_PID=
editcap -F pcapng "$PCAP_TMP" "$CAPTURE_FILE"
rm -f "$PCAP_TMP"; PCAP_TMP=
FRAMES=$(tshark -r "$CAPTURE_FILE" -T fields -e frame.number 2>/dev/null | wc -l)
KERNEL=$(uname -r)
TCPDUMP=$(tcpdump --version 2>&1 | sed -n '1p')
TSHARK=$(tshark --version 2>/dev/null | sed -n '1p')
cat > "$RESULT_FILE" <<EOF
{
  "protocol": "dummy-tcp",
  "experiment": "phase-0-netns-harness",
  "evidence_level": "real-capture",
  "environment": {"os": "linux", "kernel": "$KERNEL", "topology": "netns-veth", "tools": {"tcpdump": "$TCPDUMP", "tshark": "$TSHARK"}},
  "capture_point": "pz-server:pz-veth-s",
  "command": "scripts/dummy-capture.sh",
  "capture_filter": "tcp port $PORT",
  "result": {"handshake": "pass", "capture": "$CAPTURE", "frames": $FRAMES},
  "sanitized": true,
  "notes": ["Fixed documentation-range addresses and synthetic payload only."]
}
EOF
jsonschema -i "$RESULT_FILE" "$ROOT/schemas/experiment.schema.json"
echo "pass: $FRAMES frames -> $CAPTURE"
