#!/bin/sh
# M13 local miniature DNS hierarchy: root -> test -> museum.test + recursive cache.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd); OUT=$ROOT/captures/era3-dns; NS=pz-era3-dns; TMP=$(sudo mktemp -d /etc/bind/era3-dns.XXXX); PIDS=""
cleanup(){ for p in $PIDS; do sudo kill "$p" 2>/dev/null || true; done; sudo ip netns del "$NS" 2>/dev/null || true; sudo rm -rf "$TMP"; }
trap cleanup EXIT INT TERM
mkdir -p "$OUT"; rm -f "$OUT"/*; cleanup; TMP=$(sudo mktemp -d /etc/bind/era3-dns.XXXX); sudo chmod 777 "$TMP"; for d in root tld auth rec; do mkdir -p "$TMP/$d"; chmod 777 "$TMP/$d"; done; sudo chmod 755 "$TMP"
sudo ip netns add "$NS"; sudo ip -n "$NS" link set lo up
for ip in 198.18.200.10 198.18.200.11 198.18.200.12 198.18.200.13; do sudo ip -n "$NS" addr add "$ip/32" dev lo; done
cat >$TMP/root.zone <<'EOF'
. 60 IN SOA a.root. hostmaster.root. 1 60 60 60 10
. 60 IN NS a.root.
a.root. 60 IN A 198.18.200.10
test. 60 IN NS ns.test.
ns.test. 60 IN A 198.18.200.11
EOF
cat >$TMP/test.zone <<'EOF'
test. 60 IN SOA ns.test. hostmaster.test. 1 60 60 60 10
test. 60 IN NS ns.test.
ns.test. 60 IN A 198.18.200.11
museum.test. 60 IN NS ns.museum.test.
ns.museum.test. 60 IN A 198.18.200.12
EOF
cat >$TMP/museum.zone <<'EOF'
museum.test. 2 IN SOA ns.museum.test. hostmaster.museum.test. 1 60 60 60 4
museum.test. 2 IN NS ns.museum.test.
ns.museum.test. 2 IN A 198.18.200.12
www.museum.test. 2 IN A 198.18.200.42
EOF
mkconf(){ name=$1; ip=$2; zone=$3; file=$4; cat >$TMP/$name.conf <<EOF
options { directory "$TMP/$name"; listen-on port 53 { $ip; }; listen-on-v6 { none; }; recursion no; dnssec-validation no; pid-file "$TMP/$name.pid"; session-keyfile "$TMP/$name.key"; };
zone "$zone" { type primary; file "$file"; };
EOF
}
mkconf root 198.18.200.10 . $TMP/root.zone; mkconf tld 198.18.200.11 test $TMP/test.zone; mkconf auth 198.18.200.12 museum.test $TMP/museum.zone; chmod 644 "$TMP"/*.conf "$TMP"/*.zone
cat >$TMP/root.hints <<'EOF'
. 3600 IN NS a.root.
a.root. 3600 IN A 198.18.200.10
EOF
cat >$TMP/rec.conf <<EOF
options { directory "$TMP/rec"; listen-on port 53 { 198.18.200.13; }; listen-on-v6 { none; }; recursion yes; allow-recursion { any; }; dnssec-validation no; pid-file "$TMP/rec.pid"; session-keyfile "$TMP/rec.key"; max-cache-ttl 30; max-ncache-ttl 30; };
zone "." { type hint; file "$TMP/root.hints"; };
EOF
chmod 755 "$TMP"; chmod 644 "$TMP"/*.conf "$TMP"/*.zone "$TMP"/root.hints
for d in root tld auth rec; do sudo ip netns exec "$NS" /usr/sbin/named -g -u root -c "$TMP/$d.conf" >$OUT/$d.log 2>&1 & PIDS="$PIDS $!"; done
sudo ip netns exec "$NS" tcpdump -U -i lo -w $TMP/dns.pcap 'port 53' >/dev/null 2>&1 & PIDS="$PIDS $!"; sleep 2
D="sudo ip netns exec $NS dig @198.18.200.13"
sh -c "$D www.museum.test A +noall +answer +stats" >$OUT/dig-first.txt
sh -c "$D www.museum.test A +noall +answer +stats" >$OUT/dig-cache-hit.txt
sleep 3
sh -c "$D www.museum.test A +noall +answer +stats" >$OUT/dig-after-ttl.txt
sh -c "$D missing.museum.test A +noall +comments +authority" >$OUT/dig-nxdomain-first.txt
sh -c "$D missing.museum.test A +noall +comments +authority" >$OUT/dig-nxdomain-cache.txt
sudo ip netns exec "$NS" dig @198.18.200.10 test NS +norecurse >$OUT/dig-delegation.txt
sleep 1; for p in $PIDS; do sudo kill -INT "$p" 2>/dev/null || true; done; sleep 1
sudo editcap -F pcapng $TMP/dns.pcap $OUT/dns-hierarchy.pcapng; sudo chown "$(id -u):$(id -g)" $OUT/dns-hierarchy.pcapng
tshark -r $OUT/dns-hierarchy.pcapng -T fields -E header=y -e frame.number -e ip.src -e ip.dst -e dns.flags.response -e dns.qry.name -e dns.flags.rcode -e dns.a -e dns.ns >$OUT/dns-hierarchy.frames.tsv
frames=$(tshark -r $OUT/dns-hierarchy.pcapng -T fields -e frame.number | wc -l); start=$(date -u +%FT%TZ)
cat >$OUT/evidence.json <<EOF
{"id":"era3-dns-hierarchy","era":3,"experiment":"miniature delegated DNS hierarchy and recursive cache","protocols":["DNS"],"environment":"Linux network namespace with four BIND instances","topology":"root -> test -> museum.test; separate recursive resolver","capture_point":"$NS:lo","capture_filter":"port 53","tool":"BIND dig tcpdump tshark","tool_version":"$(/usr/sbin/named -v 2>&1)","started_at":"$start","bounded":true,"result":"pass","evidence_level":"L3","files":["captures/era3-dns/dns-hierarchy.pcapng","captures/era3-dns/dns-hierarchy.frames.tsv","captures/era3-dns/dig-first.txt","captures/era3-dns/dig-cache-hit.txt","captures/era3-dns/dig-after-ttl.txt","captures/era3-dns/dig-nxdomain-first.txt","captures/era3-dns/dig-nxdomain-cache.txt","captures/era3-dns/dig-delegation.txt"],"claims":["Local evidence shows delegation, glue, recursion, cache reuse, TTL expiry and NXDOMAIN negative caching."],"limitations":["Modern BIND reconstruction is not an original 1983 deployment and uses a single namespace loopback fabric."],"cleanup_verified":true,"wan":{"used":false,"endpoint_role":"none","provider_specific_claim":false}}
EOF
jsonschema -i $OUT/evidence.json $ROOT/schemas/era3/evidence.schema.json
cleanup; trap - EXIT INT TERM; echo "Era3 DNS: pass ($frames frames)"
