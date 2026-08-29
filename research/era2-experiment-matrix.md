# 第二纪元实验矩阵

| M | 展品 | 计划入口 | 当前证据 | 安全收口 |
|---|---|---|---|---|
| M10 | RARP/BOOTP/DHCP/TFTP | `era2-fixtures`; `era2-capture.sh` | 专用 `/24` namespace 已完成 DISCOVER/OFFER/REQUEST/ACK → TFTP RRQ/DATA/ACK | 不接 host DHCP，不写默认配置 |
| M11 | SLIP/CSLIP/PPP | `era2-ppp-capture.sh` | PPP real-capture：pppd LCP/IPCP 日志 + socat async-HDLC + ppp0 ICMP；SLIP/CSLIP 保留 fixture/static | 不碰宿主串口 |
| M12 | RIP/EGP | `era2-rip-capture.sh` | RIP/BIRD 三节点 real-capture；EGP 保留 document-reconstruction | 不改宿主路由 |
| M13 | ICMP Source Quench | `captures/fixtures/era2/icmp-lifecycle.txt` | document reconstruction/static；Source Quench 不应由现代端系统依赖 | 不向外部主机发包 |
| M14 | NetBIOS/NBNS/SMB/IPX | local Samba/fixture | NBNS/Samba 已实测；IPX/历史协议受内核/样本门禁 | 仅 namespace |
| M15 | 6to4/Teredo/ISATAP/NAT64 | `era2-ipv6-capture.sh` | 私有 SIT/protocol 41 real-capture；其余 transition 保留 static | 不连接 relay/public broker |
| M16 | NCP/pre-IP | `research/pre-ip-ncp.md` | document reconstruction | 不伪造历史 capture |
| M17 | rlogin/rsh/rexec | loopback/netns only + mature rsh-redone daemon | mature daemon isolated probe established TCP but not authenticated terminal/session; static/fixture remains | 合成凭据 |
| M18 | IGMP/DVMRP/PIM/MBONE | `era2-network-capture.sh` | IGMP membership 已 real-capture；DVMRP/PIM/MBONE 保留 static | 组播范围限实验地址 |
| M19 | natural history matrix | `second-era-natural-history.md` | comparative research + dataset/template | 标出事实/推断 |
