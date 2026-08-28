# Telnet 展品

署名：**祀（岁家老十三）**。

- 规范：RFC 854（协议）、RFC 855（选项结构）、RFC 857（回显）、RFC 858（Suppress Go Ahead）。
- 实现：Debian `inetutils-telnet` 客户端；真实服务端实验使用 `inetutils-telnetd`，另保留 netcat 字节流 fixture 以隔离展示原始协商字节。
- 核心机制：TCP 字节流中以 IAC `0xff` 开始的命令；`DO/DON'T/WILL/WON'T` 协商对端能力，普通数据仍可混在同一流内。

## 隔离实验

`scripts/real-app-capture.sh` 在 `pz-client`/`pz-server` netns 中通过 namespace-local inetd 启动 `inetutils-telnetd`，客户端使用 `inetutils-telnet`，结果见 `captures/real-app-netns/telnet.pcapng` 与 `telnet.frames.tsv`。frame 6 可见服务端发出的多组 IAC option negotiation。netcat fixture 仍用于展示可控原始字节，但不冒充 telnetd。

## Anatomy

- `IAC WILL ECHO`：发送方宣布愿意执行 ECHO。
- `IAC DO SGA`：发送方请求对方执行 Suppress Go Ahead。
- `IAC IAC`：数据中的 0xff 必须转义。
- 协商是逐字节、有状态、可拒绝的；RFC 854 的对称性避免双方无限重复请求。

## 安全

Telnet 不提供机密性或完整性；口令和会话内容可被同链路观察。只在 loopback/netns 使用，现实替代是 SSH。
