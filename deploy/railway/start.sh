#!/usr/bin/env bash
# Starts dsh web on loopback, then Caddy on $PORT; exits when either exits so
# Railway restarts the container.
#
# With DSH_USERNAME and DSH_PASSWORD set, Caddy requires HTTP basic auth for
# every request and answers a dsh 401 on `/` with a page that exchanges the
# current launch token, so the browser signs in without the printed URL.
# Without them, Caddy only proxies and the printed URL is the sole sign-in.
set -euo pipefail

if [ -z "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  echo "dsh-railway-start: RAILWAY_PUBLIC_DOMAIN is empty; generate a public domain for this service" >&2
  exit 1
fi

mkdir -p "$DSH_HOME" "$DSH_WORKSPACE"
cd "$DSH_WORKSPACE"

run_dir="$(mktemp -d)"
dsh_log="$run_dir/dsh.log"
: > "$dsh_log"

dsh web --no-open --host 127.0.0.1 --port 3080 \
  --public-url "https://${RAILWAY_PUBLIC_DOMAIN}/" \
  --trusted-host "${RAILWAY_PUBLIC_DOMAIN}" > >(tee -a "$dsh_log") 2>&1 &
dsh_pid=$!

token=""
for _ in $(seq 1 180); do
  token="$(sed -n 's/^dsh web: .*[?&]token=\([A-Za-z0-9_-]*\).*/\1/p' "$dsh_log" | head -n 1)"
  [ -n "$token" ] && break
  if ! kill -0 "$dsh_pid" 2>/dev/null; then
    echo "dsh-railway-start: dsh web exited before printing its URL" >&2
    exit 1
  fi
  sleep 1
done
if [ -z "$token" ]; then
  echo "dsh-railway-start: dsh web printed no URL within 180 seconds" >&2
  kill "$dsh_pid" 2>/dev/null || true
  exit 1
fi

if [ -n "${DSH_USERNAME:-}" ] && [ -n "${DSH_PASSWORD:-}" ]; then
  site_root="$run_dir/site"
  mkdir -p "$site_root"
  sed "s/__DSH_TOKEN__/${token}/g" /etc/caddy/sign-in.html > "$site_root/sign-in.html"
  DSH_PASSWORD_HASH="$(caddy hash-password --plaintext "$DSH_PASSWORD")"
  export DSH_PASSWORD_HASH DSH_SITE_ROOT="$site_root"
  caddy_config=/etc/caddy/Caddyfile.password
  echo "dsh-railway-start: username/password sign-in enabled for ${DSH_USERNAME}"
else
  caddy_config=/etc/caddy/Caddyfile
  echo "dsh-railway-start: DSH_USERNAME/DSH_PASSWORD not set; sign in with the dsh web URL above" >&2
fi

caddy run --config "$caddy_config" --adapter caddyfile &
caddy_pid=$!

trap 'kill "$caddy_pid" "$dsh_pid" 2>/dev/null' TERM INT

while kill -0 "$caddy_pid" 2>/dev/null && kill -0 "$dsh_pid" 2>/dev/null; do
  sleep 5
done
kill "$caddy_pid" "$dsh_pid" 2>/dev/null || true
exit 1
