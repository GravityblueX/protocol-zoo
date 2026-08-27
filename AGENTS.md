# AGENTS.md — Protocol Zoo execution contract

本仓是“能通电的协议博物馆”，不是新协议研发仓，也不是老协议攻击实验室。

## 开工前阅读

依次阅读 `README.md`、`ROADMAP.md`、`IMPLEMENTATION_PLAN.md`、`docs/PRIOR_ART.md`，以及当前 species/lab 相关文件。

## 核心原则

- 以**可重复实验**为完成单位，不以代码行数或协议数量为目标。
- 优先复用成熟 server/client、系统工具、Wireshark/tshark/Scapy；只有现有工具无法解释机制时才写最小教学实现。
- 每个 exhibit 尽量同时具备：原始规范、既有实现、最小实验、抓包、字段解释、现代状态、安全边界。
- 协议行为与某个历史实现习惯必须分开写。
- 不把“后来被替代”写成简单技术进步史。

## 实验安全

默认优先级：unit/fixture → loopback → netns/veth → 自有局域网 → 明确必要且安全时才考虑 WAN。

禁止：

- 把 Telnet/FTP/Finger/rlogin/rsh 等弱认证或明文服务暴露公网；
- 扫描不属于自己的网络；
- 在真实抓包里提交凭据、cookie、私人地址或无关流量；
- 用生产主机网络配置完成教学实验；
- 为“真实性”关闭宿主机防火墙或安全策略。

所有实验脚本必须尽量可清理；netns/veth 创建失败后也应有 teardown 路径。

## 证据规则

关键协议事实优先引用 RFC/标准/厂商手册/上游实现文档。博客可辅助，不可作为唯一依据。

化石协议若使用第三方 pcap：

- 记录来源、许可与获取日期；
- 许可不清时只保存分析笔记/引用，不提交二进制副本；
- 明确区分“自己生成的 capture”和“外部 sample”。

## Capture 规则

每份自己生成的 capture 必须能回答：

- 对应哪个实验；
- capture point；
- 环境/topology；
- 生成命令或脚本；
- 是否脱敏；
- 对应文档中的 frame 编号。

不要提交大型无关抓包。

## 默认施工循环

1. 检查当前仓库状态；
2. 从 `IMPLEMENTATION_PLAN.md` 选择依赖满足的最早未完成项；
3. 先查是否已有成熟实现/样本；
4. 实现最小实验 harness 或文档闭环；
5. 实际运行实验（环境允许时）；
6. 保存机器可读结果/capture/说明；
7. 验证 cleanup 与安全边界；
8. 提交 checkpoint；
9. 没有 blocker 时继续。

## 完成定义

一个 species 不因为“README 写完了”而完成。至少应满足本阶段要求中的规范证据、可复现实验和分析闭环。

## Stop conditions

- 已有成熟实现，而新增代码只有功能复制；
- 需要暴露弱服务到公网；
- 需要扫描第三方；
- 找不到权威规范；
- sample 许可不明；
- 实验无法在隔离环境安全复现；
- 研究重心从协议理解偏成攻击步骤。
