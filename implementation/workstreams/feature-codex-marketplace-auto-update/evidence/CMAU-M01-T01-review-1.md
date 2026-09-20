# CMAU-M01-T01 independent review — attempt 1

Date: `2026-09-20`
Review subject: `elmakus/chatgpt-ce-workstation@b769cf49e8e9dd3a5780c6b333e1990974bc6b31`
Verdict: **RED**

## Authority checked

- Stable Card: `implementation/workstreams/feature-codex-marketplace-auto-update/cards/CMAU-M01-T01.md`.
- Card requirement: failure never advances last-success state.
- Card acceptance: interrupted/failing refresh paths must not create a false successful timestamp.
- Definition requirements: CMAU-REQ-002..007, CMAU-REQ-010..012, CMAU-REQ-016.
- Accepted architecture: D3, D8, D10, D14, D17, D24.
- Milestone: CMAU-M01 deterministic scheduler core.

## Subject/evidence checked

- Exact immutable implementation subject `b769cf49e8e9dd3a5780c6b333e1990974bc6b31`.
- `scripts/container/codex_marketplace_updater.py`.
- `scripts/test-codex-marketplace-updater.py`.
- `scripts/validate-source.sh`.
- Implementation evidence for CMAU-M01-T01.
- Current upstream Codex CLI source/test evidence confirms the all-marketplace command and JSON success shape used by the implementation: `plugin marketplace upgrade --json` returns `selectedMarketplaces`, `upgradedRoots`, and `errors`, and zero configured marketplaces is a successful no-op.

## RED finding

### F1 — post-replace directory-fsync failure reports failure after last-success has already advanced

`atomic_write_last_success()` performs `os.replace(temp_path, state_path)` and only then fsyncs the parent directory. If that directory fsync raises `OSError`, the exception propagates to `run_cycle()`, which returns `CycleResult(status="failure", ...)` and logs that last-success is unchanged.

At that point the rename has already replaced the state file, so the last-success timestamp can in fact be advanced while the cycle reports the failure path.

Independent fault injection against the reviewed logic reproduced:

- previous state: `{"lastSuccessUnix": 10.0}`
- successful marketplace command completion time: `100123.0`
- injected failure: second `os.fsync` (directory fsync) raises `OSError`
- returned result: `CycleResult(status="failure", sleep_seconds=99)`
- resulting state: `{"lastSuccessUnix":100123.0}`

This violates the Card's failure-state invariant and makes the failure diagnostic false.

The existing interruption regression test injects failure at `os.replace`, so it does not cover the post-replace commit-point case.

## Corrective classification

Bounded L1/L2 implementation correction inside the existing CMAU-M01-T01 authority. No Definition, decision, milestone-plan, external-write, or research change is required.

Correction must make the persistence commit point explicit so a post-replace directory-fsync error cannot yield the contradictory state "cycle failure + advanced last-success". Add a deterministic regression test for this exact case and rerun the Card's compile/deterministic checks.
