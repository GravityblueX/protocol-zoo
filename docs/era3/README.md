# Era 3 — The Internet Grows Organs

核心问题：一个强调端到端主机通信的网络，如何长出命名、自治、政策路由、中间盒、缓存、交换、分发、隧道与控制平面。

## 展厅

A. Names Become Infrastructure  · DNS、地址与发现
B. Networks Become Autonomous  · BGP、CIDR 与自治系统
C. The Backbone Becomes a System  · IXP、Anycast 与路径观察
D. Middleboxes Enter the Path  · NAT、防火墙、代理与负载均衡
E. Address Scarcity Changes Architecture  · 地址复用与可达性
F. The Internet Learns to Cache and Distribute  · HTTP、缓存与 CDN
G. Tunnels Build Networks Inside Networks  · GRE、VPN、overlay 与 MTU
H. The End-to-End Principle Under Pressure  · TLS、终止点与责任边界

本阶段的专题文档：

- [`HTTP.md`](HTTP.md)：HTTP/0.9、1.0、1.1、2、3 的语义与 framing 演化；
- [`TLS.md`](TLS.md)：TLS 1.2/1.3、认证边界与密钥/证书限制；
- [`TUNNELS.md`](TUNNELS.md)：IP-in-IP、GRE、加密隧道、overlay 与 MTU；
- [`END-TO-END.md`](END-TO-END.md)：端到端论证、中间盒压力与逐项信任边界；
- [`SURVIVAL-MATRIX.md`](SURVIVAL-MATRIX.md)：定性存续比较与明确限制；
- [`VPS-SAFETY.md`](VPS-SAFETY.md)：自有 VPS 的最小暴露与清理边界；
- [`MTU-PMTUD.md`](MTU-PMTUD.md)：M18 本地低 MTU 复现、WAN 观察边界与 black-hole 推论；
- [`TRACEROUTE.md`](TRACEROUTE.md)：M19 TTL/Hop Limit 方法、probe family 与 `*` 的证据含义；
- [`DHCP-INTEGRATION.md`](DHCP-INTEGRATION.md)：M20 DORA 到 TFTP 的本地 packet-evidence 闭环；
- [`TCP-UDP-WAN.md`](TCP-UDP-WAN.md)：M29–M30 transport 契约、受控 WAN 失败与 L4 门槛；
- [`FAILURE-GALLERY.md`](FAILURE-GALLERY.md)：M33 timeout、权限与 application 未闭环的失败证据。

每章区分：当时的问题、当时提出的方案、最终占主导的实现、今天仍存活的部分，以及不应倒投回历史的现代解释。没有实验记录的主张不会被写成真实抓包结论。

## 证据等级

`L0` citation；`L1` fixture；`L2` executable local reproduction；`L3` local packet evidence；`L4` controlled real-WAN evidence；`L5` external corroboration。使用 VPS 不自动提高等级。本次 HTTP/TLS/TUNNELS/END-TO-END 专题新增材料为 `L0` 与比较性整理；数据中的 `not-run` 是有意的证据边界，不是遗漏。

机器可读索引见 [`../../data/era3/protocols.json`](../../data/era3/protocols.json)、[`../../data/era3/survival-matrix.json`](../../data/era3/survival-matrix.json) 与 [`../../data/era3/evidence.json`](../../data/era3/evidence.json)。M18–M33 本轮 observation ledger 见 [`../../research/data/era3-observations.md`](../../research/data/era3-observations.md) 与 `.json`；其中 `local`、`wan`、`inference` 是分开的来源标签。
