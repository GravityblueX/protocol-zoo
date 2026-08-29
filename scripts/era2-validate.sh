#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

for f in captures/fixtures/era2/*; do [ -s "$f" ] || { echo "empty fixture: $f" >&2; exit 1; }; done
for f in research/second-era-natural-history.md research/pre-ip-ncp.md research/era2-sources.md research/era2-experiment-matrix.md docs/ERA2-STATUS.md; do [ -s "$f" ] || exit 1; done
grep -q 'M10' ROADMAP.md
grep -q 'evidence_level' species/_template/README.md
grep -q 'M19' IMPLEMENTATION_PLAN.md

node - <<'NODE'
const fs = require('fs');
const rows = fs.readFileSync('datasets/era2.csv','utf8').trimEnd().split('\n').map(r => r.split(','));
const width = rows[0].length;
if (rows.some(r => r.length !== width)) throw new Error('era2.csv column mismatch');
const allowed = new Set(['real-capture','fixture','static','document-reconstruction','not-run']);
for (const [i,row] of rows.slice(1).entries()) if (!allowed.has(row[5])) throw new Error(`invalid evidence_level row ${i+2}: ${row[5]}`);
NODE

# M10 is declared real-capture: its evidence is mandatory, not optional.
JSON=captures/era2-netns/boot-chain.json
PCAP=captures/era2-netns/boot-chain.pcapng
TSV=captures/era2-netns/boot-chain.frames.tsv
for f in "$JSON" "$PCAP" "$TSV"; do [ -s "$f" ] || { echo "missing M10 real-capture evidence: $f" >&2; exit 1; }; done
jsonschema -i "$JSON" schemas/experiment.schema.json
[ "$(jq -r '.evidence_level' "$JSON")" = real-capture ]
[ "$(jq -r '.result.handshake' "$JSON")" = pass ]
[ "$(jq -r '.result.dhcp' "$JSON")" = pass ]
[ "$(jq -r '.result.tftp' "$JSON")" = pass ]
DECLARED=$(jq -r '.result.frames' "$JSON")
ACTUAL=$(tshark -r "$PCAP" -T fields -e frame.number 2>/dev/null | wc -l)
[ "$ACTUAL" -gt 0 ]
[ "$DECLARED" -eq "$ACTUAL" ] || { echo "M10 frame mismatch: json=$DECLARED pcap=$ACTUAL" >&2; exit 1; }
for msg in 1 2 3 5; do tshark -r "$PCAP" -Y "dhcp.option.dhcp == $msg" -T fields -e frame.number 2>/dev/null | grep -q . || { echo "missing DHCP message type $msg" >&2; exit 1; }; done
for op in 1 3 4; do tshark -r "$PCAP" -Y "tftp.opcode == $op" -T fields -e frame.number 2>/dev/null | grep -q . || { echo "missing TFTP opcode $op" >&2; exit 1; }; done

# M13/M18 are also declared real-capture.
for stem in icmp-lifecycle igmp-membership; do
  J="captures/era2-network/$stem.json"; P="captures/era2-network/$stem.pcapng"; T="captures/era2-network/$stem.frames.tsv"
  for f in "$J" "$P" "$T"; do [ -s "$f" ] || { echo "missing real-capture evidence: $f" >&2; exit 1; }; done
  jsonschema -i "$J" schemas/experiment.schema.json
  [ "$(jq -r '.evidence_level' "$J")" = real-capture ]
  [ "$(jq -r '.result.handshake' "$J")" = pass ]
  d=$(jq -r '.result.frames' "$J"); a=$(tshark -r "$P" -T fields -e frame.number 2>/dev/null | wc -l)
  [ "$d" -eq "$a" ] && [ "$a" -gt 0 ] || { echo "$stem frame mismatch" >&2; exit 1; }
done
tshark -r captures/era2-network/icmp-lifecycle.pcapng -Y 'icmp.type == 0' -T fields -e frame.number 2>/dev/null | grep -q .
tshark -r captures/era2-network/icmp-lifecycle.pcapng -Y 'icmp.type == 3 && icmp.code == 3' -T fields -e frame.number 2>/dev/null | grep -q .
tshark -r captures/era2-network/igmp-membership.pcapng -Y 'igmp' -T fields -e frame.number 2>/dev/null | grep -q .

NBNSJ=captures/era2-netbios/nbns.json
NBNSP=captures/era2-netbios/nbns.pcapng
[ -s "$NBNSJ" ] && [ -s "$NBNSP" ]
jsonschema -i "$NBNSJ" schemas/experiment.schema.json
[ "$(jq -r '.evidence_level' "$NBNSJ")" = real-capture ]
[ "$(jq -r '.result.frames' "$NBNSJ")" -eq "$(tshark -r "$NBNSP" -T fields -e frame.number 2>/dev/null | wc -l)" ]
tshark -r "$NBNSP" -Y 'nbns' -T fields -e frame.number 2>/dev/null | grep -q .

echo 'second-era validation: pass'
