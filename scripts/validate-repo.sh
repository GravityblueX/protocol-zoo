#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"
command -v jq >/dev/null
command -v jsonschema >/dev/null
jq empty schemas/experiment.schema.json
jsonschema -i captures/dummy-tcp-netns.json schemas/experiment.schema.json
[ "$(jq -r '.result.handshake' captures/dummy-tcp-netns.json)" = pass ]
[ "$(jq -r '.sanitized' captures/dummy-tcp-netns.json)" = true ]
if [ -f captures/capabilities.json ]; then
  jsonschema -i captures/capabilities.json schemas/experiment.schema.json
  [ "$(jq -r '.result.handshake' captures/capabilities.json)" = not_run ]
  [ "$(jq -r '.sanitized' captures/capabilities.json)" = true ]
fi
command -v tshark >/dev/null && tshark -r captures/dummy-tcp-netns.pcapng >/dev/null
for result in captures/*.json captures/*/*.json; do
  [ -f "$result" ] || continue
  case "$result" in captures/era3-*/*.json) continue ;; esac
  jsonschema -i "$result" schemas/experiment.schema.json
  [ "$(jq -r '.sanitized' "$result")" = true ] || { echo "unsanitized result: $result" >&2; exit 1; }
done
for capture in captures/*.pcap captures/*.pcapng captures/*/*.pcap captures/*/*.pcapng; do
  [ -f "$capture" ] || continue
  tshark -r "$capture" -T fields -e frame.number >/dev/null
  [ "$(stat -c '%s' "$capture")" -gt 0 ] || { echo "empty capture: $capture" >&2; exit 1; }
done
! ip netns list | grep -q '^pz-' || { echo 'namespace residue' >&2; exit 1; }
git diff --check
echo 'protocol-zoo validation: pass'
