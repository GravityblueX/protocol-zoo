# DNS：把名字变成基础设施

## 当时的问题（约 1983–1987）
HOSTS.TXT 由单一协调点维护并复制；名字、地址和管理边界随网络增长而失去可扩展性。问题不是“用户不喜欢数字”，而是集中式命名数据库与跨组织管理无法继续工作。

## 当时方案
Paul Mockapetris 的分层、委派、缓存 DNS：RFC 1034 定义概念与设施，RFC 1035 定义报文、资源记录和服务器实现。权威数据留在责任区，递归解析器通过缓存减少重复查询；层次结构把管理权分散到组织边界。

原文锚点：RFC 1034 摘要称 DNS 是 “a distributed database”; RFC 1034 §2.4 讨论 delegation；RFC 1035 §4 描述 query/response message format。引用页码以 RFC HTML 的 section 为准（RFC 无稳定纸本页码）。

## 主导现实
兼容的 DNS wire protocol、分层委派和递归缓存成为主导现实；BIND 等实现把它从研究设计变成运营基础设施。DNS 不等于单一软件：权威服务、递归服务、缓存、注册管理是不同角色。

## 今天仍存活
A/AAAA、NS、MX、CNAME、TTL、UDP/TCP 查询和委派仍是基础。DNSSEC（RFC 4033–4035）增加真实性验证；DoT/DoH 改变传输隐私，但没有消除 DNS 的命名/委派模型。

## 不可倒投
不能把现代 CDN、DoH、DNSSEC 或“DNS 是全球单点”倒投回 1987：它们是后续压力下的增量机制。也不能把 DNS 的普及解释成纯粹的用户体验胜利；原始驱动是分布式管理与数据库规模。

## 来源
见 [`../../research/data/era3-sources.json`](../../research/data/era3-sources.json)，条目 DNS-1034/1035。
