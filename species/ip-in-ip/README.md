# IP-in-IP 展品

署名：**祀（岁家老十三）**。规范：RFC 2003。外层 IP 直接承载内层 IP，展示路由域之间的简单封装；没有内建保密性/认证，协议号、MTU、NAT 和防火墙是部署难点。


## Kali 隔离实测

使用 `ip tunnel` 创建 IP-in-IP（IP protocol 4），ICMP 往返成功；`captures/kali-remaining/ipip.pcapng` 显示双层 IP 与内层 ICMP。
