#!/bin/bash
# Install Dependencies.command
# Installs required dependencies for Start AI.command / Stop AI.command on macOS.

set -euo pipefail

say() { printf '%s\n' "$*"; }
say_err() { printf '%s\n' "$*" >&2; }

require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    say_err "This installer only supports macOS."
    exit 1
  fi
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    say "Homebrew is already installed."
    return
  fi

  say "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  if ! command -v brew >/dev/null 2>&1; then
    say_err "Homebrew installation did not complete successfully."
    exit 1
  fi
}

has_docker_desktop_app() {
  open -Ra "Docker" >/dev/null 2>&1 || open -Ra "Docker Desktop" >/dev/null 2>&1
}

install_ollama_if_missing() {
  if command -v ollama >/dev/null 2>&1; then
    say "ollama is already installed; skipping installation."
    return
  fi

  say "Installing ollama via Homebrew..."
  brew install ollama
}

install_docker_if_missing() {
  if command -v docker >/dev/null 2>&1 && has_docker_desktop_app; then
    say "Docker CLI and Docker Desktop app already detected; skipping installation."
    return
  fi

  say "Installing Docker Desktop via Homebrew..."
  brew install --cask docker
}

verify_commands() {
  local missing=0

  for cmd in docker ollama curl osascript; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      say_err "Missing command after install: ${cmd}"
      missing=1
    fi
  done

  if ! has_docker_desktop_app; then
    say_err "Docker Desktop app not found after install."
    missing=1
  fi

  if [[ "${missing}" -ne 0 ]]; then
    say_err "Some dependencies are still missing."
    exit 1
  fi
}

main() {
  require_macos
  ensure_homebrew

  say "Updating Homebrew metadata..."
  brew update

  # Required by Start AI.command and Stop AI.command
  install_ollama_if_missing
  install_docker_if_missing

  verify_commands

  say ""
  say "Dependencies installed successfully."
  say "Next steps:"
  say "1) Launch Docker Desktop once and complete any first-run setup prompts."
  say "2) Run 'Start AI.command'."
}

main "$@"
