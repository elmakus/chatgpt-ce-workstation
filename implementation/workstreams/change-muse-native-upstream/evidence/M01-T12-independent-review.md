# M01-T12 independent review

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T12`
Verdict: **GREEN**

## Exact reviewed subject

`elmakus/chatgpt-ce-workstation@55c61b0df3e4a09ca36614e4ddcec352499f51e3`

Review owner: workstream Task Board Card review for M01-T12.

## Authority checked

- M01-T12 stable Card contract.
- `planning/MUSE_NATIVE_UPSTREAM_PLAN.md` approved R7, M01 planned work 3.
- `docs/DECISIONS.md#d25--workstation-updates-resolve-latest-stable-identities-before-build`.
- `implementation/workstreams/change-muse-native-upstream/evidence/M01-T11-d25-apt-mirror-blocker.md`.
- exact subject diff and implementation evidence.

## Review findings

GREEN. The subject is limited to `scripts/update.sh` and `scripts/test-update-orchestration.sh` and remains inside the bounded D25 correction authorized by M01-T12.

The updater still resolves and freezes upstreams once before candidate build. `build_candidate()` retries only `build_candidate_once` with the same already-frozen resolution path and unchanged candidate tag; no resolver call exists inside the retry loop. Exact Ubuntu InRelease SHA-256 validation remains unchanged and fail-closed in `scripts/build/assert-ubuntu-apt-identity.sh`.

Retry classification is narrow: a failed candidate build is retried only when that attempt log contains the exact assertion prefix `Ubuntu InRelease SHA-256 mismatch for `. Generic build failures return immediately. Retryable mismatch attempts are bounded to three total builds; exhaustion returns failure to the unchanged caller path, which records `pre_promotion_failed / candidate_build_failed` before any production recreation.

`set -Eeuo pipefail` ensures the `build_candidate_once | tee` pipeline retains the failing build status for retry/terminal handling. No hash broadening, mirror override, stale acceptance, expert pin, resolver re-entry, production mutation, or unrelated D25/Compose change was introduced.

No source/runtime files under `scripts/`, `compose.yaml`, or `Dockerfile` changed after the frozen subject while review-state/evidence commits advanced the branch.

## Independent verification

Run on Tower from the reviewed source tree (later branch commits contained only workflow state/evidence):

- `bash scripts/test-update-orchestration.sh` => `UPDATE_ORCHESTRATION_TESTS_GREEN`
- `bash scripts/validate-source.sh` => `SOURCE_VALIDATION_GREEN`
- focused subject inspection confirms generic build failure is one attempt, transient mismatch may retry to success, repeated mismatch is exactly three attempts with zero recreate, and the success path remains the existing D25 promotion/readback path.

## Verdict

**GREEN** — M01-T12 satisfies its acceptance contract and preserves D25 frozen-identity/fail-closed semantics. M01-T11 may resume through normal workflow routing.
