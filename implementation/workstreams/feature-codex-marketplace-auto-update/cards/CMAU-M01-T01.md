# CMAU-M01-T01 — Deterministic marketplace updater core

- Milestone: `CMAU-M01`

> This file is a stable Task Card contract. Mutable execution/review/result state lives only in `implementation/workstreams/feature-codex-marketplace-auto-update/TASK_BOARD.yaml`.

## Authority slice

- Master Plan / milestone contract: `planning/CODEX_MARKETPLACE_AUTO_UPDATE_PLAN.md#milestone-cmau-m01--deterministic-scheduler-core`
- Requirements: `requirements/CODEX_MARKETPLACE_AUTO_UPDATE.md` — CMAU-REQ-002..007, CMAU-REQ-010..012, CMAU-REQ-016
- Accepted decisions: `docs/DECISIONS.md` — D3, D8, D10, D14, D17, D24
- Relevant OpenSpec: none
- Accepted dependency results: none

### Must preserve

- Normal cadence is 24 hours from the last verified successful refresh, not container/service start.
- No recorded success means refresh is due promptly; restart before due waits only the remaining interval.
- Refresh targets all configured Git marketplaces in one Codex invocation by omitting a marketplace name.
- Zero configured Git marketplaces is a successful no-op.
- Failure never advances last-success state and must leave prior working marketplace state usable.
- Failure retries later with a bounded non-busy delay and must not affect Workstation/desktop health.
- Diagnostics stay in ordinary process/service logging and never enter LLM/session context.
- No new credentials or secret storage; tests must not require network or real credentials.
- Timer/failure behavior must be deterministically testable without real 24-hour waits.
- The implementation must remain repository-owned and use the CE-bundled Codex path when the default command is exercised.

### Must not / rationale that must travel

- Do not add cron/systemd, SessionStart hooks, an LLM decision path, per-plugin/per-skill timers, or a second standalone Codex CLI.
- Do not perform a live Workstation recreate or mutate persistent live marketplace configuration in this Card.
- Do not log credentials, auth material, or environment dumps.

## Dependencies

- none

## Outcome

A repository-owned scheduler/updater core deterministically computes due time from persistent last-success state, invokes one configurable all-marketplace Codex refresh command, validates machine-readable success, atomically records only verified success, and applies bounded retry behavior on failure.

## Scope

### Included

- Add the updater core under `scripts/container/` with injectable command/time/sleep boundaries suitable for deterministic unit tests.
- Use a persistent-state default below `/home/codex`, with the exact path chosen in implementation inside the approved Definition.
- Implement atomic last-success persistence and safe malformed/missing-state handling.
- Implement refresh result validation: non-zero process status, malformed machine-readable output, or an explicit reported upgrade error must fail closed.
- Add repository tests for first run, not-yet-due restart, exact/overdue execution, zero-marketplace success, command failure, JSON-reported error, malformed state, interruption/failure not advancing success, and bounded retry without wall-clock waiting.
- Add only the source-validation wiring needed to execute these deterministic tests when appropriate.

### Excluded

- s6 service files/user-bundle registration and Dockerfile service installation (CMAU-M02).
- Candidate/live container validation (CMAU-M03).
- Any live/persistent marketplace mutation, container recreate, deployment, or release integration.
- Changes to individual marketplace/plugin repositories.

## Acceptance

- Due-time behavior is deterministic for fresh, before-due, exact-due and overdue states.
- The refresh command is a single all-marketplace invocation with no marketplace-name argument.
- A valid zero-marketplace JSON result is accepted as success.
- Last-success advances only after verified command + JSON success and is written atomically.
- Command failure, explicit JSON error, malformed JSON/state, or interrupted refresh cannot create a false successful timestamp.
- Failure follows a bounded non-busy retry path.
- Diagnostics are emitted to process stdout/stderr without secret/context injection.
- Tests use injected/fake command/time/sleep seams and require neither network nor 24-hour waits.

## Required tests / checks

- Scheduler unit/component tests covering every acceptance case above.
- `python3 -m py_compile` (or equivalent syntax/import validation) for the updater/test module.
- Existing `scripts/validate-source.sh` after any validation wiring change that is runnable in the verification environment; otherwise record the exact unavailable dependency and run the affected deterministic checks directly.
- Source inspection confirming no credential material or live-write path was introduced.

## Optional execution hints

- Priority: HIGH
- Complexity: MEDIUM
- Phase: scheduler core
- Expected/relevant code locations:
  - `scripts/container/`
  - `scripts/test-*.py`
  - `scripts/validate-source.sh`

## External write/readback needs

Repository writes on `feat/codex-marketplace-auto-update` only. No live runtime/persistent marketplace write is authorized by this Card.

## Independent review

`RECOMMENDED` — scheduling, persistent-state and failure semantics are implementation-shaping and benefit from an independent exact-subject check before terminal Card completion.

## Contract overrides

None.
