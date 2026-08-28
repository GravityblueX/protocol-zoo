# DCCP 展品

署名：**祀（岁家老十三）**。规范：RFC 4340。DCCP 提供拥塞控制与连接状态，但不提供 TCP 式可靠重传；它拆掉“拥塞控制必然等于可靠字节流”的假设。现代部署受内核、NAT 和中间盒限制。


## Kali 能力证据

Kali 6.19.14 guest 中 DCCP socket 返回 errno 93（`Protocol not supported`），且 `/lib/modules` 无 DCCP 模块，因此本展品保持 `not_run`，不伪造握手。
