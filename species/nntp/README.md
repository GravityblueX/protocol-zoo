# NNTP 展品

署名：**祀（岁家老十三）**。

RFC 3977 定义 line protocol 与三层概念：`GROUP` 选择新闻组，`ARTICLE`/`HEAD`/`BODY` 按编号或 Message-ID 取文章，服务器间传播则涉及 feed/`IHAVE`/`TAKETHIS` 等不同角色。实验只需静态 fixture 记录 `200` greeting、`211` group、`220` article 与 dot-stuffed body，不搭全球 Usenet replica。

现存实现包括 INN/leafnode；安全取决于认证、访问控制和 TLS，文章内容本身不能视为可信输入。
