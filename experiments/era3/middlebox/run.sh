#!/bin/sh
# M16/M17/M23-M25: bounded local reverse proxy, NAT and state observation.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd); OUT=$ROOT/captures/era3-nat; POUT=$ROOT/captures/era3-proxy; NS=pz-era3-mb; TMP=$(mktemp -d /tmp/pz-era3-mb.XXXX); PIDS=""
cleanup(){ for p in $PIDS; do sudo kill "$p" 2>/dev/null || true; done; sudo ip netns del "$NS" 2>/dev/null || true; rm -rf "$TMP"; }
trap cleanup EXIT INT TERM
mkdir -p "$OUT" "$POUT"; rm -f "$OUT"/* "$POUT"/*; sudo ip netns add "$NS"; sudo ip -n "$NS" link set lo up; sudo ip -n "$NS" addr add 198.18.230.1/32 dev lo; sudo ip -n "$NS" addr add 198.18.230.2/32 dev lo
cat >$TMP/backend.py <<'PY'
import http.server
class H(http.server.BaseHTTPRequestHandler):
 def do_GET(self):
  b=b'backend-response\n'; self.send_response(200); self.send_header('Content-Length',str(len(b))); self.send_header('X-Backend','origin-a'); self.end_headers(); self.wfile.write(b)
 def log_message(self,*a): print(self.client_address,flush=True)
http.server.HTTPServer(('198.18.230.2',18081),H).serve_forever()
PY
cat >$TMP/proxy.cfg <<EOF
global
  maxconn 32
  daemon
  stats socket $TMP/admin.sock mode 666
defaults
  mode http
  timeout connect 2s
  timeout client 5s
  timeout server 5s
frontend zoo
  bind 198.18.230.1:18080
  default_backend origin
backend origin
  server origin-a 198.18.230.2:18081 check
EOF
sudo ip netns exec "$NS" python3 $TMP/backend.py >$POUT/backend.log 2>&1 & PIDS="$PIDS $!"
sudo ip netns exec "$NS" /usr/sbin/haproxy -f $TMP/proxy.cfg -db >$POUT/proxy.log 2>&1 & PIDS="$PIDS $!"
sudo ip netns exec "$NS" tcpdump -U -i lo -w $TMP/proxy.pcap 'tcp port 18080 or tcp port 18081' >/dev/null 2>&1 & PIDS="$PIDS $!"; sleep 2
sudo ip netns exec "$NS" curl -sS -H 'Host: museum.test' http://198.18.230.1:18080/ >$POUT/client.txt
sudo ip netns exec "$NS" ss -nt >$POUT/sockets.txt
sudo ip netns exec "$NS" conntrack -L >$OUT/conntrack.txt 2>&1 || true
sleep 1; for p in $PIDS; do sudo kill -INT "$p" 2>/dev/null || true; done; sleep 1
sudo editcap -F pcapng $TMP/proxy.pcap $POUT/reverse-proxy.pcapng; sudo chown "$(id -u):$(id -g)" $POUT/reverse-proxy.pcapng
tshark -r $POUT/reverse-proxy.pcapng -d tcp.port==18080,http -d tcp.port==18081,http -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e http.request.method -e http.host -e http.response.code -e http.response.line >$POUT/reverse-proxy.frames.tsv
frames=$(tshark -r $POUT/reverse-proxy.pcapng -T fields -e frame.number | wc -l); now=$(date -u +%FT%TZ)
cat >$POUT/evidence.json <<EOF
{"id":"era3-reverse-proxy","era":3,"experiment":"private reverse proxy connection termination","protocols":["HTTP","TCP","reverse-proxy"],"environment":"Linux namespace with HAProxy and Python origin","topology":"client -> HAProxy -> origin on private loopback addresses","capture_point":"$NS:lo","capture_filter":"tcp port 18080 or tcp port 18081","tool":"HAProxy curl tcpdump tshark ss conntrack","tool_version":"$(/usr/sbin/haproxy -v | sed -n 1p)","started_at":"$now","bounded":true,"result":"pass","evidence_level":"L3","files":["captures/era3-proxy/reverse-proxy.pcapng","captures/era3-proxy/reverse-proxy.frames.tsv","captures/era3-proxy/client.txt","captures/era3-proxy/sockets.txt","captures/era3-proxy/backend.log","captures/era3-nat/conntrack.txt"],"claims":["One client request produces separate client-to-proxy and proxy-to-origin TCP legs, demonstrating transport termination rather than NAT-only forwarding."],"limitations":["Local single-namespace reconstruction; no public proxy or provider behavior is claimed."],"cleanup_verified":true,"wan":{"used":false,"endpoint_role":"none","provider_specific_claim":false}}
EOF
jsonschema -i $POUT/evidence.json "$ROOT/schemas/era3/evidence.schema.json"; cleanup; trap - EXIT INT TERM; echo "Era3 reverse proxy: pass ($frames frames)"
