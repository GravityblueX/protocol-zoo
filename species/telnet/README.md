# Telnet 展品

署名：**祀（岁家老十三）**。

- 规范：RFC 854（协议）、RFC 855（选项结构）、RFC 857（回显）、RFC 858（Suppress Go Ahead）。
- 实现：Debian `inetutils-telnet` 客户端；服务端实验使用 netcat 作为字节流 fixture，不伪装为完整 telnetd。
- 核心机制：TCP 字节流中以 IAC `0xff` 开始的命令；`DO/DON'T/WILL/WON'T` 协商对端能力，普通数据仍可混在同一流内。

## 隔离实验

在 `pz-client`/`pz-server` netns 中运行 TCP fixture，向其发送合成的 `IAC WILL ECHO`、`IAC DO SUPPRESS-GO-AHEAD` 和普通文本；用 `tshark -d tcp.port==18023,telnet` 检查 `telnet.command` 与 option 字段。关键限制：netcat 不实现协商状态机，真实互操作需安装/启动 inetutils-telnetd，不能把 fixture 结果写成 telnetd 结果。

## Anatomy

- `IAC WILL ECHO`：发送方宣布愿意执行 ECHO。
- `IAC DO SGA`：发送方请求对方执行 Suppress Go Ahead。
- `IAC IAC`：数据中的 0xff 必须转义。
- 协商是逐字节、有状态、可拒绝的；RFC 854 的对称性避免双方无限重复请求。

## 安全

Telnet 不提供机密性或完整性；口令和会话内容可被同链路观察。只在 loopback/netns 使用，现实替代是 SSH。
