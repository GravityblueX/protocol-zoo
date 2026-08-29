#!/bin/sh
# Single entry point for safe, reproducible Protocol Zoo experiments.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
usage() {
  cat >&2 <<'EOF'
usage: scripts/experiment.sh {fixtures|validate|capture|real-app|sctp|remaining|era2-fixtures|era2-validate|capabilities|clean}
  fixtures       regenerate synthetic protocol fixtures (no network)
  validate       validate schema, captures, fixtures and cleanup state
  capture        run the isolated dummy TCP capture (needs sudo/CAP_NET_ADMIN)
  real-app       run mature Telnet/FTP implementations in netns
  sctp           run real SCTP inside isolated Kali nested namespaces
  remaining      run UDP-Lite, GRE, IP-in-IP and DCCP capability tests
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
  era2-validate) exec "$ROOT/scripts/era2-validate.sh" ;;
  capabilities) exec "$ROOT/scripts/capability-report.sh" ;;
  clean) exec sudo "$ROOT/scripts/lab-netns.sh" teardown ;;
  *) usage ;;
esac
