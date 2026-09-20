# M04-T01 production revalidation after C02

Status: **GREEN**

## Exact production update result

The corrected managed upstream was published as Codex Web GPT `v5.0.12`, and the normal production updater completed successfully on the target workstation.

- workstation execution subject before this evidence update: `0fb42d3c4b3ae916157853c3bff96f81e2c4f6c5`
- updater evidence status: `success`
- frozen resolution SHA-256: `27a9929c4cb4da99c0c3cd4c4e5807539ad759b5360559a872664162b5ba1fff`
- promoted candidate tag: `chatgpt-ce-workstation:candidate-27a9929c4cb4da99`
- promoted image ID: `sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852`
- retained previous image ID: `sha256:e11e3f473ee45c25585f79f7b891e18f359a0a133d9b3e37359e7514233a4972`
- retained rollback tag: `chatgpt-ce-workstation:rollback-e11e3f473ee45c25`
- production readback: running and healthy on the exact promoted image
- image provenance label and embedded resolution both match the frozen resolution SHA

The embedded resolution selects Codex Web GPT `5.0.12` with package SHA-256 `b7bd59c772fcf3f5b0bb75277d74eecc6a63dddd5edc8740436c623555b9ee2b`, CE commit `1ef0ece683afb19f8624138599308a1ca1571fa5`, Agent Workspace `0.3.3`, Muse `1.3.0-R3401.1`, Chrome `153.0.8010.52-1`, Rust `1.98.1`, and an immutable Ubuntu 24.04-family base identity.

## Ordered production revalidation

The required checks were re-run against the active candidate:

- `scripts/validate-source.sh`: `SOURCE_VALIDATION_GREEN`
- host preflight, with build-only Compose inputs reconstructed from the exact embedded frozen resolution: `HOST_PREFLIGHT_GREEN`
- health wait against the exact candidate: `health: healthy`
- `scripts/verify-runtime.sh`: `WORKSTATION_RUNTIME_GREEN`
- Ubuntu remains `24.04.5 LTS` / noble
- persistent home and project root are the exact expected bind mounts
- no legacy `/workspace` bind, Docker socket mount, host-root mount, privileged mode, or `SYS_ADMIN`
- desktop health, xdotool, managed global AGENTS reconciliation, Muse CLI and project write smoke are GREEN

A preserved pre-bind migration directory still exists under the persistent home. The runtime verifier reports it as a warning only; it is not used as the active project bind and does not change the accepted persistence boundary.

## Application regressions

### Codex Web GPT

The exact `5.0.12` runtime reports:

- configuration valid
- embedded launcher browser authenticated and reachable
- Codex native model route installed
- Responses proxy healthy on `127.0.0.1:17841`
- tunnel runtime healthy and ready
- `Doctor result: ready`
- route status `installed=true`, `active=true`, `errors=[]`
- browser check GREEN against the authenticated ChatGPT surface

This directly closes the C02 production blocker: the native `multi_agent` normalization is accepted without weakening owned-route verification.

### Native CE / Android Remote surface

The CE desktop is running, and the bundled Codex app-server is active with `app-server --remote-control`. The persistent home, keyring secret mount and CE profile survive the recreate. The target host had already passed the handset pairing/native Remote gate; this automated post-update regression confirms the remote-control server path remains enabled on the promoted candidate without forcing a new pairing.

### Agent Workspace / Computer Use

`agent-workspace-linux doctor` reports `ready_for_x11_workspace=true`, `ready_for_host_viewer=true` and no blockers.

A disposable hidden workspace `m04-t01-smoke` was actually started, ran a command that returned `M04_AGENT_WORKSPACE_GREEN` with exit code 0, reported ready state, and was stopped cleanly.

The bundled Computer Use doctor reports:

- `can_register_mcp_tools=true`
- `can_build_accessibility_tree=true`
- `can_query_windows=true`
- `can_focus_apps=true`
- `can_focus_windows=true`
- `can_send_development_input=true`
- X11 window-control backend GREEN
- AT-SPI accessibility GREEN
- xdotool input backend GREEN
- readiness blockers: none

## Result

M04-T01 acceptance is GREEN on the corrected production candidate. The two compatibility defects found by the earlier live regressions are no longer present in the active managed upstream.

The deliberate rollback/fault-injection exercise has **not** been folded into M04-T01. The retained prior image and rollback tag remain available for M04-T02, which owns that destructive-but-bounded validation plus the repeated/no-change update check.
