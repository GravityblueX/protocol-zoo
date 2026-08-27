# Gopher 展品

署名：**祀（岁家老十三）**。

RFC 1436 定义 menu line：type、display string、selector、host、port，以 TAB 分隔并以 CRLF 结尾；menu 末尾用单独的 `.` 行结束。客户端选择 selector 后重新连接并请求该 selector。文本/目录模型简单，早期浏览器可将其与 HTTP/HTML 对照：Gopher 由服务器声明类型和链接，HTML 把呈现与链接嵌入文档。

最小实验可用任意成熟 Gopher client 加静态 netns server；只使用合成 menu，不暴露公网。现代风险主要是明文、任意 selector 与内容信任。
