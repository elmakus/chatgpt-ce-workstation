# Independent review — zstd-safe Muse routing correction

Date: 2026-09-18

## Verdict

**GREEN**

## Independence and exact subject

- Reviewer: fresh normal ChatGPT chat; this chat did not implement the reviewed subject.
- Repository: `elmakus/codex-chatgpt-web`
- Branch: `feat/dual-native-upstreams`
- Review subject: `eeb57d0855f7baffc3089f66c7c84d2c06c40ef6`
- Corrective base / prior RED subject: `0cad74ba6f3f9bc13d6e973d94bc993d8b2ff5c3`
- Branch readback during review: exact branch head equals the review subject.
- Corrective range: exactly three commits ahead of the prior RED subject; changed files are only `src/native-passthrough.ts`, `src/native-network.ts`, and `tests/native-passthrough.test.ts`.

## Authority applied

M01-T03 requires every supported native request encoding, especially zstd, to classify `muse-*` from the already decoded model identity, route Muse only to CLIProxyAPI, keep encoded ordinary native traffic on Codex-LB, and preserve raw encoded bytes.

Its authority slice is:
- the blocking zstd finding in `implementation/reviews/dual-native-upstreams-correction-independent-review-2026-09-18.md`;
- the M01-T02 fail-closed contract.

## Independent findings

The prior blocker is corrected in the exact review subject:

- `forwardNativeCodexRequest()` parses POST bodies through the content-encoding-aware `readJsonRequestBody()`, which supports identity and zstd.
- The validated model string extracted from that decoded representation is passed as the second `NativeFetch` argument.
- The default production fetch path is `fetchNativeCodex(request, modelHint)`.
- `prepareNativeCodexRequest()` prefers `modelHint` for automatic route selection and falls back to reparsing only when no hint is available.
- Therefore a zstd-compressed `muse-*` request no longer loses model identity when the encoded body is preserved.
- Muse routing still fails closed when the Muse upstream is absent, while ordinary native models still select the native/Codex-LB route.
- Request rewriting reads and re-emits the request body bytes without changing `Content-Encoding`; when bridge scrubbing is unnecessary, the original encoded bytes remain the body.

The corrective regression additions cover:
1. zstd Muse with no Muse upstream -> fail closed;
2. zstd Muse with Muse configured -> CLIProxyAPI + Muse key + zstd header + exact byte preservation;
3. zstd ordinary native -> Codex-LB + native key + zstd header + exact byte preservation.

No scope expansion or unrelated behavioral change is present in the corrective range.

## Verification evidence and limitation

- Exact branch and commit ancestry were read back from GitHub.
- Exact corrective source and test changes were independently inspected.
- GitHub reports no combined commit statuses and no workflow runs for the exact review subject.
- The implementation evidence records a targeted local zstd route check as GREEN.
- Full Bun repository verification was not available for this subject before review; the new Bun regressions are present in source but were not independently executed in this review environment.

The unavailable full suite is retained as a verification limitation. It does not expose a contradictory code path or a remaining acceptance failure in the bounded T03 correction.

## Result

M01-T03 is **GREEN** at `eeb57d0855f7baffc3089f66c7c84d2c06c40ef6`.

This verdict closes only the bounded zstd correction review. Milestone M01 still requires its integrated independent acceptance review on the intended final subject.
