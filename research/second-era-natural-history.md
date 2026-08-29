# Protocol Zoo 第二纪元：网络协议自然史

## 研究问题

协议不是脱离环境的字段集合，而是对当时世界的一组假设：地址是否已知、链路是否昂贵、广播是否可用、主机是否有人值守、网络是否可信、丢包是否正常，以及中间盒是否存在。

## 生态区总表

| 区域 | 代表协议 | 核心隐含假设 | 环境变化后的压力 | 证据边界 |
|---|---|---|---|---|
| 开机/发现 | RARP、BOOTP、DHCP、TFTP | 客户端无地址、无盘、广播可达 | 交换网络、认证启动、自动配置安全 | RFC + 隔离 fixture/实测 |
| 串行链路 | SLIP、CSLIP、PPP | 带宽昂贵、点到点、帧边界稀缺 | 宽带、移动接入、链路层标准化 | RFC + pppd/fixture |
| 控制面 | RIP、EGP、BGP | 路由信息可用且信任邻居 | 规模、策略、安全和收敛要求 | RFC + routed/FRR |
| ICMP 生命周期 | Source Quench、Redirect、Echo | 端点会遵从网络控制消息 | 误用、攻击面、端系统策略 | RFC + synthetic frame |
| PC LAN | NetBIOS/NBNS/SMB、IPX | 广播发现、局域网可信 | routable IP、WINS/DNS、SMB signing | RFC + local daemon/fixture |
| IPv6 过渡 | 6to4、Teredo、ISATAP、NAT64 | IPv4 仍普遍且隧道可穿越 | NAT、失败率、原生 IPv6 | RFC + tunnel/static |
| pre-IP | ARPANET HHP/NCP、early TCP | IMP 网络与 host control protocol | TCP/IP 分层、互联规模 | document reconstruction |
| 信任远程 | rlogin/rsh/rexec、SSH | 主机/局域网可被信任 | 密钥身份、零信任、加密 | RFC + static/isolated |
| 多播 | IGMP、DVMRP、PIM、MBONE | 网络能维护组状态且一对多值得 | CDN/HTTP、运营复杂度 | RFC + local multicast/fixture |

## 比较维度

`trust`、`address stability`、`broadcast availability`、`human presence`、`bandwidth cost`、`CPU cost`、`loss model`、`endpoint identity`、`NAT presence`、`middlebox tolerance`。

“死亡”不是字段消失，而是原先有利的假设变成部署负担；“存续”也不等于普及，专业生态可以在局部保留一个协议。
