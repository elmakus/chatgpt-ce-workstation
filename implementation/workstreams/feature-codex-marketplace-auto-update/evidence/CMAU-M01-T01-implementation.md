# CMAU-M01-T01 implementation evidence

Date: `2026-09-20`
Implementation subject: `elmakus/chatgpt-ce-workstation@b769cf49e8e9dd3a5780c6b333e1990974bc6b31`
Card: `CMAU-M01-T01`

## Implemented scope

- Added `scripts/container/codex_marketplace_updater.py` as the deterministic scheduler/updater core.
- Added `scripts/test-codex-marketplace-updater.py` with injected command/time boundaries.
- Added the updater's compile/test/command-wiring checks to `scripts/validate-source.sh`.
- No s6 registration, Dockerfile service wiring, live container recreate, or persistent live marketplace mutation was performed; those remain later milestone scope.

## Bounded JIT choices

- Persistent last-success state: `/home/codex/.local/state/chatgpt-ce-workstation/codex-marketplace-updater.json`.
- Normal refresh interval: fixed `86400` seconds.
- Failure retry interval: `3600` seconds.
- Bundled runtime command: `/opt/codex-desktop/resources/codex plugin marketplace upgrade --json`.
- State persistence uses same-directory temporary file + file fsync + atomic `os.replace` + directory fsync.
- Machine-readable success requires exit status 0, an object with `selectedMarketplaces`, `upgradedRoots`, and `errors` arrays, and an empty `errors` array.
- Diagnostics report only bounded status/count/error summaries; captured Codex stdout/stderr is not copied into updater logs.

## Verification

GREEN:
- `python3 -m py_compile` for updater + test module.
- `scripts/test-codex-marketplace-updater.py`: 13/13 tests passed.
- Covered first run, restart-before-due remaining wait, exact/overdue due state, zero-marketplace success, all-marketplace command shape, nonzero command failure, JSON-reported error, malformed/incomplete JSON, malformed state recovery, failure not advancing state, not-due non-mutation, simulated interrupted atomic replace preserving prior state, and completion-time success timestamp.
- GitHub readback confirmed the exact updater/test contents and the `validate-source.sh` integration on the implementation subject.
- Current OpenAI Codex marketplace CLI source was independently checked during execution: all-marketplace upgrade omits `MARKETPLACE_NAME`; JSON success exposes `selectedMarketplaces`, `upgradedRoots`, and `errors`; upgrade errors fail the command.
- GitHub reported no PR-triggered workflow run for the implementation subject.

Not executed:
- Full `scripts/validate-source.sh` because the current execution surface does not provide a complete project checkout with Docker Compose; the Card contract permits recording this unavailable dependency and running the affected deterministic checks directly.
- Any real marketplace/network refresh or live Workstation mutation.

## Acceptance assessment

All CMAU-M01-T01 implementation acceptance is satisfied at the source/component level. The Card remains non-terminal because its stable contract requires a RECOMMENDED independent review of this exact implementation subject.
