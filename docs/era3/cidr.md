# CIDR：地址分配与路由聚合同时改造

## 当时的问题（约 1992–1993）
Classful A/B/C 分配造成地址浪费；随着 B 类空间耗尽和全球路由表增长，既有分配方式同时威胁地址可持续性与路由可聚合性。

## 当时方案
CIDR 用前缀长度替代固定类别，按拓扑分配连续地址块，并允许路由聚合。RFC 1519 的标题即为 “an Address Assignment and Aggregation Strategy”，不是只改路由器匹配规则；RFC 4632 后来更新 CIDR 实践说明。

原文锚点：RFC 1519 §1 说明 classless addressing 的动机；§2 说明 aggregation；§3 说明 routing/forwarding。RFC 无稳定纸本页码，使用 section 锚点。

## 主导现实
无类别前缀（例如 /20、/24）和最长前缀匹配成为 IPv4 互联网的基础寻址/转发表现实；ISP 分层分配与聚合缓解了增长，但多宿主、去聚合和策略仍会制造例外。

## 今天仍存活
CIDR notation、prefix aggregation、longest-prefix match 仍是 IPv4/IPv6 路由基本功。IPv6 进一步把前缀规划置于地址架构中心（RFC 4291 等）。

## 不可倒投
不能把 NAT、IPv6 或 RPKI 倒投成 CIDR 的原始动机；CIDR 首先回应的是 classful 地址浪费与路由表压力。也不能把“聚合”理解为总能成功：策略和多宿主会故意或被迫产生更具体前缀。

## 来源
见 [`../../research/data/era3-sources.json`](../../research/data/era3-sources.json)，条目 CIDR-1519/4632。
