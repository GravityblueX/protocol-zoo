# Era 3 — Middleboxes in the Path

本页是离线研究文档，不是对公网设备的测试报告。当前所有条目均为 `document-reconstruction`：没有提交实验脚本、没有连接第三方目标，也没有把 RFC 中的要求冒充为本地抓包证据。

## 读法与边界

中间盒（middlebox）是改变、检查、复制、汇聚或选择转发路径上分组的设备或功能。RFC 3234 将其作为区别于传统 IP 转发器的功能族；该分类是观察框架，不是互操作性保证。一个产品可以同时实现 NAT、状态防火墙、代理和负载均衡。

必须分开三件事：

1. **规范语义**：RFC 要求或建议设备如何处理流量；
2. **常见部署行为**：厂商策略、超时、ALG、健康检查和容量限制，往往不由单一 RFC 规定；
3. **观测证据**：本仓库尚无 Era 3 中间盒真实抓包，因此只能标为文档重建。

任何“允许”“支持”都不是端到端可达性的承诺。路径 MTU、过滤策略、地址重写、空闲状态回收、TLS 加密和协议扩展都可能使相同应用在另一条路径上失败。

## NAT（地址与端口转换）

NAT 将一个地址域中的流映射到另一个地址域，通常同时改写 IPv4 地址和传输层端口。RFC 3022（Traditional NAT）描述基本地址/端口转换；RFC 4787 规定 UDP IPv4 NAT 的行为要求；RFC 7857 更新了 RFC 4787 的若干要求；RFC 6888 讨论运营商级共享地址（CGN/LSN）的设计；RFC 6598 保留 `100.64.0.0/10` 作为共享地址空间。

**可观察机制**：出站首包创建状态，返回流量依赖映射；端口冲突通过重映射或分配策略解决；空闲映射会过期；入站新连接通常没有可用映射。端点看到的源地址/端口不等于主机本地地址/端口。

**限制与陷阱**：

- NAT 不是防火墙，但“只允许已有映射的回包”常产生类似防火墙的外观（RFC 4787 的 endpoint-independent / address-dependent / address-and-port-dependent 行为必须明确区分）。
- UDP 映射超时、端口分配、hairpinning 和 ICMP 错误处理存在实现差异；应用不能假设永久映射。
- 主动 FTP、SIP、P2P 等把地址嵌入 payload 的协议可能需要 ALG 或应用层候选地址机制；TLS 会阻止透明 payload 修补。
- 多层 NAT、CGN、共享公网地址会使入站、审计、速率限制和归因复杂化；RFC 6888 要求记录端口映射以支持运营商级追溯，但不消除隐私风险。
- NAT 不替代 IPv6 端到端安全策略，也不保证协议对未知传输层号或分片的兼容性。

## FIREWALL（状态与策略执行）

防火墙按地址、协议、端口、方向、状态、接口或应用身份实施策略。RFC 2979 讨论 Internet 防火墙行为与透明性；RFC 6092 给出 IPv6 家庭网关的状态防火墙建议。RFC 4787 的“过滤行为”术语也常用于描述 NAT 设备，但 NAT 与 firewall 仍是不同功能。

**可观察机制**：状态表由首包建立，返回包按五元组/连接跟踪匹配；策略可能静默丢弃、返回 ICMP/TCP reset，或执行速率/应用检查。状态表容量、超时、分片重组和异常包处理属于设备配置与实现边界。

**限制与陷阱**：

- “端口开放”只是某一接口、地址族、时间窗口和策略下的结果；不能推出服务质量或全球可达。
- 阻断 ICMPv6 或 ICMP Packet Too Big 会破坏 IPv6 邻居发现和 PMTUD；RFC 4890 提供 ICMPv6 过滤建议，不能被简化为“全部允许/全部拒绝”。
- 严格 TCP/UDP 假设会损害新传输协议、分片、扩展头和加密流量；RFC 8085 对 UDP 应用的拥塞与 NAT/防火墙穿越提出约束，但不是穿越保证。
- 防火墙日志是策略设备的局部观察，不是端点是否收到分组的证明；日志本身也可能截断、采样或受时钟误差影响。

## PROXY（应用层代理）

正向代理代表客户端访问上游；反向代理代表服务端接收客户端请求。HTTP 语义由 RFC 9110 定义，缓存语义由 RFC 9111 定义；HTTP CONNECT 隧道和代理认证也在 RFC 9110 的代理章节中定义。代理可以终止连接、重新建立上游连接、修改头字段、做认证、缓存或路由。

**可观察机制**：客户端连接的是代理；代理解析请求目标并生成另一条上游连接。`Via`、`Forwarded`（RFC 7239）等字段可表达代理链，但是否注入、信任及脱敏取决于部署。HTTPS 隧道模式下，CONNECT 代理只转发字节；TLS 终止模式下，代理可看见 HTTP 语义，但改变了信任边界。

**限制与陷阱**：

