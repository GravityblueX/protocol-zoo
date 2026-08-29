# Era 3 Evidence Atlas — The Internet Grows Organs

这张图按互联网器官的形成顺序组织证据，不把文献重建、本地实验和公网观察混写。

## 名字

- DNS 历史：[`era3/dns.md`](era3/dns.md)
- 本地 root → `.test` → `museum.test`：`captures/era3-dns/`
- L3 证据：delegation、glue、recursive cache、TTL expiry、NXDOMAIN、negative cache。

## 地址、自治与路由政策

- CIDR：[`era3/cidr.md`](era3/cidr.md)
- BGP：[`era3/bgp.md`](era3/bgp.md)
- IXP 与 Anycast：[`era3/ixp.md`](era3/ixp.md)、[`era3/anycast.md`](era3/anycast.md)
- 当前这些项目以历史和模型研究为主；没有把本地模型说成公网 BGP。

## 公网路径

- PMTUD：`captures/era3-pmtud/`
- Traceroute：`captures/era3-traceroute/`
- WAN ledger：`research/data/era3-observations.{md,json}`
- 本地 L3 证明 ICMP fragmentation-needed/MTU 1400 和 TTL → Time Exceeded；WAN 结果严格限定到当时路径。

## 中间盒

- 总览：[`era3/MIDDLEBOXES.md`](era3/MIDDLEBOXES.md)
- 机器矩阵：`data/era3/middlebox-matrix.json`
- Reverse proxy L3：`captures/era3-proxy/`，展示两条独立 TCP legs，而非 NAT-only forwarding。
- NAT、stateful firewall、LB、CDN 的未通电子项保持 document reconstruction。

## 缓存与分发

- HTTP 与缓存/内容分发历史：[`era3/HTTP.md`](era3/HTTP.md)、[`era3/MIDDLEBOXES.md`](era3/MIDDLEBOXES.md)
- DNS cache L3 和 reverse proxy L3 是当前可复核机制；未建立全球 CDN，不声称地理分发性能。

## 隧道

- 历史谱系：[`era3/TUNNELS.md`](era3/TUNNELS.md)
- GRE L3：`captures/era3-tunnels/`，同时显示 outer `198.18.220.0/30` 与 inner `198.18.221.0/30`。
- WireGuard WAN 未在未知 provider 网络策略下强行建立。

## 加密

- TLS 历史：[`era3/TLS.md`](era3/TLS.md)
- 本地 TLS L3：`captures/era3-tls/`
- 可见：IP、TCP、ClientHello、ALPN；不可见：明文 HTTP payload。

## 端到端压力

- [`era3/END-TO-END.md`](era3/END-TO-END.md)
- [`era3/FAILURE-GALLERY.md`](era3/FAILURE-GALLERY.md)
- [`era3/SURVIVAL-MATRIX.md`](era3/SURVIVAL-MATRIX.md)

结论不是简单的“端到端已死”：端点仍承担最终正确性，但地址转换、状态过滤、代理终止、缓存分发、隧道和加密使不同层的端到端性质分化。

## 复现

```sh
./scripts/experiment.sh era3-dns
./scripts/experiment.sh era3-http-tls
./scripts/experiment.sh era3-gre
./scripts/experiment.sh era3-path
./experiments/era3/middlebox/run.sh
./scripts/experiment.sh era3-validate
make check
```
