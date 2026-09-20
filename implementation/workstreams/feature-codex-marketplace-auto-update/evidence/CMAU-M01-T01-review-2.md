# CMAU-M01-T01 independent review — attempt 2

Date: `2026-09-20`
Review subject: `elmakus/chatgpt-ce-workstation@15b399ad0bdaf7ed843039be7e402cd75796352b`
Verdict: **GREEN**

## Authority checked

- Stable Card: `implementation/workstreams/feature-codex-marketplace-auto-update/cards/CMAU-M01-T01.md`.
- Milestone: `planning/CODEX_MARKETPLACE_AUTO_UPDATE_PLAN.md#milestone-cmau-m01--deterministic-scheduler-core`.
- Definition: CMAU-REQ-002..007, CMAU-REQ-010..012, CMAU-REQ-016 in `requirements/CODEX_MARKETPLACE_AUTO_UPDATE.md`.
- Accepted architecture: D3, D8, D10, D14, D17 and D24 in `docs/DECISIONS.md`.
- Predecessor RED: `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M01-T01-review-1.md`.

## Subject/evidence checked

- Exact immutable implementation subject `15b399ad0bdaf7ed843039be7e402cd75796352b`.
- `scripts/container/codex_marketplace_updater.py`.
- `scripts/test-codex-marketplace-updater.py`.
- `scripts/validate-source.sh` updater validation wiring.
- Corrective implementation evidence `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M01-T01-implementation-2.md`.
- Independent current upstream Codex source/test evidence at `openai/codex@551844b3efc426c563128b0e011e36dad95a865b`: the upgrade marketplace name is optional and omission targets all configured Git marketplaces; the CLI JSON result contains `selectedMarketplaces`, `upgradedRoots`, and `errors`; zero configured Git marketplaces is a successful no-op.

## Review result

GREEN. The reviewed subject satisfies the CMAU-M01-T01 contract and the bounded defect from review attempt 1 is corrected.

- The atomic rename is now the explicit state-persistence commit point. A parent-directory fsync `OSError` after successful `os.replace()` is diagnostic-only, so the implementation no longer reports the contradictory state "failure + advanced last-success".
- The pre-commit failure path remains fail-closed: an `os.replace()` failure returns bounded retry and preserves the prior last-success state.
- The new deterministic regression covers the exact post-replace directory-fsync case and asserts successful cycle result, committed success timestamp, and no temporary-file residue.
- Due-time behavior, first-run behavior, before-due waiting, exact/overdue execution, all-marketplace command shape, zero-marketplace success, non-zero command failure, JSON-reported error, malformed JSON/state handling, non-mutation on failure, and completion-time persistence are covered by deterministic tests.
- The updater captures subprocess output without logging stdout/stderr contents, adds no credential store or environment dump, and keeps ordinary diagnostics in process logging.
- The default command uses CE's bundled Codex path and omits a marketplace-name argument.
- No s6/image integration, live marketplace mutation, live Workstation recreate, or other CMAU-M02/M03 scope is present in this Card subject.

## Verification limitation

The implementation evidence records GREEN Python compile checks and 14/14 deterministic scheduler tests. Full repository `scripts/validate-source.sh` was not runnable on the implementation execution surface because Docker Compose/full-checkout dependencies were unavailable. This is explicitly permitted by the Card when the unavailable dependency is recorded and the affected deterministic checks are run directly; independent source inspection found no contradiction with that evidence.
