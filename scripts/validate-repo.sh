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
command -v tshark >/dev/null && tshark -r captures/dummy-tcp-netns.pcapng >/dev/null
! ip netns list | grep -q '^pz-' || { echo 'namespace residue' >&2; exit 1; }
git diff --check
echo 'protocol-zoo validation: pass'
