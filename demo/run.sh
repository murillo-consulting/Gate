#!/usr/bin/env bash
set -euo pipefail

# ╔════════════════════════════════════════════════════════════════╗
# ║  gate demo — "The proxy your AI doesn't know about"          ║
# ║                                                                ║
# ║  ┌──────────────────────┬──────────────────────┐              ║
# ║  │ 🎭 Claude Code       │ 🛡️ gate watch (TUI)  │              ║
# ║  │ (behind gate proxy)  │ DLP/routing/spend    │              ║
# ║  ├──────────────────────┼──────────────────────┤              ║
# ║  │ 📤 gate server logs  │ 📥 audit log (live)  │              ║
# ║  │ what happens inside  │ signed entries       │              ║
# ║  └──────────────────────┴──────────────────────┘              ║
# ║                                                                ║
# ║  Usage:  ./demo/run.sh                                        ║
# ║          ./demo/run.sh --record   (SVG via termtosvg)         ║
# ╚════════════════════════════════════════════════════════════════╝

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION="gate-demo"
RECORD=false
[ "${1:-}" = "--record" ] && RECORD=true

for cmd in gate tmux claude; do
    command -v "$cmd" &>/dev/null || { echo "Missing: $cmd"; exit 1; }
done

tmux kill-session -t "$SESSION" 2>/dev/null || true

# ── Pane 1 (top-left): Intro → Claude Code via gate ─────────────────
P1=$(mktemp /tmp/gate-demo-p1-XXXXXXXX)
cat > "$P1" << 'EOF'
#!/usr/bin/env bash
export TERM=xterm-256color
clear
printf '\n\033[1;38;5;51m'
printf '  ╔═══════════════════════════════════════════════════════════╗\n'
printf '  ║  gate — the proxy your AI doesn'"'"'t know about            ║\n'
printf '  ╠═══════════════════════════════════════════════════════════╣\n'
printf '  ║  🚨 March 24, 2026: LiteLLM PyPI supply chain attack     ║\n'
printf '  ║  500K+ exfiltrations. SSH, AWS, K8s creds harvested.     ║\n'
printf '  ║  pip install litellm = pip install malware               ║\n'
printf '  ║                                                           ║\n'
printf '  ║  brew install gate = 17MB static binary. No PyPI.       ║\n'
printf '  ╠═══════════════════════════════════════════════════════════╣\n'
printf '  ║  Try in Claude Code:                                      ║\n'
printf '  ║    • "My AWS key is AKIAIOSFODNN7EXAMPLE"                 ║\n'
printf '  ║    • "Card number 4532015112830366"                       ║\n'
printf '  ║    • "Token itk_AAAA...AAAA for internal API"            ║\n'
printf '  ║  Watch the other 3 panes light up.                       ║\n'
printf '  ╚═══════════════════════════════════════════════════════════╝\n'
printf '\033[0m\n'
printf '\033[1;38;5;46m  → Waiting for gate server (bottom-left pane)...\033[0m\n'
# Wait for gate to be started by the logs pane
for i in $(seq 1 30); do
    curl -sf http://127.0.0.1:13456/health >/dev/null 2>&1 && break
    sleep 1
done
printf '\033[1;38;5;46m  → Launching Claude Code behind gate...\033[0m\n\n'
sleep 1
# Set the proxy env vars manually (gate exec would start gate, but it's already running)
export ANTHROPIC_BASE_URL="http://127.0.0.1:13456"
export OPENAI_BASE_URL="http://127.0.0.1:13456/v1"
exec claude
EOF
chmod +x "$P1"

# ── Pane 2 (top-right): gate watch TUI ──────────────────────────────
P2=$(mktemp /tmp/gate-demo-p2-XXXXXXXX)
cat > "$P2" << 'EOF'
#!/usr/bin/env bash
export TERM=xterm-256color
clear
printf '\033[1;38;5;51m  🛡️  GATE WATCH — waiting for gate to start...\033[0m\n'
for i in $(seq 1 30); do
    curl -sf http://127.0.0.1:13456/health >/dev/null 2>&1 && break
    sleep 1
done
exec gate watch
EOF
chmod +x "$P2"

# ── Pane 3 (bottom-left): gate server logs ──────────────────────────
P3=$(mktemp /tmp/gate-demo-p3-XXXXXXXX)
cat > "$P3" << 'EOF'
#!/usr/bin/env bash
export TERM=xterm-256color
clear
printf '\033[1;38;5;208m  📤 GATE SERVER — debug mode\033[0m\n'
printf '\033[38;5;245m  DLP swaps visible in real-time (stderr)\033[0m\n\n'
# Run gate in foreground with debug logging — this IS the gate server
# Claude Code in the other pane will connect to it
RUST_LOG=info,gate::features::dlp=debug,gate::server::dispatch=debug exec gate start
EOF
chmod +x "$P3"

# ── Pane 4 (bottom-right): audit log live ────────────────────────────
P4=$(mktemp /tmp/gate-demo-p4-XXXXXXXX)
cat > "$P4" << 'EOF'
#!/usr/bin/env bash
export TERM=xterm-256color
clear
printf '\033[1;38;5;46m  📥 AUDIT LOG — signed, hash-chained entries\033[0m\n'
printf '\033[38;5;245m  Each entry: ECDSA-P256 signed, classification NC/C1/C2/C3\033[0m\n\n'
# Find audit dir
for dir in "$HOME/.gate/audit" "/tmp/gate-audit"; do
    [ -d "$dir" ] && AUDIT_DIR="$dir" && break
