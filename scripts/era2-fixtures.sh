#!/bin/sh
# Generate safe, offline/documentation fixtures for Protocol Zoo second era.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
mkdir -p "$ROOT/captures/fixtures/era2"
printf 'RARP request: sha=02:00:00:00:00:02\nRARP reply: sha=02:00:00:00:00:02 spa=198.18.50.2\n' > "$ROOT/captures/fixtures/era2/rarp.txt"
printf 'BOOTP 3001 discover chaddr=02:00:00:00:00:03\nBOOTP 3002 reply yiaddr=198.18.50.3 siaddr=198.18.50.1 file=boot.img\nDHCP 1 DISCOVER\nDHCP 2 OFFER yiaddr=198.18.50.4\nDHCP 3 REQUEST\nDHCP 5 ACK next-server=198.18.50.1 bootfile-name=boot.img\nTFTP RRQ boot.img\nTFTP DATA block=1\nTFTP ACK block=1\n' > "$ROOT/captures/fixtures/era2/boot-chain.txt"
printf 'SLIP END\nIP 198.18.60.1 > 198.18.60.2 TCP payload=synthetic\nEND\n' > "$ROOT/captures/fixtures/era2/slip.txt"
printf 'PPP LCP Configure-Request MRU=1500 ACCM=0x000a\nPPP LCP Configure-Ack\nPPP PAP Authenticate-Request identity=demo\nPPP IPCP Configure-Request address=198.18.61.2\nPPP IPCP Configure-Ack\n' > "$ROOT/captures/fixtures/era2/ppp.txt"
printf 'RIP v2 RESPONSE command=2 metric=1 198.18.70.0/24\nRIP v2 RESPONSE command=2 metric=16 198.18.70.0/24\n' > "$ROOT/captures/fixtures/era2/rip-count-to-infinity.txt"
printf 'ICMP type=4 code=0 Source Quench (historic/deprecated)\nICMP type=3 code=3 Port Unreachable\nICMP type=11 code=0 Time Exceeded\n' > "$ROOT/captures/fixtures/era2/icmp-lifecycle.txt"
printf 'NBNS query NAME=OFFICE<00> broadcast\nNBNS positive response address=198.18.80.2\nNBSS SESSION REQUEST\nSMB NEGOTIATE\n' > "$ROOT/captures/fixtures/era2/netbios.txt"
printf '6to4 outer=2002:c612:0101::/48 inner=IPv4 198.18.90.1\nTeredo UDP/IPv4 mapped-client\nISATAP proto-41 host-router\nNAT64 IPv6 client -> IPv4 server\n' > "$ROOT/captures/fixtures/era2/ipv6-transition.txt"
printf 'NCP OPEN connection-control\nNCP CLOSE connection-control\nNCP FLOW-CONTROL\nTCP/IP split: NCP host-host semantics become TCP + IP layers\n' > "$ROOT/captures/fixtures/era2/pre-ip-ncp.txt"
printf 'rlogin trusted-host .rhosts assumption\nrsh remote command with stderr channel\nrexec username/password over TCP\nSSH host-key + public-key identity\n' > "$ROOT/captures/fixtures/era2/trust-lineage.txt"
printf 'IGMPv2 Membership Report group=239.1.1.1\nIGMPv2 Leave Group group=239.1.1.1\nPIM Join/Prune upstream=198.18.100.1\nDVMRP route report\n' > "$ROOT/captures/fixtures/era2/multicast.txt"
printf 'era2 fixtures generated\n'
