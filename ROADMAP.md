# Roadmap

协议动物园按“可重复实验”推进，不按“实现了多少协议代码”推进。

## M0 — 实验笼舍

先做共用实验基础：

- [x] `docs/LAB-SAFETY.md`：旧协议安全边界；
- [x] `docs/CAPTURE-CONVENTION.md`：pcapng 命名、脱敏、frame 引用；
- [x] `scripts/lab-netns.sh`：创建两端 veth/netns 的最小实验网络；
- [x] `schemas/experiment.schema.json`；
- [x] `species/_template/` 标准展品模板。

### M0 验收

同一个实验脚本在干净 Linux 环境运行后，可以：

1. 建立隔离网络；
2. 运行服务/客户端；
3. 生成 pcapng；
4. 清理环境；
5. 不触碰公网接口。

---

## M1 — Unix 经典协议区

第一批按资料/工具可得性推进：

### Telnet

- [x] RFC 854 基线；
- [x] IAC / DO / DON'T / WILL / WON'T；
- [x] 终端 option negotiation；
- [x] GNU Inetutils 互操作边界；
- [x] 逐 frame 抓包解释规范。

### FTP

- [x] control/data connection 分离；
- [x] active vs passive；
- [x] NAT 出现后为什么 passive 更重要；
- [x] LIST / RETR 最小抓包规范；
- [x] 明文认证安全说明。

### Finger

- [x] RFC 1288；
- [x] 极简请求/响应；
- [x] 早期用户信息语境；
- [x] 现代隐私风险。

### talk

- [x] talk/talkd 的邀请模型；
- [x] terminal-to-terminal 使用体验/限制；
- [x] 协议与 Unix 登录用户模型的关系。

---

## M2 — 另类信息空间

### Gopher

- [x] RFC 1436；
- [x] selector/menu；
- [x] 现有 server/client 互操作边界；
- [x] 最小 menu fixture；
- [x] 与 early HTTP/HTML 信息模型比较。

### NNTP

- [x] group/article/message-id；
- [x] client-server 与 server propagation 分开研究；
- [x] 不搭全球 Usenet replica。

### IRC

- [x] line protocol；
- [x] prefix / command / params；
- [x] numeric reply；
- [x] channel/member 状态；
- [x] 历史 RFC 与 IRCv3 现实实现差异。

---

## M3 — 传输设计异类区

这一阶段与 `nekomusume` 可以互相参考，但禁止混仓。

- [x] SCTP：multi-stream / multi-homing；
- [x] DCCP：拥塞控制但不保证可靠；
- [x] UDP-Lite：部分 checksum coverage；
- [x] GRE / IP-in-IP：封装而非应用层会话。

每个协议重点回答：

> 它试图拆掉 TCP/UDP 的哪个假设？

而不是简单问“它为什么没流行”。

---

## M4 — 化石抓包馆

从 Wireshark 已有样本开始：

- AppleTalk（许可边界与 dissector 阅读闭环）
- DECnet（来源/许可门禁记录，not-run）
- Banyan VINES（来源/许可门禁记录，not-run）
- IPX/SPX（来源/许可门禁记录，not-run）

流程：

```text
找到合法样本
→ 记录来源/许可
→ Wireshark/tshark 解剖
→ 找原始文档
→ 建 anatomy note
→ 有条件再尝试模拟器复现
```

### 验收

至少一个化石协议完成“样本 → 原始文档 → 字段解释 → 历史用途”的闭环，即使暂时没有自己生成的包。

---

## M5 — 为什么死 / 为什么活

做跨协议研究，而不是继续堆物种数量。

维度：

- 默认安全假设；
- NAT/firewall 适应性；
- 中间盒容忍度；
- 部署权限；
- 内核支持；
- 应用生态；
- 可扩展性；
- 标准复杂度；
- 兼容成本；
- 是否被更通用协议“吃掉”。

产物：`studies/survival-matrix.md`。 [x]

---

## AI 可直接领取的第一批任务

### Task A — 建实验笼舍

只做 netns/veth + tcpdump/dumpcap harness，不实现任何协议。

### Task B — Telnet exhibit

优先使用 GNU Inetutils。生成一个无凭据 loopback/netns 抓包，逐 frame 解释 option negotiation。

### Task C — FTP active/passive

