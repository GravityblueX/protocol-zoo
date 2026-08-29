# M29–M30 — TCP / UDP 穿过真实 WAN

TCP 与 UDP 共享 IP path，却给 application 不同的契约。TCP 提供 reliable、in-order byte stream，以 sequence numbers 检测 loss、以 retransmission 修复，并建立 connection state；UDP 只提供最小 datagram mechanism，不保证 delivery、ordering 或 duplicate protection。[RFC 9293 §2.2](https://www.rfc-editor.org/rfc/rfc9293.html#section-2.2)；[RFC 768](https://www.rfc-editor.org/rfc/rfc768.html)

## 本地基线

仓库已有 `captures/dummy-tcp-netns.pcapng`，证明隔离 harness 能建立 TCP flow；但它不是本次 WAN 证据。本轮没有新增脚本或 capture。

本地 loopback/netns 的价值是把 application、socket 与 packet format 跑通；它不能复现真实 WAN 的 variable RTT、routing、NAT/firewall policy、queueing 与 asymmetric failure。

## WAN 受控观察（2026-08-29）

目标仅为自有 VPS `192.144.192.215`。本地主机经现有 route 可 ping/SSH 到达，VPS 为 Linux 6.8.0-124；远端仅临时打开高端口 44330/TCP 与 44331/UDP，并使用 explicit timeout。结束后清理相关 processes/files，并检查不再保留实验 listeners。

### TCP

client 向 44330/TCP 的 `nc` connect 返回 success，但远端 readback 文件为 0 bytes，listener 当时仍存在。

**结论：fail / inconclusive。** 这次 application-level transfer 没有闭环。client exit status 不能证明 payload 已由 server application read；没有同步 pcap，也不能确定是 command/lifecycle error、middlebox policy，还是 data 未发送。它只能证明 client API 没有立即报告 connect/write failure。

### UDP

client 向 44331/UDP send 返回 success，但远端 readback 文件为 0 bytes，listener 当时仍存在。

**结论：fail / inconclusive。** UDP `send` 成功只说明 local stack 接受 datagram，不是 remote delivery acknowledgment。没有远端 application bytes 或 packet capture，不能标为 WAN delivery pass。

因此本轮 **不生成 L4 evidence record**。失败本身进入 Failure Gallery；这比把 shell return code 冒充 WAN interoperability 更可靠。

## 如何比较，而不把 transport 神化

| 观察 | TCP 能提供 | UDP 能提供 | 仍需 application 做什么 |
|---|---|---|---|
| local send accepted | buffered stream write/connect state | datagram accepted by local stack | 不等于 remote consumption |
| network loss | retransmission/loss recovery | base UDP 不修复 | UDP app 自定 retry/FEC/ignore；TCP app 仍处理 timeout |
| message boundary | byte stream不保留 write boundaries | datagram boundary 保留 | TCP framing；UDP size/idempotency |
| middlebox state | 典型 SYN/FIN/RST 可见 state | 常依 timeout 维持 pseudo-state | keepalive/retry 必须适配 policy |
| PMTU trouble | segmentation、MSS/PMTUD 可参与调整 | application datagram 可能直接受 size 影响 | 需要 PTB/PLPMTUD 或 conservative sizing |

## 推论与边界

- **推论：** TCP 的可靠性是 endpoint transport behavior，不保证 application 在 timeout 前拿到完整业务结果，也不保证 server 已持久化数据。
- **推论：** UDP 无 handshake，减少 base protocol state，却把 loss detection、retry、ordering、congestion behavior 等选择留给上层；不能把“更少机制”写成“更快”或“更不可靠”的无条件结论。
- **未证明：** 本次 TCP 与 UDP 走完全相同 path 或经历相同 middlebox policy。
- **未证明：** WAN throughput、loss rate、jitter、congestion control quality。单次短消息且无 pcap 不能测出这些指标。

## 下一次达到 L4 的门槛

1. 双端同时 capture，只过滤自有 endpoint 与临时 ports；
2. payload 带随机 run ID 与长度/checksum；
3. TCP 由 server 回送 receipt；UDP 由 application echo/ACK 回送同一 run ID；
4. 保存 client、server、pcap、frame index 和 software versions；
5. listener 绑定所需 address，短 timeout，结束后检查 `ss`/`ps`；
6. 分开记录 `socket accepted`、`packet observed`、`application verified` 三层结果。
