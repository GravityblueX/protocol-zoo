# Protocol Zoo · 协议动物园

> 一座能通电的网络协议博物馆：把仍在、半死不活、退出主流或只剩化石的协议重新养起来——能跑、能抓包、能解释、能复现实验。

**署名：祀（岁家老十三）**

## 当前状态

实验基础设施和 M0–M9 第一纪元展品已完成；Telnet、FTP、SCTP、UDP-Lite、GRE 与 IP-in-IP 已有成熟实现或内核的隔离实测。第二纪元 M10–M19 的生态路线、数据集、研究矩阵和安全边界已建立；DHCP→TFTP、PPP、RIP、ICMP、NBNS、私有 IPv6-in-IPv4 与 IGMP 均有隔离真实证据，不能合法或安全实测的子项明确保留为 `fixture`、`static`、`document-reconstruction` 或 `not-run`。仓库优先记录可复现、可审查的实验；没有在当前环境真实跑通的协议，会明确标为 `fixture`、`static` 或 `not-run`，不把推导冒充实测。

| 区域 | 展品 | 状态 |
|---|---|---|
| Unix 经典协议 | [Telnet](species/telnet/)、[FTP](species/ftp/)、[Finger](species/finger/)、[talk](species/talk/) | 文档、机制 fixture、隔离边界完成 |
| 另类信息空间 | [Gopher](species/gopher/)、[NNTP](species/nntp/)、[IRC](species/irc/) | 文档与合成 line/menu fixture 完成 |
| 传输设计异类 | [SCTP](species/sctp/)、[DCCP](species/dccp/)、[UDP-Lite](species/udp-lite/)、[GRE](species/gre/)、[IP-in-IP](species/ip-in-ip/) | SCTP、UDP-Lite、GRE、IP-in-IP 已在独立 Kali nested-netns 实测；DCCP 保留 capability/not-run |
| 化石抓包馆 | [AppleTalk](species/appletalk/)；DECnet/VINES/IPX/SPX | AppleTalk 阅读闭环完成，其余遵守样本许可门禁并标记 `not-run` |

完整索引见 [`docs/EXHIBITS.md`](docs/EXHIBITS.md)。

## 快速开始

需要 Linux、`ip`、`tcpdump`、`tshark`、`jq`、`jsonschema`、`nc`，并需要 root/CAP_NET_ADMIN 才能建立 namespace：

```sh
# 统一入口：生成合成协议 fixtures
./scripts/experiment.sh fixtures

# 观察当前内核/工具能力（不加载模块、不改网络）
./scripts/experiment.sh capabilities

# 校验 schema、pcapng、脱敏标记、namespace cleanup 和 git diff
./scripts/experiment.sh validate

# 运行隔离 TCP capture（需要 sudo/CAP_NET_ADMIN）
./scripts/experiment.sh capture

# 第二纪元离线生态 fixtures 与校验
./scripts/experiment.sh era2-fixtures
./scripts/experiment.sh era2-validate

# 私有 IPv6-in-IPv4 transition 实验
./scripts/experiment.sh era2-ipv6
./scripts/experiment.sh era2-rip
./scripts/experiment.sh era2-ppp
./scripts/experiment.sh era2-network

# 第二纪元安全实验（当前环境可用项；失败项生成 not-run 证据）
./scripts/era2-capture.sh
```

也可以使用：

```sh
make fixtures
make capabilities
make validate
make capture
make clean

# 一次性重生成、能力观测并校验
make check
```

生成的示例证据：

- [`captures/dummy-tcp-netns.pcapng`](captures/dummy-tcp-netns.pcapng)
- [`captures/dummy-tcp-netns.json`](captures/dummy-tcp-netns.json)
- [`captures/fixtures/`](captures/fixtures/)

## 目录

```text
captures/                 自生成 pcapng、JSON 结果和合成 fixtures
datasets/species.csv      协议物种数据集
docs/                     安全边界、抓包规范、展品索引、署名
research/                  化石协议阅读与证据边界
schemas/                   实验结果 JSON Schema
scripts/                   netns harness、capture、fixture、校验脚本
species/                  各协议展品与标准模板
studies/                  协议存亡比较矩阵
```


## 实验安全边界

- 明文认证、弱认证和远程 shell 类协议只在 loopback 或专用 network namespace/veth 中实验。
- 不扫描第三方，不连接公网验证“真实性”，不把服务绑定到 `0.0.0.0`。
- 不使用真实密码、cookie、私人地址或生产数据。
- 抓包使用最小过滤器和最短生命周期，并在提交前检查脱敏。
- 失败或中断后执行 `sudo scripts/lab-netns.sh teardown`；不得修改宿主机默认路由、防火墙或 DNS。

详见 [`docs/LAB-SAFETY.md`](docs/LAB-SAFETY.md) 与 [`docs/CAPTURE-CONVENTION.md`](docs/CAPTURE-CONVENTION.md)。

## 研究原则

1. 先读 RFC/标准、厂商手册和上游文档。
2. 优先复用成熟 server/client、系统工具、Wireshark/tshark/Scapy。
3. 只有在现有实现无法展示机制时，才写最小教学 fixture；不重写生产级 daemon。
4. 区分协议规范与特定历史实现习惯。
5. 对外部 pcap 记录来源、许可、获取日期和校验值；许可不清时不提交二进制。

## 相关文档

- [`AGENTS.md`](AGENTS.md)：执行与安全契约
- [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md)：阶段完成情况
- [`ROADMAP.md`](ROADMAP.md)：研究路线与停止条件
- [`docs/EXHIBITS.md`](docs/EXHIBITS.md)：展品索引
- [`datasets/species.csv`](datasets/species.csv)：协议数据集
- [`studies/survival-matrix.md`](studies/survival-matrix.md)：为什么死 / 为什么活
- [`docs/COLOPHON.md`](docs/COLOPHON.md)：署名与资料归属
- [`docs/KALI-LAB.md`](docs/KALI-LAB.md)：独立 Kali guest、网络边界与复现入口
- [`research/era2-experiment-matrix.md`](research/era2-experiment-matrix.md)：M10–M19 第二纪元实验矩阵
- [`research/second-era-natural-history.md`](research/second-era-natural-history.md)：协议隐含世界假设与自然史
- [`datasets/era2.csv`](datasets/era2.csv)：第二纪元协议数据集
- [`docs/ERA2-STATUS.md`](docs/ERA2-STATUS.md)：第二纪元一次性状态清单
- [`research/era2-blockers.md`](research/era2-blockers.md)：剩余真实实验的已验证 blocker
