# Muse native upstream integration plan

Status: **approved**
Revision: **R9**
Date: 2026-09-21
Review requirement: **RECOMMENDED**

## Authority

- Requirements: `requirements/MUSE_NATIVE_UPSTREAM.md` R2
- Decisions:
  - `docs/DECISIONS.md#d29--muse-is-an-optional-parallel-native-upstream-through-cliproxyapi`
  - `docs/DECISIONS.md#d30--muse-bound-codex-turns-intentionally-omit-gmail-tools`
- Workstream: `change-muse-native-upstream`
- Prior approved plan: R8
- New research: `implementation/workstreams/change-muse-native-upstream/research/R4.md`
- Blocker evidence: `implementation/workstreams/change-muse-native-upstream/evidence/M01-T18-recursive-schema-blocker.md`

## Baseline

Completed R8 work remains accepted:

- `codex-chatgpt-web` v5.0.16 is released from exact reviewed commit `d7c9db70cf1d54029c061490d73335146a23ed28`.
- The promoted Workstation image is `sha256:9ede8f1f522a710707acac32d01fd8c4d7671b91912791e299d1c635d964b893`.
- The fork already applies two reviewed Muse-only compatibility rules: exact Gmail namespace omission and exact `web_search.search_content_types` omission.
- D25 consumption, ordinary native routing and Muse-only catalog filtering were GREEN.
- R3 proved HTTP 426 is the expected WebSocket-to-HTTP fallback signal.

M01-T18 then exposed a third genuine compatibility boundary. A real Codex Desktop conversation using `Muse Spark 1.3 Contributor` failed with `invalid_request_error`, `param: parameters`, and `Recursive JSON schemas are not currently supported`.

R4 establishes that Meta/Muse rejects recursive tool JSON Schemas as a general class. Exact installed Codex 0.155.0-alpha.9.2 intentionally preserves local `$ref` and reachable `$defs` / `definitions` for ordinary Responses-compatible providers. `openai/codex#44144` independently reports the same Desktop + Muse failure, and no upstream Codex fix was found.

The Tower host went offline before the required M01-T18 rollback completed. Production therefore MUST NOT be assumed Muse-disabled yet.

## Milestone M01 — Complete the optional Muse route with bounded provider compatibility

### Outcome

The next corrected fork release must keep all three Muse compatibility rules inside the existing fork boundary:

1. omit the accepted Gmail namespace;
2. preserve exact `web_search` while omitting only `search_content_types`;
3. keep affected non-Gmail tools available while replacing only provider-unsupported recursive local JSON-Schema cycles with a non-recursive representation.

Ordinary native/Codex-LB tool schemas and browser-backed `chatgpt-web/*` behavior remain unchanged. Final acceptance requires a real Codex Desktop Muse turn using the actual Desktop-managed tool surface.

### Planned work

#### 0. Restore the safe v5.0.16 baseline

This is the first target-host mutation when Tower becomes reachable and a hard gate before further production execution.

- Read back running image and native/Muse endpoint state.
- Set only `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` to empty.
- Recreate with repository-owned Compose using the same frozen v5.0.16 image/resolution; do not rebuild or re-resolve.
- Verify exact image `sha256:9ede8f1f522a710707acac32d01fd8c4d7671b91912791e299d1c635d964b893`, unchanged native upstream, healthy container, normal catalog reconciliation and `WORKSTATION_RUNTIME_GREEN`.
- Do not print or rotate the persistent Muse key.

#### 1. Add bounded Muse-only recursive-schema normalization in the related fork

Use the existing decoded Responses-body boundary in `src/native-passthrough.ts`.

Stable behavior contract:

- apply only to endpoint `responses` with validated model `muse-*`;
- inspect only JSON-Schema surfaces inside the request tool tree, not arbitrary request/history/user content;
- keep the two existing Muse rules unchanged and composable;
- resolve local JSON Pointer refs within the same schema document, including `$defs` / `definitions`;
- inline resolvable non-recursive refs while preserving non-recursive shape and `$ref` sibling constraints;
- track the active ref-expansion path;
- when expansion re-enters a ref already on the active path, replace **only that recursive occurrence** with a permissive schema node;
- remove definition tables no longer needed after successful inlining so recursive local ref graphs are not forwarded to Muse;
- do not silently widen unresolved, malformed or non-local refs;
- preserve tool identity, ordering, descriptions, required fields, non-recursive properties and unrelated request fields;
- preserve current zstd/decode/re-serialization semantics;
- leave ordinary native requests byte-preserved whenever no existing bridge rewrite applies;
- leave browser-backed routes untouched.

Exact helper structure is L1 implementation detail.

#### 2. Regression coverage

Cover at minimum:

