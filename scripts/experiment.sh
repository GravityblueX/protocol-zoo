#!/bin/sh
# Single entry point for safe, reproducible Protocol Zoo experiments.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
usage() {
  cat >&2 <<'EOF'
usage: scripts/experiment.sh {fixtures|validate|capture|capabilities|clean}
  fixtures       regenerate synthetic protocol fixtures (no network)
  validate       validate schema, captures, fixtures and cleanup state
  capture        run the isolated dummy TCP capture (needs sudo/CAP_NET_ADMIN)
  capabilities   record observational kernel/tool capability evidence
  clean          teardown Protocol Zoo namespaces
EOF
  exit 2
}
[ "$#" -eq 1 ] || usage
case "$1" in
  fixtures) exec "$ROOT/scripts/make-fixtures.sh" ;;
  validate) exec "$ROOT/scripts/validate-repo.sh" ;;
  capture) exec sudo "$ROOT/scripts/dummy-capture.sh" ;;
  capabilities) exec "$ROOT/scripts/capability-report.sh" ;;
  clean) exec sudo "$ROOT/scripts/lab-netns.sh" teardown ;;
  *) usage ;;
esac
