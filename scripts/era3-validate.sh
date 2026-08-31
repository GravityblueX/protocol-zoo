#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd); cd "$ROOT"
EVIDENCE_FILES='
captures/era3-dns/evidence.json
captures/era3-http/evidence.json
captures/era3-tls/evidence.json
captures/era3-tunnels/evidence.json
captures/era3-proxy/evidence.json
captures/era3-pmtud/evidence.json
captures/era3-traceroute/evidence.json
'

# Era 3 is closed around these seven evidence records. Do not silently pass
# when a descriptor disappears while its packet/text artifacts remain.
for f in $EVIDENCE_FILES; do
  [ -s "$f" ] || { echo "missing Era 3 evidence descriptor: $f" >&2; exit 1; }
done

command -v jq >/dev/null; command -v jsonschema >/dev/null; command -v tshark >/dev/null
jq empty schemas/era3/evidence.schema.json
for f in $EVIDENCE_FILES; do
  jsonschema -i "$f" schemas/era3/evidence.schema.json
  jq -e '.era==3 and .bounded==true and .cleanup_verified==true' "$f" >/dev/null
  jq -r '.files[]' "$f" | while read -r p; do
    case "$p" in
      /*|..|../*|*/..|*/../*) echo "evidence path escapes repository: $p ($f)" >&2; exit 1 ;;
    esac
    [ -s "$p" ] || { echo "missing or empty declared evidence: $p ($f)" >&2; exit 1; }
  done
  if [ "$(jq -r '.evidence_level' "$f")" = L3 ] || [ "$(jq -r '.evidence_level' "$f")" = L4 ]; then
    p=$(jq -r 'first(.files[] | select(test("\\.(pcap|pcapng)$"))) // empty' "$f")
    [ -n "$p" ] || { echo "packet-level record declares no capture: $f" >&2; exit 1; }
    tshark -r "$p" -T fields -e frame.number >/dev/null
  fi
done
# Protocol-specific semantic gates for packet-level evidence.
tshark -r captures/era3-dns/dns-hierarchy.pcapng -Y 'dns' -T fields -e frame.number | grep -q .
tshark -r captures/era3-http/http-versions.pcapng -d tcp.port==18080,http -Y 'http.request.version == "HTTP/1.0"' -T fields -e frame.number | grep -q .
tshark -r captures/era3-http/http-versions.pcapng -d tcp.port==18080,http -Y 'http.request.version == "HTTP/1.1"' -T fields -e frame.number | grep -q .
tshark -r captures/era3-tls/https.pcapng -d tcp.port==18443,tls -Y 'tls.handshake.type == 1' -T fields -e frame.number | grep -q .
tshark -r captures/era3-tunnels/gre-overlay.pcapng -Y 'ip.proto == 47' -T fields -e frame.number | grep -q .
tshark -r captures/era3-proxy/reverse-proxy.pcapng -Y 'tcp.port == 18080 || tcp.port == 18081' -T fields -e frame.number | grep -q .
grep -q 'backend-response' captures/era3-proxy/client.txt
grep -q '198.18.230.2' captures/era3-proxy/reverse-proxy.frames.tsv
tshark -r captures/era3-pmtud/pmtud-traceroute.pcapng -Y 'icmp.type == 3 && icmp.code == 4 && icmp.mtu == 1400' -T fields -e frame.number | grep -q .
grep -q '198.18.240.1' captures/era3-traceroute/traceroute-udp.txt
grep -q '198.18.240.6' captures/era3-traceroute/traceroute-icmp.txt
! tshark -r captures/era3-tls/https.pcapng -Y 'http' -T fields -e frame.number | grep -q .
for f in docs/era3/*.md; do [ -s "$f" ] || { echo "empty Era 3 doc: $f" >&2; exit 1; }; ! grep -Eq 'TODO|TBD|PLACEHOLDER' "$f" || { echo "placeholder in $f" >&2; exit 1; }; done
[ -s docs/中文导览.md ] || { echo 'missing Chinese guide' >&2; exit 1; }
! grep -Eq 'TODO|TBD|PLACEHOLDER' docs/中文导览.md || { echo 'placeholder in Chinese guide' >&2; exit 1; }
jq empty data/era3/*.json
! ip netns list | grep -q '^pz-era3-' || { echo 'Era 3 namespace residue' >&2; exit 1; }
! grep -RIlE 'BEGIN (OPENSSH |RSA |EC )?PRIVATE KEY' docs experiments captures data scripts >/dev/null || { echo 'private key leak' >&2; exit 1; }
echo 'third-era validation: pass'
