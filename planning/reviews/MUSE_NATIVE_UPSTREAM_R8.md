# Independent plan review — Muse native upstream R8

Plan revision: R8
Review requirement: RECOMMENDED
Review state: green
Review subject: elmakus/chatgpt-ce-workstation:blob:cfb865fd5d15de13a5cef9db516b86d92c66b088:planning/MUSE_NATIVE_UPSTREAM_PLAN.md
Review evidence: |
  GREEN — exact immutable R8 blob matches the current workstream plan and stays inside approved MUSE_NATIVE_UPSTREAM R2 plus D29/D30.
  R2 independently isolates the incompatibility to `web_search.search_content_types`: the same Muse route rejects `type: "web_search"` with that property and succeeds when only that property is absent. R8 therefore preserves the `web_search` tool, all unrelated properties/tools, the accepted Muse-only Gmail omission, and avoids unsupported broad normalization, `web_search_preview` rewriting, Workstation filtering, or CLIProxyAPI production mutation.
  The v5.0.15 fork source confirms the existing Muse-only decoded Responses-body rewrite boundary, model/endpoint guards, no-op byte preservation, and content-encoding cleanup that R8 proposes to extend rather than replace.
  Sequencing is safe and dependency-complete: retain the healthy Muse-disabled rollback baseline; implement and regression-test the bounded fork correction; independently review/release the immutable fork subject; consume it through D25 resolve -> freeze -> build -> validate -> promote; only then activate Muse and run live acceptance.
  Acceptance covers Muse catalog filtering, normal Codex-LB routing, a real Muse client turn, secret-safe forwarded-request proof of Gmail omission plus property-only web-search normalization and representative non-Gmail preservation, ordinary-native unchanged controls, browser-backed behavior, source/runtime health, and credential hygiene.
  Rollback remains deterministic to the same frozen healthy Workstation baseline with Muse unset; R2 supports normal cache self-reconciliation without destructive cache deletion.
  Active Task Board state is coherent with the replan: M01 remains in progress, prior M01-T13 is blocked on the exact R2-resolved incompatibility, and R8 deliberately leaves Card-level supersession/decomposition to Execution Prep rather than embedding premature JIT detail.
  No unresolved strategic/product authority, migration/data-integrity/security gap, authorization-gate omission, or OpenSpec boundary requiring plan correction was found.

## Authority

- Approved requirements: `requirements/MUSE_NATIVE_UPSTREAM.md` R2
- Accepted decisions:
  - `docs/DECISIONS.md#d29--muse-is-an-optional-parallel-native-upstream-through-cliproxyapi`
  - `docs/DECISIONS.md#d30--muse-bound-codex-turns-intentionally-omit-gmail-tools`
- Research evidence: `implementation/workstreams/change-muse-native-upstream/research/R2.md`
- Active execution state: `implementation/workstreams/change-muse-native-upstream/TASK_BOARD.yaml`

## Review purpose

Independently verify that R8 stays inside the accepted Definition while adding only the evidence-supported Muse `web_search.search_content_types` normalization, preserves the `web_search` tool and every unrelated tool/property, keeps Workstation and CLIProxyAPI production unchanged, retains independent fork-review/release and D25 provenance gates, and preserves safe rollback plus ordinary-native/browser behavior.
