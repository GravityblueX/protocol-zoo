#!/bin/sh
# Record local kernel/tool capability without creating interfaces or contacting a network.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-captures/capabilities.json}
mkdir -p "$ROOT/$(dirname "$OUT")"

have() { command -v "$1" >/dev/null 2>&1 && printf true || printf false; }
module_loaded() { grep -Eq "^$1( |$)" /proc/net/protocols 2>/dev/null && printf true || printf false; }
# A protocol can be compiled into the kernel without being listed in /proc/net/protocols.
# Keep this report observational: no module loading and no network setup.
KERNEL=$(uname -r)
IP=$(ip -V 2>&1 | sed -n '1p')
TSHARK=$(tshark --version 2>/dev/null | sed -n '1p' || true)

jq -n \
  --arg kernel "$KERNEL" \
  --arg ip "$IP" \
  --arg tshark "$TSHARK" \
  --argjson iproute2 "$(have ip)" \
  --argjson tshark_available "$(have tshark)" \
  --argjson sctp_proc "$(module_loaded sctp)" \
  --argjson dccp_proc "$(module_loaded dccp)" \
  --argjson udplite_proc "$(module_loaded udplite)" \
  '{protocol:"capability-report", experiment:"phase-6-kernel-capability-observation", evidence_level:"not-run", environment:{os:"linux", kernel:$kernel, topology:"host-observation", tools:{ip:$ip,tshark:$tshark}}, result:{handshake:"not_run",capture:"none",frames:0,capabilities:{iproute2:$iproute2,tshark:$tshark_available,proc_net_protocols:{sctp:$sctp_proc,dccp:$dccp_proc,udplite:$udplite_proc}}}, sanitized:true, notes:["Observation only: no module loading, namespace creation, route changes, or network peers.","not_run is intentional; a real transport experiment requires explicit CAP_NET_ADMIN and an implementation/API test."]}' > "$ROOT/$OUT"
jsonschema -i "$ROOT/$OUT" "$ROOT/schemas/experiment.schema.json"
printf 'pass: capability report -> %s\n' "$OUT"
