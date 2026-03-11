#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Clawdboss Docker Entrypoint
# Handles first-run setup and subsequent starts
# ============================================================

CONFIG_FILE="$HOME/.openclaw/openclaw.json"
MODE="${CLAWDBOSS_MODE:-auto}"

# --- Graceful shutdown ---
shutdown() {
  echo ""
  echo "🦞 Shutting down Clawdboss..."
  openclaw gateway stop 2>/dev/null || true
  exit 0
}
trap shutdown SIGTERM SIGINT SIGQUIT

# --- Mode logic ---
run_setup() {
  echo "🦞 First run detected — launching Clawdboss setup wizard..."
  echo ""
  cd /opt/clawdboss
  exec bash setup.sh
}

run_gateway() {
  echo "🦞 Config found — starting OpenClaw gateway..."
  echo ""

  # Source .env if it exists (for API keys)
  if [ -f "$HOME/.openclaw/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$HOME/.openclaw/.env"
    set +a
  fi

  # Start gateway in foreground (keeps container alive)
  openclaw gateway start

  # Wait for the gateway process to stay alive
  # The gateway daemonizes, so we tail the log to keep the container running
  echo "🦞 Gateway started. Tailing logs (Ctrl+C or docker stop to shut down)..."
  echo ""

  # Find and tail the gateway log, or just wait
  LOG_FILE="$HOME/.openclaw/gateway.log"
  if [ -f "$LOG_FILE" ]; then
    tail -f "$LOG_FILE" &
    TAIL_PID=$!
    wait $TAIL_PID
  else
    # No log file yet — just wait indefinitely
    while true; do
      sleep 60
    done
  fi
}

# --- Entrypoint ---
case "$MODE" in
  setup)
    run_setup
    ;;
  run)
    run_gateway
    ;;
  auto)
    if [ -f "$CONFIG_FILE" ]; then
      run_gateway
    else
      run_setup
    fi
    ;;
  *)
    echo "❌ Unknown CLAWDBOSS_MODE: $MODE"
    echo "   Valid options: setup, run, auto"
    exit 1
    ;;
esac
