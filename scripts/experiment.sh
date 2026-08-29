#!/bin/sh
# Single entry point for safe, reproducible Protocol Zoo experiments.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
usage() {
  cat >&2 <<'EOF'
usage: scripts/experiment.sh {fixtures|validate|capture|real-app|sctp|remaining|era2-fixtures|era2-capture|era2-network|era2-ipv6|era2-rip|era2-ppp|era2-validate|era3-validate|era3-dns|era3-http-tls|era3-gre|era3-path|era2-static|capabilities|clean}
  fixtures       regenerate synthetic protocol fixtures (no network)
  validate       validate schema, captures, fixtures and cleanup state
  capture        run the isolated dummy TCP capture (needs sudo/CAP_NET_ADMIN)
  real-app       run mature Telnet/FTP implementations in netns
  sctp           run real SCTP inside isolated Kali nested namespaces
  remaining      run UDP-Lite, GRE, IP-in-IP and DCCP capability tests
  era2-fixtures  regenerate M10-M19 offline fixtures
  era2-capture   run the real M10 DHCP-to-TFTP boot chain in a private /24
  era2-network   run real M13 ICMP and M18 IGMP experiments
  era2-ipv6      run real private M15 IPv6-in-IPv4 experiment
  era2-rip       run real three-node M12 RIPv2 propagation
  era2-ppp       run bounded M11 PPP-over-private-PTY experiment
  era2-static    regenerate structured static/not-run boundaries
  era2-validate  require and verify M10-M19 real-capture evidence
  era3-validate  validate Era 3 schema, files, cleanup and sensitive-content gates
  era3-dns       run local delegated DNS hierarchy and cache experiment
  era3-http-tls  run local HTTP/1.x and TLS visibility experiment
  era3-gre       run private GRE overlay packet experiment
  era3-path      run local PMTUD and traceroute ground-truth experiment
  capabilities   record observational kernel/tool capability evidence
  clean          teardown Protocol Zoo namespaces
EOF
  exit 2
}
[ "$#" -ge 1 ] && [ "$#" -le 2 ] || usage
case "$1" in
  fixtures) exec "$ROOT/scripts/make-fixtures.sh" ;;
  validate) exec "$ROOT/scripts/validate-repo.sh" ;;
  capture) exec sudo "$ROOT/scripts/dummy-capture.sh" ;;
  real-app) exec sudo "$ROOT/scripts/real-app-capture.sh" "${2:-captures/real-app-netns}" ;;
  sctp) exec "$ROOT/scripts/kali-sctp-capture.sh" ;;
  remaining) exec "$ROOT/scripts/kali-remaining-capture.sh" ;;
  era2-fixtures) exec "$ROOT/scripts/era2-fixtures.sh" ;;
  era2-capture) exec "$ROOT/scripts/era2-capture.sh" "${2:-captures/era2-netns}" ;;
  era2-network) exec "$ROOT/scripts/era2-network-capture.sh" "${2:-captures/era2-network}" ;;
  era2-ipv6) exec "$ROOT/scripts/era2-ipv6-capture.sh" "${2:-captures/era2-ipv6}" ;;
  era2-rip) exec "$ROOT/scripts/era2-rip-capture.sh" "${2:-captures/era2-rip}" ;;
  era2-ppp) exec "$ROOT/scripts/era2-ppp-capture.sh" "${2:-captures/era2-ppp}" ;;
  era3-validate) exec "$ROOT/scripts/era3-validate.sh" ;;
  era3-dns) exec sudo "$ROOT/experiments/era3/dns/run.sh" ;;
  era3-http-tls) exec "$ROOT/experiments/era3/http-tls/run.sh" ;;
  era3-gre) exec sudo "$ROOT/experiments/era3/tunnels/run.sh" ;;
  era3-path) exec "$ROOT/experiments/era3/path/run.sh" ;;
  era2-static) exec "$ROOT/scripts/era2-static-results.sh" ;;
  era2-validate) exec "$ROOT/scripts/era2-validate.sh" ;;
  capabilities) exec "$ROOT/scripts/capability-report.sh" ;;
  clean) exec sudo "$ROOT/scripts/lab-netns.sh" teardown ;;
  *) usage ;;
esac
