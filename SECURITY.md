# Security Policy

## Supported versions

Gate ships fixes only on the latest released minor version. Older
releases are not patched; upgrade to the latest release from
<https://github.com/murillo-consulting/gate/releases> before reporting an issue.

| Version | Security fixes |
|---------|----------------|
| Latest minor | Yes |
| Older minors | No — upgrade required |

## Reporting a vulnerability

**Do not open a public GitHub issue for security problems.**

Report vulnerabilities through GitHub's private vulnerability reporting:
<https://github.com/murillo-consulting/gate/security/advisories/new>.

Please include:

- A description of the issue and its impact.
- The gate version (`gate --version`) and build (binary, container, or
  source).
- A minimal reproduction — TOML config, request payload, and the
  observed behaviour. Redact API keys, OAuth tokens, and any personally
  identifiable data before sending.
- Your suggested severity (informational, low, medium, high, critical)
  and whether a CVE should be requested.

### What to expect

| Step | Target |
|------|--------|
| Acknowledgement of your report | Within 3 business days |
| Triage and severity assessment | Within 7 business days |
| Fix or mitigation plan shared with you | Within 30 days for high/critical |
| Coordinated public disclosure | Agreed with reporter, default 90 days |

We credit reporters in the release notes and the associated GitHub
Security Advisory unless you request anonymity.

## Scope

In scope:

- The `gate` binary and its default configuration.
- The routing, dispatch, DLP, OAuth, and policy pipelines.
- The HTTP surfaces exposed by `gate start` (Anthropic-native, OpenAI
  Chat Completions, OpenAI Responses, management endpoints).
- Supply-chain metadata shipped by the release pipeline: GitHub
  Releases artefacts, the container image at `ghcr.io/murillo-consulting/gate`,
  and the Homebrew formula at `murillo-consulting/tap/gate`.

Out of scope:

- Denial-of-service via provider-side rate limits (we cannot fix
  upstream quotas).
- Issues that require a compromised local user account with filesystem
  access to `~/.gate/`.
- Third-party providers themselves (Anthropic, OpenAI, Gemini, etc.).
  Report those to the upstream vendor.
- Experimental or opt-in feature flags not enabled in the default
  build.

## Handling sensitive data

Gate touches API keys, OAuth refresh tokens, and request payloads that
may contain secrets or PII. When reproducing an issue:

- Redact keys and tokens before sharing logs or configs.
- Prefer a synthetic reproduction over copying a production payload.
- When you must share real data, use GitHub private vulnerability reporting
  or request an encrypted exchange channel by email before sending it.

## Safe harbour

Good-faith security research that follows this policy is welcome. We
will not pursue legal action against researchers who:

- Give us a reasonable time to remediate before public disclosure.
- Avoid privacy violations, destruction of data, and service
  degradation during testing.
- Do not exfiltrate data beyond what is needed to prove the
  vulnerability.
