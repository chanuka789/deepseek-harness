#!/bin/sh
# Starts Caddy on $PORT and dsh web on loopback; exits when either exits so
# Railway restarts the container.
set -eu

if [ -z "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  echo "dsh-railway-start: RAILWAY_PUBLIC_DOMAIN is empty; generate a public domain for this service" >&2
  exit 1
fi

mkdir -p "$DSH_HOME" "$DSH_WORKSPACE"
cd "$DSH_WORKSPACE"

caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
caddy_pid=$!

dsh web --no-open --host 127.0.0.1 --port 3080 \
  --public-url "https://${RAILWAY_PUBLIC_DOMAIN}/" \
  --trusted-host "${RAILWAY_PUBLIC_DOMAIN}" &
dsh_pid=$!

trap 'kill "$caddy_pid" "$dsh_pid" 2>/dev/null' TERM INT

while kill -0 "$caddy_pid" 2>/dev/null && kill -0 "$dsh_pid" 2>/dev/null; do
  sleep 5
done
kill "$caddy_pid" "$dsh_pid" 2>/dev/null || true
exit 1
