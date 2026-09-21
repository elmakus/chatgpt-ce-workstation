# Independent plan review — Muse native upstream R7

Plan revision: R7
Review requirement: RECOMMENDED
Review state: green
Review subject: elmakus/chatgpt-ce-workstation:blob:da6f9f4e091e68974d8322108f9761067d4554e2:planning/MUSE_NATIVE_UPSTREAM_PLAN.md
Review evidence: GREEN — exact R7 subject matches approved requirements R2 plus D29/D30. It keeps Muse request filtering fork-owned, removes only the exact `mcp__codex_apps__gmail` namespace for validated `muse-*` Responses requests, preserves every other Muse tool and ordinary native/browser behavior, removes the obsolete CLIProxyAPI mutation path, and retains release provenance, D25 resolve/freeze/build/validate/promote, rollback and secret-hygiene gates. Source audit on the accepted v5.0.14 baseline (`elmakus/codex-chatgpt-web@2686d2a616864a1bc9cd975901773ab16a54ba47`) confirms `native-passthrough.ts` parses the Responses body before `fetchNativeCodex`, strips stale content length on forwarding, `http-body.ts` decodes zstd safely, and `native-network.ts` validates the model hint before selecting the Muse route. Active Task Board/R1 evidence coheres with the plan baseline: production remains rolled back with Muse unset and the earlier fork release/D25 path is GREEN. No false assumption, requirement-coverage gap, authorization gap, migration/rollback defect, data-integrity/security issue, or premature strategic detail requiring correction was found.

## Authority

- Approved requirements: `requirements/MUSE_NATIVE_UPSTREAM.md` R2
- Accepted decisions:
  - `docs/DECISIONS.md#d29--muse-is-an-optional-parallel-native-upstream-through-cliproxyapi`
  - `docs/DECISIONS.md#d30--muse-bound-codex-turns-intentionally-omit-gmail-tools`
- Research evidence: `implementation/workstreams/change-muse-native-upstream/research/R1.md`
- Active execution state: `implementation/workstreams/change-muse-native-upstream/TASK_BOARD.yaml`

## Review purpose

Independently verify that R7 faithfully implements the operator-authorized Muse-only Gmail capability reduction, keeps the filter inside the accepted fork routing boundary rather than Workstation, removes the now-unnecessary CLIProxyAPI mutation path, preserves every non-Gmail Muse tool plus native/browser behavior, and retains exact release/D25/rollback/secret-hygiene gates.
