# Finger 展品

署名：**祀（岁家老十三）**。

RFC 1288 定义了极简 TCP request/response：客户端发送可选查询并以 CRLF 结束，服务器返回文本并关闭连接；早期 Unix 语境中它用于查看登录用户与活动状态。

实验应只绑定 `198.18.0.2:79` 的 namespace fixture，发送合成查询（如 `alice\r\n`），抓取一问一答，并用 RFC 对照 CRLF、关闭方向和文本无结构性。现代风险是用户名、登录时间、终端和活动信息泄露；不要将真实 `/etc/utmp` 或用户信息放入 capture。
