# M01 handoff — Reference-safe image/tag retention

Milestone: `M01`
Plan revision: `workstation-docker-retention-R1`
Status: **GREEN / done**
Implementation checkpoint: `a3f15c251c4a31787249b6bd5fc69a7e97e4a285`

## Achieved state

The workstation updater now performs bounded image/tag retention only after exact promoted-image, health and runtime verification succeed.

The accepted M01 implementation:
- protects the exact current candidate ref/image identity and the immediately previous rollback ref/image identity;
- considers only workstation lifecycle `candidate-*` / `rollback-*` refs in the candidate repository;
- removes stale refs only with ordinary Docker reference semantics, without force or global prune;
- keeps cleanup failure separate from verified production success;
- records bounded retention cleanup evidence;
- does not implement BuildKit cache GC.

## Acceptance and review

Card `M01-T01` is terminal and its independent RECOMMENDED review is GREEN for exact subject `a3f15c251c4a31787249b6bd5fc69a7e97e4a285`.

Evidence:
- `implementation/workstreams/change-workstation-docker-retention/evidence/M01-T01.md`
- syntax/source/orchestration checks GREEN as recorded there;
- no live Unraid Docker mutation was performed for M01.

## Authority in force

- `planning/WORKSTATION_DOCKER_RETENTION_MASTER_PLAN.md#Milestone-M01--Reference-safe-imagetag-retention`
- `requirements/SMART_UPSTREAM_UPDATES.md#R11` through `R13`
- `requirements/SMART_UPSTREAM_UPDATES.md#R17` through `R19`
- `requirements/SMART_UPSTREAM_UPDATES.md#R21` through `R23`
- `docs/DECISIONS.md#D25`
- `docs/DECISIONS.md#D27`

## Next durable starting point

Proceed to M02 Execution Prep.

M02 must first perform the approved non-destructive JIT technical verification of the actual target Unraid Docker/BuildKit backend before selecting any concrete cache-GC command. If the backend cannot prove workstation-only cache scope, do not fall back to global builder/system prune; route through the workflow for bounded correction.

The explicit live-write/deployment authorization gate remains M04; M02 backend inspection is read-only.
