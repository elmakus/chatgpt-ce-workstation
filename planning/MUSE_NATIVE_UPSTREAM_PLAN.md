# Muse native upstream integration plan

Status: **approved**
Revision: **R8**
Date: 2026-09-21
Review requirement: **RECOMMENDED**

## Authority

- Requirements: `requirements/MUSE_NATIVE_UPSTREAM.md` R2
- Decisions:
  - `docs/DECISIONS.md#d29--muse-is-an-optional-parallel-native-upstream-through-cliproxyapi`
  - `docs/DECISIONS.md#d30--muse-bound-codex-turns-intentionally-omit-gmail-tools`
- Workstream: `change-muse-native-upstream`
- Prior approved plan: R7
- Research evidence: `implementation/workstreams/change-muse-native-upstream/research/R2.md`

## Baseline

Completed and accepted work remains preserved:

- Workstation optional Muse endpoint wiring and persistent secret placement are complete.
- `elmakus/codex-chatgpt-web` v5.0.15 is released from exact reviewed commit `3a6d1d28c28dbe1be885077ae53fe4bba62b9673`.
- The promoted Workstation image is `sha256:7470b64402282c56300ea6225c9d316c475b441878d38d68ff7862b5ff30248f` and embeds that v5.0.15 release.
- M01-T12 updater-retry correction is independently GREEN.
- M01-T13 activation proved catalog filtering and ordinary native routing GREEN, then failed the normal Muse turn on a second provider-specific request incompatibility and rolled production back to the same healthy image with Muse unset.
R2 isolated that incompatibility. Current Codex emits a `type: "web_search"` tool with `search_content_types: ["text", "image"]`. The current CLIProxyAPI/Meta Muse route accepts the same `web_search` tool when that property is absent, but rejects the property with `tools[].search_content_types is only supported for web_search_preview tools.`

This is not a Workstation routing defect and does not require a Definition change. Requirements R2/D30 already preserve non-Gmail Muse tools unless a specific incompatibility is independently verified. R2 provides that evidence for one optional property while proving the web-search tool itself remains usable.

## Milestone M01 — Complete the optional Muse route with bounded provider compatibility

### Outcome

A corrected `codex-chatgpt-web` release routes `muse-*` through CLIProxyAPI while:
- omitting the accepted Gmail namespace from Muse-bound Responses requests;
- preserving the `web_search` tool but omitting its provider-unsupported `search_content_types` property only on Muse-bound Responses requests;
- preserving every other Muse tool and property;
- leaving ordinary native/Codex-LB and browser-backed routes unchanged.

Production then exposes usable Muse models and a normal Muse turn succeeds with the real client tool surface under those verified provider-specific compatibility rules.

### Planned work

0. Preserve the safe baseline:
   - keep production Muse unset until the new fork release is reviewed, published, consumed and preflighted;
   - retain exact v5.0.15, promoted-image, M01-T12 and M01-T13 rollback evidence;
   - keep the native upstream, persistent Muse key and rollback baseline unchanged;
   - do not mutate CLIProxyAPI production as part of this plan.

1. Implement the second bounded Muse-only normalization in `elmakus/codex-chatgpt-web`:
   - use the existing decoded Responses-body boundary in `src/native-passthrough.ts`;
   - apply only when the validated model is `muse-*` and the endpoint is `responses`;
   - preserve every tool entry and its ordering except the already-accepted exact Gmail namespace omission;
   - for a tool whose exact `type` is `web_search`, preserve the tool and all other properties while omitting only `search_content_types`;
   - do not rename `web_search` to `web_search_preview`, disable web search, or drop any other field without new evidence;
   - do not strip `search_content_types` from `web_search_preview` shapes merely for symmetry;
   - preserve existing zstd/decode/re-serialization semantics and remove stale `content-encoding` only when rewriting is actually required;
   - leave ordinary native/Codex-LB requests byte-preserved when no existing bridge rewrite applies;
   - leave browser-backed `chatgpt-web/*` behavior unchanged;
   - add focused regression tests proving the exact Muse `web_search` field omission, preservation of the rest of that tool, composition with Gmail omission, Muse no-op when neither rewrite is needed, preview-shape non-overreach, and ordinary-native controls.

