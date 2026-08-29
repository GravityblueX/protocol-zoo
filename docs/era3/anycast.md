# Anycast：同一服务地址的多地点实例

## 当时的问题（约 1993 起）
Host/service 可达性希望靠近用户并提高故障韧性，但传统单一目的地址把流量和故障集中在一个站点；同时 IP 层语义必须面对“多个实例”的选择与会话稳定性问题。

## 当时方案
RFC 1546（1993）提出 Host Anycasting Service 的实验语义，刻意对提供机制保持中立；运营实践逐渐使用 BGP 宣告同一前缀/地址到多个地点，让路由选择把客户送到某个拓扑上“较近”的实例。RFC 4786（2006）总结 anycast service operation、故障撤告、监控与运维约束。

原文锚点：RFC 1546 Abstract 与 §2 定义语义；RFC 4786 Abstract、§3（service characteristics）和 §4（operational considerations）。RFC 无稳定纸本页码，使用 section 锚点。

## 主导现实
Anycast + BGP 成为 DNS 根/权威服务、递归 DNS、NTP、CDN/清洗服务等高可用无连接或短事务服务的主导部署形态。它是路由层的实例选择，不是应用层负载均衡；路径变化可能改变实例。

## 今天仍存活
多站点相同服务地址、BGP 宣告/撤告、健康检查、RPKI/过滤配套仍广泛存在。TCP 长连接和有状态服务通常需要额外设计，不能仅靠 anycast 保证会话连续。

## 不可倒投
不能把现代 DNS 根 anycast、DDoS 清洗、全球 CDN POP 规模倒投回 1993 的实验语义。RFC 1546 不是“当时已部署的全球方案”；RFC 4786 是后来运营经验的规范化。也不能将“最近”简化为地理距离：BGP 选择的是策略与路径属性下的路由。

## 来源
见 [`../../research/data/era3-sources.json`](../../research/data/era3-sources.json)，条目 ANYCAST-1546/4786。
