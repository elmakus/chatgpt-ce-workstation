# M01 handoff — managed reconciliation source

Status: **GREEN / complete**
Workstream: `feature-managed-persistent-agents`
Milestone: `M01`

## Completed checkpoint

Accepted implementation subject:
`elmakus/chatgpt-ce-workstation@00c32fa9f34229e2c227352f4891a7a64f119d35`

M01 now provides repository-owned managed global AGENTS reconciliation for fresh seed, bounded managed-block updates, exact known legacy migration, fail-closed ambiguous/malformed handling, content idempotency, source validation, and bounded runtime verification.

No production persistent `~/.codex/AGENTS.md` mutation occurred during M01.

## Authority in force

- `requirements/MANAGED_PERSISTENT_AGENTS.md`
- `docs/DECISIONS.md#D8`
- `docs/DECISIONS.md#D10`
- `docs/DECISIONS.md#D12`
- `docs/DECISIONS.md#D23`
- `planning/MANAGED_PERSISTENT_AGENTS_MASTER_PLAN.md`

## Acceptance / review

- Implementation evidence: `implementation/workstreams/feature-managed-persistent-agents/evidence/M01_T01_MANAGED_AGENTS_2026-09-20.md`
- Independent Card review: GREEN, `implementation/workstreams/feature-managed-persistent-agents/evidence/M01_T01_INDEPENDENT_REVIEW_2026-09-20.md`
- Exact-subject CI run #62 is GREEN, including 9/9 managed-AGENTS fixtures and source validation.

## Next durable starting point

Next approved milestone: `M02 — Production activation and live verification`.

Hard gate: before any deployment/recreate or other action that can rewrite the running workstation's persistent `~/.codex/AGENTS.md`, explicit user authorization for that live write is required. Feature approval, plan approval and M01 GREEN review do not satisfy this gate.
