#!/bin/sh
# Produce structured not-run/static results for second-era mechanisms without external traffic.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-captures/era2-static}
# shellcheck source=scripts/lib/capture-path.sh
. "$ROOT/scripts/lib/capture-path.sh"
pz_require_capture_path "$ROOT" "$OUT" directory
OUT_DIR=$PZ_CAPTURE_PATH
OUT=$PZ_CAPTURE_RELATIVE
pz_require_capture_children "$ROOT" "$OUT" status.json
mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR/status.json"
cat >"$OUT_DIR/status.json" <<'EOF'
{
  "protocol": "era2-static-suite",
  "experiment": "phase-10-to-18-static-boundaries",
  "evidence_level": "not-run",
  "environment": {"os": "linux", "kernel": "host-observation", "topology": "none", "tools": {"source": "RFC-indexed document reconstruction"}},
  "result": {"handshake": "not_run", "capture": "none", "frames": 0, "m10_rarp_bootp": "document-reconstruction", "m11_slip_ppp": "fixture", "m12_egp": "document-reconstruction", "m13_source_quench": "synthetic-fixture", "m14_netbios": "fixture", "m15_ipv6_transition": "fixture", "m16_ncp": "document-reconstruction", "m17_rlogin": "static", "m18_multicast": "fixture"},
  "sanitized": true,
  "notes": ["No external traffic, relay, broker, historical host, or production route was used.", "not_run is intentional for mechanisms lacking a safe local implementation or requiring historical infrastructure."]
}
EOF
jsonschema -i "$OUT_DIR/status.json" "$ROOT/schemas/experiment.schema.json"
printf 'era2 static results: pass\n'
