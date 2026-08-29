# Protocol Zoo Evidence Atlas

这是一张从入口到证据的导航图，不替代各展品的 RFC、实验日志或结构化结果。第三纪元独立导览见 [`ERA3-EVIDENCE-ATLAS.md`](ERA3-EVIDENCE-ATLAS.md)。

## 沿着网络世界的生长顺序

```text
出生语境 → 线缆/拓扑 → 地址 → 发现/名字 → 路由 → 信任 → 失败 → 死亡压力 → 后代
```

| 层次 | Era 1 | Era 2 | 代表证据 |
|---|---|---|---|
| 入口与会话 | Telnet、FTP | DHCP/TFTP 启动链 | `captures/real-app-netns/`、`captures/era2-netns/` |
| 串行与传输 | SCTP、UDP-Lite、GRE、IP-in-IP | SLIP/CSLIP/PPP | `captures/kali-*`、`captures/era2-ppp/` |
| 控制面 | TCP/UDP 基础 harness | RIP、ICMP | `captures/era2-rip/`、`captures/era2-network/icmp-lifecycle.*` |
| 名字与局域网 | Finger、Gopher、IRC 等文档展品 | NBNS/NetBIOS | `captures/era2-netbios/` |
| 过渡与组成员 | — | IPv6-in-IPv4、IGMP | `captures/era2-ipv6/`、`captures/era2-network/igmp-membership.*` |
| 信任模型 | Telnet/FTP 明文边界 | rlogin/rsh probe、NCP 重建 | `research/era2-blockers.md`、`research/pre-ip-ncp.md` |

## Era 1：经典协议展品

第一纪元目录与研究入口：

- [`docs/EXHIBITS.md`](EXHIBITS.md)：展品索引；
- [`species/`](../species/)：按协议展品；
- [`datasets/species.csv`](../datasets/species.csv)：第一纪元数据集；
- [`studies/survival-matrix.md`](../studies/survival-matrix.md)：安全、NAT、中间盒、生态与替代比较；
- [`docs/CAPTURE-CONVENTION.md`](CAPTURE-CONVENTION.md)：抓包命名、字段和脱敏约定。

## Era 2：M10–M19

- [`docs/ERA2-STATUS.md`](ERA2-STATUS.md)：逐生态区状态；
- [`research/era2-experiment-matrix.md`](../research/era2-experiment-matrix.md)：计划入口与安全收口；
- [`research/second-era-natural-history.md`](../research/second-era-natural-history.md)：协议的世界假设；
- [`datasets/era2.csv`](../datasets/era2.csv)：出生、寻址、信任、失败和后代字段；
- [`research/era2-blockers.md`](../research/era2-blockers.md)：没有冒充成功的门禁项。

### 已有真实隔离证据

| 机制 | 结果 | 证据文件 |
|---|---|---|
| DHCP → TFTP | 7 frames | `captures/era2-netns/boot-chain.{pcapng,json,frames.tsv}` |
| PPP LCP/IPCP → IPv4 | 4 ICMP frames + serial log | `captures/era2-ppp/` |
| RIPv2 三节点传播 | 32 frames | `captures/era2-rip/rip-convergence.*` |
| ICMP Echo/Unreachable | 4 frames | `captures/era2-network/icmp-lifecycle.*` |
| NBNS/NBDS | 19 frames | `captures/era2-netbios/nbns.*` |
| IPv6-in-IPv4 | 8 frames | `captures/era2-ipv6/sit-ipv6-in-ipv4.*` |
| IGMP membership | 4 frames | `captures/era2-network/igmp-membership.*` |

## 证据等级

每份 JSON 结果的 `evidence_level` 只能是：

```text
real-capture | fixture | static | document-reconstruction | not-run
```

`real-capture` 必须同时具备结构化结果、非空捕获、字段索引和可复核的成功条件。失败探测保留诊断，不升级为成功证据。

## 复现入口

```sh
make check
./scripts/experiment.sh era2-capture
./scripts/experiment.sh era2-ppp
./scripts/experiment.sh era2-rip
./scripts/experiment.sh era2-network
./scripts/experiment.sh era2-ipv6
./scripts/experiment.sh era2-validate
```

所有实验默认使用私有 namespace、文档保留地址和合成数据；不会连接公网 relay、broker 或生产路由域。
