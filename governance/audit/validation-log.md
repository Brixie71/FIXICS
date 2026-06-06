# Validation Log

Record validation runs that matter for implementation, review, or release decisions.

## Entries

### 2026-06-06 - Baseline before Codex operating layer

- Command: `hemtt check`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 3 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: run before adding the Codex operating scaffold.

### 2026-06-06 - Codex operating layer scaffold

- Command: `.\tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 3 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: run after adding `CODEX.md`, agent guidance, tool wrappers, orchestration, prompts, governance, evals, tests, and docs.

### 2026-06-07 - Local vehicle slope rolling and ACE handbrake

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified `FIXICS_fnc_*` source migration, ACE interaction dependency, handbrake stringtable keys, and local vehicle physics function registration.
- Manual coverage: not run.
- Notes: static regression was first run before implementation and failed for the expected missing feature checks.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 7 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: manual Eden/VR slope behavior with ACE loaded is still required for empty, driver-occupied, and passenger-only vehicles.
