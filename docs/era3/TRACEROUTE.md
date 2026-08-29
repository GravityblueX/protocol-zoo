# M19 — Traceroute：从 TTL/Hop Limit 错误拼出路径

Traceroute 不是一种 wire protocol；它是一类主动测量方法。它发送 TTL（IPv4）或 Hop Limit（IPv6）逐步增加的 probes，并把中间转发节点返回的 ICMP Time Exceeded 与最终目的响应关联起来。

RFC 792 规定：gateway 处理 datagram 时若 TTL 到零，必须丢弃，并可向源返回 ICMP Time Exceeded type 11 code 0；返回消息携带原 datagram 的 IP header 与前 64 bits data，以便源端匹配相应 probe。[RFC 792, Time Exceeded](https://www.rfc-editor.org/rfc/rfc792.html)

## probe 家族

| 模式 | 中间 hop 的典型响应 | 目的端的典型结束信号 |
|---|---|---|
| UDP to unlikely high port | ICMP Time Exceeded | ICMP Port Unreachable |
| ICMP Echo | ICMP Time Exceeded | Echo Reply |
| TCP SYN | ICMP Time Exceeded | SYN/ACK 或 RST，依目的 port 状态而异 |

不同 probe 会被 ACL、防火墙、NAT、ECMP hash 或目的 host 以不同方式处理，所以三种输出不保证一致。

## 本地实测（2026-08-29，L2）

复用临时三 namespace 拓扑：

```text
client 10.33.1.2 -> router 10.33.1.1 / 10.33.2.1 -> server 10.33.2.2
```

UDP 与 ICMP traceroute 都得到：

```text
1  10.33.1.1
2  10.33.2.2
```

这验证了方法的最小闭环：TTL=1 在 router 结束，TTL=2 到达 destination。结束后 namespace 已删除；没有保存 packet capture，因此证据为 L2。

## WAN 观察（2026-08-29，受控自有 VPS）

对自有 IPv4 endpoint 运行 bounded UDP traceroute（最多 16 hops、每 hop 1 probe、1 s wait），16 行均为 `*`。非特权环境中的 TCP/ICMP traceroute 因 raw-socket 权限失败，未执行；没有用提权规避该边界。

同时，普通 IPv4/IPv6 ping 与 SSH 均能到达 endpoint。这组观察只说明：**该时刻 UDP traceroute 所期待的 ICMP replies 没有返回到测量进程，而 destination 对其他流量仍可达。** 它不证明 16 个物理 router 都“丢包”，也不证明路径只有或多于 16 hops。

## `*` 到底是什么

`*` 是“在等待窗口内没有匹配 reply”，不是一个匿名 router。可能原因包括：

- router 转发 probe，但不产生或 rate-limit ICMP；
- reply 被回程 ACL/firewall 过滤；
- probe protocol/port 被中间盒区别处理；
- reply 超过等待时间；
- route 在 probes 间变化；
- NAT/ECMP 让 matching 或路径表现变化。

这些都是解释候选。没有 router telemetry 或双端/多点 capture 时，不应从星号中挑一个当作已证实根因。

## 推论与边界

- **推论：** traceroute 显示的是 responding interfaces，不是完整设备 inventory；一个 router 可用不同 interface address 响应，多个 hops 也可能不响应。
- **推论：** hop RTT 是 probe/reply 的 round trip，不是单条链路 delay；后续 hop RTT 更低并不矛盾。
- **未证明：** 地址到组织/地理位置的归属。需要单独、带时间戳的 RIR/运营商数据才能做此类映射。
- **未证明：** 正向和反向路径相同。单端 traceroute 只约束其 probes 与 replies 实际走过的组合。

## Failure Gallery 入口

| 误读 | 正确表述 |
|---|---|
| “第 5 跳开始断网” | “从第 5 个 TTL 起没有收到匹配 reply” |
| “某 hop RTT 高，所以该链路拥塞” | “该 hop 的控制面 reply 较慢；尚不能定位 data-plane bottleneck” |
| “UDP trace 全星，目标不可达” | 另用受控 TCP/ICMP/application probe 检查；本轮目标实际仍可 ping/SSH |
