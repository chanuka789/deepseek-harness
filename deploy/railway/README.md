# Deploy the Web UI on Railway

This directory builds a Railway image that runs the published `@deepseek-ai/dsh` CLI as `dsh web` behind Caddy, following [Publish the Web UI behind a reverse proxy](../../docs/user/guide/public-deployments.md).

## How it works

- `dsh web` listens on `127.0.0.1:3080` only, so nothing outside the container reaches it directly.
- Caddy listens on `$PORT`, which Railway routes its public HTTPS domain to, and forwards the browser-facing `Host` unchanged.
- `start.sh` passes `https://$RAILWAY_PUBLIC_DOMAIN/` as `--public-url` and the same domain as `--trusted-host`; startup fails when the service has no public domain.
- `DSH_HOME` (`/data/dsh`) and the agent working directory (`/data/workspace`) live under `/data`; mount a Railway volume there to keep settings and sessions across deploys.
- The `DSH_VERSION` build argument selects the published CLI version.

## Service settings

| Setting | Value |
|---|---|
| Variable `RAILWAY_DOCKERFILE_PATH` | `deploy/railway/Dockerfile` |
| Variable `DEEPSEEK_API_KEY` | your DeepSeek API key |
| Volume | mounted at `/data` |
| Public networking | a generated Railway domain |

## Sign in

Every container start prints one `dsh web: https://<domain>/?token=...` line in the deploy logs. Open that URL once; the browser receives a signed session cookie. A redeploy or restart issues a new token. The URL is a credential that gives shell access inside the container, so share it only with intended users.
