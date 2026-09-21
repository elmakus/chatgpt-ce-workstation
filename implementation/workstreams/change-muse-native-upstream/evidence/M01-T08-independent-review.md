# M01-T08 independent review

Date: 2026-09-21
Card: `M01-T08`
Verdict: **GREEN**

## Immutable subject

- Repository: `elmakus/codex-chatgpt-web`
- Subject: `2bd8a74a6f467767c7a640806720e672f7342471`
- Pull request: `elmakus/codex-chatgpt-web#13`
- Base: `2686d2a616864a1bc9cd975901773ab16a54ba47`

## Authority reviewed

- `requirements/MUSE_NATIVE_UPSTREAM.md` R2, R6, R7
- D29 — Muse optional parallel native upstream through CLIProxyAPI
- D30 — Muse-bound Codex turns intentionally omit Gmail tools
- approved `planning/MUSE_NATIVE_UPSTREAM_PLAN.md` R7 / M01 planned work 0–2
- `implementation/workstreams/change-muse-native-upstream/cards/M01-T08.md`
- accepted R1 research and M01-T06 production baseline

## Independent findings

The exact PR changes only `src/native-passthrough.ts` and `tests/native-passthrough.test.ts`.

The implementation gates the compatibility rewrite on all required conditions: native `responses`, a validated model string beginning `muse-`, a top-level tool with exact `type: "namespace"`, and exact `name: "mcp__codex_apps__gmail"`. It removes only matching Gmail namespace entries and preserves non-Gmail tool order/content through `Array.prototype.filter`.

When no exact Gmail namespace is present, the Muse filter reports `changed: false`; the existing byte-preserving request path remains in use unless the pre-existing bridge-artifact scrubber independently requires a rewrite. Ordinary native/Codex-LB requests therefore keep Gmail and compressed bytes unchanged. Browser-backed `chatgpt-web/*` code is outside the changed files.

For rewritten zstd Muse requests, the existing forwarding boundary deletes stale `content-encoding`; `endToEndHeaders` already removes `content-length`, so the reserialized body is not forwarded with stale transfer metadata. Existing native routing, Muse routing, authentication separation, bridge scrubbing and failure behavior remain on their established boundaries.

The focused regression uses the recursive Gmail namespace shape established by R1, proves preservation/order of representative non-Gmail function and namespace tools, proves Muse routing and Muse credential selection, proves stale `content-encoding` removal on rewrite, and proves ordinary native Gmail remains byte-for-byte unchanged. The pre-existing Muse-without-Gmail zstd test remains a byte-for-byte no-op control.

No version/release metadata, Workstation runtime/configuration, CLIProxyAPI source/configuration, or credential material is changed by the subject.

## CI readback

GitHub Actions run `35598358048` is GREEN on exact head `2bd8a74a6f467767c7a640806720e672f7342471`:

- `actionlint`: GREEN
- macOS 15: `bun run verify`, package, app smoke — GREEN
- Ubuntu: `bun run verify`, package, Linux AppImage ABI, app smoke — GREEN
- Windows: installer validation, `bun run verify`, package, app smoke — GREEN

## Verdict

**GREEN.** The immutable subject satisfies the M01-T08 Card contract and the applicable R7/D29/D30 authority without broadening the compatibility mechanism beyond the accepted Muse-only Gmail exception.
