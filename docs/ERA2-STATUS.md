# 第二纪元 M10–M19 状态

本表区分研究完成、真实隔离实验和环境/历史门禁，不把 fixture 冒充 real-capture。

| M | 主题 | 研究/数据 | 当前实验状态 | 证据 |
|---|---|---|---|---|
| M10 | RARP → BOOTP → DHCP → TFTP | RFC、启动链 fixture、era2 CSV | 专用 `/24` namespace 中从无地址客户端完成 DHCP 四步与 TFTP 文件获取 | `boot-chain.pcapng`、`boot-chain.json`、`boot-chain.frames.tsv`（`real-capture`） |
| M11 | SLIP / CSLIP / PPP | RFC、framing fixture | private PTY/pppd 尚未实测 | `captures/fixtures/era2/ppp.txt` |
| M12 | RIP → EGP → BGP | RFC、count-to-infinity fixture | 三节点路由拓扑尚未启动 | `captures/fixtures/era2/rip-count-to-infinity.txt` |
| M13 | ICMP 生命周期 | RFC 792/6633、lifecycle fixture | Echo、Port Unreachable 已实测；Source Quench 仍只作历史重建 | `captures/era2-network/icmp-lifecycle.*` |
| M14 | NetBIOS / NBNS / SMB / IPX | RFC、node model、fixture | Samba nmbd/nmblookup nested namespace 实测 | `captures/era2-netbios/nbns.*` |
| M15 | IPv6 transition | 6to4/Teredo/ISATAP/NAT64 来源与 fixture | 不连接公共 relay/broker；私有 transition 实测待补 | `captures/fixtures/era2/ipv6-transition.txt` |
| M16 | NCP / pre-IP | RFC 714、演化图 | 无历史主机/合法历史 pcap | `research/pre-ip-ncp.md` |
| M17 | rlogin / rsh / rexec → SSH | RFC 1282、trust lineage | guest 客户端可用；服务端信任配置待补 | `captures/fixtures/era2/trust-lineage.txt` |
| M18 | IGMP / DVMRP / PIM / MBONE | RFC、multicast fixture | 私有 namespace IGMPv3 membership report 已实测 | `captures/era2-network/igmp-membership.*` |
| M19 | 横向自然史 | 模板、CSV、矩阵、来源索引 | 研究设施已建立；真实实验逐项关联待补 | `research/second-era-natural-history.md` |

## 完成定义

真实环境、权限、内核、历史样本或许可证构成 blocker 时，保留 `static`、`document-reconstruction` 或 `not-run`，并记录可复核原因。实验默认只使用 namespace、私有地址和合成数据。
