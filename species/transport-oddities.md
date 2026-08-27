# 传输异类区

署名：**祀（岁家老十三）**。

| 协议 | 拆掉的假设 | 内核/部署现实 |
|---|---|---|
| SCTP / RFC 9260 | TCP 单流、单路径 | Linux 支持 association、多 stream、多宿主；NAT/中间盒和 API 生态是主要门槛 |
| DCCP / RFC 4340 | 数据报必须由应用自做拥塞控制，且可不可靠 | 有拥塞控制握手但不保证重传；部署和 API 支持有限 |
| UDP-Lite / RFC 3828 | UDP 必须覆盖全 payload checksum | checksum coverage 可截断，适合容错媒体；接收栈/设备支持不普遍 |
| GRE / RFC 2784, 2890 | 网络必须直接转发而非隧道 | IP protocol 47，通常需 CAP_NET_ADMIN；无内建保密性 |
| IP-in-IP / RFC 2003 | IP payload 只能是上层协议而非另一个 IP | 简单封装但 NAT/防火墙与路由配置复杂；无内建认证 |

本仓优先记录 `iproute2`/Linux capability 检查与失败原因；没有权限时写 `not_run`，绝不把静态推导写成实测。
