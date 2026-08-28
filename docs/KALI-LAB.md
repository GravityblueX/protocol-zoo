# Kali 隔离实验笼舍

本页记录 DATA5 上用于 Protocol Zoo 的独立 guest，而不是宿主机现有 Kali 的配置。

## 边界

- Domain：`protocol-zoo-kali`；
- 磁盘：`/media/tmzn/DATA5/qemu_vms/protocol-zoo-kali/kali-full.qcow2`，从原始归档提取的独立副本；
- 网络：libvirt `pz-isolated`，`172.31.250.0/24`，宿主侧 `172.31.250.1`；
- guest 地址：`172.31.250.195`；
- 只有一张 virtio 网卡，连接 `pz-isolated`；没有物理直连网卡和默认路由；
- SSH 仅作为宿主到 guest 的管理通道，key 位于 DATA5 的实验目录，不提交仓库。

原有 `kali` domain 使用物理 macvtap 与 `default` NAT，禁止把它改造成实验机。本页中的所有协议实验在 guest 内再次创建 `pz-a`/`pz-b` nested namespace，并只使用 `198.18.0.0/15` 文档地址。

## guest 能力

Kali GNU/Linux Rolling 2026.2，kernel `6.19.14+kali-amd64`，已安装 `iproute2`、`kmod`、`tcpdump`、`tshark`、Scapy。SCTP 模块可加载；DCCP 模块不存在且 socket 返回 errno 93。UDP-Lite socket、GRE 和 IP-in-IP tunnel 均已实测。

## 复现入口

确保 domain 已运行、SSH key 可读后，在仓库根目录执行：

```sh
./scripts/experiment.sh sctp
./scripts/experiment.sh remaining
```

宿主无法访问 guest 时，入口支持覆盖默认管理参数：

```sh
PZ_KALI_HOST=172.31.250.195 \
PZ_KALI_KEYDIR=/path/to/lab-key-dir \
./scripts/experiment.sh sctp
```

这些入口依赖 guest 内预置的 `/root/pz-sctp.sh` 和 `/root/pz-remaining.sh`。它们不是协议实现；仓库提交的是调用入口、pcap、结构化结果和安全边界。每次实验结束都删除 guest 内 nested namespace。

## 不做的事

不把原有 Kali 的公网接口接入实验，不改宿主默认路由，不停止其他 domain，不扫描 guest 以外的地址。若 guest kernel 没有某个模块，记录 capability/not-run，而不是编造 capture。
