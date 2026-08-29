# 第二纪元剩余实验 blocker 记录

本页记录已经尝试、但当前环境没有安全稳定 real-capture 的项目。`not-run` 是结果，不是未检查。

| M | 项目 | 已检查 | 结果 | 原因 |
|---|---|---|---|---|
| M11 | PPP over private PTY | 宿主 `/usr/sbin/pppd`、guest `pppd`、socat PTY | `not-run` | pppd 需要完整两端串行参数/权限和可抓取 HDLC 字节流；当前 probe 未建立稳定链路，不能把 LCP fixture 当真实包 |
| M12 | RIP count-to-infinity 扩展 | BIRD 三节点传播已 real-capture | `fixture` | 正常收敛已经实测；经典 count-to-infinity 故障注入仍保留 fixture，不能拿 poison-reverse metric 16 当完整故障史 |
| M15 | Teredo/ISATAP/NAT64 | RFC 来源与私有 SIT 实测 | `static`/`fixture` | IPv6-in-IPv4 已 real-capture；其余机制不连接公共 relay/broker，不能拿 SIT 包冒充它们 |
| M17 | rlogin/rsh/rexec | guest 客户端存在 | `static`/`fixture` | 当前 guest 没有可用的成熟 rlogind/rshd 服务端；不自写信任远程 daemon |
| M18 | DVMRP/PIM/MBONE | tshark dissectors 与 RFC | `static`/`fixture` | IGMP membership 已 real-capture，但不把 IGMP 抓包冒充路由协议/MBONE 实验；不接现有路由域 |
| M16 | ARPANET/NCP | RFC 714 与历史文献 | `document-reconstruction` | 没有合法历史主机或来源清晰的真实历史 pcap |

所有 blocker 均遵守：不碰宿主公网接口、不改默认路由、不提交许可不明样本、不把合成文本或失败 probe 冒充成功实验。
