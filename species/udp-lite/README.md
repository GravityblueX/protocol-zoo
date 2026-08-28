# UDP-Lite 展品

署名：**祀（岁家老十三）**。规范：RFC 3828。UDP-Lite 允许 checksum 只覆盖报头和 payload 前缀，拆掉“整个 datagram 必须完整校验”的假设；适用于可容错媒体，但应用必须理解损坏数据语义。


## Kali 隔离实测

在独立 Kali nested namespaces 中使用真实 UDP-Lite socket（protocol 136）完成往返；抓包 `captures/kali-remaining/udplite.pcapng` 显示两帧，Wireshark `udp.checksum_coverage` 为 28 和 39。入口：`./scripts/experiment.sh remaining`。
