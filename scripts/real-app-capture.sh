#!/bin/sh
# Run mature Telnet and FTP implementations entirely inside pz-client/pz-server.
# Redirects intentionally stay in caller-writable temporary/output directories.
# shellcheck disable=SC2024
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-captures/real-app-netns}
# shellcheck source=scripts/lib/capture-path.sh
. "$ROOT/scripts/lib/capture-path.sh"
pz_require_capture_path "$ROOT" "$OUT" directory
OUT_DIR=$PZ_CAPTURE_PATH
OUT=$PZ_CAPTURE_RELATIVE
pz_require_capture_children "$ROOT" "$OUT" \
  telnet.pcapng \
  ftp-passive.log \
  ftp-active.log \
  ftp.pcapng \
  telnet.frames.tsv \
  ftp.frames.tsv
mkdir -p "$OUT_DIR"
rm -f \
  "$OUT_DIR/telnet.pcapng" \
  "$OUT_DIR/ftp-passive.log" \
  "$OUT_DIR/ftp-active.log" \
  "$OUT_DIR/ftp.pcapng" \
  "$OUT_DIR/telnet.frames.tsv" \
  "$OUT_DIR/ftp.frames.tsv"
PIDS=""; cleanup() { for p in $PIDS; do sudo kill "$p" 2>/dev/null || true; done; sudo "$ROOT/scripts/lab-netns.sh" teardown; }
trap cleanup EXIT INT TERM
sudo "$ROOT/scripts/lab-netns.sh" setup
# inetd config is namespace-local and is not installed on the host.
cat >/tmp/pz-inetd.conf <<'EOF'
18023 stream tcp nowait root /usr/sbin/telnetd telnetd -h -E /bin/cat
EOF
sudo ip netns exec pz-server /usr/sbin/inetutils-inetd --foreground /tmp/pz-inetd.conf >/tmp/pz-inetd.log 2>&1 & PIDS="$PIDS $!"
sudo ip netns exec pz-server tcpdump -U -i pz-veth-s -w /tmp/pz-telnet-real.pcap 'tcp port 18023' >/dev/null 2>&1 & PIDS="$PIDS $!"
sleep 1
printf 'protocol-zoo-telnet\n' | sudo ip netns exec pz-client telnet 198.18.0.2 18023 >/tmp/pz-telnet-client.log 2>&1 || true
sleep 1
for p in $PIDS; do sudo kill -INT "$p" 2>/dev/null || true; done; PIDS=""
editcap -F pcapng /tmp/pz-telnet-real.pcap "$OUT_DIR/telnet.pcapng"
# FTP server and client use a namespace-only address and synthetic data.
FTP_ROOT=/tmp/pz-ftp-root-$$; mkdir -p "$FTP_ROOT"; chmod 755 "$FTP_ROOT"; printf 'protocol-zoo ftp payload\n' >"$FTP_ROOT/readme.txt"; chmod 644 "$FTP_ROOT/readme.txt"
cat >/tmp/pz-ftp-server.py <<PY
from pyftpdlib.authorizers import DummyAuthorizer
from pyftpdlib.handlers import FTPHandler
from pyftpdlib.servers import FTPServer
a=DummyAuthorizer(); a.add_user('zoo','zoo-pass', '$FTP_ROOT', perm='elradfmwMT')
h=FTPHandler; h.authorizer=a; h.passive_ports=19000,19009
FTPServer(('198.18.0.2',2121),h).serve_forever()
PY
sudo ip netns exec pz-server python3 /tmp/pz-ftp-server.py >/tmp/pz-ftp-real.log 2>&1 & PIDS="$PIDS $!"
sudo ip netns exec pz-server tcpdump -U -i pz-veth-s -w /tmp/pz-ftp-real.pcap 'tcp port 2121 or portrange 19000-19009' >/dev/null 2>&1 & PIDS="$PIDS $!"
sleep 1
printf 'user zoo zoo-pass\npassive\npassive\nlist\nget readme.txt /tmp/pz-ftp-retrieved\nquit\n' | sudo ip netns exec pz-client ftp -inv 198.18.0.2 2121 >"$OUT_DIR/ftp-passive.log" 2>&1
printf 'user zoo zoo-pass\nlist\nquit\n' | sudo ip netns exec pz-client ftp -inv 198.18.0.2 2121 >"$OUT_DIR/ftp-active.log" 2>&1
sleep 1
for p in $PIDS; do sudo kill -INT "$p" 2>/dev/null || true; done; PIDS=""
editcap -F pcapng /tmp/pz-ftp-real.pcap "$OUT_DIR/ftp.pcapng"
tshark -r "$OUT_DIR/telnet.pcapng" -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e tcp.payload >"$OUT_DIR/telnet.frames.tsv" 2>/dev/null || true
tshark -r "$OUT_DIR/ftp.pcapng" -d tcp.port==2121,ftp -d tcp.port==19009,ftp-data -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e ftp.request.command -e ftp.response.code >"$OUT_DIR/ftp.frames.tsv" 2>/dev/null || true
rm -rf "$FTP_ROOT" /tmp/pz-inetd.conf /tmp/pz-ftp-server.py /tmp/pz-telnet-real.pcap /tmp/pz-ftp-real.pcap
printf 'real application captures written to %s\n' "$OUT"
