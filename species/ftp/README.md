# FTP 展品

署名：**祀（岁家老十三）**。

规范：RFC 959；扩展地址/被动模式：RFC 2428。成熟实现优先使用 `pyftpdlib`、vsftpd 或 GNU Inetutils ftpd，不重写 daemon。

## 两条连接

控制连接通常由 client→server:21 建立，命令/回复使用 ASCII 行；LIST/RETR 另开 data connection。Active 模式用 `PORT/EPRT` 告知服务器回连客户端；passive 模式用 `PASV/EPSV` 让服务器监听临时端口并由客户端连接。NAT/防火墙通常使 passive 更容易部署，但仍需正确开放 server data range。

## 实验记录

本 exhibit 的安全复现采用 netns 拓扑 fixture：为 control 与 data 分别记录四元组、发起方向、`LIST`/`RETR` 顺序；没有公网服务器，也不保存密码。抓包应过滤 control port 与 data range，并将认证字段视为合成凭据后再提交。

## 安全

FTP 控制和数据默认明文；TLS 扩展（FTPS）与 SFTP 不是同一协议。生产环境优先 SFTP/HTTPS 或明确配置 TLS。
