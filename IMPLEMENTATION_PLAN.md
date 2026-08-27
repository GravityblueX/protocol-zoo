# IMPLEMENTATION_PLAN.md — Protocol Zoo

本文件把 `ROADMAP.md` 转成连续施工顺序。

## Phase 0 — Lab harness

- [ ] `docs/LAB-SAFETY.md`；
- [ ] `docs/CAPTURE-CONVENTION.md`；
- [ ] `scripts/lab-netns.sh`；
- [ ] `schemas/experiment.schema.json`；
- [ ] `species/_template/`；
- [ ] teardown/cleanup test；
- [ ] 一份最小 TCP/UDP dummy capture 证明 harness 可用。

验收：干净 Linux 环境可创建隔离网络、运行两端、抓包、生成结构化结果、清理，不触碰公网接口。

## Phase 1 — Telnet

- [ ] source map：RFC 854 + option RFC；
- [ ] 使用成熟实现互操作；
- [ ] 无凭据 netns 会话；
- [ ] capture IAC/DO/DON'T/WILL/WON'T；
- [ ] 逐 frame 注释；
- [ ] terminal option negotiation 说明；
- [ ] 安全说明。

## Phase 2 — FTP active/passive

- [ ] control/data connection 分离；
- [ ] active 实验；
- [ ] passive 实验；
- [ ] 两套四元组/方向图；
- [ ] LIST/RETR 最小 capture；
- [ ] NAT 语境说明；
- [ ] 不保存真实密码。

## Phase 3 — Finger / talk

Finger：极简 request/response + 隐私语境。

talk：邀请模型、终端用户模型、至少一份可复核协议/实现分析；若现代环境难以复活，允许以“规范 + 现有实现 + 模拟/样本”闭环，不伪造运行成功。

## Phase 4 — Gopher

- [ ] RFC 1436；
- [ ] selector/menu；
- [ ] 现有 client/server 互操作；
- [ ] 若有解释增量，再写最小 menu server；
- [ ] 与早期 HTTP/HTML 信息模型比较。

## Phase 5 — NNTP / IRC

先研究再实验：

- NNTP：group/article/message-id，client-server 与 propagation 分层；
- IRC：line protocol、numeric reply、channel/member 状态、历史 RFC 与 IRCv3 差异。

## Phase 6 — Transport oddities

每个候选都先回答“它拆掉了 TCP/UDP 的哪个假设”：

- [ ] SCTP；
- [ ] DCCP；
- [ ] UDP-Lite；
- [ ] GRE；
- [ ] IP-in-IP。

优先系统内核/namespace 实验；需要高权限的步骤必须显式说明。

## Phase 7 — Fossil captures

- [ ] 从许可明确的 sample 开始；
- [ ] AppleTalk / DECnet / VINES / IPX/SPX 至少选一个；
- [ ] source + license；
- [ ] tshark/Wireshark 字段；
- [ ] 原始文档；
- [ ] anatomy note；
- [ ] 有条件才做模拟器复现。

验收：至少一个完成“样本 → 规范 → 字段 → 历史用途”闭环。

## Phase 8 — Species dataset

建立 `datasets/species.csv`，至少包含：名称、层次、原始/当前规范、状态、现存实现、Wireshark dissector、Scapy 支持、现代部署难点、安全模型。

## Phase 9 — Survival matrix

产出 `studies/survival-matrix.md`，比较：安全假设、NAT/firewall、中间盒、权限、内核、生态、扩展、兼容成本、被通用协议替代情况。

## 每个阶段门禁

- 不重复成熟实现；
- capture 可追溯；
- 默认隔离网络；
- 不含真实凭据；
- 原始/权威规范可定位；
- 实验步骤与分析可复现；
- checkpoint commit 后继续。
