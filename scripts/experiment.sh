#!/bin/sh
# Single entry point for safe, reproducible Protocol Zoo experiments.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
usage() {
  cat >&2 <<'EOF'
usage: scripts/experiment.sh {fixtures|validate|capture|real-app|sctp|remaining|era2-fixtures|era2-capture|era2-network|era2-ipv6|era2-rip|era2-validate|era2-static|capabilities|clean}
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
  era2-static    regenerate structured static/not-run boundaries
  era2-validate  require and verify M10 real-capture evidence
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
  era2-static) exec "$ROOT/scripts/era2-static-results.sh" ;;
  era2-validate) exec "$ROOT/scripts/era2-validate.sh" ;;
  capabilities) exec "$ROOT/scripts/capability-report.sh" ;;
  clean) exec sudo "$ROOT/scripts/lab-netns.sh" teardown ;;
  *) usage ;;
esac
