# SCTP 展品

署名：**祀（岁家老十三）**。规范：RFC 9260。SCTP 用 association、chunk、多 stream 和 multi-homing 拆掉 TCP 单连接单流单路径假设；Linux `lksctp-tools` 是成熟实现入口。实验需 capability/netns，环境不具备时明确记录 `not_run`。


## Kali 隔离实测

在 DATA5 的独立 `protocol-zoo-kali`（Kali 6.19.14）中加载 `sctp.ko`，再在 guest 内创建 `pz-a`/`pz-b` 两个 nested network namespace，使用 Python SCTP socket 完成 `sctp-ok:protocol-zoo-sctp` 往返。抓包和结构化结果见 `captures/kali-sctp/sctp.pcap`、`sctp.json`；共 11 个 SCTP frame，其中 2 个 DATA frame。宿主机仅通过 `pz-isolated` 管理网卡连接 guest，guest 没有默认路由。复现实验入口：`./scripts/experiment.sh sctp`。
