# Independent plan review — Smart upstream updates R1

Plan revision: smart-upstream-updates-R1
Review requirement: RECOMMENDED
Review state: in_progress
Review subject: elmakus/chatgpt-ce-workstation@b9aac41b7886ddc084b3ba469a1a7687bcf101b1
Reviewed plan: planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md
Review evidence: pending

## Review scope

Independently review the exact immutable plan subject above against:

- approved `requirements/SMART_UPSTREAM_UPDATES.md`;
- accepted `docs/DECISIONS.md#D2`, `#D4`, `#D5`, `#D6`, `#D10`, `#D11`, `#D15`, `#D16` and `#D24`;
- the current workstation build/update baseline referenced by the plan;
- only the upstream/source evidence materially needed to assess feasibility, trust boundaries and update safety.

Audit especially whether the plan:

- preserves Ubuntu 24.04 LTS while making normal upstream policy latest trusted stable/current;
- separates CE Git freshness from the signed OpenAI ChatGPT package freshness without weakening CE's authenticity contract;
- replaces timestamp-only invalidation with reproducible resolved identities;
- states realistic Docker cache semantics rather than promising impossible layer reuse;
- keeps `update.sh` as the one normal updater and `build.sh` as a lower-level exact/development primitive;
- provides inspectable exact candidate provenance without secrets;
- leaves production untouched on resolution/build/pre-promotion failure;
- retains and verifies a deterministic previous-image rollback path on post-promotion failure;
- preserves disabled runtime self-updaters and existing container isolation;
- places real workstation recreate/fault injection behind explicit deployment/live-write authorization;
- covers all approved requirements without freezing vendor-specific mechanisms prematurely.

A GREEN verdict means the plan may be approved and routed to Execution Prep for M01. A RED verdict must identify whether correction belongs to Planning, Project Definition or Research.
