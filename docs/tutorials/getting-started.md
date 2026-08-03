# Getting Started with Gate

This tutorial walks you through installing Gate, configuring it with a preset, and using it with Claude Code. By the end, you will have a working LLM routing proxy with automatic provider fallback.

## Prerequisites

- A Unix-like system (macOS or Linux) or Windows
- At least one LLM provider account (Anthropic, OpenAI, OpenRouter, or a local Ollama install)
- Rust toolchain (if building from source) or `curl` (for the install script)

## Step 1: Install Gate

Gate ships as a standalone binary. Choose one of two methods:

**Option A: Install script (recommended)**

```bash
curl -fsSL https://raw.githubusercontent.com/murillo-consulting/gate/main/scripts/install.sh | sh
```

**Option B: Homebrew (macOS / Linux)**

```bash
brew install murillo-consulting/tap/gate
```

The install script fetches the latest release binary for your platform from
[GitHub Releases](https://github.com/murillo-consulting/gate/releases). Container users
can pull `ghcr.io/murillo-consulting/gate:latest` instead.

Verify the installation:

```bash
gate --help
```

You should see a list of available commands.

## Step 2: Set your API keys

Gate reads API keys from environment variables. Set the ones for the providers you plan to use:

```bash
# Anthropic (required for most presets)
export ANTHROPIC_API_KEY="sk-ant-..."

# OpenRouter (optional, for fallback providers)
export OPENROUTER_API_KEY="sk-or-..."
```

If you have an Anthropic Pro or Max subscription and want to use OAuth instead of an API key, skip this step -- you will authenticate via browser in Step 4.

## Step 3: Apply a preset

Presets are pre-built configurations that set up providers, models, and routing in one command. List them with `gate preset list`, then pick the one that matches your setup:

| Preset | What it sets up | Monthly cost estimate |
|--------|-----------------|----------------------|
| `perf` | Pure Anthropic OAuth (Pro/Max), auto-maps `claude-*` to native | Subscription only |
| `ultra-cheap` | Stacked free tiers (Groq + Cerebras + Z.ai + OpenRouter `:free`) | ~€0-2/month |
| `gdpr` | EU-only routing (Mistral, Scaleway, OVH) + DLP | Pay-as-you-go |
| `eu-ai-act` | EU AI Act controls (EU providers + transparency headers) | Pay-as-you-go |
| `eu-eco` / `eu-pro` / `eu-max` | Strict-EU sovereign tiers (budget / balanced / premium) | Pay-as-you-go |

Apply the `perf` preset (simplest — one Anthropic subscription, no fallbacks):

```bash
gate preset apply perf
```

This creates `~/.gate/config.toml` with Anthropic OAuth for every `claude-*` model.

To see what a preset contains before applying:

```bash
gate preset info perf
```

## Step 4: Start Gate and launch your tool

The simplest way is `gate exec`, which starts the proxy, sets the right environment variables, launches your tool, and stops the proxy when your tool exits:

```bash
gate exec -- claude
```

This is equivalent to:

```bash
gate start -d
ANTHROPIC_BASE_URL=http://[::1]:13456 claude
gate stop
```

(The default bind address is `::1`, IPv6 localhost. Use `http://127.0.0.1:13456` if your system does not support IPv6.)

If you applied an OAuth preset, a browser window will open on first start for authentication. Complete the login flow and return to the terminal.

## Step 5: Verify it works

In another terminal, check Gate's status:

```bash
gate status
```

You should see output like:

```
Gate is running (PID 12345)
  Port: 13456
  Preset: perf
  Spend: $0.00 / $0.00 (no limit)
```

Run a diagnostic check:

```bash
gate doctor
```

This verifies your config file, environment variables, and provider connectivity.

## Step 6: Check your spend

After some usage, check what it cost:

```bash
gate spend
```

This shows a breakdown by provider and model for the current month.

## What just happened?

When you ran `gate exec -- claude`:

1. Gate loaded `~/.gate/config.toml`
2. It started an HTTP server on `[::1]:13456` (IPv6 localhost)
3. It set `ANTHROPIC_BASE_URL=http://[::1]:13456` so Claude Code sends requests to Gate
4. For each request, Gate classified the task type (thinking, default, web search, background)
5. It selected the best model for that task type and tried providers in priority order
6. If a provider failed, it automatically tried the next one in the fallback chain
7. Responses were streamed back to Claude Code with DLP scanning and spend tracking

## Next steps

- **Customize your config**: Edit `~/.gate/config.toml` directly -- see [Configuration Reference](../reference/configuration.md)
- **Add more providers**: See [Provider Setup](../how-to/providers.md) for all 13+ supported backends
- **Set a budget**: Add `[budget] monthly_limit_usd = 50.0` to your config -- see [How to Configure](../how-to/configure.md)
- **Understand the architecture**: Read the [Architecture Overview](../explanation/architecture.md)
- **Fix problems**: Check [Troubleshooting](../how-to/troubleshooting.md)