- `X-Forwarded-*` 不是统一安全信号；未认证的客户端可伪造它。应用必须只信任明确配置的代理 hop。
- 代理不能自动修复不适合代理的协议；绝对 URI、升级、WebSocket、长连接、流式响应和双向字节流分别有不同要求。
- 缓存必须遵守 RFC 9111 的 freshness、validation、`Vary`、Authorization 与 `Cache-Control` 语义；“命中缓存”不等于内容适合所有用户。
- TLS 终止、证书、密钥和审计使代理成为高价值信任锚；端到端加密的安全性质不能在文档中默认为保留。

## LOAD-BALANCING（负载均衡）

负载均衡器根据五元组、连接状态、应用请求、健康检查或权重选择后端。它可能是 L4 转发/NAT，也可能是 L7 反向代理；两者对客户端地址、连接寿命和协议可见性完全不同。Anycast 的地址发布与服务分布可参考 RFC 4786；它描述运营实践，不规定某个负载均衡算法。

**可观察机制**：同一连接通常需保持到同一后端（connection affinity）；后端故障会影响新连接，也可能中断既有连接。L7 设备可以按 Host/path/cookie 分流，L4 设备通常只看连接元数据。

**限制与陷阱**：

- “均匀分配连接”不等于均匀分配负载；长尾请求、缓存热度和连接复用会造成明显偏斜。
- 健康检查只证明检查路径在某时刻满足条件，不能证明真实用户请求成功。
- Anycast 收敛、路径改变和状态非共享会造成会话漂移；UDP、QUIC、长连接尤其需要显式状态策略。
- PROXY protocol 等元数据传递机制不是 HTTP 标准；启用前必须约束可信入口，否则客户端地址可被伪造。

## CDN（内容分发网络）

CDN 是分布式缓存、反向代理、请求路由和源站保护的组合，而不是单一线协议。HTTP 缓存的规范依据是 RFC 9111；CDN 间互联的架构讨论见 RFC 6770。内容是否可缓存、缓存多久及何时验证由响应元数据和部署策略共同决定。

**可观察机制**：请求被路由到边缘节点；命中时边缘直接响应，未命中时向源站获取并按缓存键存储。缓存键通常至少受 scheme/authority/path 影响，可能还受 query、`Vary`、设备或租户策略影响；这些扩展并非 RFC 统一规定。

**限制与陷阱**：

- CDN 不会自动保证低延迟、强一致或可用性；DNS/Anycast/应用路由、回源拥塞和失效传播都会改变结果。
- 个性化、带 Authorization、`Set-Cookie` 或敏感数据必须按 RFC 9111 与业务策略防止跨用户泄露；错误的缓存键是严重安全缺陷。
- HTTPS 终止位置决定密钥和内容可见性；CDN 的“边缘加密”不等于源站到边缘或边缘到客户端都具备同一信任模型。
- purge/invalidation 通常是供应商控制面能力，不是 HTTP 协议承诺；“已刷新”需要供应商证据，不能从单次响应推断。

## Middlebox Museum：应当展示的失真

博物馆不把中间盒描绘成“网络坏了的例外”。它展示的是端到端模型如何被现实约束重写：

| 展柜 | 失真 | 仍应保留的端到端问题 |
|---|---|---|
| NAT | 地址与端口不再稳定可见 | 端点身份、入站建立、映射过期 |
| Stateful firewall | 可达性取决于状态与策略 | 失败是否可区分、ICMP/PMTUD 是否生存 |
| Proxy | 一条连接变成两条信任关系 | 谁终止 TLS、谁可见请求语义 |
| Load balancer | 服务地址与实际后端分离 | 状态粘滞、故障收敛、真实容量 |
| CDN | 响应来自缓存而非源站 | freshness、失效、一致性、隐私 |

结论必须克制：中间盒提高了可部署性、地址复用、策略控制和容量利用率，但同时引入状态、隐藏拓扑、额外信任根和协议兼容成本。任何实验或历史叙述都应报告设备角色、观察点、时间、地址族、超时与失败语义；只报告“能通”是不充分的。

## 规范索引

- RFC 2979 — Behavior of and Requirements for Internet Firewalls
- RFC 3022 — Traditional IP Network Address Translator (Traditional NAT)
- RFC 3234 — Middleboxes: Taxonomy and Issues
- RFC 4786 — Operation of Anycast Services
- RFC 4787 — Network Address Translation (NAT) Behavioral Requirements for Unicast UDP
- RFC 4890 — Recommendations for Filtering ICMPv6 Messages in Firewalls
- RFC 6092 — Recommended Simple Security Capabilities in Customer Premises Equipment (IPv6)
- RFC 6598 — IPv4 Address Space Reserved for Shared Address Space
- RFC 6770 — Requirements for the Application of Content Distribution Networks
- RFC 6888 — Common Requirements for Carrier-Grade NATs (CGNs)
- RFC 7239 — Forwarded HTTP Extension
- RFC 7857 — Updates to Network Address Translation (NAT) Behavioral Requirements
- RFC 8085 — UDP Usage Guidelines for Application Designers
- RFC 9110 — HTTP Semantics
- RFC 9111 — HTTP Caching

RFC 状态、更新关系和 errata 应在实际实现或实验前再次核对；本页不替代各 RFC 正文。
