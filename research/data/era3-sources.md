# Era 3 来源与检索边界

本目录只收录可追溯来源；RFC 是协议史的规范原始材料，机构资料用于 IXP 组织史。检索日期：2026-08-29（UTC+8）。RFC HTML 没有稳定纸本页码，因此章节使用 section 锚点；文档中的“原文锚点”不伪装成页码。

## 主题—来源映射

| 主题 | 原始/关键来源 | 用途 |
|---|---|---|
| DNS | Mockapetris, “Domain Names—Concepts and Facilities”, RFC 1034, ISI, 1987；Mockapetris, “Domain Names—Implementation and Specification”, RFC 1035, ISI, 1987 | 分层、委派、缓存、报文与资源记录 |
| BGP | Lougheed & Rekhter, “A Border Gateway Protocol (BGP)”, RFC 1105, cisco, 1989；Rekhter et al., “A Border Gateway Protocol 4 (BGP-4)”, RFC 1771, 1995；Rekhter et al., RFC 4271, 2006 | EGP 后的域间政策路由；现行 BGP-4 基线 |
| CIDR | Fuller et al., “Classless Inter-Domain Routing (CIDR): an Address Assignment and Aggregation Strategy”, RFC 1519, 1993；Bates et al., “Classless Inter-Domain Routing (CIDR): The Internet Address Assignment and Aggregation Plan”, RFC 4632, 2006 | 无类别分配、聚合与最长前缀匹配 |
| IXP | Hain et al., “Internet Exchange BGP Route Server”, RFC 7948, IETF, 2016；Packet Clearing House, *Internet Exchange Directory*；Euro-IX, *IXP Database* | route server 模型及交换点运营组织资料 |
| Anycast | Partridge, Mendez & Milliken, “Host Anycasting Service”, RFC 1546, BBN, 1993；Abley & Lindqvist, “Operation of Anycast Services”, RFC 4786, 2006 | 实验语义到运营 BCP 的时间层次 |

## 学术数据库检索记录

- CNKI：以“域名系统 分层 委派”“边界网关协议 自治系统 策略路由”“无类别域间路由 地址聚合”“互联网交换中心 对等互联”“IP 任播 服务”检索；本次工作未将搜索摘要当作证据，未发现比上述 RFC 更适合支撑协议原始机制且可核验全文的中文学位论文条目，故不编造结果。
- Google Scholar：以 `domain name system delegation caching Mockapetris`、`BGP policy inter-domain routing autonomous systems`、`CIDR address allocation aggregation`、`Internet exchange point route server peering`、`IP anycast operational services` 检索；Scholar 的索引/摘要仅作线索，规范事实回到 RFC 原文。
- ArXiv：以 `DNS delegation anycast`, `BGP inter-domain routing`, `Internet exchange point` 检索；未把后来的测量论文倒写成 1980/90 年代原始方案。ArXiv 结果若未提供与本章断言直接对应的原始历史证据，不纳入主来源表。

## 证据限制

1. 这些章节是历史研究文档，不是实验报告；没有新增抓包或公网观测。
2. IXP 的“早期历史”不能只由 RFC 7948（2016）证明；PCH/Euro-IX 资料是机构档案入口，需在后续若要求精确年代时逐条保存 URL、版本和访问日期。
3. RFC 1546 是 Informational/experimental semantics，不能写成当时已成为全球主导部署；RFC 4786 是 2006 年 BCP，代表后来的运营经验。
4. DOI：RFC 与本目录机构资料通常无 DOI；以 RFC number、作者、机构、年份和稳定 URL 作为唯一定位元数据。
