#!/bin/bash
# Clean AI.command
# Optional teardown for local AI stack resources.
# Stops/removes Open WebUI container and removes the named Docker volume.

set -euo pipefail

WEBUI_NAME="open-webui"
WEBUI_VOLUME="open-webui"

say() { printf '%s\n' "$*"; }
say_err() { printf '%s\n' "$*" >&2; }

require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    say_err "This cleanup command is supported on macOS only."
    exit 1
  fi
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    say_err "docker CLI not found in PATH."
    exit 1
  fi
}

confirm_cleanup() {
  say "This will permanently remove:"
  say "  - Docker container: ${WEBUI_NAME}"
  say "  - Docker volume: ${WEBUI_VOLUME}"
  say ""
  read -r -p "Type CLEAN to continue: " answer

  if [[ "${answer}" != "CLEAN" ]]; then
    say "Cleanup cancelled."
    exit 0
  fi
}

main() {
  require_macos
  require_docker
  confirm_cleanup

  say "Stopping/removing container (${WEBUI_NAME}) if present..."
  docker rm -f "${WEBUI_NAME}" >/dev/null 2>&1 || true

  say "Removing volume (${WEBUI_VOLUME}) if present..."
  docker volume rm "${WEBUI_VOLUME}" >/dev/null 2>&1 || true

  say "Cleanup complete."
}

main "$@"
