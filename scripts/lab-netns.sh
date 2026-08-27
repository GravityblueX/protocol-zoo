#!/bin/sh
# Minimal isolated two-node harness. Requires root/CAP_NET_ADMIN.
set -eu
CLIENT_NS=${CLIENT_NS:-pz-client}
SERVER_NS=${SERVER_NS:-pz-server}
VETH_C=${VETH_C:-pz-veth-c}
VETH_S=${VETH_S:-pz-veth-s}
CLIENT_IP=${CLIENT_IP:-198.18.0.1/30}
SERVER_IP=${SERVER_IP:-198.18.0.2/30}

exists_ns() { ip netns list | awk '{print $1}' | grep -Fxq "$1"; }
teardown() {
  ip netns del "$CLIENT_NS" 2>/dev/null || true
  ip netns del "$SERVER_NS" 2>/dev/null || true
  ip link del "$VETH_C" 2>/dev/null || true
}
setup() {
  teardown
  ip netns add "$CLIENT_NS"
  ip netns add "$SERVER_NS"
  ip link add "$VETH_C" type veth peer name "$VETH_S"
  ip link set "$VETH_C" netns "$CLIENT_NS"
  ip link set "$VETH_S" netns "$SERVER_NS"
  ip -n "$CLIENT_NS" link set lo up
  ip -n "$SERVER_NS" link set lo up
  ip -n "$CLIENT_NS" addr add "$CLIENT_IP" dev "$VETH_C"
  ip -n "$SERVER_NS" addr add "$SERVER_IP" dev "$VETH_S"
  ip -n "$CLIENT_NS" link set "$VETH_C" up
  ip -n "$SERVER_NS" link set "$VETH_S" up
  ip netns exec "$CLIENT_NS" ping -c 1 -W 1 "${SERVER_IP%/*}" >/dev/null
  echo "ready: $CLIENT_NS <-> $SERVER_NS (${CLIENT_IP%/*} <-> ${SERVER_IP%/*})"
}
status() {
  exists_ns "$CLIENT_NS" && ip -n "$CLIENT_NS" addr show "$VETH_C"
  exists_ns "$SERVER_NS" && ip -n "$SERVER_NS" addr show "$VETH_S"
}
case "${1:-}" in setup) setup ;; teardown) teardown ;; status) status ;; *) echo "usage: $0 {setup|teardown|status}" >&2; exit 2 ;; esac
