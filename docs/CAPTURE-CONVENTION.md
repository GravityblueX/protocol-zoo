# Capture Convention

## 命名

自生成抓包使用：`captures/<species>-<topology>-<YYYYMMDD>.pcapng`。同一实验的结构化结果放在同目录，使用相同 basename 的 `.yaml` 或 `.json`。

示例：`captures/dummy-tcp-netns-20260828.pcapng`。

## 必须记录的元数据

结果文件至少记录：

- `protocol`、`experiment`、`environment`（OS、kernel、工具版本）；
- `topology` 与 `capture_point`；
- `command` 或生成脚本路径；
- `capture_filter`；
- `result.handshake`、`result.capture`、`result.frames`；
- `sanitized`（自生成实验也要明确）；
- `notes`（关键 frame 与解释）。

推荐使用 `schemas/experiment.schema.json` 校验。

## 抓包规则

- 优先抓 veth 的 namespace 对端，避免无关宿主机流量。
- 使用最小 BPF filter，例如 `tcp port 18080` 或 `udp port 18053`。
- pcapng 只保存能说明机制的最小会话；不要提交大型背景流量。
- 时间戳、接口和软件版本必须可追溯；自己生成的 capture 标记 `source: generated`。
- 不产生抓包的能力观测也必须保存结构化结果，并将 `result.handshake` 标为 `not_run`，明确说明未加载模块、未改路由、未连接对端。
- 外部样本标记 `source: external`，记录 URL、许可和获取日期；许可不清不提交二进制。

## Frame 引用

文档引用 `frame 1`、`frame 2` 等 tshark/Wireshark frame 编号，并说明方向、层次、字段和预期现象。若重生成导致编号改变，应同步更新文档和结果文件。

## 脱敏

提交前检查 payload、DNS、地址、用户名、认证信息和时间范围。任何真实凭据、cookie、私人地址或无关流量都必须删除；不能可靠脱敏时，不提交该 capture。
