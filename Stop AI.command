#!/bin/bash
# Stop AI.command
# Stops: Open WebUI container + Ollama server,
# closes the exact Terminal windows created by Start (tracked by window IDs),
# quits Docker Desktop completely,
# deletes the temp state file.

set -euo pipefail

WEBUI_NAME="open-webui"

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
    say_err "Error: Stop AI.command only supports macOS (Terminal + AppleScript required)."
    exit 1
  fi
}

close_terminal_window_by_id() {
  local win_id="$1"
  /usr/bin/osascript - "$win_id" <<'APPLESCRIPT' >/dev/null 2>&1
on run argv
  set winId to (item 1 of argv) as integer
  tell application "Terminal"
    try
      set targetWins to (every window whose id is winId)
      repeat with w in targetWins
        close w saving no
      end repeat
    end try
  end tell
end run
APPLESCRIPT
}

resolve_state_file() {
  local legacy_file

  if [[ -e "${STATE_FILE}" ]]; then
    printf '%s\n' "${STATE_FILE}"
    return
  fi

  for legacy_file in "${LEGACY_STATE_FILES[@]}"; do
    if [[ -e "${legacy_file}" ]]; then
      printf '%s\n' "${legacy_file}"
      return
    fi
  done

  printf '%s\n' "${STATE_FILE}"
}

quit_docker_desktop() {
  # Prefer bundle id (stable), then fall back to app names.
  /usr/bin/osascript <<'APPLESCRIPT' >/dev/null 2>&1
try
  tell application id "com.docker.docker" to quit
on error
  try
    tell application "Docker Desktop" to quit
  on error
    try
      tell application "Docker" to quit
    end try
  end try
end try
APPLESCRIPT

  # If it’s still running, force kill as a last resort.
  if pgrep -x "Docker" >/dev/null 2>&1 || pgrep -x "Docker Desktop" >/dev/null 2>&1; then
    killall "Docker" >/dev/null 2>&1 || true
    killall "Docker Desktop" >/dev/null 2>&1 || true
  fi
}

require_macos

echo "Stopping AI stack..."

# Stop services first (so logs stop cleanly)
if command -v docker >/dev/null 2>&1; then
  docker stop "${WEBUI_NAME}" >/dev/null 2>&1 || true
fi
pkill -f "[o]llama serve" >/dev/null 2>&1 || true

# Close Terminal windows created by Start script
RESOLVED_STATE_FILE="$(resolve_state_file)"
if [[ ! -e "${RESOLVED_STATE_FILE}" ]]; then
  echo "No saved Terminal window state found at ${RESOLVED_STATE_FILE}."
elif [[ ! -f "${RESOLVED_STATE_FILE}" ]]; then
  echo "Warning: State path is not a regular file: ${RESOLVED_STATE_FILE}"
elif [[ ! -s "${RESOLVED_STATE_FILE}" ]]; then
  echo "State file exists but is empty: ${RESOLVED_STATE_FILE}"
else
  while IFS= read -r WIN_ID; do
    [[ -z "${WIN_ID}" ]] && continue
    if [[ "${WIN_ID}" =~ ^[0-9]+$ ]]; then
      close_terminal_window_by_id "${WIN_ID}" || true
    else
      echo "Warning: Ignoring corrupt window id in state file: ${WIN_ID}"
    fi
  done < "${RESOLVED_STATE_FILE}"
fi

# Delete state files
rm -f "${STATE_FILE}" >/dev/null 2>&1 || true
for legacy_file in "${LEGACY_STATE_FILES[@]}"; do
  rm -f "${legacy_file}" >/dev/null 2>&1 || true
done

# Quit Docker Desktop completely
if pgrep -x "Docker" >/dev/null 2>&1 || pgrep -x "Docker Desktop" >/dev/null 2>&1; then
  echo "Quitting Docker Desktop..."
  quit_docker_desktop
fi

echo "AI stack stopped."

# Close the Terminal window that ran this Stop script (do it async so the script can finish)
(
  sleep 0.4
  /usr/bin/osascript <<'APPLESCRIPT' >/dev/null 2>&1
tell application "Terminal"
  try
    close front window saving no
  end try
end tell
APPLESCRIPT
) & disown

