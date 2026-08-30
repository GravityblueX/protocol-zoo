# Tunnels：在一个网络里携带另一个网络

## 历史问题

组织需要跨越不支持某种地址族、路由域或链路边界的基础设施连接网络。隧道将内层包封装进外层承载：外层负责到达隧道端点，内层仍按自身协议处理。隧道不是天然的加密，也不是天然的身份认证；“能封装”与“安全 VPN”必须分开。

## 类型与规范

- IP-in-IP：RFC 2003；IPv4 包作为 IPv4 载荷，机制简单但依赖外层路由和协议号。
- GRE：RFC 2784，扩展字段见 RFC 2890；可携带多种网络层协议，但本身不提供机密性。
- IPsec tunnel mode：由 IPsec 体系（如 RFC 4301）提供认证/加密语境，但协商、策略和密钥管理是独立问题。
- VXLAN：RFC 7348，在 UDP 上承载二层 VNI，服务于数据中心虚拟网络；它不是通用公网隐身工具。
- WireGuard、OpenVPN 等是实现/协议体系，不应与“任意 GRE 隧道”视为同一安全性质。

封装增加头部开销，可能引发 MTU、分片和 PMTUD 问题；嵌套路由环路、密钥/策略错误和隧道端点暴露也会扩大故障域。

## 仍然存活的部分

隧道持续存在，因为管理边界与物理拓扑不总能同步：云网络、运营商承载、站点互联、IPv6 过渡和数据中心 overlay 都需要逻辑拓扑。主导实现按场景分化，而非一种隧道淘汰全部其他隧道。

## 实验证据与边界

本节的历史谱系属于 **L0 citation + document reconstruction**；此外，第三纪元已经在 [`../../captures/era3-tunnels/`](../../captures/era3-tunnels/) 保存受控本地 **GRE L3 packet evidence**。实验明确区分外层与内层：outer `198.18.220.1 ↔ 198.18.220.2`，inner `198.18.221.1 ↔ 198.18.221.2`；pcap 同时显示 IPv4 protocol 47 的 GRE 外层和被封装的 ICMP 内层流量。

这份证据证明的是“网络包可以作为另一个网络包的载荷，并由不同地址空间分别承担外层传输与内层通信”，不证明 GRE 具有加密或认证性质，也不代表公网 GRE 可达性、吞吐或 provider 策略。仓库既有 Era 2 的私有 SIT/protocol-41 与 GRE/IP-in-IP 资料同样不能自动升级为公网结论；WireGuard 公网隧道仍保留为明确未闭环边界。

复现实验只允许私有 namespace/veth、明确的 capture point 和可清理的路由；不修改宿主默认路由、不接入生产 overlay、不扫描第三方、不把未经加密的 GRE 描述成 VPN。必须记录内层/外层地址、MTU、封装协议号与 cleanup 结果。

## 参考

- RFC 2003, <https://www.rfc-editor.org/rfc/rfc2003>
- RFC 2784, <https://www.rfc-editor.org/rfc/rfc2784>
- RFC 2890, <https://www.rfc-editor.org/rfc/rfc2890>
- RFC 4301, <https://www.rfc-editor.org/rfc/rfc4301>
- RFC 7348, <https://www.rfc-editor.org/rfc/rfc7348>
