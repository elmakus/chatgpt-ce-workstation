# Independent milestone acceptance review — M01 dual native upstreams

Date: 2026-09-18

## Verdict

**GREEN / PR READY**

## Independence and exact subject

- Reviewer: fresh normal ChatGPT chat performing the milestone acceptance review; this chat did not implement the reviewed subject.
- Implementation repository: `elmakus/codex-chatgpt-web`
- Branch: `feat/dual-native-upstreams`
- Review subject / intended final M01 head: `eeb57d0855f7baffc3089f66c7c84d2c06c40ef6`
- Original milestone base: `f8dc469a43cc562a4173bb77f7a7d9fe2b569187`
- Project execution-state source: `elmakus/chatgpt-ce-workstation@dc134cf0a6f630391eef36ec361ccf6aa1015044:implementation/TASK_BOARD.yaml`
- Branch readback during review: `feat/dual-native-upstreams` points exactly at the review subject.
- Complete milestone range is 11 commits ahead of the original base and zero behind.

## Authority applied

M01 requires the user-approved parallel routing in the related fork:

- `chatgpt-web/*` stays on the local ChatGPT Web adapter;
- `muse-*` routes only to CLIProxyAPI / Meta;
- remaining native models route through the native/Codex-LB upstream.

The accepted review decisions remain in force:

- Muse is intended for simple single tasks, so its differing `multi_agent_version` is not a blocker;
- Muse context metadata must remain provider-reported rather than being hardcoded or overwritten.

The corrective contracts are also part of final milestone acceptance:

- missing Muse upstream must fail closed and must never fall through to Codex-LB or the official backend;
- supported encoded native requests, especially zstd, must retain the already-decoded Muse model identity for routing while preserving raw encoded bytes when no bridge scrub is required.

## Integrated findings

The exact final source satisfies the accepted M01 routing and authentication boundaries.

### Request routing

- `src/server.ts` keeps `chatgpt-web/*` on the local adapter and sends non-Web models through native passthrough.
- `src/native-network.ts` classifies public `muse-*` model IDs as the Muse route independently of whether the Muse upstream is configured.
- Missing Muse upstream therefore fails closed instead of reclassifying Muse as ordinary native traffic.
- Configured Muse requests are rewritten to the CLIProxyAPI base and use only the dedicated Muse ingress key.
- Non-Muse native requests continue to use the native/Codex-LB upstream and its separate key.
- Rewriting replaces the incoming Authorization bearer before either configured proxy is contacted.

### Encoded request correction

The prior zstd blocker is closed in the final subject.

- `forwardNativeCodexRequest()` decodes supported POST bodies through the content-encoding-aware body reader and extracts a validated model identity.
- That identity is passed as `modelHint` into the native network layer.
- Automatic routing prefers the decoded hint instead of reparsing preserved encoded bytes.
- When bridge history scrubbing is unnecessary, the original encoded bytes and `Content-Encoding: zstd` are retained.
- The bounded M01-T03 independent review is already GREEN at the same exact subject.

### Model catalog

- Primary native rows remain available from the native/Codex-LB catalog.
- Only `muse-*` rows are imported from the optional CLIProxyAPI catalog; unrelated provider rows are filtered.
- Failure of the optional Muse catalog does not take down the primary native catalog or the appended `chatgpt-web/*` rows.
- Muse catalog rows are not normalized through the bridge's native context override or compatibility `multi_agent_version`, matching the accepted decisions.

### Scope and diff

The complete M01 range changes only the documented routing/catalog surface and its tests/docs:

- `docs/codex-lb-upstream.md`
- `src/model-catalog.ts`
- `src/native-network.ts`
- `src/native-passthrough.ts`
- `src/server.ts`
- `tests/native-network-upstream.test.ts`
- `tests/native-passthrough.test.ts`
- `tests/server-models.test.ts`

No unrelated behavioral expansion was found in the accepted milestone range.

## Verification evidence and limitation

Independently confirmed during this review:

- exact branch head and commit ancestry;
- complete changed-file set from milestone base to final subject;
- final routing, passthrough, catalog, and server source at the exact subject;
- current regression coverage for configured Muse routing, missing-upstream fail-closed behavior, separate proxy credentials, catalog filtering/failure isolation, and all three zstd routing cases;
- exact subject has no GitHub workflow runs and no commit statuses.

The implementation evidence records targeted routing checks as GREEN, including the corrected zstd path. Full Bun repository verification remains unavailable in the current ChatGPT runtime because Bun is not installed and direct Git access to `github.com` cannot resolve. This is retained as a verification limitation; no contradictory source path or unresolved accepted-scope defect was found.

## Result

M01 integrated acceptance is **GREEN / PR READY** at `eeb57d0855f7baffc3089f66c7c84d2c06c40ef6`.

This verdict completes the independent milestone acceptance gate only. Publication/PR verification remains a separate next gate and must verify that any published PR artifact is exactly this accepted implementation state with no unreviewed behavioral drift.
