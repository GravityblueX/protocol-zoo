# End-to-End：原则、压力与重新分层

## 原则是什么

端到端论证（Saltzer、Reed、Clark，1984）主张：某些功能若只有在通信端点才能完整实现，就不应仅依赖网络内部的低层实现；网络可以提供通用传输，应用端负责最终语义校验。它是设计论证，不是“网络中不得有中间设备”的禁令。

端到端可靠性、机密性、身份、幂等性和应用级一致性，往往仍需端点参与。链路校验、路由收敛、拥塞控制和局部过滤则可以在网络内部提供，而且可能改善效率或可用性；两者并不互斥。

## 为什么承受压力

DNS、NAT、状态防火墙、代理、负载均衡、CDN、企业审计和地址短缺把状态与策略放进了路径。它们解决了命名、可扩展性、地址复用、缓存和运营控制问题，却也引入状态超时、路径依赖、可观测性差异、证书终止和协议 ossification 等代价。

TLS、QUIC、HTTP/2/3 与 CONNECT 等机制不是简单“恢复纯端到端网络”：它们在端点保护语义的同时，仍需 DNS、路由、策略设备和服务分发系统协作。端到端性应按具体性质逐项说明（例如“内容机密性直到 TLS 终止点”），不能用一个二元标签概括。

## 本仓的判断框架

1. 先说明功能和信任边界：谁验证什么、在哪个端点终止。
2. 区分协议规范、某实现默认值和一次实验观察。
3. 把中间盒的收益（缓存、过滤、分发、故障隔离）与成本（状态、兼容、集中风险）同时记录。
4. 不把部署普及写成设计正确，也不把中间盒存在写成端到端原则失效。

## 实验与限制

本节为 **L0 citation + comparative analysis**，不声称已测量全球互联网路径。任何真实 WAN 观察都只能作为受控、时间和路径限定的证据；VPS 不是代表性互联网。实验优先 loopback/netns，必要时才使用自有 VPS，且不扫描、不改变生产路由、不收集第三方内容。没有 capture 或结构化证据时，结论应标为 `not-run`、`static` 或 `document-reconstruction`，而不是伪造“真实网络行为”。

## 参考

- Saltzer, Reed & Clark (1984), *End-to-End Arguments in System Design*, ACM TOCS, 2(4), 277–288, <https://web.mit.edu/Saltzer/www/publications/endtoend/endtoend.pdf>
- RFC 3234, <https://www.rfc-editor.org/rfc/rfc3234>
- RFC 6888, <https://www.rfc-editor.org/rfc/rfc6888>
- RFC 9293, <https://www.rfc-editor.org/rfc/rfc9293>
