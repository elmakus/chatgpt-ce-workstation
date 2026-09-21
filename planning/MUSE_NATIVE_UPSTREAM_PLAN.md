# Muse native upstream integration plan

Status: **approved**
Revision: **R5**
Date: 2026-09-21
Review requirement: **RECOMMENDED**

## Authority

- Requirements: `requirements/MUSE_NATIVE_UPSTREAM.md` R1
- Decision: `docs/DECISIONS.md#d29--muse-is-an-optional-parallel-native-upstream-through-cliproxyapi`
- Workstream: `change-muse-native-upstream`
- Execution evidence: `implementation/workstreams/change-muse-native-upstream/evidence/M01-T02-live-activation-blocker.md`

## Baseline

The accepted system boundary remains unchanged: `elmakus/codex-chatgpt-web` owns parallel native routing/catalog adaptation, while Workstation owns only reproducible endpoint wiring, persistent credential placement and production lifecycle.

R4 execution established the following durable state:
- Workstation repository wiring is complete: `compose.yaml` passes optional `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` and `.env.example` documents it without a secret; source validation is GREEN.
- The CLIProxyAPI ingress key is persistently installed at the fork-owned `~/.config/codex-web-gpt/muse-proxy-api-key` with owner `99:100` and mode `0600`; its value was never emitted.
- Production runs `codex-web-gpt` v5.0.13 on image `sha256:9a6be62fdab865a9dce65412933acd21d1a944e4c250172ddb8e0afdbceb5248`.
- An authorized activation attempt kept Workstation healthy and preserved ordinary native plus `chatgpt-web/*` discovery, but produced zero `muse-*` rows.
- Live CLIProxyAPI `GET /v1/models` returns the OpenAI-compatible shape `{ object, data: [...] }`, with model identity in `id`; it currently exposes five `muse-*` rows plus 12 non-Muse rows.
- v5.0.13 and current fork `main` pass the raw Muse response to `mergeMuseNativeModelCatalog()`, which requires a `models` array. The optional-catalog error path therefore failure-isolates Muse instead of merging the live CLIProxyAPI rows.
- The latest published fork release remains v5.0.13; no released compatibility correction exists yet.
- Production was rolled back immediately: Muse upstream is unset again, the exact same image is healthy, `WORKSTATION_RUNTIME_GREEN` is restored, and discovery contains 12 ordinary native plus 3 `chatgpt-web/*` rows.
- The already-provisioned Muse key file is left dormant as permitted by the accepted rollback contract.

The v5.0.13 transport/proxy-resolution gate from R4 remains necessary but is no longer sufficient. Any production-ready fork subject must also prove compatibility with the actual CLIProxyAPI model-list contract.

## Milestone M01 — Make the optional Muse upstream production-ready and deploy it

### Outcome

The related fork accepts the actual CLIProxyAPI model catalog contract while preserving Muse-only filtering, failure isolation and route ownership; Workstation then consumes an immutable release containing that correction, supplies the optional CLIProxyAPI endpoint and persistent ingress key, and production model discovery plus request routing expose available `muse-*` models without changing the primary Codex-LB or `chatgpt-web/*` routes.

### Planned work

0. Preserve completed Workstation preparation:
   - retain the already-GREEN repository wiring from M01-T01;
   - retain the dormant persistent Muse key file and its verified restrictive metadata;
   - keep production `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` unset until the corrected fork has been released, consumed and preflighted.

1. Correct the live CLIProxyAPI catalog contract in `elmakus/codex-chatgpt-web`:
   - make the optional Muse catalog path accept the actual OpenAI-compatible CLIProxyAPI `/v1/models` response used in production, where rows are under `data` and public model identity is in `id`;
   - normalize only eligible `muse-*` rows into the fork's Codex model-catalog surface before merge;
   - continue excluding every non-`muse-*` CLIProxyAPI row;
   - preserve ordinary native/Codex-LB routing, `chatgpt-web/*` catalog placement, separate Muse authentication, fail-closed Muse request routing, optional-catalog failure isolation and the v5.0.13 configured-upstream proxy-resolution correction;
   - add automated regression coverage using a fixture that matches the observed live CLIProxyAPI response shape, including Muse-only filtering and failure isolation;
   - run the fork's required CI/test/package gates and independently review the exact correction subject when required by that repository's workflow.

