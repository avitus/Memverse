#!/usr/bin/env bash
# DNS-independent smoke test of a Memverse host. Usage: smoke.sh 64.23.176.115 (or 192.241.205.154).
# Every check is reported and bounded (20 s per request); the script exits non-zero if any check
# failed, so it can gate the cutover (plan §9 step 11). Pair with a browser session via an /etc/hosts override.
set -uo pipefail
IP=${1:?usage: smoke.sh <ip>}
R=(--max-time 20 --connect-timeout 10 --resolve "www.memverse.com:443:$IP" --resolve "memverse.com:443:$IP" --resolve "www.memverse.com:80:$IP")
fails=0
pass() { printf 'ok    %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*"; fails=$((fails + 1)); }
chk() {
  local want=$1 url=$2 code
  code=$(curl -sS -o /dev/null -w '%{http_code}' "${R[@]}" "$url" 2>/dev/null) || code=000
  if [ "$code" = "$want" ]; then pass "$url -> $code"; else fail "$url -> $code (want $want)"; fi
}

chk 301 http://www.memverse.com/
chk 301 https://memverse.com/
chk 200 https://www.memverse.com/
chk 200 https://www.memverse.com/users/sign_in
chk 200 https://www.memverse.com/forum
chk 200 https://www.memverse.com/blog
chk 302 https://www.memverse.com/admin
chk 200 https://www.memverse.com/apidocs.json
chk 302 "https://www.memverse.com/verses/verse_search?searchParams=love"   # login required; Sphinx itself is checked while signed in (plan 3.7) and via port 9312

body=$(curl -sS "${R[@]}" https://www.memverse.com/apidocs.json 2>/dev/null) || body=""
if grep -q accessCode <<<"$body"; then pass "apidocs.json advertises accessCode"; else fail "apidocs.json lacks accessCode"; fi

code=$(curl -sS "${R[@]}" -A GPTBot -o /dev/null -w '%{http_code}' https://www.memverse.com/ 2>/dev/null) || code=000
if [ "$code" = "403" ]; then pass "bot block -> 403"; else fail "bot block -> $code (want 403)"; fi

page=$(curl -sS "${R[@]}" https://www.memverse.com/users/sign_in 2>/dev/null) || page=""
asset=$(grep -oE '/assets/application-[0-9a-f]+\.css' <<<"$page" | head -1) || asset=""
if [ -n "$asset" ]; then chk 200 "https://www.memverse.com$asset"; else fail "no fingerprinted application CSS on the sign-in page"; fi

# perl alarm bounds openssl s_client, which has no timeout of its own (portable to macOS and Linux).
if echo | perl -e 'alarm 15; exec @ARGV' openssl s_client -connect "$IP:443" -servername www.memverse.com 2>/dev/null | openssl x509 -noout -checkend 604800 >/dev/null 2>&1; then
  pass "TLS certificate for www.memverse.com valid for at least 7 more days"
else
  fail "TLS certificate missing, not for www.memverse.com, or expiring within 7 days"
fi

if [ "$fails" -eq 0 ]; then echo "SMOKE OK"; else echo "SMOKE FAILED: $fails check(s)"; exit 1; fi
