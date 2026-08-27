# Prior Art / 已有实现与资料地图

协议动物园最容易犯的错误，就是把“我要理解协议”误写成“我要从头实现一个完整服务端”。本文件用于强制查重。

## 1. 原始 RFC / 标准永远优先

建议直接从 RFC Editor 查原文：<https://www.rfc-editor.org/>

第一批物种的基础入口：

- TELNET：RFC 854
- FTP：RFC 959
- TFTP：RFC 1350
- Finger：RFC 1288
- Gopher：RFC 1436
- NNTP：RFC 3977（现代规范；同时追踪早期 RFC）
- IRC：RFC 1459（历史基础；后续实现有大量扩展）
- SCTP：RFC 9260
- DCCP：RFC 4340
- UDP-Lite：RFC 3828
- GRE：RFC 2784 / RFC 2890

### 原则

RFC 用来说明协议定义，但不能单独证明“真实世界的实现一直这样工作”。因此每个 exhibit 还要有真实实现和抓包。

## 2. GNU Inetutils

- 项目：<https://www.gnu.org/software/inetutils/>
- 手册：<https://www.gnu.org/software/inetutils/manual/inetutils.html>

GNU Inetutils 已经提供/维护多种经典 Unix 网络程序，包括：

- ftp / ftpd
- telnet / telnetd
- tftp / tftpd
- rlogin / rlogind
- rsh / rshd
- talk / talkd
- inetd
- 以及 ping、traceroute、whois 等工具

### 本项目决策

对于这些协议，第一选择不是自己重写 daemon，而是：

1. 用 Inetutils 或系统实现跑起来；
2. 在 loopback/netns 抓包；
3. 对照 RFC 解释；
4. 只在需要展示某个机制时写几十行“最小实现”。

完整重写只有在“实现差异本身就是研究对象”时才值得做。

## 3. Wireshark Sample Captures

- Resources / Sample Captures：<https://www.wireshark.org/resources>

Wireshark 官方资源中已有大量协议样本，其中甚至有：

- `Obsolete_Packets.cap`
- AppleTalk
- DECnet
- Banyan VINES
- 以及大量 ICMP、USB、路由协议等样本

### 价值

化石协议不一定需要先找硬件。

可以先做：

```text
existing pcap
→ dissector
→ frame-by-frame reading
→ protocol anatomy note
→ later reproduce if possible
```

### 注意

外部样本不能直接无脑复制进仓库。先确认来源与许可；最稳妥的是记录下载来源，再生成我们自己的实验抓包。

## 4. Scapy

- 文档：<https://scapy.readthedocs.io/>
- 项目：<https://github.com/secdev/scapy>

Scapy 已经具备大量协议层定义、组包/解包和交互实验能力。

### 适合本项目

- 构造最小报文；
- 解剖字段；
- 快速验证 checksum / option / header；
- 在隔离环境生成自己的 pcap。

### 不应该做

为了“自主可控”把 Scapy 已经实现好的 packet codec 全部重写一遍。

如果要自写编码器，必须有教学目的：例如只实现 TELNET option negotiation 的 30 行状态机，并与成熟实现互测。

## 5. 系统自带工具与 BSD 生态

很多旧协议在不同 BSD/Linux 发行版中仍有客户端、daemon 或历史源码。

每个协议开工前检查：

- GNU Inetutils；
- NetBSD / FreeBSD base system；
- Debian/Ubuntu package；
- OpenBSD 是否已移除或保留；
- BusyBox 是否有简化实现。

“现代系统把它删了”本身也是有价值的历史事实。

## 6. Gopher 现有生态

Gopher 今天仍有小型社区和大量现成 server/client。

因此本项目做 Gopher 的目标不应是“发布一个功能最全的新服务器”，而应是：

- 用最小 server 展示 selector/menu model；
- 对比 Gopher 信息架构与 HTTP/HTML；
- 记录为什么它看起来像“目录协议”；
- 分析它在今天仍能低成本存活的原因。

## 7. IRC / NNTP 的现成实现

IRC 和 NNTP 都有成熟 daemon/client，不应该从 socket accept 开始重新造生产实现。

适合研究：

- IRC line protocol 与 server federation；
- numeric replies；
- IRCv3 与旧 RFC 的演化；
- NNTP article / group / propagation 模型；
- “协议简单”与“分布式社会系统复杂”之间的落差。

## 8. 抓包工具链

建议标准化为：

```text
tcpdump / dumpcap
       ↓
pcapng
       ↓
Wireshark / tshark
       ↓
(optional) Scapy verification
```

每个 exhibit 尽可能提交：

- 生成命令；
- 拓扑；
- 软件版本；
- 过滤器；
- 关键 frame number；
- 预期现象。

## 9. 不要忽视“博物馆已经存在”

有大量 retrocomputing 社区、旧 Unix 软件源码和协议文档已经保存了真实实现。

协议动物园的增量不是把这些内容搬进一个仓库，而是提供统一实验体例：

```text
history + standard + implementation + capture + explanation + present-day status
```

## 开工前强制查重清单

每新增一种 protocol：

- [ ] 原始/当前 RFC 是什么？是否已经 obsoleted/superseded？
- [ ] GNU/BSD/BusyBox 有没有现成实现？
- [ ] Scapy 是否已有 layer？
- [ ] Wireshark 是否已有 dissector？
- [ ] Wireshark Sample Captures 是否已有样本？
- [ ] 是否已有成熟 server/client，可直接用于互操作？
- [ ] 我们新增的代码是在证明一个机制，还是仅仅重写现成库？
- [ ] 是否必须联网？能否 loopback/netns 完成？
- [ ] 协议是否明文/弱认证，是否应该禁止公网实验？

如果已有实现 + dissector + sample capture 都齐全，那么第一步应该是**读、跑、抓、解释**，而不是创建 `server.py`。
