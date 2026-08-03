# Gate Quick Start

Get up and running in 30 seconds.

## 1. Install

```bash
brew install murillo-consulting/tap/gate
# or without Homebrew:
curl -fsSL https://raw.githubusercontent.com/murillo-consulting/gate/main/scripts/install.sh | sh
```

## 2. Apply a preset

```bash
gate preset apply perf
```

This writes `~/.gate/config.toml` with Anthropic + OpenAI + Gemini providers and top-tier models.
Set the required API keys in your environment first:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
export OPENAI_API_KEY=sk-...
export GEMINI_API_KEY=AI...
```

Available presets: `perf`, `medium`, `cheap`, `fast`, `local`, `gdpr`, `eu-ai-act`.
Run `gate preset list` to see all options.

## 3. Launch your tool

```bash
gate exec -- claude
```

Gate starts in the background, sets `ANTHROPIC_BASE_URL` and `OPENAI_BASE_URL` to point at the proxy, launches your command, and stops when it exits.

Other examples:

```bash
gate exec -- aider
gate exec -- opencode
gate exec -- my-custom-tool --flag
```

## What just happened?

Gate is now proxying all LLM requests. It routes them to the best provider based on the model requested, handles fallback if a provider is down, enforces budgets, and tracks spend. Check the status anytime:

```bash
gate status     # Service status, loaded models, active preset
gate spend      # Current month's spend vs. budget
gate doctor     # Full diagnostic check
```

## Next steps

- [Architecture overview](../explanation/architecture.md) -- how the request pipeline works
- [Troubleshooting](../how-to/troubleshooting.md) -- common errors and fixes
- [Configuration reference](../reference/configuration.md) -- all TOML options
- [OpenAPI spec](../openapi.yaml) -- full API reference