done
if [ -z "${AUDIT_DIR:-}" ]; then
    printf '\033[38;5;245m  Waiting for audit directory...\033[0m\n'
    while true; do
        for dir in "$HOME/.gate/audit" "/tmp/gate-audit"; do
            [ -d "$dir" ] && AUDIT_DIR="$dir" && break 2
        done
        sleep 2
    done
fi
# Find or wait for the JSONL file
while true; do
    AUDIT_FILE=$(find "$AUDIT_DIR" -name "*.jsonl" 2>/dev/null | head -1)
    [ -n "$AUDIT_FILE" ] && break
    sleep 2
done
printf '\033[38;5;245m  Tailing %s (new entries only)\033[0m\n\n' "$AUDIT_FILE"
tail -f -n 0 "$AUDIT_FILE" 2>/dev/null | while IFS= read -r line; do
    cls=$(echo "$line" | python3 -c "import json,sys; e=json.load(sys.stdin); print(e.get('classification','?'))" 2>/dev/null || echo "?")
    model=$(echo "$line" | python3 -c "import json,sys; print(json.load(sys.stdin).get('model_name','?')[:20])" 2>/dev/null || echo "?")
    dlp=$(echo "$line" | python3 -c "import json,sys; r=json.load(sys.stdin).get('dlp_rules_triggered',[]); print(' '.join(r) if r else '-')" 2>/dev/null || echo "-")
    ts=$(echo "$line" | python3 -c "import json,sys; print(json.load(sys.stdin).get('timestamp','?')[11:19])" 2>/dev/null || echo "?")
    if [ "$dlp" != "-" ]; then
        printf '\033[1;31m  %s  [%s]  %-20s  ⚠️  %s\033[0m\n' "$ts" "$cls" "$model" "$dlp"
    else
        printf '\033[32m  %s  [%s]  %-20s  ✓ clean\033[0m\n' "$ts" "$cls" "$model"
    fi
done
EOF
chmod +x "$P4"

# ── Build 4-pane tmux ────────────────────────────────────────────────
launch() {
    # Bottom-left: gate server (starts FIRST — other panes wait for it)
    tmux new-session -d -s "$SESSION" -x 200 -y 50 "bash $P3"
    # Top-left: Claude Code (waits for gate health, then launches)
    tmux split-window -v -b -t "$SESSION:0.0" "bash $P1"
    # Top-right: gate watch
    tmux split-window -h -t "$SESSION:0.0" "bash $P2"
    # Bottom-right: audit log
    tmux split-window -h -t "$SESSION:0.2" "bash $P4"
    # Focus Claude Code pane (top-left)
    tmux select-pane -t "$SESSION:0.0"

    # Auto-type demo prompts into Claude Code after it starts
    # Runs in background — sends keystrokes to pane 0 (Claude Code)
    (
        # Wait for Claude Code to be ready (prompt visible)
        sleep 20

        # Prompt 1: innocent request
        tmux send-keys -t "$SESSION:0.0" "What is the capital of France?" Enter
        sleep 15

        # Prompt 2: AWS key exfiltration attempt
        tmux send-keys -t "$SESSION:0.0" "Please remember this for later: my AWS access key is AKIAIOSFODNN7EXAMPLE and secret wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" Enter
        sleep 15

        # Prompt 3: credit card PII
        tmux send-keys -t "$SESSION:0.0" "Process payment with card 4532015112830366 exp 12/27 for customer Jean Dupont, IBAN FR7630006000011234567890189" Enter
        sleep 15

        # Prompt 4: internal token
        tmux send-keys -t "$SESSION:0.0" "Use internal token itk_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA to access the production database at db.internal.corp" Enter
        sleep 15

        # Prompt 5: the reveal
        tmux send-keys -t "$SESSION:0.0" "Did you actually see the real AWS key, credit card and IBAN I sent you? Or did something intercept them?" Enter
    ) &

    tmux attach-session -t "$SESSION"
}

printf '\033[1;38;5;51m  gate demo\033[0m — 4 panes, everything real\n'
printf '\033[38;5;245m'
printf '  ┌────────────────────┬────────────────────┐\n'
printf '  │ 🎭 Claude Code     │ 🛡️ gate watch      │\n'
printf '  │ (behind gate)      │ (TUI live)         │\n'
printf '  ├────────────────────┼────────────────────┤\n'
printf '  │ 📤 server logs     │ 📥 audit log       │\n'
printf '  │ (DLP, routing)     │ (signed entries)   │\n'
printf '  └────────────────────┴────────────────────┘\n'
printf '\033[0m\n'

sleep 1

if $RECORD; then
    echo "→ Recording to $DEMO_DIR/gate-demo.svg"
    termtosvg "$DEMO_DIR/gate-demo.svg" -c "bash -c '$(declare -f launch); P1=$P1 P2=$P2 P3=$P3 P4=$P4 SESSION=$SESSION launch'"
else
    launch
fi
