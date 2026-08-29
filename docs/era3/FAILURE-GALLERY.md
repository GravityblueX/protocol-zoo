# M33 — Failure Gallery

本馆把失败当作 evidence boundary，而不是把失败命令修辞成协议结论。每条记录都分为 **观察**、**可支持结论**、**尚未证明** 和 **下一证据**。

## F01 — PMTU threshold 的结果不单调

- **范围：WAN，2026-08-29，自有 VPS。**
- **观察：** 多个大 IPv4/IPv6 echo probe 成功；相邻 size 中出现较小 probe 无响应、较大 probe 有响应。
- **可支持结论：** 单次 echo response 不是可靠的 PMTU binary-search oracle；本轮不能给 WAN PMTU 定值。
- **尚未证明：** 无响应由 MTU、rate limit、loss、offload、middlebox 或 reply path 中哪一项造成。
- **下一证据：** 每个 size 多次交错 probes；双端 pcap；核对 DF/PTB、actual IP length 与 fragmentation；记录 route/interface MTU。

## F02 — WAN UDP traceroute 全是 `*`，目标仍可达

- **范围：WAN，2026-08-29，自有 VPS。**
- **观察：** bounded UDP traceroute 1–16 hops 均无 matching reply；同一时段 ping 与 SSH 可达。
- **可支持结论：** traceroute probe/reply 的 visibility 与 destination reachability 不等价。
- **尚未证明：** 哪一 hop 或哪条 policy 丢弃/抑制了 ICMP；实际 hop count；物理 path。
- **下一证据：** 在有权限的受控环境比较 UDP/ICMP/TCP probes，保存 pcap；若要研究回程，需第二 observation point。

## F03 — TCP client success，server application 收到 0 bytes

- **范围：WAN，2026-08-29，自有 VPS，高端口 44330/TCP。**
- **观察：** client command status 为 0；远端 listener 仍在，readback 文件 0 bytes。
- **可支持结论：** client-side success status 不足以证明 application delivery。
- **尚未证明：** connection 是否完成、payload 是否上 wire、server kernel 是否收到、netcat invocation/lifecycle 是否正确。
- **下一证据：** 双端 pcap + server receipt/echo + run ID；分别验证 SYN handshake、payload ACK 与 application read。

## F04 — UDP send success，server application 收到 0 bytes

- **范围：WAN，2026-08-29，自有 VPS，高端口 44331/UDP。**
- **观察：** local `send` command status 为 0；远端 listener readback 文件 0 bytes。
- **可支持结论：** UDP local send acceptance 不是 remote delivery confirmation。
- **尚未证明：** datagram 是否离开 client、是否到达 VPS NIC/socket、是否被 policy 丢弃。
- **下一证据：** 双端 pcap；server 回送含 run ID 的 application ACK；固定 source/destination tuple 并记录 timeout。

## F05 — DHCP ACK 不等于 Internet ready

- **范围：本地隔离实验的一般诊断边界。**
- **观察：** 现有 capture 证明 DORA 后 TFTP 成功，因而该实验的 address-to-application chain 闭环。
- **可支持结论：** 只有 ACK 时，最多证明 server 发出了配置；还需 client state 与 data-plane test。
- **尚未证明：** 未出现于 packet/options 或未检查 client state 的 default route、DNS、relay、WAN reachability。
- **下一证据：** lease dump、`ip addr/route`、resolver state、ARP/ND 与目标 application packet chain。

## F06 — ICMP/raw-socket 权限不足

- **范围：本地主机工具执行环境。**
- **观察：** TCP/ICMP traceroute 返回 `Operation not permitted`；UDP traceroute 可运行。
- **可支持结论：** 这两个 probe modes 是 `not-run`，不是网络失败。
- **尚未证明：** 若运行这些 probe，path 会如何响应。
- **下一证据：** 在明确授权且不改生产网络的环境授予最小 capability，再记录工具版本与 probes；不能把权限错误写成 destination filtering。

## 失败分类模板

```text
ID / 时间 / 范围（本地、WAN、外部佐证）
操作与边界：target、count、timeout、capture point
观察：原始 exit status / packet / application state
可支持结论：只写证据直接覆盖的范围
尚未证明：列出竞争解释
下一证据：能区分竞争解释的最小实验
cleanup：listener、process、namespace、firewall、temp files
```

## 写作禁区

- 不把 timeout 自动翻译成 packet loss；
- 不把 `connect(2)`/`send(2)` success 翻译成 remote application success；
- 不把 traceroute `*` 当作一台 router；
- 不把 endpoint interface MTU 当作 PMTU；
- 不把 RFC 定义的能力写成当前实现或当前路径已观察行为；
- 不因使用了 VPS 就把证据自动升级到 L4。
