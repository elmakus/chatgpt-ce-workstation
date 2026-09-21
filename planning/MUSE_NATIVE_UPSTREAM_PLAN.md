# Muse native upstream integration plan

Status: **draft**
Revision: **R6**
Date: 2026-09-21
Review requirement: **RECOMMENDED**

## Authority

- Requirements: `requirements/MUSE_NATIVE_UPSTREAM.md` R1
- Decision: `docs/DECISIONS.md#d29--muse-is-an-optional-parallel-native-upstream-through-cliproxyapi`
- Workstream: `change-muse-native-upstream`
- Prior approved plan: R5
- Execution/Research evidence:
  - `implementation/workstreams/change-muse-native-upstream/evidence/M01-T07-hook-repair-checkpoint.md`
  - `implementation/workstreams/change-muse-native-upstream/research/R1.md`

## Baseline

The accepted system boundary remains unchanged: Workstation owns reproducible endpoint/credential lifecycle, `codex-chatgpt-web` owns parallel model routing/catalog filtering, and CLIProxyAPI owns Meta/Muse provider compatibility before forwarding requests to Meta.

Completed R5 work remains accepted and is not repeated:

- Workstation repository wiring for optional `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` is complete and source validation is GREEN.
- The persistent Muse ingress key exists outside Git/`.env` with restrictive metadata; its value has not been emitted.
- Related fork `elmakus/codex-chatgpt-web` v5.0.14 was independently reviewed, published and consumed through D25.
- Production Workstation image `sha256:ce07c414c1442bae243689a17fb32310eed457cb38c52e89394899b9a0289b42` is healthy and embeds the corrected v5.0.14 catalog behavior.
- The unrelated Interrupt-hook drift encountered during activation was repaired without changing unrelated Codex configuration and is preserved as a separate deferred issue workstream.
- With Muse temporarily activated, direct CLIProxyAPI catalog and Workstation catalog isolation were GREEN, ordinary `gpt-5.6-sol` was GREEN, browser-backed `chatgpt-web/high` was GREEN, and a minimal tool-free Muse Responses request was GREEN.

R1 Research identified the remaining production blocker:

- a normal current Codex turn contains 33 tool entries;
- the only top-level tool bundle that independently triggers Meta/Muse HTTP 400 `Recursive JSON schemas are not currently supported` is `mcp__codex_apps__gmail`;
- the exact incompatible actions are `_create_draft`, `_forward_emails`, `_send_email` and `_update_draft`;
- each uses a self-recursive `#/$defs/GmailMessagePartRequest` whose `parts[]` items refer back to the same definition;
- a non-recursive Gmail control action succeeds through the same route.

The deployed CLIProxyAPI baseline is `eceasy/cli-proxy-api:v7.3.4` (image `sha256:83c752d7e98c4b818691fcaede7b17a8ad8a4dd93b520764345949d993c4548d`). Source readback at upstream tag `v7.3.4` shows the Meta executor does not invoke the existing Codex tool-schema normalizer. CLIProxyAPI already owns provider-side tool-schema compatibility helpers for other incompatibilities, making the Meta provider boundary the correct place to resolve this defect.

Because normal native-Codex Muse acceptance failed, the R5 rollback contract has been applied:

- `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` is unset in production;
- the same frozen Workstation image was recreated without rebuild;
- native upstream is unchanged;
- local catalog is HTTP 200 with zero `muse-*`, `gpt-5.6-sol` present and `chatgpt-web/high|light|medium` present;
- route status has zero errors;
- `WORKSTATION_RUNTIME_GREEN`;
- tracked checkout is clean.

## Milestone M01 — Make the optional Muse upstream production-ready and deploy it

### Outcome

CLIProxyAPI/Meta accepts the normal Codex request shape needed for Muse without silently corrupting tool semantics; Workstation then re-enables the already-corrected parallel Muse route and proves normal native, normal Muse and browser-backed turns remain functional and isolated.

### Planned work

0. Preserve accepted completed state:
   - retain completed Workstation wiring, v5.0.14 fork/release/D25 evidence and the dormant persistent Muse key;
   - keep production Muse endpoint unset until the provider-compatibility gate below is GREEN;
   - keep primary native/Codex-LB and `chatgpt-web/*` behavior unchanged.

1. Correct Meta/Muse tool-schema compatibility at the CLIProxyAPI provider boundary:
   - use the exact R1 recursive Gmail fixture as regression evidence;
   - first establish, in an isolated test surface, which representation of the recursive `GmailMessagePartRequest` Meta accepts while preserving the useful message-part semantics;
   - implement the smallest Meta-specific/provider-compatible normalization only when semantic equivalence or a bounded semantics-preserving representation is demonstrated;
   - reuse/refine CLIProxyAPI's existing schema traversal/normalization infrastructure where appropriate rather than creating a second router/adapter in Workstation or `codex-chatgpt-web`;
   - preserve non-Meta providers and non-recursive tool schemas byte-for-byte/semantically as applicable;
   - add regression coverage proving the recursive Gmail actions no longer abort a normal Muse-bound request and that ordinary non-recursive tools remain unchanged;
   - run the owning CLIProxyAPI source/release verification before any production consumption.

   If Meta cannot represent the recursive tool contract without capability loss, **do not** silently strip, truncate or hide Gmail tools. Return to Project Definition to decide whether a Muse-specific capability reduction is acceptable.