用成熟 server/client 做两个隔离实验，画出四元组与 data connection 发起方向；不要写新的 FTP daemon。

### Task D — Obsolete capture 阅读

从 Wireshark sample captures 找一份 obsolete protocol 样本，做 `research/obsolete-pcap-reading.md`，先证明我们能读“化石”。

### Task E — RFC 状态盘点

为第一批 10 个协议建立 `datasets/species.csv`：名称、原始 RFC、当前 RFC、obsolete/superseded 状态、现存实现、Wireshark dissector、Scapy layer。

## Stop conditions

- 已经存在成熟实现，而我们的代码只是功能复制；
- 实验需要把弱认证/明文服务暴露公网；
- 为了“抓真实包”开始扫描不属于自己的网络；
- 找不到协议原始/权威规范，只靠博客；
- 化石协议样本许可不明却准备提交二进制副本。

协议动物园追求的是**可理解、可复现、可比较**，不是代码行数。

---

# 第二纪元：网络协议自然史（M10–M19）

第二纪元不再只按协议数量推进，而按生态区推进。每个展品必须标出 `real-capture`、`fixture`、`static`、`document-reconstruction` 或 `not-run`，并记录出生语境、线缆/拓扑、寻址、发现、信任、失败和中间盒假设。

## M10 — 开机之前：RARP → BOOTP → DHCP → TFTP

- [x] 空地址客户端到地址发现与启动文件获取的完整链；
- [x] RFC/历史关系与离线启动链 fixture；
- [x] dnsmasq/dhclient/TFTP 在独立 `/24` namespace 实测；
- [x] RARP/BOOTP 的不可行真实条件与证据边界记录。

## M11 — 电话线时代：SLIP / CSLIP / PPP

- [x] RFC 1055/1144/1661/1334/1994 来源与 framing/协商分析；
- [x] SLIP/PPP 离线 framing 与 LCP/PAP/IPCP fixture；
- [ ] pppd over private PTY 的真实抓包；
- [x] 低速链路成本与现代替代分析。

## M12 — 路由控制面：RIP → EGP → BGP

- [x] RIP/EGP/BGP 历史关系与 count-to-infinity fixture；
- [ ] 3-node RIP/FRR namespace 收敛实验；
- [x] 不改宿主路由的控制面安全边界。

## M13 — ICMP 的灭绝器官

- [x] Echo、Unreachable、Redirect、Source Quench、Time Exceeded 的生命周期研究；
- [x] RFC 6633 Source Quench 废弃证据与 synthetic fixture；
- [x] 私有 namespace 中 Echo 与 Port Unreachable 行为抓包；Redirect 保留独立扩展。

## M14 — PC 局域网生态：NetBIOS / NBNS / SMB / IPX

- [x] RFC 1001/1002 与 B/P/M node 模型研究；
- [ ] Samba/NBNS namespace 实测；
- [x] IPX/DECnet/VINES 许可与内核门禁。

## M15 — IPv6 过渡墓园

- [x] 6to4、Teredo、ISATAP、6rd、NAT64/DNS64 来源与死亡压力；
- [x] 无公网 relay/broker 的静态/fixture 边界；
- [ ] 私有 IPv6-in-IPv4/IPv6-in-UDP transition 实测。

## M16 — TCP/IP 之前：ARPANET Host/IMP、NCP、early TCP

- [x] RFC 714 与 NCP → early TCP → TCP/IP document reconstruction；
- [x] 禁止把历史重建冒充 real historical capture。

## M17 — 信任局域网：rlogin / rsh / rexec → SSH

- [x] RFC 1282 与 trusted-host 演化研究；
- [ ] 私有 namespace rlogin/rsh/rexec 实测（有成熟实现才做）；
- [x] 合成凭据与明文安全边界。

## M18 — 多播与 MBONE

- [x] IGMP/DVMRP/PIM/MBONE 历史与 CDN 替代研究；
- [x] 私有 namespace IGMP membership 实测；
- [x] 不接宿主现有路由域与多播边界。

## M19 — 比较研究设施

- [x] 隐含世界假设矩阵、来源索引、实验矩阵；
- [x] M10 新实验补结构化结果、capture、字段索引和清理验证；
- [x] 第二纪元离线生态骨架与证据矩阵 checkpoint；
- [ ] PPP/RIP/NetBIOS/IGMP 实验按能力继续推进。
