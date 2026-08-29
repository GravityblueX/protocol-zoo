#!/bin/sh
# M26/M27: bounded plaintext HTTP vs HTTPS evidence inside one namespace.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd); OUT=$ROOT/captures/era3-http; TLSOUT=$ROOT/captures/era3-tls; NS=pz-era3-http; TMP=$(mktemp -d /tmp/pz-era3-http.XXXX); PIDS=""
cleanup(){ for p in $PIDS; do sudo kill "$p" 2>/dev/null || true; done; sudo ip netns del "$NS" 2>/dev/null || true; rm -rf "$TMP"; }
trap cleanup EXIT INT TERM
mkdir -p "$OUT" "$TLSOUT"; rm -f "$OUT"/* "$TLSOUT"/*; sudo ip netns del "$NS" 2>/dev/null || true; sudo ip netns add "$NS"; sudo ip -n "$NS" link set lo up; sudo ip -n "$NS" addr add 198.18.210.1/32 dev lo
openssl req -x509 -newkey rsa:2048 -nodes -subj '/CN=museum.test' -days 1 -keyout "$TMP/key.pem" -out "$TMP/cert.pem" >/dev/null 2>&1
cat >$TMP/server.py <<'PY'
import http.server,ssl,sys
class H(http.server.BaseHTTPRequestHandler):
 protocol_version='HTTP/1.1'
 def do_GET(self):
  body=b'protocol-zoo-era3-payload\n'
  self.send_response(200); self.send_header('Content-Type','text/plain'); self.send_header('Content-Length',str(len(body))); self.send_header('Connection','keep-alive'); self.end_headers(); self.wfile.write(body)
 def log_message(self,fmt,*args): print(self.client_address, self.request_version, self.headers.get('Host'), fmt%args, flush=True)
port=int(sys.argv[1]); s=http.server.ThreadingHTTPServer(('198.18.210.1',port),H)
if len(sys.argv)>2:
 c=ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER); c.load_cert_chain(sys.argv[2],sys.argv[3]); c.set_alpn_protocols(['http/1.1']); s.socket=c.wrap_socket(s.socket,server_side=True)
s.serve_forever()
PY
sudo ip netns exec "$NS" python3 "$TMP/server.py" 18080 >$OUT/server.log 2>&1 & PIDS="$PIDS $!"
sudo ip netns exec "$NS" python3 "$TMP/server.py" 18443 "$TMP/cert.pem" "$TMP/key.pem" >$TLSOUT/server.log 2>&1 & PIDS="$PIDS $!"
sudo ip netns exec "$NS" tcpdump -U -i lo -w "$TMP/http.pcap" 'tcp port 18080' >/dev/null 2>&1 & HP=$!; PIDS="$PIDS $HP"
sudo ip netns exec "$NS" tcpdump -U -i lo -w "$TMP/tls.pcap" 'tcp port 18443' >/dev/null 2>&1 & TP=$!; PIDS="$PIDS $TP"; sleep 1
sudo ip netns exec "$NS" curl --http1.0 -sS -H 'Host: museum.test' http://198.18.210.1:18080/ >$OUT/http10-body.txt
sudo ip netns exec "$NS" curl --http1.1 -sS -H 'Host: museum.test' http://198.18.210.1:18080/ >$OUT/http11-body.txt
sudo ip netns exec "$NS" curl --http1.1 -skS -H 'Host: museum.test' https://198.18.210.1:18443/ >$TLSOUT/https-body.txt
sleep 1; sudo kill -INT "$HP" "$TP" 2>/dev/null || true; sleep 1
sudo editcap -F pcapng "$TMP/http.pcap" "$OUT/http-versions.pcapng"; sudo editcap -F pcapng "$TMP/tls.pcap" "$TLSOUT/https.pcapng"; sudo chown "$(id -u):$(id -g)" "$OUT/http-versions.pcapng" "$TLSOUT/https.pcapng"
tshark -r "$OUT/http-versions.pcapng" -d tcp.port==18080,http -T fields -E header=y -e frame.number -e tcp.stream -e http.request.version -e http.host -e http.response.code >$OUT/http-versions.frames.tsv 2>/dev/null
tshark -r "$TLSOUT/https.pcapng" -d tcp.port==18443,tls -T fields -E header=y -e frame.number -e tls.handshake.type -e tls.handshake.extensions_server_name -e tls.handshake.extensions_alpn_str >$TLSOUT/https.frames.tsv 2>/dev/null
hf=$(tshark -r "$OUT/http-versions.pcapng" -T fields -e frame.number | wc -l); tf=$(tshark -r "$TLSOUT/https.pcapng" -T fields -e frame.number | wc -l); now=$(date -u +%FT%TZ)
cat >$OUT/evidence.json <<EOF
{"id":"era3-http-versions","era":3,"experiment":"HTTP/1.0 and HTTP/1.1 plaintext connection evidence","protocols":["HTTP/1.0","HTTP/1.1","TCP"],"environment":"Linux network namespace and Python mature stdlib server","topology":"client and origin on isolated loopback address","capture_point":"$NS:lo","capture_filter":"tcp port 18080","tool":"curl Python tcpdump tshark","tool_version":"$(curl --version | sed -n 1p)","started_at":"$now","bounded":true,"result":"pass","evidence_level":"L3","files":["captures/era3-http/http-versions.pcapng","captures/era3-http/http-versions.frames.tsv","captures/era3-http/http10-body.txt","captures/era3-http/http11-body.txt","captures/era3-http/server.log"],"claims":["Plaintext capture exposes HTTP version, Host and application payload while separate client invocations create separate TCP streams."],"limitations":["This is a local modern reconstruction, not a historical browser workload; pipelining and chunked transfer are not claimed."],"cleanup_verified":true,"wan":{"used":false,"endpoint_role":"none","provider_specific_claim":false}}
EOF
cat >$TLSOUT/evidence.json <<EOF
{"id":"era3-tls-visibility","era":3,"experiment":"HTTP plaintext versus HTTPS visibility","protocols":["TLS","HTTPS","TCP"],"environment":"Linux network namespace with temporary self-signed certificate","topology":"client and TLS origin on isolated loopback address","capture_point":"$NS:lo","capture_filter":"tcp port 18443","tool":"OpenSSL curl Python tcpdump tshark","tool_version":"$(openssl version)","started_at":"$now","bounded":true,"result":"pass","evidence_level":"L3","files":["captures/era3-tls/https.pcapng","captures/era3-tls/https.frames.tsv","captures/era3-tls/https-body.txt","captures/era3-tls/server.log"],"claims":["Capture exposes IP, TCP and TLS handshake metadata while the HTTP payload is not readable as plaintext HTTP."],"limitations":["Self-signed local TLS does not establish public PKI trust and no real private session content was used."],"cleanup_verified":true,"wan":{"used":false,"endpoint_role":"none","provider_specific_claim":false}}
EOF
jsonschema -i $OUT/evidence.json $ROOT/schemas/era3/evidence.schema.json; jsonschema -i $TLSOUT/evidence.json $ROOT/schemas/era3/evidence.schema.json
cleanup; trap - EXIT INT TERM; echo "Era3 HTTP/TLS: pass ($hf HTTP frames, $tf TLS frames)"