- self-recursive `$defs`: preserve normal fields, widen only the cycle edge, no recursive local ref remains;
- mutual recursion;
- non-recursive local refs;
- ref siblings;
- nested schema-bearing tool/namespace shapes used by current Codex requests;
- composition with Gmail omission and `web_search.search_content_types` normalization;
- unchanged non-recursive Muse tools;
- unresolved/non-local refs fail closed rather than silently widening;
- ordinary-native recursive-schema byte preservation;
- browser-backed non-interference.

When exact target-host Desktop schema evidence is available, add a representative regression shape without hard-coding a single tool name as the compatibility rule.

#### 3. Review and publish one immutable corrected fork release

- Run focused tests plus the fork's full verify/package/platform gates.
- Independently review the exact behavioral correction when required.
- Prepare only release-coupled version metadata after behavioral acceptance.
- Independently review the exact release candidate when required.
- Publish with exact commit/tag/artifact/checksum provenance.
- Retain v5.0.16 as rollback provenance until final production acceptance.

#### 4. Consume through Workstation D25

Use the repository-owned `resolve -> freeze -> build -> validate -> promote` path. Require exact release/checksum provenance, frozen resolution, candidate validation, health/runtime verification and deterministic rollback. Do not change native upstream, Muse credentials or CLIProxyAPI production.

#### 5. Reactivate Muse

Only after the corrected release is promoted:

- verify Muse key metadata/readability without content;
- set only `CODEX_CHATGPT_WEB_MUSE_UPSTREAM=http://192.168.2.104:8317/v1`;
- recreate using the exact promoted frozen image;
- require health/runtime GREEN before functional acceptance.

#### 6. Final integrated verification

Require all of:

- direct CLIProxyAPI catalog healthy;
- exactly available `muse-*` rows imported, no CLIProxyAPI non-Muse rows;
- ordinary `gpt-5.6-sol` GREEN through Codex-LB;
- a **real Codex Desktop** conversation explicitly using an available `muse-*` model succeeds with the actual Desktop-managed tool surface;
- no toy/debug helper that silently starts on another/default model counts as Muse evidence;
- secret-safe evidence shows Gmail omitted, `web_search` preserved without `search_content_types`, no recursive local schema cycle forwarded to Muse, and representative non-recursive tool/schema structure preserved;
- ordinary-native control preserves its recursive tool schemas and Gmail/web-search shapes;
- browser-backed `chatgpt-web/*` functionally GREEN;
- source validation, route status, container health and `WORKSTATION_RUNTIME_GREEN` GREEN;
- no credential or unrelated private request content in durable evidence.

### Rollback

Before any new correction is consumed, restore the exact v5.0.16 Muse-disabled baseline described above.

If a new fork release or D25 consumption regresses ordinary routes before activation, restore that baseline.

If final activation fails after the corrected release, unset only the Muse endpoint and recreate the same newly promoted frozen image/resolution. Verify native upstream unchanged, Muse absent after normal catalog reconciliation, ordinary native and browser-backed routes retained, clean route status and `WORKSTATION_RUNTIME_GREEN`.

No manual model-cache deletion is part of normal rollback absent new evidence.

### Authorization

Existing Definition authority remains sufficient:

- D29 keeps routing/compatibility in the fork/CLIProxyAPI boundary rather than Workstation.
- D30 already permits another non-Gmail Muse exception when separate verified incompatibility evidence establishes it.
- R4 is that evidence for recursive tool schemas.
- The correction keeps affected tools available and widens only a recursive cycle edge instead of dropping the whole tool/schema.
- Ordinary native, browser-backed behavior, credential boundaries and CLIProxyAPI production remain unchanged.

R9 is therefore a material execution-strategy revision inside accepted Definition, not a Definition change.

### Requirement coverage

- R1/R5: reproducible endpoint wiring plus rollback/reactivation readback.
- R2: fork-owned routing/compatibility.
- R3: persistent separate credential; metadata/readability only.
- R4: catalog isolation and final catalog verification.
- R6: ordinary-native/browser preservation and secret hygiene.
- R7: Gmail omission plus independently evidenced web-search and recursive-schema Muse compatibility while retaining non-Gmail tools.

## Planning audit

GREEN for independent review.

R9 is required because production evidence invalidated R8's assumption that two Muse compatibility rules were sufficient. The cycle-only strategy is proportional: multiple independent reports establish recursion as a Meta/Muse class, while cycle-only widening preserves materially more tool semantics than disabling tools or replacing whole schemas.

The immediate rollback gate reflects current reality: Tower is offline and the runtime cannot yet be claimed Muse-disabled. No further production execution may proceed until rollback readback is GREEN.

Independent plan review remains **RECOMMENDED** because R9 materially changes execution strategy and final acceptance surface.
