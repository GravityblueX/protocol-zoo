# GRE 展品

署名：**祀（岁家老十三）**。规范：RFC 2784、RFC 2890。GRE 是网络层隧道封装，不是加密协议；Key/Sequence 扩展不能替代认证与机密性。实验需要自有 namespace 和 CAP_NET_ADMIN。


## Kali 隔离实测

使用 `ip tunnel` 在 nested namespaces 创建 GRE（IP protocol 47），ICMP 往返成功；`captures/kali-remaining/gre.pcapng` 显示 GRE 外层及 ICMP 内层。
