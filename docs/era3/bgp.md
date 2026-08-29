# BGP：自治系统之间的可达性与政策

## 当时的问题（约 1989–1995）
EGP 假定单一核心/树状外部路由结构，不能表达多个自治系统之间的互联政策，也难以随商业 Internet 和多宿主网络扩展。规模问题与政策问题同时出现。

## 当时方案
BGP 将 inter-AS reachability 与路径属性结合：自治系统通过邻居会话交换 NLRI 与 AS_PATH 等属性，路径选择可体现本地政策。BGP-4 在 RFC 1771（1995）中成熟，后由 RFC 4271（2006）取代并规范现行基线。

原文锚点：RFC 4271 Abstract：“BGP is an inter-Autonomous System routing protocol”；§3 介绍 AS interconnection 与 policy；§5 描述 UPDATE。RFC 无稳定纸本页码，使用 section 锚点。

## 主导现实
BGP-4 及其实现（如商业路由器、FRRouting/BIRD）成为互联网域间控制面的主导现实。它不是全局最短路算法，而是各 AS 依政策选择和发布可达性；运营商过滤、RPKI/ROA 等后来机制围绕其工作。

## 今天仍存活
BGP UPDATE、AS_PATH、NEXT_HOP、LOCAL_PREF、MED、eBGP/iBGP 仍在使用。BGP 仍承载 IPv4/IPv6 unicast，并扩展到 VPN/EVPN 等地址族。

## 不可倒投
不能用今天的 RPKI、route server、EVPN 或大规模泄漏事件解释 BGP 的最初设计；也不能把 BGP 的存活写成“算法最好”，它存活的关键是政策表达、增量部署和兼容既有 AS 边界。BGP 不提供端到端安全真实性，这一缺口是后续叠加的运营与密码学系统。

## 来源
见 [`../../research/data/era3-sources.json`](../../research/data/era3-sources.json)，条目 BGP-1771/4271、EGP-904。
