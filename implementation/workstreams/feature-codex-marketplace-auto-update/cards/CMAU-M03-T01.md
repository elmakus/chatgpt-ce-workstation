# CMAU-M03-T01 — Candidate runtime validation and release readiness

- Milestone: `CMAU-M03`

> This file is a stable Task Card contract. Mutable execution/review/result state lives only in `implementation/workstreams/feature-codex-marketplace-auto-update/TASK_BOARD.yaml`.

## Authority slice

- Master Plan / milestone contract: `planning/CODEX_MARKETPLACE_AUTO_UPDATE_PLAN.md#milestone-cmau-m03--runtime-validation-and-release-readiness`
- Requirements: `requirements/CODEX_MARKETPLACE_AUTO_UPDATE.md` — CMAU-REQ-001..016
- Accepted decisions: `docs/DECISIONS.md` — D3, D6, D8, D10, D14, D15, D17, D24
- Accepted dependency result: `implementation/workstreams/feature-codex-marketplace-auto-update/handoffs/CMAU-M02_HANDOFF.md`
- Relevant OpenSpec: none

### Must preserve

- Validate the exact repository-built candidate, not an ad-hoc live patch.
- The updater remains one independent s6-overlay service, runs as `codex`, uses persistent `/home/codex`, and invokes CE's bundled Codex runtime.
- Cadence remains 24 hours from persisted last successful refresh; restart/recreate before due must not refresh again.
- A due refresh must advance success state only after verified success.
- Failure must leave last-success unchanged, retry non-busily, and remain isolated from desktop/Workstation health.
- Zero configured Git marketplaces remains a successful no-op.
- Candidate validation must use isolated/disposable state and must not mutate the user's live persistent Codex marketplace configuration.
- No new credential material or standalone Codex installation may be introduced.

### Must not / rationale that must travel

- Do not recreate/replace the live production Workstation container in this Card without explicit user authorization.
- Do not use the user's production `/home/codex` or production marketplace configuration as the candidate test state.
- Do not add artificial source changes solely to make runtime validation easier; controlled runtime fixtures/isolated state are allowed.
- Do not treat a local/disposable candidate as proof of a different production environment beyond the checks actually performed.

## Dependencies

- `CMAU-M01` GREEN.
- `CMAU-M02` GREEN at accepted implementation subject `51d9cf2463c03c15dde6ae0c09965fc6ba572ab8`.

## Outcome

An exact repository-built disposable candidate demonstrates the complete marketplace updater behavior required for release readiness: service presence and runtime identity, bundled-Codex execution, first-run success, persisted not-yet-due behavior across restart/recreate, controlled due refresh, controlled failure without state corruption or desktop/health coupling, and sufficient durable evidence for final independent review/integration.

## Scope

### Included

- Build the candidate image from one exact workstream commit using normal repository tooling.
- Run a disposable candidate container with isolated persistent home/project/secrets or equivalent isolated fixture state.
- Verify the updater s6 service exists, is registered/running, and executes under user `codex` with `HOME=/home/codex`.
- Exercise a zero-marketplace first-run refresh through the real bundled Codex path and verify successful persisted updater state.
- Restart/recreate the disposable candidate against the same isolated home before due and verify no extra refresh/state advance.
- Force a due state by controlled timestamp/state adjustment and verify another successful refresh advances persisted success state.
- Exercise a controlled failing command/refresh path against isolated state and verify last-success is unchanged, retry behavior is bounded, and workstation desktop/health remains unaffected.
- Re-run applicable source validation and capture exact runtime commands/readback in durable evidence.
- Preserve or clean up only disposable candidate artifacts when cleanup is unambiguously safe.

### Excluded

- Live production Workstation recreate/cutover.
- Persistent mutation of the user's real Codex marketplace configuration or credentials.
- Changes to marketplace/plugin repositories.
- Workstream final integration/merge to `main` (owned by Close after this Card and review).

## Acceptance

- Candidate image/source identity is exact and durably recorded.
- The updater service is present/running under `codex` with persistent `HOME=/home/codex`.
- Real bundled Codex invocation succeeds in an isolated zero-marketplace state and writes a valid last-success timestamp.
- Restart/recreate before due preserves the timestamp and does not trigger another refresh.
- Controlled due-state execution performs another successful refresh and advances last-success.
- Controlled failure leaves the prior success timestamp unchanged and demonstrates bounded retry semantics without making desktop/Workstation health fail.
- Runtime evidence shows the bundled Codex executable used by the updater and no standalone CLI/credential path was introduced.
- Full applicable source validation remains GREEN.
- No production/live persistent marketplace state was mutated.

## Required tests / checks

- `bash scripts/validate-source.sh` on the exact candidate source when runnable.
- Candidate build completes from the exact recorded commit.
- s6 runtime/status/process ownership inspection for `codex-marketplace-updater`.
- Process/environment/readback proving runtime user and `HOME=/home/codex`.
- First-run state-file readback and timestamp capture.
- Restart/recreate-before-due readback proving timestamp unchanged.
- Controlled due-state readback proving timestamp advances only after success.
- Controlled failure-path readback proving timestamp unchanged, bounded retry result, and healthy/independent desktop substrate.
- Final container/image/source identity readback sufficient to bind evidence to the exact candidate.

## External write/readback needs

Authorized without further user input:
- repository writes on `feat/codex-marketplace-auto-update`;
- disposable candidate image/container creation;
- isolated temporary/persistent fixture directories used only by the candidate;
- cleanup of those disposable artifacts only when their identity is unambiguous.

Explicit user authorization is required before:
- recreating/replacing the live production Workstation;
- writing to the user's real persistent Codex marketplace configuration/home for validation.

Every material candidate write must be followed by concrete readback/verification.

## Independent review

`RECOMMENDED` — this is the final feature-candidate runtime validation Card. The independent review should judge the exact candidate source plus durable runtime evidence against CMAU-REQ-001..016 and the integrated CMAU-M01..M03 acceptance surface before terminal completion/final integration.

## Contract overrides

None.
