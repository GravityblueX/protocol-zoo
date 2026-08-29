# M18 — MTU 与 Path MTU Discovery

MTU 是一条链路一次可承载的最大 IP packet；Path MTU（PMTU）是源到目的路径上各链路 MTU 的最小值。二者不能由接口上的同一个数字替代：第一跳 MTU 只给出起始上限，中途的低 MTU 链路才可能成为瓶颈。[RFC 1191 §1](https://www.rfc-editor.org/rfc/rfc1191.html#section-1)；[RFC 8201 §2](https://www.rfc-editor.org/rfc/rfc8201.html#section-2)

## 机制

IPv4 PMTUD 让发送端设置 DF；不能在下一跳 MTU 内转发的路由器丢弃 packet，并返回 ICMP Destination Unreachable / Fragmentation Needed（type 3, code 4）及 next-hop MTU。发送端随后降低该路径的 PMTU 估计。[RFC 1191 §2](https://www.rfc-editor.org/rfc/rfc1191.html#section-2)；[RFC 792, Destination Unreachable](https://www.rfc-editor.org/rfc/rfc792.html)

IPv6 的路由器不在路径中分片。过大的 packet 触发 ICMPv6 Packet Too Big，发送端据其中 MTU 调整 packetization；若不做 PMTUD，节点以 IPv6 minimum link MTU 为发送上限。[RFC 8201 §§1,3](https://www.rfc-editor.org/rfc/rfc8201.html#section-3)

## 本地实测（2026-08-29，L2）

三 namespace 拓扑：

```text
client 10.33.1.2 -- MTU 1500 -- router -- MTU 1400 -- 10.33.2.2 server
```

仅在临时 namespace 中运行，未改宿主路由；结束后 namespace 已删除。

| probe | 观察 |
|---|---|
| `ping -M do -s 1372` | IPv4 total length 1400，2/2 replies |
| `ping -M do -s 1373` | IPv4 total length 1401；router 返回 `Frag needed and DF set (mtu = 1400)` |
| `ip route get 10.33.2.2` | route cache 出现 `mtu 1400` |

这是“低 MTU 下一跳 → ICMP 错误 → 发送端更新路径状态”的可执行复现。它不是 WAN 结论，也没有保存 pcap，因此等级为 L2 而非 L3。

## WAN 观察（2026-08-29，受控自有 VPS）

目标仅为仓库登记的自有 endpoint `192.144.192.215` / `2402:4e00:c050:1b00:450:1bde:8a6e:1`。IPv4、IPv6 echo 均可达，往返时间约 18–26 ms。远端 `eth0` 报告 MTU 1500，但 IPv6 connected prefix route 报告 MTU 1464。

从本地主机发出的若干 large echo probes 成功；个别相邻 size 的响应并不单调（例如 IPv4 payload 1472 无响应而 1473 有响应）。因此本轮 **没有**把某个数值记作 WAN PMTU，也没有把 endpoint interface MTU 当作 end-to-end PMTU。无同步双端 pcap 时，这些结果只构成 L2 的实时可达性观察，不升级为 L4 packet evidence。

## 推论与边界

- **推论：** 若 ICMP Fragmentation Needed / Packet Too Big 被过滤，classic PMTUD 可能形成黑洞：小 packet 或 TCP handshake 成功，较大的 data packet 停住。RFC 8201 §1 明确描述这种连接形态；这是规范支持的机制推论，不是本轮 WAN 复现。
- **推论：** tunnel、overlay 或其他 encapsulation 增加 outer headers，会压低 inner packet 可用空间；具体减多少取决于实际封装，不能从“常见 Ethernet MTU 1500”直接推出。
- **未证明：** 当前 WAN 路径始终对称、稳定，或所有 router 都正确返回 ICMP。PMTU 与 route 都可能随时间和方向改变。

## Failure Gallery 入口

| 症状 | 先查什么 | 不能立刻声称什么 |
|---|---|---|
| 小请求成功，大传输卡住 | DF/PTB、MSS、retransmission、interface/tunnel MTU | “一定是防火墙” |
| endpoint MTU 1500，但大 packet 失败 | 中间路径与 encapsulation | “PMTU 就是 1500” |
| 单次 probe 无响应 | 连续 size、重复样本、双端 capture | “这个 size 超过 PMTU” |
