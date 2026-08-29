#!/bin/sh
set -eu
modprobe sctp
ip netns del pz-a 2>/dev/null || true; ip netns del pz-b 2>/dev/null || true
ip netns add pz-a; ip netns add pz-b
ip link add pz-veth-a type veth peer name pz-veth-b
ip link set pz-veth-a netns pz-a; ip link set pz-veth-b netns pz-b
ip -n pz-a addr add 198.18.0.5/30 dev pz-veth-a; ip -n pz-b addr add 198.18.0.6/30 dev pz-veth-b
ip -n pz-a link set lo up; ip -n pz-b link set lo up; ip -n pz-a link set pz-veth-a up; ip -n pz-b link set pz-veth-b up
cat >/tmp/sctp-server.py <<"PY"
import socket
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM,socket.IPPROTO_SCTP); s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1); s.bind(("198.18.0.6",19090)); s.listen(1)
c,a=s.accept(); data=c.recv(1024); c.sendall(b"sctp-ok:"+data); c.close(); s.close()
PY
cat >/tmp/sctp-client.py <<"PY"
import socket
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM,socket.IPPROTO_SCTP); s.connect(("198.18.0.6",19090)); s.sendall(b"protocol-zoo-sctp"); print(s.recv(1024).decode()); s.close()
PY
rm -f /root/pz-sctp.pcap /root/pz-sctp.json
ip netns exec pz-b python3 /tmp/sctp-server.py >/root/pz-sctp-server.log 2>&1 & sp=$!
ip netns exec pz-b tcpdump -U -i pz-veth-b -w /root/pz-sctp.pcap "sctp port 19090" >/dev/null 2>&1 & cp=$!
sleep 1
out=$(ip netns exec pz-a python3 /tmp/sctp-client.py); test "$out" = "sctp-ok:protocol-zoo-sctp"
wait $sp
sleep 1; kill -INT $cp 2>/dev/null || true; wait $cp 2>/dev/null || true
frames=$(tshark -r /root/pz-sctp.pcap -T fields -e frame.number 2>/dev/null | wc -l)
cat >/root/pz-sctp.json <<EOF
{"protocol":"sctp","experiment":"phase-6-sctp-netns-kali","evidence_level":"real-capture","environment":{"os":"kali","kernel":"$(uname -r)","topology":"nested-netns-veth","tools":{"tcpdump":"$(tcpdump --version 2>&1 | sed -n 1p)","tshark":"$(tshark --version 2>/dev/null | sed -n 1p)"}},"capture_point":"pz-b:pz-veth-b","command":"/root/pz-sctp.sh","capture_filter":"sctp port 19090","result":{"handshake":"pass","capture":"/root/pz-sctp.pcap","frames":$frames},"sanitized":true,"notes":["SCTP kernel module loaded inside Kali guest.","Nested namespaces used; synthetic payload only; no default route or external interface."]}
EOF
tshark -r /root/pz-sctp.pcap -q -z io,phs
cat /root/pz-sctp.json
ip netns del pz-a; ip netns del pz-b