2. Review and publish one immutable corrected fork release:
   - run the fork's required test/verify/package gates on the exact behavioral correction subject;
   - independently review that exact subject when required by the related-fork workflow;
   - after behavioral acceptance, prepare only the version-coupled release metadata needed by the fork's release contract;
   - independently review the exact release candidate when required;
   - publish from the exact accepted candidate with commit/tag/artifact checksum provenance;
   - retain v5.0.15 as rollback provenance until production acceptance is GREEN.

3. Consume the corrected release through Workstation D25:
   - use the repository-owned `resolve -> freeze -> build -> validate -> promote` path;
   - require exact release/checksum provenance, frozen resolution, candidate validation, health/runtime verification and deterministic rollback;
   - do not change the native upstream or provision a new Muse credential.

4. Repeat Muse activation from the healthy rollback baseline:
   - recheck persistent Muse key metadata/readability without printing it;
   - set only `CODEX_CHATGPT_WEB_MUSE_UPSTREAM=http://192.168.2.104:8317/v1`;
   - recreate Workstation through repository-owned Compose using the exact frozen resolution for the promoted image.

5. Final verification:
   - direct CLIProxyAPI catalog remains healthy;
   - Workstation catalog imports exactly available `muse-*` rows and no CLIProxyAPI non-Muse rows;
   - ordinary `gpt-5.6-sol` remains GREEN through Codex-LB;
   - a normal Codex client `muse-*` turn succeeds with the real tool surface under the two verified Muse-only normalizations;
   - secret-safe forwarded-request evidence proves the Gmail namespace is absent, `web_search` remains present, only its `search_content_types` property is absent, and representative other non-Gmail tools remain;
   - an ordinary-native control proves Gmail and current `web_search` shape remain unchanged there;
   - browser-backed `chatgpt-web/*` remains GREEN;
   - source validation, route status, health and `WORKSTATION_RUNTIME_GREEN` remain GREEN;
   - no credential value is emitted or committed.

### Rollback

If the new fork correction/release introduces a regression before Muse activation, retain or restore the exact v5.0.15 Workstation baseline through D25 rollback and keep Muse unset.

If final Muse activation fails acceptance, unset `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` and recreate the same frozen Workstation image/resolution. Verify native upstream unchanged, Muse absent after normal catalog refresh, ordinary native + `chatgpt-web/*` retained, clean route status and `WORKSTATION_RUNTIME_GREEN`.

The persistent Muse key may remain dormant. No manual Codex model-cache deletion is part of normal rollback: R2 verified the stale Muse rows self-reconcile on the normal catalog refresh path.

### Authorization

Existing Definition authority remains sufficient:
- D29 keeps provider/model routing in the existing fork and CLIProxyAPI boundary rather than Workstation.
- D30 permits a non-Gmail Muse compatibility exception when separate verified evidence establishes it.
- R2 provides that evidence only for `search_content_types` on `web_search`, while proving that the tool itself remains supported.

Existing workstream authorization therefore covers the bounded related-fork correction/review/release, the already-approved Workstation D25 update and the endpoint recreate. No CLIProxyAPI production mutation is required by R8.

### Requirement coverage

- R1, R5 → completed Compose/example wiring plus final production readback.
- R2 → fork-owned model routing/compatibility; Workstation does not duplicate provider logic.
- R3 → existing persistent separate key, metadata-only verification.
- R4 → existing catalog isolation plus final live catalog verification.
- R6 → native/catalog/browser preservation, including non-Muse `web_search` shape, and secret hygiene.
- R7 → Muse-only Gmail omission plus the independently evidenced property-level `web_search` normalization, normal Muse success, non-Gmail tool preservation and native Gmail control.

## Planning audit

GREEN for independent review.
R8 is a material execution-strategy revision, not a Definition change. It preserves the approved M01 outcome and repeats the already-established correction -> independent review/release -> D25 consumption -> activation sequence for the newly evidenced provider incompatibility.

The extra complexity is justified by exact production evidence: the real Muse turn cannot pass Meta validation while current Codex's `web_search.search_content_types` field is forwarded unchanged. The correction is deliberately narrower than disabling web search, changing CLIProxyAPI, or adding a generic provider-normalization framework.

Security and rollback boundaries are unchanged. Production remains on the healthy Muse-disabled baseline until the new exact release is accepted. No secret moves into Git or `.env`. The rollback model cache is transient discovery state and requires no destructive cleanup.

Independent plan review remains **RECOMMENDED** because R8 materially changes the approved execution strategy and acceptance surface relative to R7.