2. Obtain and freeze an immutable corrected CLIProxyAPI artifact:
   - identify the exact source/release/image that contains the accepted Meta compatibility correction;
   - bind evidence to its exact source identity and immutable image/package digest rather than a floating tag alone;
   - preserve the current v7.3.4 image identity as rollback baseline until the corrected provider artifact is accepted.

3. Deploy the corrected CLIProxyAPI artifact only after the required external-write gate:
   - production replacement/recreate of the operator-managed CLIProxyAPI container is a separate live provider write and requires explicit user authorization when due;
   - preserve its existing authentication/configuration and do not expose credentials;
   - after deployment, directly verify the provider with the recursive Gmail namespace/request shape before re-advertising Muse through Workstation;
   - if provider verification fails, restore the known v7.3.4 baseline and keep Workstation Muse unset.

4. Re-activate Muse through the already-corrected Workstation path:
   - recheck exact Workstation image/frozen resolution and persistent key metadata;
   - set only `CODEX_CHATGPT_WEB_MUSE_UPSTREAM=http://192.168.2.104:8317/v1`;
   - keep `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM` unchanged;
   - recreate through repository-owned Compose using the exact frozen resolution environment, without an unnecessary Workstation rebuild.

5. Final production verification:
   - direct authenticated CLIProxyAPI catalog is healthy and public model IDs are recorded without exposing the key;
   - Workstation catalog imports exactly available `muse-*` rows, imports no CLIProxyAPI non-Muse rows, and retains ordinary native plus `chatgpt-web/*`;
   - an ordinary native `gpt-5.6-sol` request succeeds through Codex-LB;
   - a **normal native Codex client** Muse turn succeeds with the recursive Gmail namespace/actions still represented, not merely a tool-free synthetic Responses request;
   - a browser-backed `chatgpt-web/*` request succeeds;
   - catalog failure isolation remains covered by the already-reviewed v5.0.14 evidence;
   - Workstation source validation, frozen-image identity, health and `WORKSTATION_RUNTIME_GREEN` remain GREEN;
   - no secret value is emitted or committed.

### Rollback

Two independent rollback boundaries remain:

1. CLIProxyAPI provider correction:
   - restore the exact known v7.3.4 provider image/configuration if corrected provider deployment fails its direct recursive-schema acceptance;
   - keep Workstation Muse unset.

2. Workstation Muse activation:
   - unset `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` and recreate the same frozen Workstation image/resolution if final activation fails;
   - verify native upstream unchanged, zero Muse catalog rows, ordinary native + `chatgpt-web/*` discovery retained, clean route status and `WORKSTATION_RUNTIME_GREEN`.

The persistent Muse key may remain dormant.

### Authorization

Existing authority continues to cover repository changes and the already-approved Workstation endpoint/recreate lifecycle inside D29.

Replacing/recreating the operator-managed production CLIProxyAPI provider with a corrected artifact is a **separate explicit live-write authorization gate**. Planning and isolated verification may proceed before that gate; production provider mutation may not.

Deliberate production failure injection remains outside authorization and is unnecessary.

## Requirement coverage

- R1, R5 → completed Workstation Compose/example wiring plus final activation/readback.
- R2 → model routing remains owned by `codex-chatgpt-web`; provider request compatibility remains owned by CLIProxyAPI/Meta; Workstation adds neither router nor schema adapter.
- R3 → persistent separate ingress key remains outside Git/`.env`, with metadata-only verification.
- R4 → corrected v5.0.14 catalog normalization/failure-isolation evidence plus final live catalog verification.
- R6 → final native + **normal Muse with real Codex tool surface** + browser-backed smokes, Muse-only catalog filtering, health and secret hygiene.

## Planning audit

GREEN for review.

R6 changes execution strategy only where R1 production evidence proved R5 acceptance insufficient. It does not change the approved requirements, D29 route ownership, authentication separation, catalog isolation, rollback intent or user-visible target state.

The provider compatibility correction is placed at CLIProxyAPI's Meta boundary because that component constructs and forwards the provider request and already owns related tool-schema compatibility normalization. Moving recursive-schema mutation into Workstation would violate D29; silently stripping or flattening the schema in `codex-chatgpt-web` would risk semantic loss outside its accepted routing/catalog responsibility.

The plan deliberately does not prescribe a lossy flattening algorithm before isolated provider evidence proves what Meta can represent. If no semantics-preserving representation exists, the issue becomes Definition-owned rather than being hidden as implementation detail.

Production is fail-safe while R6 is reviewed: Muse is not advertised, the same known Workstation image is healthy, ordinary Sol and browser-backed models remain available, and the CLIProxyAPI live provider has not been mutated.

Independent plan review is RECOMMENDED because R6 materially revises the remaining execution strategy, adds a provider-artifact correction/deployment boundary, and introduces an explicit live-write authorization gate.
