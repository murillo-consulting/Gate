# How to Deploy Gate

## Run in a container

Gate publishes a minimal container image (~6 MB, `FROM scratch`) to GitHub Container Registry.

### Docker / Podman

```bash
docker run -d \
  -e ANTHROPIC_API_KEY=sk-ant-... \
  -e OPENROUTER_API_KEY=sk-or-... \
  -p 8080:8080 \
  ghcr.io/murillo-consulting/gate:latest
```

The container runs `gate run --json-logs --host 0.0.0.0 --port 8080` by default. Use `-p 13456:8080` if you want the native host default on the outside.

### With a config file

Mount your config:

```bash
docker run -d \
  -v ~/.gate/config.toml:/etc/gate/config.toml:ro \
  -e GATE_CONFIG=/etc/gate/config.toml \
  -e GATE_HOME=/var/lib/gate \
  -e ANTHROPIC_API_KEY=sk-ant-... \
  -p 8080:8080 \
  ghcr.io/murillo-consulting/gate:latest
```

### With remote config

```bash
docker run -d \
  -e GATE_CONFIG=https://config.example.com/gate.toml \
  -e ANTHROPIC_API_KEY=sk-ant-... \
  -p 8080:8080 \
  ghcr.io/murillo-consulting/gate:latest
```

## Kubernetes

A sample manifest is provided in `deploy/gate-kube.yml`. Key points:

- Use a Secret for API keys
- Mount config via ConfigMap or use remote config URL
- Set `GATE_CONFIG=/etc/gate/config.toml` and `GATE_HOME=/var/lib/gate`
- The health endpoint is `GET /health` (returns 200 with PID)
- Metrics are at `GET /metrics` (Prometheus format)
- The container runs as non-root (UID/GID 65534); hostPath volumes must be writable by that user

```yaml
livenessProbe:
  httpGet:
    path: /live
    port: 8080
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
startupProbe:
  httpGet:
    path: /health
    port: 8080
```

## Build from source

```bash
# Standard release build
cargo build --release

# Static binary (for container builds)
RUSTFLAGS="-C target-feature=+crt-static" \
  cargo build --release --target x86_64-unknown-linux-musl
```

## Build the container image

```bash
podman build -f Containerfile -t gate:latest .
```

The multi-stage build uses `cargo-chef` for layer caching, so only code changes rebuild the final layer.

## Run as a systemd service

Create `/etc/systemd/system/gate.service`:

```ini
[Unit]
Description=Gate LLM Routing Proxy
After=network.target

[Service]
Type=exec
ExecStart=/usr/local/bin/gate run --json-logs --host 127.0.0.1 --port 13456
Restart=on-failure
RestartSec=5
Environment=ANTHROPIC_API_KEY=sk-ant-...
EnvironmentFile=-/etc/gate/env

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable --now gate
```

## Monitor with Prometheus

Gate exposes metrics at `/metrics` in Prometheus format:

- `gate_requests_total` -- request count by model, provider, status
- `gate_request_duration_seconds` -- latency histogram
- `gate_spend_usd` -- current month spend
- `gate_input_tokens_total`, `gate_output_tokens_total` -- token counts
- `gate_ratelimit_hits_total` -- upstream rate limit events
- `gate_circuit_breaker_state` -- per-provider circuit breaker state

A Grafana dashboard is provided in `docs/grafana-dashboard.json`.

### Protect `/metrics` with a bearer token

`/metrics` is **public by default** (the Prometheus convention — rely on network
policy / TLS). Because it exposes spend, budget, and tenant labels, you can
require a bearer token instead:

```toml
[metrics]
# Inline token, OR read it from a file (the file wins and is trimmed):
bearer_token = "REPLACE_WITH_A_LONG_RANDOM_TOKEN"
# bearer_token_file = "/etc/gate/metrics-token"
```

With a token set, `/metrics` requires `Authorization: Bearer <token>` (compared
in constant time) and returns `401` otherwise. `/health`, `/live`, and `/ready`
stay public. Point your scraper at the same token:

```yaml
scrape_configs:
  - job_name: gate
    scheme: https            # TLS is handled by gate's TLS/ACME layer or your ingress
    authorization:
      type: Bearer
      credentials_file: /etc/prometheus/gate-metrics-token
    static_configs:
      - targets: ["gate:13456"]
```

On Kubernetes, the Helm chart's `serviceMonitor.bearerTokenSecret` wires the
token into a `ServiceMonitor` — see `deploy/helm/gate/README.md`.
