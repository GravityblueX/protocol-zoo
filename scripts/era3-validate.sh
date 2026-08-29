#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd); cd "$ROOT"
command -v jq >/dev/null; command -v jsonschema >/dev/null; command -v tshark >/dev/null
jsonschema -i schemas/era3/evidence.schema.json schemas/era3/evidence.schema.json >/dev/null 2>&1 || jq empty schemas/era3/evidence.schema.json
count=0
find captures -path '*/era3-*/*.json' -type f -print | sort | while read -r f; do
  jsonschema -i "$f" schemas/era3/evidence.schema.json
  jq -e '.era==3 and .bounded==true and .cleanup_verified==true' "$f" >/dev/null
  jq -r '.files[]' "$f" | while read -r p; do [ -e "$p" ] || { echo "missing declared evidence: $p ($f)" >&2; exit 1; }; done
  if [ "$(jq -r '.evidence_level' "$f")" = L3 ] || [ "$(jq -r '.evidence_level' "$f")" = L4 ]; then
    p=$(jq -r '.files[] | select(test("\\.(pcap|pcapng)$"))' "$f" | head -1); [ -n "$p" ] && [ -s "$p" ]; [ -z "$p" ] || tshark -r "$p" -T fields -e frame.number >/dev/null
  fi
  count=$((count+1))
done
for f in docs/era3/*.md; do [ -s "$f" ] || { echo "empty Era 3 doc: $f" >&2; exit 1; }; ! grep -Eq 'TODO|TBD|PLACEHOLDER' "$f" || { echo "placeholder in $f" >&2; exit 1; }; done
jq empty data/era3/*.json 2>/dev/null || true
! ip netns list | grep -q '^pz-era3-' || { echo 'Era 3 namespace residue' >&2; exit 1; }
! grep -RIlE 'BEGIN (OPENSSH |RSA |EC )?PRIVATE KEY' docs experiments captures data scripts >/dev/null || { echo 'private key leak' >&2; exit 1; }
echo 'third-era validation: pass'
