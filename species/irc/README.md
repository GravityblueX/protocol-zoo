# IRC 展品

署名：**祀（岁家老十三）**。

RFC 1459 的 line protocol 由可选 prefix、command/numeric、params 组成，以 CRLF 结束；典型状态是 `NICK`、`USER`、`JOIN #zoo`、`PRIVMSG`。服务端用 numeric reply 表示注册、错误和 channel 状态。IRCv3 在此基础上增加 tags、CAP、现代认证与批处理等扩展。

可复现实验使用本地成熟 daemon（如 Ergo/InspIRCd）或合成 fixture，抓取注册、JOIN、numeric、频道消息；不连接公网。TLS、账号认证、operator/channel 权限决定现代安全性。
