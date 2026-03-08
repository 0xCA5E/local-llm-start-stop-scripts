# local-llm-stack

Homebrew formula + helper scripts to run a local Ollama + Open WebUI stack on macOS with Docker Desktop.

## Install

```bash
brew tap <org>/tap
brew install local-llm-stack
```

After install:

1. Run `local-llm-install-deps` to install/check dependencies.
2. Launch Docker Desktop once and complete first-run prompts/permissions.
3. Run `local-llm-start`.

## Commands

- `local-llm-install-deps`: install/check Homebrew, Ollama, and Docker Desktop.
- `local-llm-start`: starts Docker Desktop (if needed), Ollama, and Open WebUI.
- `local-llm-stop`: stops stack services and closes managed Terminal windows.
- `local-llm-clean`: **optional destructive cleanup** that removes the Open WebUI container and volume after explicit `CLEAN` confirmation.

## Uninstall

```bash
brew uninstall local-llm-stack
```

Uninstalling the formula removes the command wrappers and packaged scripts, but does **not** remove Docker containers, named volumes, or app data by default.
Use `local-llm-clean` before uninstall if you want to tear down the managed container/volume.
