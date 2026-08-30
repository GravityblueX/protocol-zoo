# HTTP：把资源交换做成通用接口

## 历史问题

早期网络应用需要在不同主机之间取得文档和其他资源；命名、格式与传输机制尚未形成统一的、可扩展接口。HTTP 将请求方法、目标资源、元数据（headers）和表示（representation）组合成无状态的应用层交换模型。它不是“互联网本身”，也不等于浏览器：HTTP 可以承载多种媒体类型，浏览器只是最成功的使用者之一。

## 规范与演化

- HTTP/0.9：早期实现的最小 GET/响应模型；不应把它与后来的完整消息语法混为一谈。
- HTTP/1.0：RFC 1945，形成版本、状态码、headers 与独立响应的常见语法。
- HTTP/1.1：RFC 9112（现行消息语法），RFC 9110（语义）；持久连接、Host、缓存和范围请求等能力使共享基础设施成为可能。
- HTTP/2：RFC 9113，以二进制帧、多路复用和 HPACK 改善同一连接上的并发交换；HTTP 语义没有因此变成另一套资源模型。
- HTTP/3：RFC 9114，在 QUIC（RFC 9000）之上承载 HTTP 语义；它不是“UDP 版 HTTP/1.1”，而是使用 QUIC 的流、握手和丢包处理。

规范事实与具体服务器、代理、浏览器的默认行为需分开验证。缓存语义以 RFC 9111 为准，不能由某一次浏览器观察概括所有实现。

## 仍然存活的部分

HTTP 的持久性来自清晰的资源/表示/缓存边界、代理可组合性、可观察的状态码，以及对传输层的逐步替换。HTTP/1.1 仍是互操作基线；HTTP/2、HTTP/3 主要改变 framing 与连接管理，而不是抛弃 HTTP 语义。反向代理、API、对象存储和 CDN 也说明 HTTP 已从“取 HTML”扩展为通用应用接口。

## 实验证据与边界

本节的历史解释仍属于 **L0 citation + document reconstruction**；此外，仓库已经在 [`../../captures/era3-http/`](../../captures/era3-http/) 保存受控本地 **L3 packet evidence**。该实验在隔离 network namespace 中使用成熟客户端/服务端，实际抓到 HTTP/1.0 与 HTTP/1.1 请求、`Host`、明文应用 payload，并显示两次独立客户端调用落在不同的 TCP stream 中。

这些抓包只证明该受控现代复现中的协议可见性和连接事实，不代表历史浏览器工作负载，不代表公网 HTTP 性能或部署比例，也没有声称完成 pipelining、chunked transfer、HTTP/2 或 HTTP/3 的 packet-level 子实验。HTTPS 的可见性边界另见 [`TLS.md`](TLS.md) 与 [`../../captures/era3-tls/`](../../captures/era3-tls/)：TLS 建立后不能把加密应用载荷直接解码成明文 HTTP。

安全复现仍应使用 loopback 或专用 namespace 的成熟 server/client，过滤器只保留目标五元组；不得向公网暴露临时服务、提交真实 cookie 或凭据。HTTP 明文本身不提供机密性、完整性或服务器身份认证，这些性质由 TLS/应用认证另行提供。

## 参考

- RFC 1945, <https://www.rfc-editor.org/rfc/rfc1945>
- RFC 9110, <https://www.rfc-editor.org/rfc/rfc9110>
- RFC 9111, <https://www.rfc-editor.org/rfc/rfc9111>
- RFC 9112, <https://www.rfc-editor.org/rfc/rfc9112>
- RFC 9113, <https://www.rfc-editor.org/rfc/rfc9113>
- RFC 9114, <https://www.rfc-editor.org/rfc/rfc9114>
- RFC 9000, <https://www.rfc-editor.org/rfc/rfc9000>
