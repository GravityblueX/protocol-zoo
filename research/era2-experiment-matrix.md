# 第二纪元实验矩阵

| M | 展品 | 计划入口 | 当前证据 | 安全收口 |
|---|---|---|---|---|
| M10 | RARP/BOOTP/DHCP/TFTP | `era2-fixtures`; `era2-capture.sh` | 专用 `/24` namespace 已完成 DISCOVER/OFFER/REQUEST/ACK → TFTP RRQ/DATA/ACK | 不接 host DHCP，不写默认配置 |
| M11 | SLIP/CSLIP/PPP | `captures/fixtures/era2/ppp.txt`; guest `pppd`/pty | fixture/static；串行 pty 受权限与实现约束 | 不碰宿主串口 |
| M12 | RIP/EGP | FRR ripd nested namespaces | FRR/ripd 尚未形成稳定三节点收敛实验，保留 fixture/document-reconstruction | 不改宿主路由 |
| M13 | ICMP Source Quench | `captures/fixtures/era2/icmp-lifecycle.txt` | document reconstruction/static；Source Quench 不应由现代端系统依赖 | 不向外部主机发包 |
| M14 | NetBIOS/NBNS/SMB/IPX | local Samba/fixture | NBNS/Samba 已实测；IPX/历史协议受内核/样本门禁 | 仅 namespace |
| M15 | 6to4/Teredo/ISATAP/NAT64 | static/tunnel harness | document reconstruction/static | 不连接 relay/public broker |
| M16 | NCP/pre-IP | `research/pre-ip-ncp.md` | document reconstruction | 不伪造历史 capture |
| M17 | rlogin/rsh/rexec | loopback/netns only | static unless local daemon available | 合成凭据 |
| M18 | IGMP/DVMRP/PIM/MBONE | `era2-network-capture.sh` | IGMP membership 已 real-capture；DVMRP/PIM/MBONE 保留 static | 组播范围限实验地址 |
| M19 | natural history matrix | `second-era-natural-history.md` | comparative research + dataset/template | 标出事实/推断 |
