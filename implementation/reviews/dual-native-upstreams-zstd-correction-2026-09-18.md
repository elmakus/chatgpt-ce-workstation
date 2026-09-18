# Dual native upstreams — zstd-safe routing correction

Date: 2026-09-18

## Corrective subject

- Repository: `elmakus/codex-chatgpt-web`
- Branch: `feat/dual-native-upstreams`
- Corrective base / RED subject: `0cad74ba6f3f9bc13d6e973d94bc993d8b2ff5c3`
- Corrected implementation head: `eeb57d0855f7baffc3089f66c7c84d2c06c40ef6`
- Corrective card: `M01-T03`

## RED finding addressed

The independent re-review found that zstd-compressed `muse-*` requests could still fall through to ordinary native routing. `native-passthrough` already decoded zstd and extracted the model, but `native-network` reparsed the preserved encoded body with ordinary `Request.json()`, failed to recover the model, and selected the native route.

## Correction

The already validated model identity is now carried across the passthrough/network boundary:

- `NativeFetch` accepts an optional `modelHint`.
- `forwardNativeCodexRequest()` passes the model extracted from the content-encoding-aware decoded body.
- `fetchNativeCodex()` forwards that hint to `prepareNativeCodexRequest()`.
- automatic routing prefers the supplied decoded model hint and only falls back to reparsing the request when no hint is available.

The encoded request bytes and `Content-Encoding: zstd` remain unchanged when native history scrubbing is not required.

## Regression coverage added

`tests/native-passthrough.test.ts` now covers the exact supported zstd path:

1. zstd-compressed `muse-spark-1.3` with Codex-LB configured but no Muse upstream fails closed with the Muse-upstream configuration error;
2. zstd-compressed `muse-spark-1.3` with Muse configured routes to CLIProxyAPI, uses the Muse ingress key, retains `Content-Encoding: zstd`, and preserves the exact encoded bytes;
3. zstd-compressed `gpt-5.6-sol` continues to route to Codex-LB with the native key and preserves the encoded bytes.

## Verification performed

- GitHub readback confirms the corrective branch is exactly three commits ahead of the RED subject and changes only:
  - `src/native-passthrough.ts`
  - `src/native-network.ts`
  - `tests/native-passthrough.test.ts`
- Exact branch readback confirms `feat/dual-native-upstreams` points to `eeb57d0855f7baffc3089f66c7c84d2c06c40ef6`.
- A targeted local Node zstd routing check using the same decode -> model identity -> route decision sequence returned `TARGETED_ZSTD_ROUTE_CHECK_GREEN`.

## Verification limitation

Full Bun repository verification was not executable in this ChatGPT runtime:

- `bun` is not installed;
- direct Git access to `github.com` fails because DNS resolution is unavailable;
- GitHub reports no workflow runs or commit statuses for the corrected head;
- repository CI triggers on pull requests or pushes to `main`, not on this implementation branch directly.

No PR was opened solely to obtain CI before the required independent review.

## Review boundary

This is implementation evidence only, not an independent verdict. Because the correction changes the reviewed routing subject and M01 remains under independent review, a fresh normal ChatGPT chat must independently review the exact corrected head before M01 can become GREEN.
