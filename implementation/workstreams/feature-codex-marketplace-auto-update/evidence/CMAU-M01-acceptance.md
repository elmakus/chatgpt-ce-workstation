# CMAU-M01 milestone acceptance

Date: `2026-09-20`
Milestone: `CMAU-M01`
Verdict: **GREEN**
Accepted implementation subject: `elmakus/chatgpt-ce-workstation@15b399ad0bdaf7ed843039be7e402cd75796352b`

## Acceptance basis

- `CMAU-M01-T01` is terminal and its RECOMMENDED independent review is GREEN.
- The deterministic scheduler core satisfies CMAU-REQ-002..007, CMAU-REQ-010..012 and CMAU-REQ-016 for the M01 scope.
- Fresh, not-yet-due, exact-due and overdue cadence behavior is deterministic.
- The default refresh command targets CE's bundled Codex and omits a marketplace name, so all configured Git marketplaces are selected.
- Zero configured Git marketplaces is accepted as a successful no-op.
- Last-success is updated only after verified command + JSON success; pre-commit persistence failure preserves prior state.
- The corrected post-replace directory-fsync path no longer reports a false failure after state has already committed.
- Failure returns a bounded non-busy retry interval and does not couple scheduler failure to desktop/Workstation health.
- Diagnostics remain ordinary process logging; subprocess stdout/stderr and environment dumps are not injected into model/session context.
- Deterministic tests require neither network access nor real 24-hour waits.

## Evidence

- Card implementation evidence: `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M01-T01-implementation-2.md`.
- Independent GREEN review: `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M01-T01-review-2.md`.
- Card result subject: `15b399ad0bdaf7ed843039be7e402cd75796352b`.
- Implementation evidence records Python compile GREEN and 14/14 deterministic scheduler tests GREEN.

## Limitations / deferred scope

- Full repository `scripts/validate-source.sh` was unavailable on the implementation execution surface because the required complete checkout/Docker Compose dependency was unavailable; the Card-authorized direct deterministic checks were run instead.
- s6 registration, image installation, candidate-container validation, live Workstation recreate and persistent live marketplace mutation are outside CMAU-M01 and remain for CMAU-M02/CMAU-M03.
