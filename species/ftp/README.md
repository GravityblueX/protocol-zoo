# FTP 展品

署名：**祀（岁家老十三）**。

规范：RFC 959；扩展地址/被动模式：RFC 2428。成熟实现优先使用 `pyftpdlib`、vsftpd 或 GNU Inetutils ftpd，不重写 daemon。

## 两条连接

控制连接通常由 client→server:21 建立，命令/回复使用 ASCII 行；LIST/RETR 另开 data connection。Active 模式用 `PORT/EPRT` 告知服务器回连客户端；passive 模式用 `PASV/EPSV` 让服务器监听临时端口并由客户端连接。NAT/防火墙通常使 passive 更容易部署，但仍需正确开放 server data range。

## 实验记录

`scripts/real-app-capture.sh` 使用 `pyftpdlib 1.5.9` 在 `pz-server` 的 `198.18.0.2:2121` 启动成熟 FTP 服务，`pz-client` 使用系统 `ftp` 客户端完成登录、EPSV 被动数据连接和 `RETR`；结果见 `captures/real-app-netns/ftp.pcapng`、`ftp.frames.tsv` 与两个脱敏 transcript。control 与 data 四元组、`USER/PASS`、`230`、`EPSV/229`、`RETR/125/226` 均可由抓包复核。实验只使用合成账号和文件，不连接公网。

## 安全

FTP 控制和数据默认明文；TLS 扩展（FTPS）与 SFTP 不是同一协议。生产环境优先 SFTP/HTTPS 或明确配置 TLS。
