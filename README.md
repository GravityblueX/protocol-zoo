# Protocol Zoo · 协议动物园

> 不是重新发明网络协议，而是把那些仍在、半死不活、已经退出主流或只剩化石的协议重新“养起来”：能跑、能抓包、能解释、能复现实验。

## 项目定位

每一种协议都是一个 exhibit（展笼）。一个完整 exhibit 应同时回答：

- 它当初解决什么问题？
- 运行在哪一层，依赖哪些下层协议？
- 报文到底长什么样？
- 今天还能不能在现代 Linux / BSD / Windows / VPS 上真实跑起来？
- Wireshark 怎么看？
- 哪些行为是协议本身，哪些只是某个历史实现的习惯？
- 它为什么被替代、退化成兼容层，或者仍然活着？
- 它有哪些今天看起来危险、奇怪或反直觉的设计？

## 不做什么

- 不以“自己重写完整生产级 Telnet/FTP/IRC server”为目标；
- 不为了怀旧把明文认证协议暴露到公网；
- 不把 RFC 摘抄成百科；
- 不把协议历史写成“新协议必然优于旧协议”的进步史；
- 不和 `nekomusume` 合并：这里是博物馆/实验场，猫娘协议是活的研发项目。

## 每只“动物”的标准笼子

```text
species/<name>/
├── README.md        # 历史、用途、状态
├── anatomy.md       # 报文/状态机拆解
├── lab.md           # 最小可重复实验
├── security.md      # 现代安全边界
├── captures/        # 自己生成的小型 pcap/pcapng
├── scripts/         # 最小实验脚本
└── sources.md       # RFC、手册、既有实现
```

一个 exhibit 至少应该有：

1. **原始规范**：RFC / 标准 / 厂商手册；
2. **一个既有实现**：优先复用系统工具或成熟开源项目；
3. **一个自己的最小实验**；
4. **一个抓包**；
5. **逐字段解释**；
6. **现代网络上的现实状态**；
7. **“为什么今天不这么做了 / 为什么它还没死”**。

## 第一批物种

### A 区：今天仍很容易复活

- Telnet
- FTP（主动 / 被动）
- TFTP
- Finger
- talk / talkd
- rlogin / rsh
- IRC
- NNTP
- Gopher

### B 区：协议设计值得研究

- SCTP
- DCCP
- UDP-Lite
- GRE
- IP-in-IP

### C 区：化石区

优先从抓包和模拟环境入手，不承诺真实联网：

- AppleTalk
- DECnet
- Banyan VINES
- IPX/SPX

## 实验规范

每个实验尽量产生机器可读结果：

```yaml
protocol: telnet
environment:
  os: linux
  kernel: "..."
  topology: loopback
result:
  handshake: pass
  capture: captures/telnet-loopback.pcapng
notes:
  - "明文，仅隔离实验环境"
```

测试优先级：

1. loopback；
2. network namespace / veth；
3. 两台局域网机器；
4. 只有确实安全且有意义时才考虑真实 WAN。

## 安全原则

很多旧协议的危险不是 bug，而是时代假设不同。

因此：

- 明文口令协议默认只允许 loopback / netns；
- 不提供自动化公网扫描器；
- 不默认启用匿名写入、远程 shell 或弱认证服务；
- 抓包样本必须去除真实凭据、真实私人地址和无关数据；
- 重点解释设计边界，而不是“如何攻击老服务”。

## 第一阶段

- [ ] `docs/PRIOR_ART.md`：已有实现、RFC、抓包资源盘点；
- [ ] Telnet：协商选项 + 最小抓包；
- [ ] FTP：主动/被动模式为什么这么别扭；
- [ ] Gopher：一个最小菜单服务；
- [ ] Finger：协议极简主义案例；
- [ ] talk：终端时代的即时通信；
- [ ] Wireshark obsolete sample capture 阅读笔记；
- [ ] 做一张“协议为什么死 / 为什么活”的比较表。

## 这个仓库最终应该像什么

不是协议教程合集，而是一座**能通电的网络协议博物馆**：每个展品既有铭牌，也有线路，按下按钮真的会有包在网线上跑过去。
