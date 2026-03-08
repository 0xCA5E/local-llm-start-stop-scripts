# Changelog

All notable changes to this project are documented in this file.

## [1.0.0] - 2026-03-08

### Added
- Published stable CLI contract **v1** with supported command semantics for:
  - `local-llm-start`
  - `local-llm-stop`
  - `local-llm-doctor` (and `local-llm-status` alias)
- Added `Doctor AI.command` and formula wrappers for `local-llm-doctor` / `local-llm-status`.
- Added README legacy command mapping:
  - `Start AI.command` → `local-llm-start`
  - `Stop AI.command` → `local-llm-stop`

### Notes
- Default orchestration remains unchanged in v1:
  - Browser auto-open remains enabled on start.
  - Managed Terminal log windows remain enabled on start.
- Future optional flags such as `--no-open` and `--no-log-windows` may be added without changing default behavior.
