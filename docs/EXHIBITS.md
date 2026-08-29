# 展品索引

署名：**祀（岁家老十三）**。

本索引把每个展品的规范、现有实现、实验边界和当前结论放在一起。所有网络实验默认使用 loopback 或 `scripts/lab-netns.sh`；没有成功运行的协议明确标注为模拟/静态分析。

| 展品 | 权威规范 | 实验状态 | 核心问题 |
|---|---|---|---|
| Telnet | RFC 854, RFC 855 | inetutils-telnetd 隔离抓包 + anatomy | IAC 协商如何嵌入字节流 |
| FTP | RFC 959, RFC 2428 | pyftpdlib + tnftp active/passive 隔离抓包 | 为什么 active/passive 与 NAT 强相关 |
| Finger | RFC 1288 | request/response fixture | 极简接口为何泄露隐私 |
| talk | BSD talk/talkd 文档 | 静态/模拟 | 邀请与终端用户模型 |
| Gopher | RFC 1436 | menu/selector fixture | 目录信息模型 |
| NNTP | RFC 3977 | command/article fixture | group、article、传播分层 |
| IRC | RFC 1459, IRCv3 | line/numeric fixture | 状态机与扩展 |
| SCTP | RFC 9260 | Kali nested-netns 实测抓包 | 多流、多宿主 |
| DCCP | RFC 4340 | Kali capability：errno 93 / not-run | 拥塞控制而不保证可靠 |
| UDP-Lite | RFC 3828 | Kali nested-netns 实测抓包 | 部分 checksum coverage |
| GRE | RFC 2784, RFC 2890 | Kali nested-netns 实测抓包 | 隧道封装 |
| IP-in-IP | RFC 2003 | Kali nested-netns 实测抓包 | 直接 IP 封装 |
| AppleTalk | DDP/AARP 文档 | Wireshark dissector reading | 化石样本与许可边界 |

详见各目录和 `research/`、`studies/`。
