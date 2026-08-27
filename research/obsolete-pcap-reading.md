# 化石抓包阅读：AppleTalk

署名：**祀（岁家老十三）**。

## 证据边界

本仓不复制许可不明的二进制样本。阅读路径采用 Wireshark 官方 Sample Captures 页面（<https://www.wireshark.org/resources>）作为来源目录，记录 dissector 能力与字段解释；下载、日期和许可证应在本地实验记录中补齐后再提交外部样本。

## 解剖路径

AppleTalk 的 DDP 是网络层数据报，AARP 用于地址解析，ATP/ASP/ADSP 提供会话或事务语义。用 `tshark -G protocols` 可确认当前工具包含 AARP、DDP、ATP、ASP 等 dissector。分析时先识别链路类型，再沿 DDP type、源/目的 AppleTalk 地址、socket 与上层协议解码；不要把 Wireshark 的启发式显示误当成原始规范的全部约束。

## 历史用途

AppleTalk 面向 Macintosh/早期局域网的即插即用发现和文件/打印共享，依赖广播式地址与区域命名。以太网/IP 生态、路由规模、安全模型和厂商支持变化使其退出主流。此 exhibit 的完成状态是“合法来源目录 → dissector → 权威字段路径 → 历史用途”，不伪造现代内核复现。

## 可复核命令

`tshark -G protocols | grep -Ei 'AppleTalk|AARP|DDP|ATP|ASP'`；对外部 capture 只使用明确许可的副本，并保存 SHA-256、来源 URL、许可和获取日期。
