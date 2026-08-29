# Era 3 VPS Safety

VPS 仅作为自有、bounded 的公网观察端点。默认保留 SSH；临时 listener 使用高端口、最短时间和显式超时，结束后验证 `ss`、`ps`、namespace、nftables 与临时文件。

禁止扫描、放大、高 QPS、第三方私有目标、生产代理修改、凭据入库与未经确认的公网 BGP。公网结果只描述该时间、路径和环境下的观察。

当前 endpoint：IPv4 `192.144.192.215`；IPv6 `2402:4e00:c050:1b00:450:1bde:8a6e:1`。仓库不保存 SSH 私钥。
