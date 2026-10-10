#!/usr/bin/env bash
# DNS-independent smoke test of a Memverse host. Usage: smoke.sh 64.23.176.115 (or 192.241.205.154).
# Plan §9 step 11 / Appendix A.4. Pair with a browser session via an /etc/hosts override.
set -u
IP=${1:?usage: smoke.sh <ip>}
R=(--resolve "www.memverse.com:443:$IP" --resolve "memverse.com:443:$IP" --resolve "www.memverse.com:80:$IP")
chk() { local want=$1 url=$2; code=$(curl -sS -o /dev/null -w '%{http_code}' "${R[@]}" "$url"); printf '%-62s %s (want %s)\n' "$url" "$code" "$want"; }
chk 301 http://www.memverse.com/
chk 301 https://memverse.com/
chk 200 https://www.memverse.com/
chk 200 https://www.memverse.com/users/sign_in
chk 200 https://www.memverse.com/forum
chk 200 https://www.memverse.com/blog
chk 302 https://www.memverse.com/admin
chk 200 https://www.memverse.com/apidocs.json
chk 200 "https://www.memverse.com/verses/verse_search?searchParams=love"   # Thinking Sphinx
curl -sS "${R[@]}" https://www.memverse.com/apidocs.json | grep -q accessCode && echo "apidocs: accessCode present" || echo "apidocs: accessCode MISSING"
curl -sS "${R[@]}" -A GPTBot -o /dev/null -w 'bot block: %{http_code} (want 403)\n' https://www.memverse.com/
asset=$(curl -sS "${R[@]}" https://www.memverse.com/users/sign_in | grep -oE '/assets/application-[0-9a-f]+\.css' | head -1)
[ -n "$asset" ] && chk 200 "https://www.memverse.com$asset"
echo | openssl s_client -connect "$IP:443" -servername www.memverse.com 2>/dev/null | openssl x509 -noout -subject -dates
