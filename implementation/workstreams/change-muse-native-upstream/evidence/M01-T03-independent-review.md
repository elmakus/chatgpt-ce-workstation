# M01-T03 independent review

Review subject: `elmakus/codex-chatgpt-web@9ec01b939a08a191082b551bc2d6dc738a0159e2`
Review owner: workstream Task Board Card `M01-T03`
Verdict: **GREEN**

## Authority reviewed

- `implementation/workstreams/change-muse-native-upstream/cards/M01-T03.md`
- `planning/MUSE_NATIVE_UPSTREAM_PLAN.md` R5 / M01
- `requirements/MUSE_NATIVE_UPSTREAM.md` R2, R4, R6
- `docs/DECISIONS.md` D29
- predecessor blocker evidence `M01-T02-live-activation-blocker.md`

## Exact subject and evidence

- Related-fork PR #11 is still draft/open and points to exact HEAD `9ec01b939a08a191082b551bc2d6dc738a0159e2` on base `main@9de6a670f1934f5f4843a9df0d4b0d408884798f`.
- Exact PR delta is limited to:
  - `src/model-catalog.ts`
  - `tests/model-catalog.test.ts`
  - `tests/server-models.test.ts`
- CI run `35580909483` for the exact subject completed successfully:
  - actionlint GREEN;
  - macOS `bun run verify`, package, app smoke GREEN;
  - Windows `bun run verify`, package, app smoke GREEN;
  - Ubuntu `bun run verify`, package, Linux AppImage ABI validation, app smoke GREEN.

## Findings

1. **Observed CLIProxyAPI shape is handled correctly.**
   The new path accepts `data[]` rows with public identity in `id`, preserves the exact ID as the Codex `slug`, de-duplicates repeated IDs, and imports only IDs beginning with `muse-`. Non-Muse CLIProxyAPI rows are excluded.

2. **Existing catalog compatibility is preserved.**
   The previous Codex-shaped `models[]` / `slug` form remains accepted and tested.

3. **Failure isolation is preserved.**
   `modelsRequest()` still treats Muse as an optional parallel backend. HTTP failure, malformed Muse schema, or merge failure is caught on the Muse path while the already-built primary native + `chatgpt-web/*` catalog is returned.

4. **Route/auth ownership remains unchanged.**
   The reviewed delta does not modify request routing or authentication. Exact-subject `native-network.ts` still routes `muse-*` requests to the separate Muse upstream/key, leaves non-Muse native requests on Codex-LB, and fails closed for Muse when its upstream/key is absent. Existing `tests/native-network-upstream.test.ts` covers those contracts and is included in `bun run test` / `bun run verify`.

5. **Normalized rows satisfy the current Codex catalog wire contract.**
   Independent comparison against current `openai/codex` source at `8f2c15c39871c0698cd76a22ae239d36f7e8c9b8` confirms the emitted descriptor supplies every `ModelInfo` field that lacks a serde default and uses valid values for the typed fields. Optional/defaulted context, capability and policy fields are deliberately not copied from an unrelated native model. This matches the Card requirement to make Muse rows discoverable/selectable without inventing unsupported capability claims.

6. **Change remains proportional.**
   The implementation adds only the bounded normalization needed by the observed live contract. It does not add a second provider router, generic CLIProxyAPI import layer, Workstation production mutation, release publication, or credential handling change.

## Acceptance result

All M01-T03 acceptance conditions are satisfied by the exact immutable subject and its CI/evidence. No corrective finding is required.

**GREEN**
