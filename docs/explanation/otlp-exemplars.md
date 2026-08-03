# OTLP Exemplars (latency → trace correlation)

This document explains why gate does **not yet** emit OpenTelemetry exemplars on
its OTLP histograms, what the code already does in preparation, and exactly what
is (still) missing — which turns out to be an **upstream** gap, not a gate one.

## What exemplars are for

An *exemplar* is a representative histogram sample carrying the
`trace_id`/`span_id` of the request that produced it. A metrics backend that
retains those samples can let Grafana turn a latency spike into "open the trace
that produced it".

The local `/metrics` surface is different from the OTLP surface. Gate builds
`metrics_exporter_prometheus::PrometheusBuilder` without configuring histogram
buckets. Version 0.16 therefore renders the duration distribution as a
Prometheus **summary**, with these real series:

```text
gate_request_duration_seconds{quantile="0.5", ...}
gate_request_duration_seconds_sum{...}
gate_request_duration_seconds_count{...}
```

It does not emit a `gate_request_duration_seconds_bucket` series, so a local
Prometheus `query_exemplars` call against that name cannot succeed. Summary
quantiles are already calculated per label set and must not be aggregated as
histogram buckets.

## Current status: OTLP exemplars are empty

With `[otel] metrics = true`, the fan-out bridge records the same source metric
as an OpenTelemetry histogram. The exact query series then depends on the
collector and metrics backend. Regardless of that backend representation,
exemplars are currently empty because the OpenTelemetry **Rust** SDK does not
capture them in any released version.

## Root cause: opentelemetry-rust has not implemented exemplar capture

gate pins the OpenTelemetry 0.28 release train (`opentelemetry` /
`opentelemetry_sdk` / `opentelemetry-otlp` / `opentelemetry-appender-tracing`
0.28, `tracing-opentelemetry` 0.29) on a pure rustls/tonic tree with no openssl.

A bump to the **latest** train (0.32 / tracing-opentelemetry 0.33) was
investigated specifically to enable exemplars and **reverted**, because it
changes nothing here: **exemplar capture is not implemented upstream in any
released version, including the latest stable `opentelemetry_sdk` 0.32.1** (so
the upgrade buys no exemplar benefit). This is a version-independent gap:

- The data model carries the field — `metrics::data::Exemplar<T>` exists with
  `trace_id: [u8; 16]` / `span_id: [u8; 8]`, and 0.32 even exposes an
  `exemplars()` accessor — so the OTLP proto *can* represent exemplars.
- But the aggregation pipeline never populates it. Every aggregator
  (`internal/histogram.rs`, `sum.rs`, `last_value.rs`,
  `exponential_histogram.rs`, `aggregate.rs`) still hardcodes
  `exemplars: vec![]` when it builds a data point, and **never reads the OTel
  `Context`** during `measure`/`collect`.
- There is **no API to enable a reservoir**: a full-tree grep of
  `opentelemetry 0.32.0`, `opentelemetry_sdk 0.32.1`, and
  `opentelemetry-otlp 0.32.0` finds **no** `ExemplarFilter`, `ExemplarReservoir`,
  `with_exemplar_filter`, `TraceBased`, nor any `OTEL_METRICS_EXEMPLAR_FILTER`
  handling. None of the SDK feature flags (`spec_unstable_metrics_views`,
  `experimental_metrics_*`) enable exemplars either.

So the `ExemplarFilter::TraceBased` knob that other OTel language SDKs expose
**does not exist in the Rust SDK yet**. Consequently no change on gate's side can
produce exemplars today — not a config flag, not a custom `View`, not the
`Context` attach. The SDK simply does not capture them.

## What gate already does (the half it can do today)

A reservoir — once it exists — can only capture a `trace_id` if the **OTel
`Context` is current at the moment of `record`**. `tracing-opentelemetry` stores
each request's OTel span in the *tracing* span's extensions but does **not** push
it onto the OTel thread-local `Context`. So at the metrics call-site,
`opentelemetry::Context::current()` is empty.

`server::budget::record_request_metrics` therefore attaches the active span's
OTel context for the duration of the metric recording (feature-gated `otel`):

```rust
let cx = tracing::Span::current().context();          // OpenTelemetrySpanExt
if cx.span().span_context().is_valid() {
    let _guard = cx.attach();                          // OTel Context = request span
    // counter!/histogram!/… record here
}
```

The request span itself comes from the `tower_http` `TraceLayer` (`http_request`
span), which `tracing-opentelemetry` exports as an OTel span under the `otel`
feature. The attach is a **no-op for exemplars today** (the SDK ignores the
Context), and it is also a no-op when `otel` is disabled or no span is active
(the validity guard). It exists so that the day upstream lands exemplar capture,
the trace_id is already on the Context.

## What is needed to finish it

The blocker is now entirely **upstream**:

1. **opentelemetry-rust must implement exemplar capture** in the metrics SDK
   (a trace-based reservoir wired into the histogram/sum aggregators, plus a
   `with_exemplar_filter`/`ExemplarFilter::TraceBased` configuration API).
   This is tracked upstream (the data model is already in place; the aggregation
   wiring is not). It is **not** something gate can polyfill without forking the
   SDK's aggregation internals.
2. **Then, in gate**: add the trace-based filter to the bridge's
   `SdkMeterProvider` in `src/shared/otel_metrics.rs`
   (`builder.with_exemplar_filter(ExemplarFilter::TraceBased)`, exact name per
   the version that ships it) — a one-liner.
3. **Keep the `Context` attach** in `record_request_metrics` (already in place).
4. **Verify empirically**: run gate with `[otel] metrics = true` against a
   collector, generate traffic, inspect the series schema produced by that
   collector/backend, then run its exemplar query for
   `gate_request_duration_seconds`. The result must carry a non-empty
   `trace_id`; do not assume that the backend names a series `_bucket`.

Until step 1 lands upstream, exemplars remain empty by SDK design across **all**
released opentelemetry-rust versions, and that is expected.
