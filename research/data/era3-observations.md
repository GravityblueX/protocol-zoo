# Era 3 observation ledger — 2026-08-29

本 ledger 只记录本轮可复核 observation 与 provenance。`local`、`wan`、`inference` 不互相替代；没有保存 packet capture 的 WAN 操作不标 L4。

| ID | scope | subject | observation | evidence | status / limitation |
|---|---|---|---|---|---|
| E3-20260829-01 | local | IPv4 PMTUD | 三 namespace、egress MTU 1400；1400-byte IP packet 成功，1401-byte DF packet 触发 `Frag needed ... mtu=1400`；route cache 记入 MTU 1400 | command transcript observed during run | pass, L2；无 pcap |
| E3-20260829-02 | local | traceroute | client→router→server；UDP 与 ICMP probes 均显示 hop 1 router、hop 2 destination | command transcript observed during run | pass, L2；无 pcap |
| E3-20260829-03 | local | DHCP→TFTP | DORA frames 1–4；leased address 198.18.50.13 随后在 frames 5–7 完成 TFTP RRQ/DATA/ACK | `captures/era2-netns/boot-chain.{pcapng,json,frames.tsv}` | pass, L3；isolated `/24` |
| E3-20260829-04 | wan | reachability | 自有 IPv4/IPv6 endpoint 均回 echo；IPv4 SSH 可登录，VPS kernel 6.8.0-124 | live commands | pass, L2；不构成 packet capture |
| E3-20260829-05 | wan | endpoint MTU state | VPS eth0 MTU 1500；IPv6 connected-prefix route advertises MTU 1464 | remote `ip link` / `ip -6 route` | observed host state；不是 PMTU |
| E3-20260829-06 | wan | PMTU probing | large echo results across adjacent sizes non-monotonic | bounded ping commands | inconclusive；不报告 WAN PMTU |
| E3-20260829-07 | wan | UDP traceroute | TTL 1–16 每级一个 probe，全部 `*`；同一 endpoint 仍可 ping/SSH | local traceroute + reachability checks | observed no matching replies；不能定位 drop hop |
| E3-20260829-08 | local | traceroute capability | TCP/ICMP traceroute modes报 raw-socket `Operation not permitted` | tool stderr | not-run；不是 path result |
| E3-20260829-09 | wan | TCP high-port transfer | client status 0；remote readback 0 bytes，listener remained during check | client/remote command state | fail/inconclusive；无 pcap，不声称 delivery |
| E3-20260829-10 | wan | UDP high-port transfer | client status 0；remote readback 0 bytes，listener remained during check | client/remote command state | fail/inconclusive；local send ≠ delivery |
| E3-20260829-11 | inference | PMTU black hole | blocked PTB can permit small packets/handshake while larger transfer hangs | RFC 8201 §1 | normative mechanism inference；本轮 WAN 未复现 |
| E3-20260829-12 | inference | DHCP integration | ACK 中 option 被发送不等于 client 已安装/采用；需 client state + data-plane evidence | RFC 2131 + evidence method | methodological inference |

## Cleanup

- local namespaces `pz-era3-doc-c`, `pz-era3-doc-r`, `pz-era3-doc-s` were deleted by trap；
- WAN listeners used only high ports 44330/TCP and 44331/UDP with explicit timeout；
- related remote netcat processes and `/tmp/pz-era3-*` files were removed；
- no firewall, default route, production proxy, credential, or repository script was modified；
- no binary capture was created in this documentation-only run.

## Source anchors

- RFC 792, ICMP Destination Unreachable and Time Exceeded: <https://www.rfc-editor.org/rfc/rfc792.html>
- RFC 1191, IPv4 Path MTU Discovery: <https://www.rfc-editor.org/rfc/rfc1191.html>
- RFC 8201, IPv6 Path MTU Discovery: <https://www.rfc-editor.org/rfc/rfc8201.html>
- RFC 2131, DHCP: <https://www.rfc-editor.org/rfc/rfc2131.html>
- RFC 768, UDP: <https://www.rfc-editor.org/rfc/rfc768.html>
- RFC 9293, TCP: <https://www.rfc-editor.org/rfc/rfc9293.html>
