//! Cross-cutting modules shared across vertical slices.
//!
//! Hosts small, low-coupling modules that are used by multiple features but
//! do not themselves define a feature slice. This keeps the `src/` root for
//! genuinely top-level concerns (entry point, library contract, core traits).
//!
//! Contents:
//!
//! - [`acme`] — Automatic TLS certificate provisioning via ACME (feature-gated).
//! - [`instance`] — Multi-instance coordination (PID + port probing).
//! - [`log_time`] — Consistent UTC timestamps for all tracing subscribers.
//! - [`message_tracing`] — Request/response trace pipeline (JSONL with rotation).
//! - [`net`] — Network binding helpers (SO_REUSEPORT for zero-downtime upgrades).
//! - [`otel`] — OpenTelemetry subscriber bootstrap.
//! - `otel_metrics` — OpenTelemetry metrics bridge / fan-out recorder (feature-gated).
//! - [`pid`] — PID file management for daemon mode.

/// Automatic TLS certificate provisioning via ACME.
#[cfg(feature = "acme")]
pub mod acme;

/// Server instance lifecycle helpers (PID + port probing).
pub mod instance;

/// Consistent UTC timestamp formatting for tracing subscribers.
pub mod log_time;

/// Request/response message tracing utilities.
pub mod message_tracing;

/// Network utilities and port management.
pub mod net;

/// OpenTelemetry distributed tracing export.
pub mod otel;

/// OpenTelemetry metrics bridge (fan-out recorder).
#[cfg(feature = "otel")]
pub mod otel_metrics;

/// PID file management for daemon mode.
pub mod pid;

/// Return the smallest valid UTF-8 character boundary at or after `index`.
///
/// This is equivalent to `str::ceil_char_boundary`, but keeps Gate compatible
/// with its declared Rust 1.88 MSRV (the standard-library method stabilized in
/// Rust 1.91).
pub(crate) fn ceil_char_boundary(value: &str, index: usize) -> usize {
    let mut boundary = index.min(value.len());
    while !value.is_char_boundary(boundary) {
        boundary += 1;
    }
    boundary
}
