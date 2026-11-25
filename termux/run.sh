#!/data/data/com.termux/files/usr/bin/bash
# Start the already-built Blockbench:  bash termux/run.sh [--port 8080]
cd "$(dirname "$0")/.."
command -v termux-wake-lock >/dev/null && termux-wake-lock || true
exec node termux/serve.mjs "$@"
