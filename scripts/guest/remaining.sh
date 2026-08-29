#!/bin/bash
set -euo pipefail
BASE=/root/pz-remaining; rm -rf "$BASE"; mkdir -p "$BASE"
cleanup(){ ip netns del pz-a 2>/dev/null || true; ip netns del pz-b 2>/dev/null || true; }
trap cleanup EXIT
setup(){ cleanup; ip netns add pz-a; ip netns add pz-b; ip link add pz-va type veth peer name pz-vb; ip link set pz-va netns pz-a; ip link set pz-vb netns pz-b; ip -n pz-a addr add "$1" dev pz-va; ip -n pz-b addr add "$2" dev pz-vb; ip -n pz-a link set lo up; ip -n pz-b link set lo up; ip -n pz-a link set pz-va up; ip -n pz-b link set pz-vb up; }
setup 198.18.10.1/30 198.18.10.2/30
cat >$BASE/udplite-server.py <<'PY'
import socket
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM,136); s.bind(('198.18.10.2',19136)); d,a=s.recvfrom(2048); s.sendto(b'udplite-ok:'+d,a); s.close()
PY
cat >$BASE/udplite-client.py <<'PY'
import socket
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM,136); s.sendto(b'protocol-zoo-udplite',('198.18.10.2',19136)); d,_=s.recvfrom(2048); print(d.decode()); s.close()
PY
ip netns exec pz-b python3 $BASE/udplite-server.py & sp=$!; ip netns exec pz-b tcpdump -U -i pz-vb -w $BASE/udplite.pcap 'udp port 19136' >/dev/null 2>&1 & cp=$!; sleep 1; test "$(ip netns exec pz-a python3 $BASE/udplite-client.py)" = udplite-ok:protocol-zoo-udplite; wait $sp; sleep 1; kill -INT $cp 2>/dev/null || true; wait $cp 2>/dev/null || true
setup 198.18.20.1/30 198.18.20.2/30
ip netns exec pz-a ip tunnel add gre-zoo mode gre local 198.18.20.1 remote 198.18.20.2 ttl 64
ip netns exec pz-b ip tunnel add gre-zoo mode gre local 198.18.20.2 remote 198.18.20.1 ttl 64
ip -n pz-a addr add 198.18.30.1/30 dev gre-zoo; ip -n pz-b addr add 198.18.30.2/30 dev gre-zoo; ip -n pz-a link set gre-zoo up; ip -n pz-b link set gre-zoo up
ip netns exec pz-b tcpdump -U -i pz-vb -w $BASE/gre.pcap 'proto 47 or icmp' >/dev/null 2>&1 & cp=$!; sleep 1; ip netns exec pz-a ping -c 2 -W 2 198.18.30.2 >/dev/null; sleep 1; kill -INT $cp 2>/dev/null || true; wait $cp 2>/dev/null || true
ip netns exec pz-a ip tunnel add ipip-zoo mode ipip local 198.18.20.1 remote 198.18.20.2 ttl 64
ip netns exec pz-b ip tunnel add ipip-zoo mode ipip local 198.18.20.2 remote 198.18.20.1 ttl 64
ip -n pz-a addr add 198.18.40.1/30 dev ipip-zoo; ip -n pz-b addr add 198.18.40.2/30 dev ipip-zoo; ip -n pz-a link set ipip-zoo up; ip -n pz-b link set ipip-zoo up
ip netns exec pz-b tcpdump -U -i pz-vb -w $BASE/ipip.pcap 'proto 4 or icmp' >/dev/null 2>&1 & cp=$!; sleep 1; ip netns exec pz-a ping -c 2 -W 2 198.18.40.2 >/dev/null; sleep 1; kill -INT $cp 2>/dev/null || true; wait $cp 2>/dev/null || true
for f in udplite gre ipip; do editcap -F pcapng $BASE/$f.pcap $BASE/$f.pcapng; done
python3 - <<'PY' >$BASE/capabilities.txt
import socket,os
print('kernel='+os.uname().release)
for n,p in [('udplite',136),('dccp',33)]:
 try: s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM,p); print(n+'_socket=pass'); s.close()
 except OSError as e: print(n+'_socket=not_supported:'+str(e.errno))
print('gre_tunnel=pass'); print('ipip_tunnel=pass')
PY
cat $BASE/capabilities.txt
