# local-llm-stack

Homebrew cask + helper scripts to run a local Ollama + Open WebUI stack on macOS with Docker Desktop.

## CLI contract

Current stable CLI contract: **v1**.

### Supported commands (v1)

- `local-llm-start`
  - Starts Docker Desktop when needed.
  - Waits for Docker daemon readiness.
  - Starts `ollama serve` in a managed Terminal log window (unless already running).
  - Starts or creates the `open-webui` Docker container.
  - Opens a managed Terminal log window for `docker logs -f open-webui`.
  - Waits for `http://localhost:3000` and opens it in the browser.
- `local-llm-stop`
  - Stops the `open-webui` container (if present/running).
  - Stops `ollama serve`.
  - Closes Terminal windows previously tracked by `local-llm-start`.
  - Quits Docker Desktop.
- `local-llm-doctor`
  - Reports host/OS compatibility.
  - Reports whether required CLIs are present (`docker`, `ollama`, `curl`, `osascript`).
  - Reports Docker daemon readiness.
  - Reports whether `ollama serve` and `open-webui` are running.
  - Reports Open WebUI HTTP reachability at `http://localhost:3000`.

### Default behavior and forward compatibility

Current defaults are intentionally unchanged:

- Browser auto-open on start remains enabled.
- Terminal log windows remain enabled.

Future non-breaking flags may be added (for example `--no-open` and `--no-log-windows`) while preserving default orchestration behavior.

## Install

```bash
brew tap 0xCA5E/tools
brew install --cask local-llm-stack
```

After install:

1. Launch Docker Desktop once and complete first-run prompts/permissions.
2. Run `local-llm-start`.

## Commands

- `local-llm-start`: start/orchestrate the stack and open browser/log windows (v1 default behavior).
- `local-llm-stop`: stop stack services, close managed Terminal windows, and quit Docker Desktop.
- `local-llm-doctor`: inspect stack health and dependency/runtime status.

## Uninstall

```bash
brew uninstall local-llm-stack
```

Uninstalling the cask removes the packaged commands and prompts whether to remove Ollama models too.

- `y`: full cleanup, including Ollama models.
- `n` or Enter: remove everything except Ollama models.

In all cases, uninstall removes the managed Open WebUI Docker image/container/volume, local state files, and Docker Desktop data. In non-interactive contexts, uninstall defaults to full cleanup.
