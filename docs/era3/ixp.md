# IXP：互联从专线交叉连接变成共享交换

## 当时的问题（约 1990 年代）
商业化和多运营商互联使“每个网络与每个网络单独互联”的全网状成本、端口和管理复杂度迅速上升；核心交换设施也需要中立、可扩展的互联场所。

## 当时方案
Internet Exchange Point 以共享二层交换 fabric 和 peering 政策，把多个自治系统集中到同一互联设施；参与者通过 BGP 建立对等会话。交换 fabric 负责转发以太帧，BGP 负责控制面；二者不可混为一个协议。

原文锚点：RFC 7948（Internet Exchange BGP Route Server）§1 描述 IXP route server 的问题与模型；RFC 4271 §3/§5 提供 BGP 会话和 UPDATE 基线。IXP 历史细节还需以 Euro-IX/Packet Clearing House 的机构档案交叉核对。

## 主导现实
区域/国家级 IXP、私有 peering 和 route server 成为互联生态的重要组成，但不是所有流量都经过 IXP；transit、content network 私联、云互联并存。route server 通常不转发用户包，而是降低 peering session 的 n² 管理成本。

## 今天仍存活
以太网交换、BGP peering、route server、成员端口/VLAN、过滤与监控仍是 IXP 的常见现实。

## 不可倒投
不能把今天的 100G/400G fabric、云 CDN 或 route-server 自动化倒投回早期 NAP/MAE；也不能把 IXP 写成“互联网的单一中心”。它是互联组织形式和共享设施，不替代域间路由协议。

## 来源
见 [`../../research/data/era3-sources.json`](../../research/data/era3-sources.json)，条目 IXP-7948、PCH/Euro-IX。
