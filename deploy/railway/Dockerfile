# Railway image for the dsh Web UI: the published @deepseek-ai/dsh CLI behind
# Caddy. dsh listens on loopback only; Caddy owns the public port Railway routes
# to and forwards the browser-facing Host unchanged.
FROM caddy:2.8.4 AS caddy

FROM node:24-bookworm

ARG DSH_VERSION=0.2.2-rc.1
ARG PNPM_VERSION=11.28.5

# The GitHub CLI lets the agent use GitHub; start.sh signs it in when
# DSH_GITHUB_TOKEN is set.
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends gh \
  && rm -rf /var/lib/apt/lists/*

# pnpm is the package manager the dsh plugin manager runs to install plugins.
RUN npm install -g "@deepseek-ai/dsh@${DSH_VERSION}" "pnpm@${PNPM_VERSION}" && npm cache clean --force

COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY deploy/railway/Caddyfile deploy/railway/Caddyfile.password deploy/railway/sign-in.html /etc/caddy/
COPY deploy/railway/start.sh /usr/local/bin/dsh-railway-start
RUN chmod +x /usr/local/bin/dsh-railway-start

ENV DSH_HOME=/data/dsh \
    DSH_WORKSPACE=/data/workspace \
    PORT=8080

CMD ["dsh-railway-start"]
