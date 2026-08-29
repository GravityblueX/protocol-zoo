# IMPLEMENTATION_PLAN.md — Protocol Zoo

本文件把 `ROADMAP.md` 转成连续施工顺序。

## Phase 0 — Lab harness

- [x] `docs/LAB-SAFETY.md`；
- [x] `docs/CAPTURE-CONVENTION.md`；
- [x] `scripts/lab-netns.sh`；
- [x] `schemas/experiment.schema.json`；
- [x] `species/_template/`；
- [x] teardown/cleanup test；
- [x] 一份最小 TCP/UDP dummy capture 证明 harness 可用。

验收：干净 Linux 环境可创建隔离网络、运行两端、抓包、生成结构化结果、清理，不触碰公网接口。

## Phase 1 — Telnet

- [x] source map：RFC 854 + option RFC；
- [x] 使用成熟实现互操作边界已记录；
- [x] 无凭据 netns 会话/fixture；
- [x] capture IAC/DO/DON'T/WILL/WON'T 机制说明；
- [x] 逐 frame 注释规范已建立；
- [x] terminal option negotiation 说明；
- [x] 安全说明。

## Phase 2 — FTP active/passive

- [x] control/data connection 分离；
- [x] active 实验拓扑与方向已记录；
- [x] passive 实验拓扑与方向已记录；
- [x] 两套四元组/方向图；
- [x] LIST/RETR 最小 capture 规范；
- [x] NAT 语境说明；
- [x] 不保存真实密码。

## Phase 3 — Finger / talk

- [x] Finger：极简 request/response + 隐私语境。
- [x] talk：邀请模型、终端用户模型与可复核实现分析；现代环境限制明确记录为 not-run。

## Phase 4 — Gopher

- [x] RFC 1436；
- [x] selector/menu；
- [x] 现有 client/server 互操作边界；
- [x] 最小 menu fixture；
- [x] 与早期 HTTP/HTML 信息模型比较。

## Phase 5 — NNTP / IRC

- [x] NNTP：group/article/message-id，client-server 与 propagation 分层；
- [x] IRC：line protocol、numeric reply、channel/member 状态、历史 RFC 与 IRCv3 差异；
- [x] 合成 line-protocol fixtures 与安全边界。

## Phase 6 — Transport oddities

每个候选都先回答“它拆掉了 TCP/UDP 的哪个假设”：

- [x] SCTP；
- [x] DCCP；
- [x] UDP-Lite；
- [x] GRE；
- [x] IP-in-IP；

所有当前环境未具备的 capability 实验均标记为 not-run，提供可复核的协议/内核边界说明。

优先系统内核/namespace 实验；需要高权限的步骤必须显式说明。

## Phase 7 — Fossil captures

- [x] 从许可边界明确的 sample 目录开始；
- [x] AppleTalk 完成 sample→dissector→规范→历史用途闭环；
- [x] source + license 约束；
- [x] tshark/Wireshark 字段路径；
- [x] 原始文档定位；
- [x] anatomy note；
- [x] 无模拟器时明确 not-run，不伪造复现。

验收：至少一个完成“样本 → 规范 → 字段 → 历史用途”闭环。

## Phase 8 — Species dataset

[x] 建立 `datasets/species.csv`，包含名称、层次、原始/当前规范、状态、现存实现、Wireshark dissector、Scapy 支持、现代部署难点、安全模型。

## Phase 9 — Survival matrix

[x] 产出 `studies/survival-matrix.md`，比较安全假设、NAT/firewall、中间盒、权限、内核、生态、扩展、兼容成本和替代情况。

## Phase 10 — Second era ecology M10–M19

- [x] `species/_template/` 增加出生语境、线缆/拓扑、寻址、发现、信任、状态、失败、带宽、中间盒、死亡压力、后代和证据等级字段；
- [x] `datasets/era2.csv`；
- [x] `research/second-era-natural-history.md`、`era2-sources.md`、`era2-experiment-matrix.md`、`pre-ip-ncp.md`；
- [x] M10–M19 离线 fixtures；
- [x] DHCP/TFTP 真实 namespace 实验；
- [x] ICMP 与 IGMP 真实 namespace 实验；
- [x] NetBIOS/NBNS 真实 namespace 实验；
- [ ] 在能力允许时完成 PPP、RIP 的真实 namespace 实验；
- [x] 不可安全/合法复现的项目明确为 static、document-reconstruction 或 not-run；
- [x] 第二纪元离线数据、fixture、来源和证据矩阵 checkpoint；
- [ ] 第二纪元真实应用/链路实验按环境能力继续推进。

## 每个阶段门禁

- 不重复成熟实现；
- capture 可追溯；
- 默认隔离网络；
- 不含真实凭据；
- 原始/权威规范可定位；
- 实验步骤与分析可复现；
- checkpoint commit 后继续。
