# M03 cumulative handoff — smart upstream updates

## Completed checkpoint

M03 — Safe promote/verify/rollback updater

Final implementation head: `ffe39dfcb6ac5584af9410feee5eab5f81b008cc`

## Achieved state

- `scripts/update.sh` owns the normal resolve/freeze -> source validation/preflight -> exact candidate build/readback -> exact promotion -> health/runtime verification lifecycle.
- The previous known-working image identity is retained before promotion and deterministic rollback is attempted after post-promotion failure.
- Successful rollback is verified and remains an update failure, not a false success.
- Rollback failure is explicit and records best-effort actual recovery state: readback classification, current container ID, running state, health state and actual image ID.
- Pre-promotion failure paths are proven not to recreate production.
- Timestamp/random/global-no-cache freshness is absent from the normal updater path.

## Authority and evidence

Authority:
- `planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md#milestone-m03--safe-promoteverifyrollback-updater`
- requirements R1, R2, R9-R16
- decisions D4, D5, D10, D15, D16, D25

Acceptance:
- exact M03 subject: `ffe39dfcb6ac5584af9410feee5eab5f81b008cc`
- CI #162 / run `35486258531`: GREEN, including isolated updater orchestration, source validation, noVNC, ShellCheck, Dockerfile checks and secret scan
- exact candidate build #27 / run `35486258589`: GREEN with candidate provenance readback
- REQUIRED independent M03-T02 review: GREEN at `implementation/workstreams/feature-smart-upstream-updates/evidence/M03-T02-correction-review.md`
- no real production updater invocation, Compose recreate, promotion or live rollback occurred during M03

## Next durable starting point

Next approved milestone: M04 — Production activation and live fault-injection verification.

M04 remains behind the explicit deployment/live-write authorization gate from the Master Plan. No action that recreates the currently running workstation, changes its production image or deliberately triggers live rollback is authorized by M03 completion alone.
