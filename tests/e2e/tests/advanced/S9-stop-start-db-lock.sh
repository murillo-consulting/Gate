#!/usr/bin/env bash
set -euo pipefail

# S9: Regression test for stop/start cycle.
# gate stop must wait until the process fully exits before returning.
# A subsequent gate start must succeed without storage lock errors.
#
# Bug: stop_service sent SIGTERM + 500ms grace but didn't verify death.
# Fix: stop_service now polls kill(0) for up to 5s, then SIGKILL.

cd "$(dirname "$0")/../.."
HOST="${HOST:-127.0.0.1:13456}"

echo "  S9: stop/start cycle (clean shutdown regression)"

# Skip if gate is not locally installed (pod mode)
if ! command -v gate &>/dev/null; then
    echo "  SKIP: S9 — gate not in PATH (pod mode)"
    exit 0
fi

# Start gate
gate start -d 2>/dev/null || true
sleep 2

if ! curl -sf "http://$HOST/health" >/dev/null 2>&1; then
    echo "  SKIP: S9 — gate failed to start (may need OAuth)"
    exit 0
fi

# Stop immediately
gate stop 2>/dev/null

# Verify process is actually dead (the fix)
sleep 1
if pgrep -f "gate start" >/dev/null 2>&1; then
    echo "  FAIL: S9 — gate process still running after stop"
    exit 1
fi

# Start again — this must succeed
gate start -d 2>/dev/null
sleep 3

if curl -sf "http://$HOST/health" >/dev/null 2>&1; then
    echo "  PASS: S9 — stop/start cycle clean"
    gate stop 2>/dev/null
else
    echo "  FAIL: S9 — gate failed to start after stop"
    gate stop 2>/dev/null
    exit 1
fi