2. Publish and freeze a corrected fork release:
   - merge the accepted fork correction through its normal branch/PR path;
   - publish an immutable release containing the catalog compatibility correction and retain exact release/commit/checksum evidence;
   - do not use a bare version threshold as proof: production preflight must bind to the exact release/commit known to contain both the catalog correction and the earlier configured-upstream proxy-resolution fix.

3. Update Workstation to consume the corrected release:
   - because production currently runs v5.0.13, use the repository-owned D25 `resolve -> freeze -> build -> validate -> promote` path to build and promote a Workstation image that embeds the corrected fork release;
   - require the normal candidate provenance, health, runtime verification and rollback gates before Muse activation;
   - after promotion, verify the installed `codex-web-gpt` identity/capability against the exact corrected release subject.

4. Production activation:
   - only after the corrected-release preflight is GREEN, set `CODEX_CHATGPT_WEB_MUSE_UPSTREAM=http://192.168.2.104:8317/v1`;
   - reuse the already-provisioned persistent Muse key after metadata/readability recheck; do not copy its value into Git or Workstation `.env`;
   - recreate the Workstation through repository-owned Compose using the exact frozen resolution environment for the running image. A raw Compose invocation without those frozen inputs is not a valid deployment path because interpolation fails before mutation.

5. Verification:
   - repository/source checks remain GREEN and no secret is committed or emitted;
   - production readback proves `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM` is unchanged and the Muse endpoint is present only after the corrected-release gate;
   - key-file readback verifies only presence/ownership/mode/readability;
   - direct authenticated CLIProxyAPI evidence records the public catalog shape and available `muse-*` IDs without emitting the key;
   - Workstation-side model discovery includes the expected available `muse-*` rows, retains ordinary native plus `chatgpt-web/*`, and excludes all CLIProxyAPI non-`muse-*` rows;
   - secret-safe functional route smokes prove one ordinary native request still succeeds through Codex-LB, one available `muse-*` request succeeds through CLIProxyAPI, and one browser-backed `chatgpt-web/*` request remains functional;
   - exact corrected-release automated/source evidence proves Muse-catalog failure isolation without intentionally degrading production; use an isolated/staged failure check only if release evidence is insufficient;
   - existing Workstation health and runtime verification remain GREEN.

### Rollback

If corrected-release activation fails acceptance:
- unset `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` and recreate the Workstation with the same frozen image/resolution;
- verify the native upstream remains unchanged, Muse is unset, ordinary native plus `chatgpt-web/*` discovery remains available, and Workstation runtime is GREEN;
- the persistent Muse key may remain dormant;
- if the corrected Workstation image itself introduces a regression independent of Muse configuration, use the existing D25 image rollback path.

### Authorization

The operator's existing authorization covers the bounded production Workstation update/configuration/recreate described by this milestone. The related-fork source correction, PR/release and Workstation D25 consumption are repository changes inside the accepted D29 boundary. Deliberate production failure injection remains outside the authorization and is not required.

## Requirement coverage

- R1, R5 → already-complete Workstation Compose/example wiring plus final production readback.
- R2 → corrected fork retains routing ownership and Workstation does not duplicate provider routing.
- R3 → already-provisioned persistent key outside Git/`.env`, with secret-safe metadata verification.
- R4 → live-shape-compatible Muse catalog normalization, final merged-catalog verification and exact-release failure-isolation evidence.
- R6 → final production discovery, Muse-only filtering, native/Muse/browser-backed route smokes, health/readback and secret hygiene.

## Planning audit

GREEN.

R5 changes execution strategy only where R4 evidence proved the existing release insufficient. It does not change accepted product/system intent, route ownership, authorization boundaries or rollback semantics. The added fork correction is the minimum place to repair the contract mismatch because D29 explicitly assigns provider/catalog adaptation to `codex-chatgpt-web`; implementing a parallel adapter in Workstation would duplicate routing responsibility and violate the accepted boundary.

The sequencing is now fail-safe: keep Muse disabled -> correct and test the fork against the observed live catalog shape -> publish an immutable corrected release -> consume it through D25 -> preflight exact capability -> activate endpoint -> verify all three routes and isolation. Completed R4 work is preserved rather than repeated. The dormant key file is not a blocker or a reason to re-provision the secret.

Independent plan review is RECOMMENDED because R5 materially revises milestone execution strategy by adding a related-fork correction/release and mandatory Workstation image update before production activation.
