# M20 — DHCP Integration：拿到地址之后，主机才成为网络成员

DHCP 不只是“发一个 IP”。RFC 2131 把它定义为向 host 传递配置参数的框架，同时提供 address allocation；它沿用 BOOTP message format 与 relay model，使 server 不必位于每个 physical segment。[RFC 2131 Abstract, §§1–1.3](https://www.rfc-editor.org/rfc/rfc2131.html)

## 本地 packet evidence（复用 Era 2 capture，L3）

现有自生成证据：

- `captures/era2-netns/boot-chain.pcapng`
- `captures/era2-netns/boot-chain.json`
- `captures/era2-netns/boot-chain.frames.tsv`

capture point 为 server namespace 的私有 veth，filter 为 UDP 67/68/69；地址全部位于文档用途网段 `198.18.50.0/24`，payload 为合成 `boot.img`。结构化记录显示 Linux kernel 6.8.0-137、dnsmasq 2.90、ISC dhclient 4.4.3-P1；实验完成后隔离环境已清理。

| Frame | packet evidence | 意义 |
|---:|---|---|
| 1 | `0.0.0.0:68 -> 255.255.255.255:67`, DHCP type 1 | client 尚无地址，发 DISCOVER |
| 2 | `198.18.50.1:67 -> 198.18.50.13:68`, type 2 | server OFFER，`yiaddr=198.18.50.13` |
| 3 | broadcast type 3 | client REQUEST |
| 4 | server -> client type 5 | server ACK |
| 5 | `198.18.50.13:54456 -> 198.18.50.1:69`, TFTP RRQ `boot.img` | leased address 已可用于后续 application flow |
| 6 | server ephemeral UDP port -> client, TFTP DATA block 1 | TFTP transfer 改用 server transfer ID |
| 7 | client -> server ephemeral port, TFTP ACK block 1 | boot file transaction 完成 |

这里的 integration 证据不是“看到了 DORA 就宣布网络可用”，而是同一 client 紧接着以 leased address 成功发起 TFTP RRQ 并确认 data block。

## 配置面必须与数据面分开读

DHCP 可传递 address、lease 与多种 options；客户端随后如何把它们安装到 interface、route、resolver 或 boot logic，属于 client implementation 与系统 integration。Packet capture 可以证明 server **发送了**某 option，却不能单凭该 packet 证明 client **采用了**它。

本 capture 明确证明 address allocation 与 TFTP boot-file use。它没有证明：

- default route 已安装并可到达 WAN；
- DNS resolver option 已发送或被应用；
- lease renewal / rebind；
- DHCP relay；
- 多 server selection；
- hostile/rogue DHCP 防护。

## WAN 状态

**未运行 WAN DHCP。** DHCP discovery 使用 link-local broadcast 语境，公网/云 VPS 的地址与 route 通常由 provider control plane 或虚拟网络提供；在公网 interface 上起实验 DHCP server 会越过本仓的 bounded 安全边界。M20 的真实证据因此刻意停留在 isolated namespace。

## 推论与边界

- **推论：** 若 ACK 缺少或 client 未应用 route/DNS 等必要参数，主机可能“有地址但不能完成目标业务”。具体缺失项必须由 lease state、route/resolver state 和 packet evidence 联合定位。
- **推论：** relay 能跨 subnet 转送 client/server exchange，但这不是当前 capture 的行为；不能把 RFC 能力写成已实测。
- **未证明：** DHCP 是该 WAN VPS public address 的分配机制。远端 `ip route` 显示 IPv4 default route 标为 `proto dhcp`，但这只是该 host 当前 kernel state；没有 DHCP capture，不能重建完整 exchange。

## Failure Gallery 入口

| 症状 | 可验证层次 |
|---|---|
| 一直 DISCOVER | L2 reachability、server/relay visibility、reply path |
| OFFER 后反复 REQUEST | transaction ID/client identity、selected server、ACK/NAK |
| 已 ACK 但访问失败 | installed address/prefix/route、ARP/ND、DNS、policy |
| TFTP RRQ 到 69 后停住 | DATA 使用的新 server UDP port 是否被 stateful policy 接受 |
