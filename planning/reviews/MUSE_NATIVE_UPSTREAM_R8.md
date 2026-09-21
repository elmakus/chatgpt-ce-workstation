# Independent plan review — Muse native upstream R8

Plan revision: R8
Review requirement: RECOMMENDED
Review state: in_progress
Review subject: elmakus/chatgpt-ce-workstation:blob:cfb865fd5d15de13a5cef9db516b86d92c66b088:planning/MUSE_NATIVE_UPSTREAM_PLAN.md
Review evidence: null

## Authority

- Approved requirements: `requirements/MUSE_NATIVE_UPSTREAM.md` R2
- Accepted decisions:
  - `docs/DECISIONS.md#d29--muse-is-an-optional-parallel-native-upstream-through-cliproxyapi`
  - `docs/DECISIONS.md#d30--muse-bound-codex-turns-intentionally-omit-gmail-tools`
- Research evidence: `implementation/workstreams/change-muse-native-upstream/research/R2.md`
- Active execution state: `implementation/workstreams/change-muse-native-upstream/TASK_BOARD.yaml`

## Review purpose

Independently verify that R8 stays inside the accepted Definition while adding only the evidence-supported Muse `web_search.search_content_types` normalization, preserves the `web_search` tool and every unrelated tool/property, keeps Workstation and CLIProxyAPI production unchanged, retains independent fork-review/release and D25 provenance gates, and preserves safe rollback plus ordinary-native/browser behavior.
