#!/bin/sh
# Generate small text fixtures for line-oriented exhibits; no network access.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
mkdir -p "$ROOT/captures/fixtures"
printf 'IAC WILL ECHO\\nIAC DO SUPPRESS-GO-AHEAD\\n' > "$ROOT/captures/fixtures/telnet-negotiation.txt"
printf '200 news.example ready\\r\\n211 2 1 2 zoo.group\\r\\n220 1 <demo@zoo> article\\r\\n' > "$ROOT/captures/fixtures/nntp-session.txt"
printf ':zoo.example 001 visitor :welcome\\r\\n:visitor JOIN #zoo\\r\\n:zoo.example 353 visitor = #zoo :visitor\\r\\n' > "$ROOT/captures/fixtures/irc-session.txt"
printf '0Info\\tProtocol Zoo\\t\\t198.18.0.2\\t7070\\r\\n1README\\tREADME\\treadme.txt\\t198.18.0.2\\t7070\\r\\n.\\r\\n' > "$ROOT/captures/fixtures/gopher-menu.txt"
printf 'alice\\r\\n' > "$ROOT/captures/fixtures/finger-request.txt"
echo 'fixtures generated'
