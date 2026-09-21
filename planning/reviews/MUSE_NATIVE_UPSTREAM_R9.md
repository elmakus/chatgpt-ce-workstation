# Independent plan review — Muse native upstream R9

Plan revision: R9
Review requirement: RECOMMENDED
Review state: in_progress
Review subject: elmakus/chatgpt-ce-workstation:blob:9474cc52951c0481a898b66b45cc2df2312e4722:planning/MUSE_NATIVE_UPSTREAM_PLAN.md
Review evidence: pending

## Authority

- Approved requirements: `requirements/MUSE_NATIVE_UPSTREAM.md` R2
- Accepted decisions:
  - `docs/DECISIONS.md#d29--muse-is-an-optional-parallel-native-upstream-through-cliproxyapi`
  - `docs/DECISIONS.md#d30--muse-bound-codex-turns-intentionally-omit-gmail-tools`
- Research evidence:
  - `implementation/workstreams/change-muse-native-upstream/research/R4.md`
  - `implementation/workstreams/change-muse-native-upstream/evidence/M01-T18-recursive-schema-blocker.md`
- Active execution state: `implementation/workstreams/change-muse-native-upstream/TASK_BOARD.yaml`

## Review purpose

Independently verify that R9:
- remains inside the accepted Definition while adding only the independently evidenced Muse recursive-schema compatibility;
- uses bounded local-ref expansion with cycle-only widening rather than deleting affected non-Gmail tools or broadly rewriting request content;
- preserves the already-reviewed Gmail and web-search rules;
- preserves ordinary native/Codex-LB schema bytes and browser-backed behavior;
- makes restoration of the exact v5.0.16 Muse-disabled baseline the first execution gate because Tower went offline before M01-T18 rollback;
- preserves immutable fork review/release and D25 provenance gates;
- requires final acceptance through a real Codex Desktop Muse turn with the actual Desktop-managed tool surface;
- preserves rollback, catalog isolation, secret hygiene and CLIProxyAPI production boundaries.
