# Gateway review and adoption guide

Reviewed on 2026-09-05. Gate's useful position is a local Rust gateway for AI
tools with configurable provider routing, DLP and operational evidence.
Feature presence does not establish a certification, DLP detection rate or
performance advantage.

## Market references

| Reference | Observed practice | Direction for Gate |
| --- | --- | --- |
| [LiteLLM fallback documentation](https://docs.litellm.ai/docs/proxy/reliability) | Explicit fallback groups and provider failure testing | Keep provider failover in the configured routing chain and test with synthetic upstream failures. |
| [LiteLLM documentation](https://docs.litellm.ai/) | Gateway budgets, guardrails and observability | Describe defaults and limits for each control. Avoid treating feature switches as evidence that a policy was enforced. |
| [Reqwest redirect policy](https://docs.rs/reqwest/latest/reqwest/redirect/index.html) | Redirect behavior is an explicit HTTP-client policy | Disable automatic redirects for provider calls so configured routing remains the egress boundary. |

## Changes and operator impact

### Provider redirects

Provider HTTP clients do not automatically follow 301, 302, 303, 307 or 308
responses. Prompts and provider-specific headers must not be replayed at a
destination selected by a redirect. Configure the final provider endpoint
directly. This applies to both streaming and non-streaming calls using the
shared provider client.

If HTTP-client initialization fails, Gate stops instead of silently replacing
the requested TLS and redirect policy with a default client. Investigate the
startup error and certificate configuration before restarting. This does not
add an outbound firewall or validate every possible DNS resolution.

### Scriptable validation

`gate validate` now exits unsuccessfully when provider initialization fails or
a router model has no healthy provider. A working fallback still counts as a
usable model, matching the printed health summary. Partial provider failures
remain visible in that summary. This command makes real provider calls and can
consume tokens; it is not an offline configuration-only check.

```bash
# Explicit live validation before adopting a configuration:
gate validate && echo "Every checked router model has a healthy provider"
```

### Supply chain

Third-party GitHub Actions are pinned to verified commit IDs while preserving
their existing selected versions. Dependabot can propose updates for review.
Commit pinning does not certify the contents or provenance of an action.

## Offline regression checks

```bash
cargo fmt --all -- --check
cargo test --locked --lib
cargo clippy --locked --all-targets -- -D warnings
```

Redirect tests use two local synthetic HTTP servers and check that no redirected
prompt reaches the second server. Direct requests still succeed. Validation
tests cover empty results, broken models, mixed model health and a working
fallback. No production provider credentials are required by these tests.

## Prioritized next milestones

| Priority | Work | Acceptance criterion |
| --- | --- | --- |
| P1 | Budget enforcement under concurrency | Parallel requests cannot overrun a configured reservation ceiling; restart and failed-upstream accounting are tested. |
| P1 | Streaming privacy corpus | Secrets split across chunks and tool-call fields are tested with documented precision/recall limits. |
| P1 | Audit continuity | Detect tampering, missing records and key rotation using synthetic fixtures and an independently verified export. |
| P2 | Provider compatibility matrix | Versioned fixtures exercise errors, streaming cancellation, tool calls and fallback for each supported protocol. |
| P2 | Reproducible performance evidence | Publish p50/p95/p99, throughput, memory and hardware with direct-provider baselines and identical payloads. |

## Rollback

There is no configuration or spend-journal migration. Revert the change commit
to restore prior behavior. Endpoint URLs that depended on redirects should be
corrected rather than relying on rollback, which restores the egress risk.
Automation that previously ignored validation failures must handle nonzero
exit status after this change.
