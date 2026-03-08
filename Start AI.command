#!/bin/bash
# Start AI.command
# Starts Docker Desktop, Ollama (live logs), Open WebUI container, WebUI logs,
# waits for WebUI, then opens browser.
# Tracks Terminal window IDs so Stop script can close them.

set -euo pipefail

WEBUI_NAME="open-webui"
WEBUI_URL="http://localhost:3000"

# State file stored in user state directory (override with LOCAL_LLM_STATE_DIR)
STATE_DIR="${LOCAL_LLM_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/local-llm}"
STATE_FILE="${STATE_DIR}/terminal_window_ids.tmp"
LEGACY_STATE_FILES=(
  "/tmp/local_llm_terminal_window_ids.tmp"
  "/tmp/terminal_window_ids.tmp"
)

say_err() { printf '%s\n' "$*" >&2; }

require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    say_err "Error: Start AI.command only supports macOS (Terminal + AppleScript required)."
    exit 1
  fi
}

require_command() {
  local cmd="$1"
  local install_hint="${2-}"

  if command -v "${cmd}" >/dev/null 2>&1; then
    return
  fi

  say_err "Error: ${cmd} is required but was not found in PATH."
  if [[ -n "${install_hint}" ]]; then
    say_err "Hint: ${install_hint}"
  fi
  exit 1
}

ensure_state_dir() {
  if [[ -d "${STATE_DIR}" ]]; then
    chmod 700 "${STATE_DIR}" 2>/dev/null || true
    return
  fi

  if ! install -d -m 700 "${STATE_DIR}" 2>/dev/null; then
    if ! mkdir -p "${STATE_DIR}" 2>/dev/null; then
      say_err "Error: Cannot create state directory: ${STATE_DIR}"
      exit 1
    fi
    chmod 700 "${STATE_DIR}" 2>/dev/null || true
  fi
}

relocate_legacy_state_file() {
  local legacy_file

  if [[ -f "${STATE_FILE}" && -s "${STATE_FILE}" ]]; then
    return
  fi

  for legacy_file in "${LEGACY_STATE_FILES[@]}"; do
    if [[ -f "${legacy_file}" && -s "${legacy_file}" ]]; then
      cp "${legacy_file}" "${STATE_FILE}" 2>/dev/null || true
      rm -f "${legacy_file}" 2>/dev/null || true
      return
    fi
  done
}

# Open a Terminal window running a command and return the window id
open_terminal_window() {
  local cmd="$1"
  /usr/bin/osascript - "$cmd" <<'APPLESCRIPT'
on run argv
  set cmd to item 1 of argv
  tell application "Terminal"
    activate
    try
      set w to (make new window)
      do script cmd in w
      delay 0.2
      return id of w
    on error
      -- fallback for macOS versions where make new window fails
      do script cmd
      delay 0.2
      return id of front window
    end try
  end tell
end run
APPLESCRIPT
}

echo "Starting AI stack..."

require_macos
require_command docker "Install Docker Desktop: brew install --cask docker"
require_command ollama "Install Ollama: brew install ollama"
require_command curl

ensure_state_dir
relocate_legacy_state_file

# Create/reset state file
: > "${STATE_FILE}" 2>/dev/null || {
  say_err "Error: Cannot write state file: ${STATE_FILE}"
  exit 1
}

# Track the window running THIS start script (so Stop can close it too)
START_WIN_ID="$(/usr/bin/osascript <<'APPLESCRIPT' 2>/dev/null || true
tell application "Terminal"
  try
    return id of front window
  on error
    return ""
  end try
end tell
APPLESCRIPT
)"
if [[ -n "${START_WIN_ID}" ]]; then
  echo "${START_WIN_ID}" >> "${STATE_FILE}"
fi

# --- Docker Desktop ---
if ! pgrep -x "Docker" >/dev/null 2>&1 && ! pgrep -x "Docker Desktop" >/dev/null 2>&1; then
  echo "Launching Docker Desktop..."
  open -a "Docker" 2>/dev/null || open -a "Docker Desktop" 2>/dev/null || true
fi

echo "Waiting for Docker daemon..."
for _ in {1..90}; do
  if docker info >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! docker info >/dev/null 2>&1; then
  say_err "Error: Docker daemon never became ready."
  exit 1
fi

# --- Ollama server ---
if ! pgrep -f "[o]llama serve" >/dev/null 2>&1; then
  echo "Launching Ollama server in Terminal (live logs)..."

  OLLAMA_CMD="bash -lc 'echo Starting Ollama server...; exec ollama serve'"
  OLLAMA_WIN_ID="$(open_terminal_window "${OLLAMA_CMD}" || true)"

  if [[ -n "${OLLAMA_WIN_ID}" ]]; then
    echo "${OLLAMA_WIN_ID}" >> "${STATE_FILE}"
  else
    echo "Warning: Could not open Terminal window for Ollama logs."
  fi
else
  echo "Ollama already running."
fi

# --- Open WebUI container ---
if docker ps -a --format '{{.Names}}' | grep -qx "${WEBUI_NAME}"; then
  echo "Starting existing Open WebUI container..."
  docker start "${WEBUI_NAME}" >/dev/null
else
  echo "Creating + starting Open WebUI container..."
  docker run -d -p 3000:8080 \
    -v open-webui:/app/backend/data \
    --name "${WEBUI_NAME}" \
    ghcr.io/open-webui/open-webui:main >/dev/null
fi

# --- WebUI logs window ---
echo "Opening Open WebUI logs in Terminal..."

WEBUI_LOGS_CMD="bash -lc 'echo Tailing Open WebUI logs...; exec docker logs -f ${WEBUI_NAME}'"
WEBUI_LOGS_WIN_ID="$(open_terminal_window "${WEBUI_LOGS_CMD}" || true)"

if [[ -n "${WEBUI_LOGS_WIN_ID}" ]]; then
  echo "${WEBUI_LOGS_WIN_ID}" >> "${STATE_FILE}"
else
  echo "Warning: Could not open Terminal window for WebUI logs."
fi

# --- Wait for WebUI readiness ---
echo "Waiting for WebUI to become reachable..."

READY=0
for _ in {1..90}; do
  if curl -fsS "${WEBUI_URL}" >/dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 1
done

if [[ "${READY}" -ne 1 ]]; then
  say_err "Warning: WebUI did not become reachable at ${WEBUI_URL}. Opening anyway."
fi

echo "Opening Web UI: ${WEBUI_URL}"
open "${WEBUI_URL}"

echo "AI stack started."
