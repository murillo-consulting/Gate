# Changelog

All notable changes to Gate are documented in this file.

## [0.1.0] - 2026-07-29

### Added

- Initial Gate release.
- Multi-provider LLM routing with fallback and circuit breakers.
- Anthropic Messages, OpenAI Chat Completions, and OpenAI Responses API
  compatibility.
- Inline DLP, budget controls, encrypted credential storage, signed audit
  records, and Prometheus/OpenTelemetry instrumentation.
- CLI, container, Podman Quadlet, Docker Compose, and Helm deployment options.

### Changed

- Established `gate` as the crate, binary, container, chart, metric, and
  configuration namespace.
- Reset the public release line to `0.1.0`.

[0.1.0]: https://github.com/murillo-consulting/gate/releases/tag/v0.1.0
