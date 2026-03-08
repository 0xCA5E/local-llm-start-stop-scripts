#!/bin/bash
# Doctor AI.command
# Health/status checks for local AI stack on macOS.

set -euo pipefail

WEBUI_NAME="open-webui"
WEBUI_URL="http://localhost:3000"

ok() { printf '[OK] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*"; }

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

main() {
  local issues=0

  if [[ "$(uname -s)" == "Darwin" ]]; then
    ok "Running on macOS"
  else
    fail "Unsupported OS: $(uname -s) (expected Darwin/macOS)"
    issues=$((issues + 1))
  fi

  for cmd in docker ollama curl osascript; do
    if has_cmd "${cmd}"; then
      ok "Command available: ${cmd}"
    else
      fail "Missing command: ${cmd}"
      issues=$((issues + 1))
    fi
  done

  if has_cmd docker; then
    if docker info >/dev/null 2>&1; then
      ok "Docker daemon is reachable"
    else
      warn "Docker daemon is not reachable"
      issues=$((issues + 1))
    fi

    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "${WEBUI_NAME}"; then
      ok "Open WebUI container is running (${WEBUI_NAME})"
    elif docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "${WEBUI_NAME}"; then
      warn "Open WebUI container exists but is not running (${WEBUI_NAME})"
    else
      warn "Open WebUI container does not exist (${WEBUI_NAME})"
    fi
  fi

  if pgrep -f "[o]llama serve" >/dev/null 2>&1; then
    ok "Ollama server process is running"
  else
    warn "Ollama server process is not running"
  fi

  if has_cmd curl; then
    if curl -fsS "${WEBUI_URL}" >/dev/null 2>&1; then
      ok "Open WebUI is reachable at ${WEBUI_URL}"
    else
      warn "Open WebUI is not reachable at ${WEBUI_URL}"
    fi
  fi

  if [[ "${issues}" -eq 0 ]]; then
    echo ""
    ok "Doctor checks completed with no critical issues."
    exit 0
  fi

  echo ""
  warn "Doctor checks completed with ${issues} issue(s)."
  exit 1
}

main "$@"
