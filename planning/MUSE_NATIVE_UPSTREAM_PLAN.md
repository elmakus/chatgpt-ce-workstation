# Muse native upstream integration plan

Status: **draft**
Revision: **R7**
Date: 2026-09-21
Review requirement: **RECOMMENDED**

## Authority

- Requirements: `requirements/MUSE_NATIVE_UPSTREAM.md` R2
- Decisions:
  - `docs/DECISIONS.md#d29--muse-is-an-optional-parallel-native-upstream-through-cliproxyapi`
  - `docs/DECISIONS.md#d30--muse-bound-codex-turns-intentionally-omit-gmail-tools`
- Workstream: `change-muse-native-upstream`
- Prior approved plan: R5
- Superseded unreviewed draft: R6
- Research evidence: `implementation/workstreams/change-muse-native-upstream/research/R1.md`

## Baseline

Completed work from R5 remains accepted:

- Workstation optional Muse endpoint wiring and persistent secret placement are complete.
- `elmakus/codex-chatgpt-web` v5.0.14 contains the reviewed CLIProxyAPI catalog-shape correction and is installed through the D25 Workstation image.
- Current production Workstation image is `sha256:ce07c414c1442bae243689a17fb32310eed457cb38c52e89394899b9a0289b42`.
- Ordinary `gpt-5.6-sol`, `chatgpt-web/*`, source validation and runtime verification are GREEN.
- Production Muse activation is currently rolled back: `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` is unset, catalog contains zero `muse-*` rows, native upstream is unchanged, route status has zero errors, and `WORKSTATION_RUNTIME_GREEN`.

R1 isolated the remaining normal-client failure. A current Codex turn advertises the Gmail plugin as namespace `mcp__codex_apps__gmail`; four nested Gmail actions contain a self-recursive `#/$defs/GmailMessagePartRequest`, and Meta/Muse rejects that schema. The same Muse route succeeds when the incompatible Gmail namespace is absent.

The operator has now explicitly accepted the D30 capability reduction: Gmail may be unavailable for Muse. Therefore R6's strategy of changing CLIProxyAPI/Meta is no longer required and no production CLIProxyAPI mutation is planned.

Source inspection of the current v5.0.14 fork shows that `src/native-passthrough.ts` already decodes the Responses body before calling the network-routing layer, while `src/native-network.ts` selects `muse-*` versus ordinary native upstream. This provides a bounded fork-owned point to remove only the Gmail namespace for Muse-bound requests without adding logic to Workstation or touching CLIProxyAPI.

## Milestone M01 — Complete the optional Muse route with the accepted Gmail exception

### Outcome

A corrected `codex-chatgpt-web` release routes `muse-*` through CLIProxyAPI while omitting only `mcp__codex_apps__gmail` from Muse-bound Responses requests. Production then exposes usable Muse models; ordinary native/Codex-LB and browser-backed routes retain their existing behavior and Gmail capability.

### Planned work

0. Preserve completed and currently safe state:
   - keep production Muse unset until the new fork release is reviewed, published, consumed and preflighted;
   - retain v5.0.14/D25 evidence, native upstream, persistent Muse key and rollback baseline;
   - do not mutate CLIProxyAPI.

1. Implement the Muse-only Gmail filter in `elmakus/codex-chatgpt-web`:
   - on a Responses request whose validated model is `muse-*`, remove tool entries matching `type: "namespace"` and `name: "mcp__codex_apps__gmail"`;
   - preserve order and content of every other tool entry;
   - if the Gmail namespace is absent, preserve request semantics without unrelated mutation;
   - leave non-Muse native requests unchanged, including Gmail;
   - leave browser-backed `chatgpt-web/*` behavior unchanged;
   - when body rewriting is required, handle existing compressed/decoded request semantics correctly and do not forward a stale `content-encoding` header;
   - add focused unit/regression tests using the exact R1 namespace shape plus controls proving non-Gmail Muse tools and native requests are unchanged.

2. Review and publish an immutable corrected fork release:
   - run the fork's required test/verify/package gates;
   - independently review the exact correction subject when required by that repository/workstream;
   - prepare a version-only release candidate after behavioral acceptance;
   - publish an immutable release with exact commit/artifact checksum evidence;
   - preserve v5.0.14 as the behavioral rollback baseline until the new release is accepted.

3. Consume the corrected release through Workstation D25:
   - use the repository-owned `resolve -> freeze -> build -> validate -> promote` path;
   - require exact release/checksum provenance, candidate validation, health/runtime verification and deterministic rollback;
   - do not change the native upstream or provision a new Muse credential.

4. Activate Muse:
   - recheck persistent Muse key metadata/readability without printing it;
   - set only `CODEX_CHATGPT_WEB_MUSE_UPSTREAM=http://192.168.2.104:8317/v1`;
   - recreate Workstation through repository-owned Compose using the exact frozen resolution for the promoted image.

5. Final verification:
   - direct CLIProxyAPI catalog remains healthy;
   - Workstation catalog imports exactly available `muse-*` rows and no CLIProxyAPI non-Muse rows;
   - ordinary `gpt-5.6-sol` request remains GREEN through Codex-LB;
   - a normal Codex client `muse-*` turn is GREEN with the real tool surface except Gmail;
   - secret-safe request evidence proves the Muse-forwarded tool list omits `mcp__codex_apps__gmail` and still contains representative non-Gmail tools;
   - a native control proves Gmail remains available on ordinary native/Codex-LB requests;
   - browser-backed `chatgpt-web/*` remains GREEN;
   - source validation, route status, health and `WORKSTATION_RUNTIME_GREEN` remain GREEN;
   - no credential value is emitted or committed.

### Rollback

If the corrected fork/release introduces a regression before Muse activation, retain/restore the current v5.0.14 Workstation baseline through D25 rollback and keep Muse unset.

If final Muse activation fails acceptance, unset `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` and recreate the same frozen Workstation image/resolution. Verify native upstream unchanged, zero Muse rows, ordinary native + `chatgpt-web/*` retained, clean route status and `WORKSTATION_RUNTIME_GREEN`.

The persistent Muse key may remain dormant.

### Authorization

The operator's explicit D30 choice authorizes the Muse-only Gmail capability reduction.

Existing workstream authorization covers the related-fork correction/review/release and the already-approved Workstation D25 update plus endpoint recreate inside D29. No CLIProxyAPI production change is required by R7.

### Requirement coverage

- R1, R5 → completed Compose/example wiring plus final production readback.
- R2 → fork-owned model routing; Workstation does not duplicate routing.
- R3 → existing persistent separate key, metadata-only verification.
- R4 → reviewed v5.0.14 catalog correction/failure isolation plus final live catalog verification.
- R6 → native/catalog/browser route preservation and secret hygiene.
- R7 → exact Muse-only Gmail namespace omission, normal Muse turn success, non-Gmail preservation and native Gmail control.

## Planning audit

GREEN for review.

R7 incorporates the operator's explicit Definition change rather than hiding capability loss as an implementation workaround. It removes R6's unnecessary CLIProxyAPI correction/deployment path and uses the smallest existing fork-owned request boundary that can enforce the accepted Muse-only exception.

The design is fail-safe and narrowly scoped: production Muse remains disabled until the new release is accepted; the filter is selected by validated `muse-*` model identity; only the Gmail namespace is removed; non-Muse routes and non-Gmail Muse tools remain unchanged.

Independent plan review is RECOMMENDED because R7 materially changes the execution strategy and acceptance surface relative to approved R5.
