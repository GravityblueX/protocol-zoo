# Protocol Zoo 实验安全边界

Protocol Zoo 是隔离的协议考古实验场，不是扫描器，也不是公网服务集合。

## 默认边界

- 明文认证、弱认证和远程 shell 类协议只允许 `loopback` 或专用 network namespace/veth。
- 实验脚本不得修改宿主机默认路由、iptables/firewall、DNS 或任何公网接口。
- 不扫描不属于自己的地址，不连接公网验证“真实性”。
- 不使用真实密码、cookie、私有地址或生产数据；示例凭据必须是固定的假值。
- 抓包应使用最小 BPF 过滤器和最短生命周期，并在提交前检查是否含敏感信息。
- 默认以非特权服务用户运行；需要 `CAP_NET_ADMIN` 的步骤必须明确说明并可 teardown。

## 拓扑

标准双端实验使用两个 namespace（`pz-client`、`pz-server`）和一对 veth，地址固定在私有文档网段 `198.18.0.0/15` 的实验子网 `198.18.0.0/30`。该网段由 RFC 2544 保留为 benchmark 测试用途；脚本只在 namespace 内配置地址，不触碰物理接口。

实验服务只绑定 `198.18.0.2`，客户端只连接 `198.18.0.2`。不要把服务绑定到 `0.0.0.0`，也不要将 namespace 接到宿主机 bridge。

## 清理要求

脚本必须在正常退出、失败和中断时删除 namespace、veth 和临时 PID。可重复执行前先运行 `teardown`。若脚本异常中止，使用：

```sh
sudo scripts/lab-netns.sh teardown
ip netns list | grep '^pz-'
```

最后一条应无输出。脚本不会自动 flush 宿主机防火墙或路由。

## 证据与审查

每份 capture 旁边保存实验 YAML/JSON 结果和生成命令。提交前用 `tcpdump -r` 或 `capinfos` 检查包数、接口和时间范围；确认没有真实凭据。外部 capture 不得在许可不明时复制进仓库。
