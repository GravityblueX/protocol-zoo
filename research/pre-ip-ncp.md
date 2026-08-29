# pre-IP：NCP 与 TCP/IP 分层前史

## 证据等级

`document-reconstruction`。本仓不声称拥有 ARPANET 历史真实抓包，也不提交来源不明二进制。

RFC 714 描述 ARPANET-type network 的 Host-Host Protocol；RFC 908/early TCP 材料可用于追踪可靠传输语义如何从特定 IMP 网络语境中抽离。NCP 的关键历史角色不是“早期 TCP”，而是 host 上负责连接控制、关闭和流量控制的程序。

## 演化图

```text
Host/IMP 网络假设 → NCP host-host control → early TCP → TCP + IP 分层
```

## 可复核边界

提交 synthetic frame 时必须标 `document-reconstruction`；只有合法历史样本才可升级为 `real historical capture`。不把 RFC 图示或后人重建当作现场抓包。
